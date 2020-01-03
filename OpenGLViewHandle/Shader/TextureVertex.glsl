//#version 330 core
attribute vec3 Position;

attribute vec4 SourceColor;

attribute vec2 TextureCoord;

varying vec4 vertexColor;

varying vec2 textureCoord;

void main(void) {
    vertexColor = SourceColor;
    textureCoord = TextureCoord;
    gl_Position = vec4(Position, 1.0);
}
