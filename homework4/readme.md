# GAMES202->assignment4 Kulla-Conty BRDF

## PBR

初始状态

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

![初始状态](https://i.loli.net/2021/06/29/Z2qJBsxXPK5HmV6.gif)

## Kulla-Conty