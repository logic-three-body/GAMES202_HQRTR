#ifdef GL_ES
precision mediump float;
#endif

// Phong related variables
uniform sampler2D uSampler;
uniform vec3 uKd;
uniform vec3 uKs;
uniform vec3 uLightPos;
uniform vec3 uCameraPos;
uniform vec3 uLightIntensity;

varying highp vec2 vTextureCoord;
varying highp vec3 vFragPos;
varying highp vec3 vNormal;

// Shadow map related variables
#define NUM_SAMPLES 20
#define BLOCKER_SEARCH_NUM_SAMPLES NUM_SAMPLES
#define PCF_NUM_SAMPLES NUM_SAMPLES
#define NUM_RINGS 10

//FOR filter_radius blocksearch
#define NEAR_PLANE 0.5
#define LIGHT_WORLD_SIZE 0.5
#define LIGHT_FRUSTUM_WIDTH 9.0
#define LIGHT_SIZE_UV (LIGHT_WORLD_SIZE/LIGHT_FRUSTUM_WIDTH)

#define EPS 1e-3
#define PI 3.141592653589793
#define PI2 6.283185307179586

uniform sampler2D uShadowMap;

varying vec4 vPositionFromLight;

highp float rand_1to1(highp float x ) { 
  // -1 -1
  return fract(sin(x)*10000.0);
}

highp float rand_2to1(vec2 uv ) { 
  // 0 - 1
	const highp float a = 12.9898, b = 78.233, c = 43758.5453;
	highp float dt = dot( uv.xy, vec2( a,b ) ), sn = mod( dt, PI );
	return fract(sin(sn) * c);
}

float unpack(vec4 rgbaDepth) {
    const vec4 bitShift = vec4(1.0, 1.0/256.0, 1.0/(256.0*256.0), 1.0/(256.0*256.0*256.0));
    return dot(rgbaDepth, bitShift);
}

vec2 poissonDisk[NUM_SAMPLES];

void poissonDiskSamples( const in vec2 randomSeed ) {

  float ANGLE_STEP = PI2 * float( NUM_RINGS ) / float( NUM_SAMPLES );
  float INV_NUM_SAMPLES = 1.0 / float( NUM_SAMPLES );

  float angle = rand_2to1( randomSeed ) * PI2;
  float radius = INV_NUM_SAMPLES;
  float radiusStep = radius;

  for( int i = 0; i < NUM_SAMPLES; i ++ ) {
    poissonDisk[i] = vec2( cos( angle ), sin( angle ) ) * pow( radius, 0.75 );
    radius += radiusStep;
    angle += ANGLE_STEP;
  }
}

void uniformDiskSamples( const in vec2 randomSeed ) {

  float randNum = rand_2to1(randomSeed);
  float sampleX = rand_1to1( randNum ) ;
  float sampleY = rand_1to1( sampleX ) ;

  float angle = sampleX * PI2;
  float radius = sqrt(sampleY);

  for( int i = 0; i < NUM_SAMPLES; i ++ ) {
    poissonDisk[i] = vec2( radius * cos(angle) , radius * sin(angle)  );

    sampleX = rand_1to1( sampleY ) ;
    sampleY = rand_1to1( sampleX ) ;

    angle = sampleX * PI2;
    radius = sqrt(sampleY);
  }
}

float ShadowBias(vec3 normal,vec3 lightDir)
{
  return max(0.01*(1.0-max(dot(normal,lightDir),0.0)),0.005);
 // return 1.0;
}

float useShadowMap(sampler2D shadowMap, vec4 shadowCoord){
  shadowCoord=shadowCoord*0.5+0.5;//shadow between [0,1] NDC
//  float bias=0.06;//constant test
  float bias=ShadowBias(vNormal,normalize(uLightPos));
  float closetDepth=texture2D(shadowMap,shadowCoord.xy).r;
  float currentDepth=shadowCoord.z-bias;//相当于把点向上移动减小深度，参考RTR4 P237 Figure 7.13. || Yan老师 PDF P18
  return currentDepth>closetDepth?0.0:1.0;
}

float findBlocker( sampler2D shadowMap,  vec2 uv, float zReceiver ) {
  					// This uses similar triangles to compute what
					// area of the shadow map we should search
					float searchRadius = LIGHT_SIZE_UV * ( zReceiver - NEAR_PLANE ) / zReceiver;
					float blockerDepthSum = 0.0;
					int numBlockers = 0;

					for( int i = 0; i < BLOCKER_SEARCH_NUM_SAMPLES; i++ ) {
						float shadowMapDepth = unpack(texture2D(shadowMap, uv + poissonDisk[i] * searchRadius));
						if ( shadowMapDepth < zReceiver ) {
							blockerDepthSum += shadowMapDepth;
							numBlockers ++;
						}
					}

					if( numBlockers == 0 ) return -1.0;

					return blockerDepthSum / float( numBlockers );
	//return 1.0;
}

float penumbraSize( const in float zReceiver, const in float zBlocker ) { // Parallel plane estimation
					return (zReceiver - zBlocker) / zBlocker;
				}

float PCF(sampler2D shadowMap, vec4 coords) {
  //refer three.js master webgl-shadowmap_pcss 
  coords=coords*0.5+0.5;//shadow between [0,1] NDC
  float bias=ShadowBias(vNormal,normalize(uLightPos));
  vec2 uv = coords.xy;
	float zReceiver = coords.z; // Assumed to be eye-space z in this code
  poissonDiskSamples(uv);
  //uniformDiskSamples(uv);
  float filter_radius=1.0;
  float sum=0.0;
  for(int i=0;i<PCF_NUM_SAMPLES;++i)
  {
    float depth=unpack(texture2D(shadowMap,uv+poissonDisk[i]/float(PCF_NUM_SAMPLES)*filter_radius));
    if(zReceiver<=depth+bias) ++sum;
  }
  for(int i=0;i<PCF_NUM_SAMPLES;++i)
  {
    float depth=unpack(texture2D(shadowMap,uv-poissonDisk[i].yx/float(PCF_NUM_SAMPLES)*filter_radius));
    if(zReceiver<=depth+bias) ++sum;
  }

  //return 1.0;
  return sum/(2.0 * float( PCF_NUM_SAMPLES ));
}

float PCF(sampler2D shadowMap, vec2 uv, float zReceiver, float filterRadius ) {
					float sum = 0.0;
          float bias=ShadowBias(vNormal,normalize(uLightPos));
					for( int i = 0; i < PCF_NUM_SAMPLES; i ++ ) {
						float depth = unpack( texture2D( shadowMap, uv + poissonDisk[ i ] * filterRadius ) );
						if( zReceiver <= depth+bias ) sum += 1.0;
					}
					for( int i = 0; i < PCF_NUM_SAMPLES; i ++ ) {
						float depth = unpack( texture2D( shadowMap, uv + -poissonDisk[ i ].yx * filterRadius ) );
						if( zReceiver <= depth+bias ) sum += 1.0;
					}
					return sum / ( 2.0 * float( PCF_NUM_SAMPLES ) );
}

float PCSS(sampler2D shadowMap, vec4 coords){
  coords=coords*0.5+0.5;//shadow between [0,1] NDC
  vec2 uv = coords.xy;
	float zReceiver = coords.z; // Assumed to be eye-space z in this code
  poissonDiskSamples( uv );
  // STEP 1: avgblocker depth
  float avgBlockerDepth = findBlocker( shadowMap, uv, zReceiver );
  //There are no occluders so early out (this saves filtering)
	if( avgBlockerDepth == -1.0 ) return 1.0;
  // STEP 2: penumbra size
	float penumbraRatio = penumbraSize( zReceiver, avgBlockerDepth );
	float filterRadius = penumbraRatio * LIGHT_SIZE_UV * NEAR_PLANE / zReceiver;
  // STEP 3: filtering
 	//return avgBlockerDepth;
  float test_num=1.0;
	return PCF( shadowMap, uv, zReceiver, filterRadius/test_num ); 
  //return 1.0;

}



vec3 blinnPhong() {
  vec3 color = texture2D(uSampler, vTextureCoord).rgb;
  color = pow(color, vec3(2.2));

  vec3 ambient = 0.05 * color;

  vec3 lightDir = normalize(uLightPos);
  vec3 normal = normalize(vNormal);
  float diff = max(dot(lightDir, normal), 0.0);
  vec3 light_atten_coff =
      uLightIntensity / pow(length(uLightPos - vFragPos), 2.0);
  vec3 diffuse = diff * light_atten_coff * color;

  vec3 viewDir = normalize(uCameraPos - vFragPos);
  vec3 halfDir = normalize((lightDir + viewDir));
  float spec = pow(max(dot(halfDir, normal), 0.0), 32.0);
  vec3 specular = uKs * light_atten_coff * spec;

  vec3 radiance = (ambient + diffuse + specular);
  vec3 phongColor = pow(radiance, vec3(1.0 / 2.2));
  return phongColor;
}

void main(void) {

  float visibility=1.0;
  vec3 shadowCoord=vPositionFromLight.xyz;
  //visibility = useShadowMap(uShadowMap, vec4(shadowCoord, 1.0));
 // visibility = PCF(uShadowMap, vec4(shadowCoord, 1.0));
  visibility = PCSS(uShadowMap, vec4(shadowCoord, 1.0));

  vec3 phongColor = blinnPhong();
 // gl_FragColor=vec4(texture2D(uShadowMap,shadowCoord.xy).rrr,1);
  gl_FragColor = vec4(phongColor * visibility, 1.0);
  //gl_FragColor = vec4(phongColor, 1.0);
}