precision highp float;

varying vec2 v_texcoord;

uniform sampler2D texSampler_y;
uniform sampler2D texSampler_u;
uniform sampler2D texSampler_v;

void main(void) {
    float y = texture2D(texSampler_y, v_texcoord).r;
    float u = texture2D(texSampler_u, v_texcoord).r - 0.5;
    float v = texture2D(texSampler_v, v_texcoord).r - 0.5;
    float r = y + 1.402 * v;
    float g = y - 0.344 * u - 0.714 * v;
    float b = y + 1.772 * u;
    gl_FragColor = vec4(r, g, b, 1.0);
//    gl_FragColor = mix(texture2D(texSampler_y, v_texcoord), texture2D(texSampler_u, v_texcoord), 0.2);
//    gl_FragColor = vec4(1.0, 1.0, 0.0, 1.0);
//    gl_FragColor = texture2D(texSampler_y, v_texcoord);
}
