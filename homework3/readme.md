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

间接光着色（spp=1）

```glsl
  //indir shading:
  for(int i=0;i<SAMPLE_NUM;++i)
  {
    float pdf=0.0;
    vec3 dir=SampleHemisphereUniform(s,pdf);
    //vec3 dir=SampleHemisphereCos(s,pdf);
    dir = dirToWorld(normal,dir);
    vec3 hitPos=vec3(0.0);
    vec3 direct = normalize(vec3(1.0,0.0,0.0));
    direct = normalize(dir);
    if(RayMarch(worldPos,direct,hitPos))
    {
      vec2 uv1=GetScreenCoordinate(hitPos);
      if(length(res)>0.0) 
        indir += res;//avoid neg   
    }
  }
```

![间接光](https://i.loli.net/2021/06/06/tEuHrnKIZAs74iN.gif)



## 其他图片结果

### cube2 

#### 直接光

#### ![直接光cube](https://i.loli.net/2021/06/06/8hXzv7RuApMOfjB.png)

#### 间接光spp=100

#### ![间接光cube](https://i.loli.net/2021/06/06/ALowkM8OFeQZdyX.png)

#### 直接光+间接光spp=100

#### ![直接光+间接光cube](https://i.loli.net/2021/06/06/6lno4VzcE3PiewF.png)

### cave
#### 直接光

![直接光cave](https://i.loli.net/2021/06/06/pAMqtfR1lL4cFU3.png)

#### 间接光spp=100

![间接光cave](https://i.loli.net/2021/06/06/j2kNBTYmoV6M3fO.png)

#### 直接光+间接光spp=100

![直接光+间接光cave](https://i.loli.net/2021/06/06/mAnztkgGE7IOZ39.png)

## 主函数 main

```glsl
vec3 dirToWorld(vec3 normal,vec3 localDir)
{
  vec3 b1=vec3(0.0);
  vec3 b2=vec3(0.0);
  LocalBasis(normal,b1,b2);
  mat3 tbn = mat3(b1,b2,normal);
  return tbn*localDir;
}
```



```glsl
void main() {
  float s = InitRand(gl_FragCoord.xy);
  vec3 L = vec3(0.0);
  vec3 worldPos = vPosWorld.xyz;
  vec2 uv0 = GetScreenCoordinate(worldPos);
  vec3 dirL = EvalDirectionalLight(uv0);
  //L = GetGBufferDiffuse(uv0);
  vec3 wi = normalize(uLightDir);
  vec3 wo = normalize(uCameraPos - worldPos);
  float scale = 5.0;
  L+=dirL*EvalDiffuse(wi,wo,uv0)*scale;
  //L = dirL/scale;
  vec3 normal = GetGBufferNormalWorld(uv0);
  //raymarch:
  vec3 indir=vec3(0.0);

  //test mirro:
  // vec3 test_dir = vec3(0.0);
  // test_dir=reflect(-wo,normal);
  // vec3 test_hit;
  // if(RayMarch(worldPos,test_dir,test_hit))
  // {
  //   indir = GetGBufferDiffuse(GetScreenCoordinate(test_hit));    
  // }


  //indir shading:
  for(int i=0;i<SAMPLE_NUM;++i)
  {
    float pdf=0.0;
    vec3 dir=SampleHemisphereUniform(s,pdf);
    //vec3 dir=SampleHemisphereCos(s,pdf);
    dir = dirToWorld(normal,dir);
    vec3 brdf0 = EvalDiffuse(wi,wo,uv0)/pdf;
    vec3 hitPos=vec3(0.0);
    vec3 direct = normalize(vec3(1.0,0.0,0.0));
    direct = normalize(dir);
    if(RayMarch(worldPos,direct,hitPos))
    {
      vec2 uv1=GetScreenCoordinate(hitPos);
      vec3 res = brdf0*EvalDiffuse(-wi,vec3(0.0),uv1)
                 *EvalDirectionalLight(uv1);      
      //vec3 res = EvalDiffuse(-direct,vec3(0.0),uv1);
      if(length(res)>0.0) 
        indir += res;//avoid neg   
    }
  }
  indir/=float(SAMPLE_NUM);
  //L= indir*10.0;
  L+=indir;
  vec3 color = pow(clamp(L, vec3(0.0), vec3(1.0)), vec3(1.0 / 2.2));
  //color=vec3(0.6);
  gl_FragColor = vec4(vec3(color.rgb), 1.0);
}
```

