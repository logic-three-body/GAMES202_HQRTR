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
   // TODO: To calculate GGX NDF here
   float NdotH = max((dot(N,H)),0.0);
   float NdotH2 = NdotH * NdotH;
   float a2 = roughness * roughness;  
   float d = (NdotH * a2 - NdotH) * NdotH + 1.0; // 2 mad  from Unity
   return  a2 / ((d * d + 1e-7)*PI);   
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
    return GeometrySchlickGGX(LdotH,roughness)*GeometrySchlickGGX(VdotH,roughness);
}

float Pow5(float x)
{
    return x*x*x*x*x;
}

vec3 fresnelSchlick(vec3 F0, vec3 V, vec3 H)
{
    // TODO: To calculate Schlick F here
    float cosA = dot(V,H);
    float t = Pow5(1.0 - cosA);
    return F0 + (vec3(1.0)-F0) * t;
}
```

![PBR1](https://i.loli.net/2021/06/30/QMZKctNV437wpYX.gif)

## Kulla-Conty