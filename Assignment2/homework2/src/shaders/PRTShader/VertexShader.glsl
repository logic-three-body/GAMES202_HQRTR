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

float calcuComponent(mat3 v1,mat3 v2)
{
    return (v1[0][0]+v1[1][1]+v1[2][2])/3.0;
}

void main(void)
{
    vFragPos = (uModelMatrix * vec4(aVertexPosition, 1.0)).xyz;
    vNormal = (uModelMatrix * vec4(aNormalPosition, 0.0)).xyz;
    gl_Position = uProjectionMatrix * uViewMatrix * uModelMatrix *
                vec4(aVertexPosition, 1.0);

    float r=dot(aPrecomputeLT[0],PrecomputeLR[0])+dot(aPrecomputeLT[1],PrecomputeLR[1])+dot(aPrecomputeLT[2],PrecomputeLR[2]);
    float g=dot(aPrecomputeLT[0],PrecomputeLG[0])+dot(aPrecomputeLT[1],PrecomputeLG[1])+dot(aPrecomputeLT[2],PrecomputeLG[2]);
    float r=dot(aPrecomputeLT[0],PrecomputeLB[0])+dot(aPrecomputeLT[1],PrecomputeLB[1])+dot(aPrecomputeLT[2],PrecomputeLB[2]);
    
    vColor=vec4(r,g,b,1.0);
}
