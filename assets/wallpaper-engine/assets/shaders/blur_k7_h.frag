
#include "common_blur.h"

varying vec2 v_TexCoord;
uniform sampler2D g_Texture0;
uniform vec2 g_TexelSize;

void main() {
	vec3 albedo = blur7(v_TexCoord, vec2(g_TexelSize.x * SCALE, 0));
	gl_FragColor = vec4(albedo, 1.0);
}
