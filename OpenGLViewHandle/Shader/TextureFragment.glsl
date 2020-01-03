//#version 330 core
//precision mediump float;

varying mediump vec4 vertexColor;

varying mediump vec2 textureCoord;

uniform sampler2D leftImageTexture;
uniform sampler2D rightImageTexture;

void main(void) {
//    gl_FragColor = texture2D(leftImageTexture, textureCoord) * vertexColor;
//    if (textureCoord.x <= 0.5) {
//        gl_FragColor = texture2D(leftImageTexture, vec2(textureCoord.x, 1.0 - textureCoord.y));
//    } else {
//        gl_FragColor = texture2D(rightImageTexture, vec2(textureCoord.x, 1.0 - textureCoord.y));
//    }
    gl_FragColor = mix(texture2D(leftImageTexture, vec2(textureCoord.x, 1.0 - textureCoord.y)), texture2D(rightImageTexture, vec2(textureCoord.x, 1.0 - textureCoord.y)), 0.4);
}

