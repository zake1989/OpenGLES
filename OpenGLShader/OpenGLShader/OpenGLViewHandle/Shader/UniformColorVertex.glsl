//#version 330 core
attribute vec3 Position;

uniform vec4 SourceColor;

varying vec4 vertexColor;

void main(void) {
    vertexColor = SourceColor;
    gl_Position = vec4(Position, 1.0);
}
