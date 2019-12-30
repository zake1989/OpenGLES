//#version 330 core
//precision mediump float;

varying mediump vec4 vertexColor;

void main(void) {
    gl_FragColor = vertexColor; // must set gl_FragColor for fragment shader
}
