# GAMES202->assignment4 Kulla-Conty BRDF

## PBR

### 初始状态

```glsl
float DistributionGGX(vec3 N, vec3 H, float roughness)
{
   // TODO: To calculate GGX NDF here
   return 1.0;  
}
float GeometrySchlickGGX(float NdotV, float roughness)
{
    // TODO: To calculate Smith G1 here   
    return 1.0;
}
float GeometrySmith(vec3 N, vec3 V, vec3 L, float roughness)
{
    // TODO: To calculate Smith G here
    return 1.0;
}
vec3 fresnelSchlick(vec3 F0, vec3 V, vec3 H)
{
    // TODO: To calculate Schlick F here
    return vec3(1.0);
}
```

### 补充公式

![初始状态](https://i.loli.net/2021/06/29/Z2qJBsxXPK5HmV6.gif)

```glsl
float DistributionGGX(vec3 N, vec3 H, float roughness)
{
    float a = roughness*roughness;
    float a2 = a*a;
    float NdotH = max(dot(N, H), 0.0);
    float NdotH2 = NdotH*NdotH;
    float nom   = a2;
    float denom = (NdotH2 * (a2 - 1.0) + 1.0);
    denom = PI * denom * denom;
    return nom / max(denom, 0.0001);
}

float GeometrySchlickGGX(float NdotV, float roughness) {
    float a = roughness;
    float k = (a * a) / 2.0;
    float nom = NdotV;
    float denom = NdotV * (1.0 - k) + k;
    return nom / denom;
}

float GeometrySmith(vec3 N, vec3 V, vec3 L, float roughness)
{
    // TODO: To calculate Smith G here
    float NdotL = max(dot(N,L),0.0);
    float NdotV = max(dot(N,V),0.0);
    return GeometrySchlickGGX(NdotL, roughness)*GeometrySchlickGGX(NdotV, roughness);
}

float Pow5(float x)
{
    return x*x*x*x*x;
}

vec3 fresnelSchlick(vec3 F0, vec3 V, vec3 H)
{
    // TODO: To calculate Schlick F here
    float cosA = max(dot(V,H),0.0);
    float t = Pow5(1.0 - cosA);
    return F0 + (vec3(1.0)-F0) * t;
}
```

![PBR2](https://i.loli.net/2021/06/30/3pCDMlWy8kYNtZI.gif)

![image-20210630150640416](https://i.loli.net/2021/06/30/6xP1VU4fHjcbuvB.png)

## Kulla-Conty