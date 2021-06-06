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

```glsl
bool RayMarch(vec3 ori, vec3 dir, out vec3 hitPos) {
  vec2 ori_uv = GetScreenCoordinate(ori);
  vec2 dir_uv = GetScreenCoordinate(dir);
  float step_size = 2.0/float(total_step)/length(dir_uv);
  
  const int first_step=1;
  for(int i = first_step;i<=total_step;++i)
  { 
    vec3 pos = ori+dir*step_size*float(i);
    vec2 pos_uv = GetScreenCoordinate(pos);
    if(GetGBufferDepth(pos_uv)+EPS<GetDepth(pos))
    {
      hitPos = pos;
      return true;
    }
  }
 // hitPos = vec3(normalize(dir_uv),0.0);
  return false;
}
```

镜面反射查询

```glsl
  //test mirro:
  vec3 test_dir = vec3(0.0);
  test_dir=reflect(-wo,normal);
  vec3 test_hit;
  if(RayMarch(worldPos,test_dir,test_hit))
  {
    indir = GetGBufferDiffuse(GetScreenCoordinate(test_hit));    
  }
```

![镜面反射handin](https://i.loli.net/2021/06/06/3bDSpK4ZitxrJwe.gif)