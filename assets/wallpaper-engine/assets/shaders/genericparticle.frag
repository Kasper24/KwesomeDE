
#include "common_fragment.h"

uniform sampler2D g_Texture0; // {"label":"ui_editor_properties_albedo","default":"util/white"}

uniform float g_Overbright; // {"material":"ui_editor_properties_overbright","default":1.0,"range":[0,5]}

#if REFRACT
uniform sampler2D g_Texture1; // {"label":"ui_editor_properties_normal","format":"normalmap","default":"util/flatnormal"}
uniform sampler2D g_Texture2; // {"default":"_rt_FullFrameBuffer","hidden":true}
#endif

#if SPRITESHEET
varying vec4 v_TexCoord;
varying float v_TexCoordBlend;
#else
varying vec2 v_TexCoord;
#endif

varying vec4 v_Color;

#if REFRACT
varying vec3 v_ScreenCoord;
varying vec4 v_ScreenTangents;
#endif

void main() {
#if SPRITESHEET
#if SPRITESHEETBLEND
	// This is wrong because it can sample colors that are invisible on one frame but changing this can negatively impact additive particles
	vec4 color = v_Color * mix(ConvertTexture0Format(texSample2D(g_Texture0, v_TexCoord.xy)),
								ConvertTexture0Format(texSample2D(g_Texture0, v_TexCoord.zw)),
								v_TexCoordBlend);
#else
	vec4 color = v_Color * ConvertTexture0Format(texSample2D(g_Texture0, v_TexCoord.xy));
#endif
#else
	vec4 color = v_Color * ConvertTexture0Format(texSample2D(g_Texture0, v_TexCoord.xy));
#endif

#if REFRACT
	vec4 normal = DecompressNormalWithMask(texSample2D(g_Texture1, v_TexCoord.xy));
	//normal = vec4((v_TexCoord.xy - 0.5) * 2, 0, 1);
	vec2 screenRefractionOffset = v_ScreenTangents.xy * normal.x + v_ScreenTangents.zw * normal.y;
#ifndef HLSL
	screenRefractionOffset.y = -screenRefractionOffset.y;
#endif
	vec2 refractTexCoord = v_ScreenCoord.xy / v_ScreenCoord.z * vec2(0.5, 0.5) + 0.5 + screenRefractionOffset * normal.a * v_Color.a;
	
	color.rgb *= texSample2D(g_Texture2, refractTexCoord).rgb;
#endif

	color.rgb *= g_Overbright;
	gl_FragColor = color;
}