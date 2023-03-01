
#include "common.h"

varying vec4 v_TexCoord;
varying vec2 v_Direction;

#if PERSPECTIVE == 1
varying vec3 v_TexCoordPerspective;
#endif

uniform sampler2D g_Texture0; // {"hidden":true}
uniform sampler2D g_Texture1; // {"label":"ui_editor_properties_opacity_mask","mode":"opacitymask","combo":"MASK","paintdefaultcolor":"0 0 0 1"}
uniform sampler2D g_Texture2; // {"label":"ui_editor_properties_time_offset","mode":"opacitymask","default":"util/black","combo":"TIMEOFFSET"}
uniform float g_Time;

uniform float g_Speed; // {"material":"speed","label":"ui_editor_properties_speed","default":5,"range":[0.01,50]}
uniform float g_Scale; // {"material":"scale","label":"ui_editor_properties_scale","default":200,"range":[0.01,1000]}
uniform float g_Strength; // {"material":"strength","label":"ui_editor_properties_strength","default":0.1,"range":[0.01,1]}
uniform float g_Perspective; // {"material":"perspective","label":"ui_editor_properties_perspective","default":0,"range":[0,0.2]}

void main() {
#if MASK
	float mask = texSample2D(g_Texture1, v_TexCoord.zw).r;
#else
	float mask = 1.0;
#endif

	vec2 texCoord = v_TexCoord.xy;
	vec2 texCoordMotion = texCoord;

#if PERSPECTIVE == 1
	texCoordMotion = v_TexCoordPerspective.xy / v_TexCoordPerspective.z;
#endif

	float pos = abs(dot((texCoordMotion - 0.5), v_Direction));
	float distance = g_Time * g_Speed + dot(texCoordMotion, v_Direction) * (g_Scale + g_Perspective * pos);
#if PERSPECTIVE == 1
	distance *= step(0.0, v_TexCoordPerspective.z);
#endif

#if TIMEOFFSET
	distance += texSample2D(g_Texture2, v_TexCoord.zw).r * M_PI_2;
#endif

	vec2 offset = vec2(v_Direction.y, -v_Direction.x);
	float strength = g_Strength * g_Strength + g_Perspective * pos;
	texCoord += sin(distance) * offset * strength * mask;

	gl_FragColor = texSample2D(g_Texture0, texCoord);
}
