
varying vec2 v_TexCoord;
varying vec3 v_ScreenCoord;

uniform sampler2D g_Texture0; // {"hidden":true}

void main() {
	vec2 texCoord = v_ScreenCoord.xy / v_ScreenCoord.z * vec2(0.5, 0.5) + 0.5;
	gl_FragColor = texSample2D(g_Texture0, texCoord);
	
#if CLEARALPHA == 1
	gl_FragColor.a = 0;
#endif
}
