//#version 330 core
attribute vec3 Position;

varying vec4 vertexColor;

void main(void) {
    vertexColor = vec4(0.5, 1.0, 1.0, 1.0);
    gl_Position = vec4(Position, 1.0);
}
