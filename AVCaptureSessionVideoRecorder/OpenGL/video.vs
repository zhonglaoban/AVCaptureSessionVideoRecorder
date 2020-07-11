attribute vec2 a_Position;
attribute vec2 a_TextureCoord;

varying vec2 v_texcoord;

void main(void) {
    v_texcoord = a_TextureCoord;
    gl_Position = vec4(a_Position, 1.0, 1.0);
}
