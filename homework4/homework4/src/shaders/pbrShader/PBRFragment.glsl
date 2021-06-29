#ifdef GL_ES
precision mediump float;
#endif

uniform vec3 uLightPos;
uniform vec3 uCameraPos;
uniform vec3 uLightRadiance;
uniform vec3 uLightDir;

uniform sampler2D uAlbedoMap;
uniform float uMetallic;
uniform float uRoughness;
uniform sampler2D uBRDFLut;
uniform samplerCube uCubeTexture;

varying highp vec2 vTextureCoord;
varying highp vec3 vFragPos;
varying highp vec3 vNormal;

const float PI = 3.14159265359;

float DistributionGGX(vec3 N, vec3 H, float roughness)
{
   // TODO: To calculate GGX NDF here
   float NdotH = max((dot(N,H)),0.0);
   float a2 = roughness * roughness;  
 //  float d = (NdotH * a2 - NdotH) * NdotH + 1.0; // 2 mad  from Unity
   float d = (a2-1.0)+1.0; 
 //   return  a2 / ((d * d + 1e-7)*PI);   
   return a2/(PI*NdotH*NdotH*d*d);
}

float GeometrySchlickGGX(float NdotV, float roughness)
{
    // TODO: To calculate Smith G1 here
    float k = (roughness+1.0)*(roughness+1.0)/8.0;  
    return NdotV/(NdotV*(1.0-k)+k);
}

float GeometrySmith(vec3 N, vec3 V, vec3 L, float roughness)
{
    // TODO: To calculate Smith G here
    vec3 H = normalize(V + L);
    float VdotH = max(dot(L,H),0.0);
    float LdotH = max(dot(V,H),0.0);
    return GeometrySchlickGGX(VdotH,roughness)*GeometrySchlickGGX(LdotH,roughness);
}

float Pow5(float x)
{
    return x*x*x*x*x;
}

vec3 fresnelSchlick(vec3 F0, vec3 V, vec3 H)
{
    // TODO: To calculate Schlick F here
    V = normalize(V);
    H = normalize(H);
    float cosA = dot(V,H);
    float t = Pow5(1.0 -cosA);
    return F0 + (vec3(1.0)-F0) * t;
}

void main(void) {
  vec3 albedo = pow(texture2D(uAlbedoMap, vTextureCoord).rgb, vec3(2.2));

  vec3 N = normalize(vNormal);
  vec3 V = normalize(uCameraPos - vFragPos);
  float NdotV = max(dot(N, V), 0.0);
 
  vec3 F0 = vec3(0.04); 
  F0 = mix(F0, albedo, uMetallic);

  vec3 Lo = vec3(0.0);

  vec3 L = normalize(uLightDir);
  vec3 H = normalize(V + L);
  float NdotL = max(dot(N, L), 0.0); 

  vec3 radiance = uLightRadiance;

  float NDF = DistributionGGX(N, H, uRoughness);   
  float G   = GeometrySmith(N, V, L, uRoughness); 
  vec3 F = fresnelSchlick(F0, V, H);
      
  vec3 numerator    = NDF * G * F; 
  float denominator = max((4.0 * NdotL * NdotV), 0.001);
  vec3 BRDF = numerator / denominator;

  Lo += BRDF * radiance * NdotL;
  vec3 color = Lo;

  color = color / (color + vec3(1.0));
  color = pow(color, vec3(1.0/2.2)); 
  gl_FragColor = vec4(color, 1.0);
}