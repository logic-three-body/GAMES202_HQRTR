#include "denoiser.h"

Denoiser::Denoiser() : m_useTemportal(false) {}

void Denoiser::Reprojection(const FrameInfo &frameInfo) {
    int height = m_accColor.m_height;
    int width = m_accColor.m_width;
    Matrix4x4 preWorldToScreen =
        m_preFrameInfo.m_matrix[m_preFrameInfo.m_matrix.size() - 1];
    Matrix4x4 preWorldToCamera =
        m_preFrameInfo.m_matrix[m_preFrameInfo.m_matrix.size() - 2];
#pragma omp parallel for
    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            // TODO: Reproject
            m_valid(x, y) = false;
            m_misc(x, y) = Float3(0.f);
        }
    }
    std::swap(m_misc, m_accColor);
}

void Denoiser::TemporalAccumulation(const Buffer2D<Float3> &curFilteredColor) {
    int height = m_accColor.m_height;
    int width = m_accColor.m_width;
    int kernelRadius = 3;
#pragma omp parallel for
    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            // TODO: Temporal clamp
            Float3 color = m_accColor(x, y);
            // TODO: Exponential moving average
            float alpha = 1.0f;
            m_misc(x, y) = Lerp(color, curFilteredColor(x, y), alpha);
        }
    }
    std::swap(m_misc, m_accColor);
}

/*
reference:
https://github.com/ydaiydai/Filtering/blob/main/main.cpp
*/

// Joint bilateral filter kernel
float J_kernel(float distanceSqr, float colorDistSqr, float normalDistSqr,
               float positionDistSqr, float sigma_p, float sigma_c, float sigma_n,
               float sigma_d) {

    return exp(-(distanceSqr / (2 * Sqr(sigma_p))) -
               (colorDistSqr / (2 * Sqr(sigma_c))) -
               (normalDistSqr / (2 * Sqr(sigma_n))) -
               (positionDistSqr / (2 * Sqr(sigma_d))));
}

// Find the distance between pixels
float distanceSqr(int i_x, int i_y, int j_x, int j_y) {
    return float(pow((i_x - j_x), 2) + pow((i_y - j_y), 2));
}

// clamp function
float clamp(float num, float low, float high) {
    if (num > high) {
        return high;
    } else if (num < low) {
        return low;
    } else {
        return num;
    }
}

Buffer2D<Float3> Denoiser::Filter(const FrameInfo &frameInfo) {
    int height = frameInfo.m_beauty.m_height;
    int width = frameInfo.m_beauty.m_width;
    Buffer2D<Float3> filteredImage = CreateBuffer2D<Float3>(width, height);  // color
    Buffer2D<Float3> FinalImage = CreateBuffer2D<Float3>(width, height);  // color
    Buffer2D<Float3> filteredNormal = CreateBuffer2D<Float3>(width, height); // normal
    Buffer2D<Float3> filteredPos = CreateBuffer2D<Float3>(width, height); // position
    int kernelRadius = 16;
    // Parameters

#pragma omp parallel for
    for (int y = 0; y < height; ++y) {
        for (int x = 0; x < width; ++x) {
            // TODO: Joint bilateral filter
            filteredImage(x, y) = frameInfo.m_beauty(x, y);
            filteredNormal(x, y) = frameInfo.m_normal(x, y);
            filteredPos(x, y) = frameInfo.m_position(x, y);

            float weight = 0.0;//weight_xy sum
            for (int i_y = y - kernelRadius; i_y <= y + kernelRadius; ++i_y) 
			{
                for (int i_x = x - kernelRadius; i_x <= x + kernelRadius; ++i_x) 
				{
                    float w_ixy = 0.0;
					//Out of Bounds
                    if (i_y<0||i_y>=height||i_x<0||i_x>=width) 
					{
                        continue;
                    } 
					else 
					{
                        filteredImage(i_x, i_y) = frameInfo.m_beauty(i_x, i_y);
                        filteredNormal(i_x, i_y)= frameInfo.m_normal(i_x, i_y);
                        filteredPos(i_x, i_y) = frameInfo.m_position(i_x, i_y);
                        float DisSqr = distanceSqr(x, y, i_x, i_y);
                        float colorDistSqr =
                            SqrLength(filteredImage(x, y) - filteredImage(i_x, i_y));
                        float NormDot =
                            Dot(filteredNormal(x, y), filteredNormal(i_x, i_y));
                        float DnormalSqr = Sqr(SafeAcos(NormDot));
                        Float3 DistancePos =//don't divide into zero
                            (filteredPos(i_x, i_y) - filteredPos(x, y)) /
                            clamp(Distance(filteredPos(i_x, i_y), filteredPos(x, y)),1e-5,1.0);
                        float Dplane = Dot(filteredNormal(x, y), DistancePos);

						w_ixy = J_kernel(DisSqr, colorDistSqr, DnormalSqr, Dplane,m_sigmaCoord,m_sigmaColor,m_sigmaNormal,m_sigmaPlane);
                        FinalImage(x, y) += filteredImage(i_x, i_y) * w_ixy;
						//add weights
                        weight += w_ixy;                       
					}
                }
            }
            if (0.0!=weight) 
			{
                FinalImage(x, y) /= weight;
            }
            //filteredImage(x, y) = float(0.0);

        }
    }
  
    //return filteredImage;
    return FinalImage;
}

void Denoiser::Init(const FrameInfo &frameInfo, const Buffer2D<Float3> &filteredColor) {
    m_accColor.Copy(filteredColor);
    int height = m_accColor.m_height;
    int width = m_accColor.m_width;
    m_misc = CreateBuffer2D<Float3>(width, height);
    m_valid = CreateBuffer2D<bool>(width, height);
}

void Denoiser::Maintain(const FrameInfo &frameInfo) { m_preFrameInfo = frameInfo; }

Buffer2D<Float3> Denoiser::ProcessFrame(const FrameInfo &frameInfo) {
    // Filter current frame
    Buffer2D<Float3> filteredColor;
    filteredColor = Filter(frameInfo);

    // Reproject previous frame color to current
    if (m_useTemportal) {
        Reprojection(frameInfo);
        TemporalAccumulation(filteredColor);
    } else {
        Init(frameInfo, filteredColor);
    }

    // Maintain
    Maintain(frameInfo);
    if (!m_useTemportal) {
        m_useTemportal = true;
    }
    return m_accColor;
}
