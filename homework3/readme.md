# assignment 3 Screen Space Ray Tracing

## EvalDir

```glsl
vec3 EvalDirectionalLight(vec2 uv) {
  vec3 lightDirWS = normalize(uLightDir);
  vec3 normalWS = normalize(GetGBufferNormalWorld(uv));
  float ndotl = max(0.0,dot(lightDirWS,normalWS));
  float visibility = GetGBufferuShadow(uv);
  Le = uLightRadiance * visibility * ndotl;
  return Le;
}
```

![dir_only](https://i.loli.net/2021/06/05/dr3AWa9bjVmhvEJ.gif)

## EvalDiffuse

```glsl
vec3 EvalDiffuse(vec3 wi, vec3 wo, vec2 uv) {
  vec3 normal = normalize(GetGBufferNormalWorld(uv));
  vec3 diff = GetGBufferDiffuse(uv);
  float cosTheta = dot(normalize(wi),normal);
  vec3 L = diff * INV_PI * cosTheta;
  return L;
}
```

main：

```glsl
vec3 worldPos = vPosWorld.xyz;
vec2 uv0 = GetScreenCoordinate(worldPos);
vec3 wi = normalize(uLightDir);
vec3 wo = normalize(uCameraPos - worldPos);
float scale = 5.0;
vec3 dirL = EvalDirectionalLight(uv0);
L+=dirL*EvalDiffuse(wi,wo,uv0)*scale;
```

![dir+Diff](https://i.loli.net/2021/06/05/73yn8sEIHYKA2LN.gif)

## RayMarch