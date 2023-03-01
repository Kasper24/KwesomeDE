
#include "common_fragment.h"

uniform sampler2D g_Texture0; // {"material":"ui_editor_properties_albedo","default":"util/white"}
uniform float g_Overbright; // {"material":"ui_editor_properties_overbright","default":1.0,"range":[0,5]}

varying vec2 v_TexCoord;
varying vec4 v_Color;

void main() {
	vec4 color = v_Color * ConvertTexture0Format(texSample2D(g_Texture0, v_TexCoord.xy));

	color.rgb *= g_Overbright;
	
	gl_FragColor = color;
}
