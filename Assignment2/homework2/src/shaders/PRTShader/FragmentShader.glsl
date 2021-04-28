#ifdef GL_ES
precision mediump float;
#endif

varying highp vec4 vColor;

void main(void) { gl_FragColor = vColor; }