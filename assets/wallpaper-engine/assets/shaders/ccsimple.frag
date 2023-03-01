
#include "common.h"

varying vec2 v_TexCoord;

uniform sampler2D g_Texture0;
uniform vec4 g_Params; // {"material":"params","default":"1 1 1 0"}

void main()
{
	vec4 albedo = texSample2D(g_Texture0, v_TexCoord);
	albedo.rgb = mix(CAST3(0.5), albedo.rgb, g_Params.y);
	
	vec3 hsv = rgb2hsv(albedo.xyz);
	hsv.z *= g_Params.x;
	hsv.y *= g_Params.z;
	hsv.x += g_Params.w;
	albedo.rgb = hsv2rgb(hsv);
	
	gl_FragColor = albedo;
}
