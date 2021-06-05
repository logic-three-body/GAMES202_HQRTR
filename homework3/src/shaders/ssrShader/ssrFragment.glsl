#ifdef GL_ES
precision highp float;
#endif

uniform vec3 uLightDir;
uniform vec3 uCameraPos;
uniform vec3 uLightRadiance;
uniform sampler2D uGDiffuse;
uniform sampler2D uGDepth;
uniform sampler2D uGNormalWorld;
uniform sampler2D uGShadow;
uniform sampler2D uGPosWorld;

varying mat4 vWorldToScreen;
varying highp vec4 vPosWorld;

#define M_PI 3.1415926535897932384626433832795
#define TWO_PI 6.283185307
#define INV_PI 0.31830988618
#define INV_TWO_PI 0.15915494309

float Rand1(inout float p) {
  p = fract(p * .1031);
  p *= p + 33.33;
  p *= p + p;
  return fract(p);
}

vec2 Rand2(inout float p) {
  return vec2(Rand1(p), Rand1(p));
}

float InitRand(vec2 uv) {
	vec3 p3  = fract(vec3(uv.xyx) * .1031);
  p3 += dot(p3, p3.yzx + 33.33);
  return fract((p3.x + p3.y) * p3.z);
}

vec3 SampleHemisphereUniform(inout float s, out float pdf) {
  vec2 uv = Rand2(s);
  float z = uv.x;
  float phi = uv.y * TWO_PI;
  float sinTheta = sqrt(1.0 - z*z);
  vec3 dir = vec3(sinTheta * cos(phi), sinTheta * sin(phi), z);
  pdf = INV_TWO_PI;
  return dir;
}

vec3 SampleHemisphereCos(inout float s, out float pdf) {
  vec2 uv = Rand2(s);
  float z = sqrt(1.0 - uv.x);
  float phi = uv.y * TWO_PI;
  float sinTheta = sqrt(uv.x);
  vec3 dir = vec3(sinTheta * cos(phi), sinTheta * sin(phi), z);
  pdf = z * INV_PI;
  return dir;
}

void LocalBasis(vec3 n, out vec3 b1, out vec3 b2) {
  float sign_ = sign(n.z);
  if (n.z == 0.0) {
    sign_ = 1.0;
  }
  float a = -1.0 / (sign_ + n.z);
  float b = n.x * n.y * a;
  b1 = vec3(1.0 + sign_ * n.x * n.x * a, sign_ * b, -sign_ * n.x);
  b2 = vec3(b, sign_ + n.y * n.y * a, -n.y);
}

vec4 Project(vec4 a) {
  return a / a.w;
}

float GetDepth(vec3 posWorld) {
  float depth = (vWorldToScreen * vec4(posWorld, 1.0)).w;
  return depth;
}

/*
 * Transform point from world space to screen space([0, 1] x [0, 1])
 *
 */
vec2 GetScreenCoordinate(vec3 posWorld) {
  vec2 uv = Project(vWorldToScreen * vec4(posWorld, 1.0)).xy * 0.5 + 0.5;
  return uv;
}

float GetGBufferDepth(vec2 uv) {
  float depth = texture2D(uGDepth, uv).x;
  if (depth < 1e-2) {
    depth = 1000.0;
  }
  return depth;
}

vec3 GetGBufferNormalWorld(vec2 uv) {
  vec3 normal = texture2D(uGNormalWorld, uv).xyz;
  return normal;
}

vec3 GetGBufferPosWorld(vec2 uv) {
  vec3 posWorld = texture2D(uGPosWorld, uv).xyz;
  return posWorld;
}

float GetGBufferuShadow(vec2 uv) {
  float visibility = texture2D(uGShadow, uv).x;
  return visibility;
}

vec3 GetGBufferDiffuse(vec2 uv) {
  vec3 diffuse = texture2D(uGDiffuse, uv).xyz;
  diffuse = pow(diffuse, vec3(2.2));
  return diffuse;
}

/*
 * Evaluate diffuse bsdf value.
 *
 * wi, wo are all in world space.
 * uv is in screen space, [0, 1] x [0, 1].
 *
 */
 /*
wi:dir
wo:camera_pos-shading_point
 */
vec3 EvalDiffuse(vec3 wi, vec3 wo, vec2 uv) {
  vec3 normal = normalize(GetGBufferNormalWorld(uv));
  const float value =0.65;
  vec3 L = vec3(0.0);
  if(dot(normal,wi)>0.0)
  {
    L = vec3(value)/M_PI;
  }
  else
  {
    L = vec3(0.0);
  }
  return L;
}

/*
 * Evaluate directional light with shadow map
 * uv is in screen space, [0, 1] x [0, 1].
 *
 */
vec3 EvalDirectionalLight(vec2 uv) {
  vec3 Le = vec3(0.0);
  vec3 Posworld = GetGBufferPosWorld(uv);
  float shadow_coef = GetGBufferuShadow(uv);
  vec3 diff_col = GetGBufferDiffuse(uv);
  if(shadow_coef>0.0)
  {
    vec3 normal = normalize(GetGBufferNormalWorld(uv));
    vec3 lightDir = normalize(uLightDir);
    float diff = max(dot(lightDir,normal),0.0);
    Le= diff_col*diff;
  }
  else
  {
    Le=vec3(0.0);
  }
  return Le;
}

bool RayMarch(vec3 ori, vec3 dir, out vec3 hitPos) {
  float firstStep=0.1;
  int step=1;
  vec3 endPoint = ori;
  const int total = 200;
  for(int i=0;i<total;++i)
  {
    vec3 testPoint = endPoint + float(step)*dir*firstStep;
    if(step>100)
    {
      return false;
    }
    else if(abs(GetDepth(testPoint)-GetGBufferDepth(GetScreenCoordinate(testPoint)))<1e-4)//equal condition
    {
      hitPos = testPoint;
      return true;
    }
    else if(GetDepth(testPoint)<GetGBufferDepth(GetScreenCoordinate(testPoint)))
    {
      ++step;
      endPoint = testPoint;
    }
    else if(GetDepth(testPoint)>GetGBufferDepth(GetScreenCoordinate(testPoint)))
    {
      --step;
    }
  }
  return false;
}

vec3 dirToWorld(vec3 normal,vec3 localDir)
{
  vec3 b1=vec3(0.0);
  vec3 b2=vec3(0.0);
  LocalBasis(normal,b1,b2);
  mat3 tbn = mat3(b1,b2,normal);
  return tbn*localDir;
}

#define SAMPLE_NUM 10

void main() {
  float s = InitRand(gl_FragCoord.xy);
  vec3 L = vec3(0.001);
  vec3 worldPos = vPosWorld.xyz;
  vec2 uv0 = GetScreenCoordinate(worldPos);
  vec3 dirL = EvalDirectionalLight(uv0);
  //L += GetGBufferDiffuse(GetScreenCoordinate(vPosWorld.xyz));
  L+=dirL;
  vec3 normal = GetGBufferNormalWorld(uv0);
  vec3 inDirL_col = vec3(0.0);
  for(int i=0;i<SAMPLE_NUM;++i)
  {
    float pdf;
    //vec3 dir = SampleHemisphereCos(s,pdf);
    vec3 dir = SampleHemisphereUniform(s,pdf);
    vec3 wi = normalize(dir);
    vec3 wo = normalize(uCameraPos - worldPos);
    vec3 brdf0 = EvalDiffuse(wi,wo,uv0);
    vec3 hitPos = vec3(0.0);
    bool isHit = true;
    isHit=RayMarch(worldPos,wi,hitPos);
    if(isHit)
    {
      vec2 uv1 = GetScreenCoordinate(hitPos);
      vec3 inDirL = brdf0 * EvalDiffuse(-wi,wo,uv1) * EvalDirectionalLight(uv1) /pdf;
      inDirL_col += inDirL;
    }
  }
  inDirL_col /= float(SAMPLE_NUM);
  L+=inDirL_col;
  vec3 color = pow(clamp(L, vec3(0.0), vec3(1.0)), vec3(1.0 / 2.2));
  //color=vec3(0.6);
  gl_FragColor = vec4(vec3(color.rgb), 1.0);
}
