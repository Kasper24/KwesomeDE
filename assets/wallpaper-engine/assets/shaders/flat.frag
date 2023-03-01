
uniform mediump float g_Alpha;
uniform mediump vec3 g_Color;

varying vec3 v_Color;

void main() {
	gl_FragColor = vec4(g_Color, g_Alpha);
	
#ifdef VERTEXCOLOR
	gl_FragColor.rgb *= v_Color;
#endif
}