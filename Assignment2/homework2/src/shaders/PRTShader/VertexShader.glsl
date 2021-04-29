attribute mat3 aPrecomputeLT;
attribute vec3 aVertexPosition;
attribute vec3 aNormalPosition;
attribute vec2 aTextureCoord;

uniform mat4 uModelMatrix;
uniform mat4 uViewMatrix;
uniform mat4 uProjectionMatrix;

uniform mat3 PrecomputeLR;
uniform mat3 PrecomputeLG;
uniform mat3 PrecomputeLB;

varying highp vec2 vTextureCoord;
varying highp vec3 vFragPos;
varying highp vec3 vNormal;
varying highp vec4 vColor;



void main(void)
{
    vFragPos = (uModelMatrix * vec4(aVertexPosition, 1.0)).xyz;
    vNormal = (uModelMatrix * vec4(aNormalPosition, 0.0)).xyz;
    gl_Position = uProjectionMatrix * uViewMatrix * uModelMatrix *
                vec4(aVertexPosition, 1.0);

    float r=0.0;
    float g=0.0;
    float b=0.0;
    for(int i=0;i<3;++i)
    {
        r+=dot(aPrecomputeLT[i],PrecomputeLR[i]);
        g+=dot(aPrecomputeLT[i],PrecomputeLG[i]);
        b+=dot(aPrecomputeLT[i],PrecomputeLB[i]);       
    }
    
    vColor=vec4(1.0,0.0,0.0,1.0);
}
