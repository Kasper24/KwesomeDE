
uniform float g_Alpha;

uniform sampler2D g_Texture0;

varying vec2 v_TexCoord;

void main() {
	gl_FragColor = texSample2D(g_Texture0, v_TexCoord);
	gl_FragColor.a *= g_Alpha;
}
