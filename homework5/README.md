# assignment5 Real Time Ray Tracing Denoise

项目地址：[here](https://github.com/logic-three-body/GAMES202_HQRTR/tree/master/homework5)

## 单帧降噪

```C++
// Joint bilateral filter kernel
float J_kernel(float distanceSqr, float colorDistSqr, float normalDistSqr,
               float positionDistSqr, float sigma_p, float sigma_c, float sigma_n,
               float sigma_d) {

    return exp(-(distanceSqr / (2 * Sqr(sigma_p))) - (colorDistSqr / (2 * Sqr(sigma_c))) -
               (normalDistSqr / (2 * Sqr(sigma_n))) -
               (positionDistSqr / (2 * Sqr(sigma_d))));
}

// Find the distance between pixels
float distanceSqr(int i_x, int i_y, int j_x, int j_y) {
    return float(pow((i_x - j_x), 2) + pow((i_y - j_y), 2));
}
```

```c++
for (int y = 0; y < height; ++y)
{
	for (int x = 0; x < width; ++x)
	{
		// TODO: Joint bilateral filter
		filteredImage(x, y) = frameInfo.m_beauty(x, y);
		filteredNormal(x, y) = Normalize(frameInfo.m_normal(x, y));
		filteredPos(x, y) = frameInfo.m_position(x, y);

		float weight = 0.0; // weight_xy sum
		for (int i_y = y - kernelRadius; i_y <= y + kernelRadius; ++i_y)
		{
			for (int i_x = x - kernelRadius; i_x <= x + kernelRadius; ++i_x)
			{
				float w_ixy = 0.0;
				// Out of Bounds
				if (i_y < 0 || i_y >= height || i_x < 0 || i_x >= width)
				{
					continue;
				}
				else
				{
					filteredImage(i_x, i_y) = frameInfo.m_beauty(i_x, i_y);
					filteredNormal(i_x, i_y) =
						Normalize(frameInfo.m_normal(i_x, i_y));
					filteredPos(i_x, i_y) = frameInfo.m_position(i_x, i_y);
					float DisSqr = distanceSqr(x, y, i_x, i_y);
					float colorDistSqr =
						SqrLength(filteredImage(x, y) - filteredImage(i_x, i_y));
					float NormDot =
						Dot(filteredNormal(x, y), filteredNormal(i_x, i_y));
					NormDot = std::clamp(NormDot, 0.0f, 1.0f);

					float DnormalSqr = Sqr(SafeAcos(NormDot));
					Float3 DistancePos =
						Normalize((filteredPos(i_x, i_y) - filteredPos(x, y)));
					float Dplane = Dot(filteredNormal(x, y), DistancePos);
					Dplane = std::clamp(Dplane, 1e-5f, 1.0f);

					w_ixy = J_kernel(DisSqr, colorDistSqr, DnormalSqr, Dplane,
									 m_sigmaCoord, m_sigmaColor, m_sigmaNormal,
									 m_sigmaPlane);
					FinalImage(x, y) += filteredImage(i_x, i_y) * w_ixy;
					// add weights
					weight += w_ixy;
				}
			}
		}
		if (0.0 != weight)
		{
			FinalImage(x, y) /= weight;
		}
		else
		{
			FinalImage(x, y) = 0.0;
		}

		filteredImage(x, y) = float(0.0);
	}
}
```

![box-result-filter](https://i.loli.net/2021/08/12/DZqoLQhOegy3Jtl.gif)

```c++
m_sigmaColor = 8.4;//下图
```

![pinkroom-result-filter](https://i.loli.net/2021/08/12/F5MHcWO7SZyQj82.gif)

## 投影上一帧结果

```c++
for (int y = 0; y < height; y++)
{
	for (int x = 0; x < width; x++)
	{
		// TODO: Reproject
		int id = static_cast<int>(frameInfo.m_id(x, y));
		if (-1 != id)
		{

			Matrix4x4 InvModel = Inverse(frameInfo.m_matrix[id]);
			Matrix4x4 PreModel = m_preFrameInfo.m_matrix[id];
			//上一点屏幕坐标<-MVP(上一帧即运动前)-运动前模型坐标<-逆模型矩阵-当前位置
			// Matrix4x4 Reprojection =
			//    preWorldToScreen * PreModel * InvModel;

			Float3 inv_pos = InvModel(frameInfo.m_position(x, y), Float3::Point);
			Float3 pre_pos = PreModel(inv_pos, Float3::Point);
			Float3 proj_pos = preWorldToScreen(pre_pos, Float3::Point);

			int prex = static_cast<int>(proj_pos.x);
			int prey = static_cast<int>(proj_pos.y);
			if (prex < 0 || prex >= width || prey < 0 ||
				prey >= height)
			{ // for pink room boundary check
				m_valid(x, y) = false;
				continue;
			}
			int pre_id = static_cast<int>(m_preFrameInfo.m_id(prex, prey));
			if (pre_id != id)
			{
				m_valid(x, y) = false;
				continue;
			}
			else
			{
				m_valid(x, y) = true;
				m_misc(x, y) = m_accColor(prex, prey);
			}
		}
	}
}
```

![box-proj](https://i.loli.net/2021/08/12/yABvx2SZOFKRGnf.gif)

```c++
m_colorBoxK = 0.1f;//下图
```

![PinkProj_K=0.1](https://i.loli.net/2021/08/12/6m7VbnpEe5Bwk3T.gif)

## 累计多帧信息

```c++
for (int y = 0; y < height; y++)
{
	for (int x = 0; x < width; x++)
	{
		// TODO: Temporal clamp
		Float3 color = m_accColor(x, y);
		Float3 mu(0.0f);
		for (int i = -kernelRadius; i <= kernelRadius; i++)
		{
			for (int j = -kernelRadius; j <= kernelRadius; j++)
			{
				int x_i = x + i;
				int y_j = y + j;
				mu += curFilteredColor(x_i, y_j);
			}
		}
		mu /= Sqr(static_cast<float>(kernelRadius * 2 + 1));
		Float3 sigma(0.0f);
		for (int i = -kernelRadius; i <= kernelRadius; i++)
		{
			for (int j = -kernelRadius; j <= kernelRadius; j++)
			{
				int x_i = x + i;
				int y_j = y + j;
				sigma += Sqr(curFilteredColor(x_i, y_j) - mu);
			}
		}
		sigma /= Sqr(static_cast<float>(kernelRadius * 2 + 1));
		if (1280 == width)
		{	// for pink room
			//m_colorBoxK = 2.0f;
			//m_colorBoxK = 0.5f;
			//m_colorBoxK = 0.25f;
			m_colorBoxK = 0.1f;
		}
		color = Clamp(color, mu - sigma * m_colorBoxK, mu + sigma * m_colorBoxK);

		// TODO: Exponential moving average
		float alpha = 1.0f;
		if (m_valid(x, y))
		{
			alpha = m_alpha;
		}
		m_misc(x, y) = Lerp(color, curFilteredColor(x, y), alpha);
		//m_misc(x, y) =
		//    Lerp(curFilteredColor(x, y), color, alpha); // for debug reproject
	}
}
```

![box-result](https://i.loli.net/2021/08/12/LyEZ48YiA7N2uFJ.gif)

![pinkroom-result](https://i.loli.net/2021/08/12/UjlQBv3y1DOpKEh.gif)

## 其他

更改部分数学函数以排除**除0**情况。

