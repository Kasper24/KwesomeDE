
// [OFF_COMBO] {"material":"ui_editor_properties_position","combo":"POSITION","type":"options","default":0,"options":{"Center":0,"Post":1,"Pre":2}}

varying vec4 v_TexCoord;
varying vec2 v_Scroll;

uniform sampler2D g_Texture0; // {"hidden":true}
uniform sampler2D g_Texture1; // {"label":"ui_editor_properties_flow_map","mode":"flowmask","default":"util/noflow"}
uniform sampler2D g_Texture2; // {"label":"ui_editor_properties_time_offset"}
uniform float g_Time;

uniform float g_FlowSpeed; // {"material":"speed","label":"ui_editor_properties_speed","default":1,"range":[0.01, 2]}
uniform float g_FlowAmp; // {"material":"strength","label":"ui_editor_properties_strength","default":1,"range":[0.01, 1]}
uniform float g_FlowPhaseScale; // {"material":"phasescale","label":"ui_editor_properties_phase_scale","default":2,"range":[0.01, 10]}

void main() {

	float flowPhase = texSample2D(g_Texture2, v_TexCoord.xy * g_FlowPhaseScale).r;
	vec2 flowColors = texSample2D(g_Texture1, v_TexCoord.zw).rg;
	vec2 flowMask = (flowColors.rg - vec2(0.498, 0.498)) * 2.0;
	float flowAmount = length(flowMask);
	
	vec4 cycles = vec4(frac(g_Time * g_FlowSpeed),
						frac(g_Time * g_FlowSpeed + 0.5),
						frac(0.25 + g_Time * g_FlowSpeed),
						frac(0.25 + g_Time * g_FlowSpeed + 0.5));
	
	float blend = 2 * abs(cycles.x - 0.5);
	float blend2 = 2 * abs(cycles.z - 0.5);
	
	cycles = cycles - CAST4(0.5);
	
	vec4 flowUVOffset = CAST4(flowMask.xyxy * g_FlowAmp * 0.1) * cycles.xxyy;
	vec4 flowUVOffset2 = CAST4(flowMask.xyxy * g_FlowAmp * 0.1) * cycles.zzww;

	vec4 albedo = texSample2D(g_Texture0, v_TexCoord.xy);
	vec4 flowAlbedo = mix(texSample2D(g_Texture0, v_TexCoord.xy + flowUVOffset.xy),
					texSample2D(g_Texture0, v_TexCoord.xy + flowUVOffset.zw),
					blend);
	vec4 flowAlbedo2 = mix(texSample2D(g_Texture0, v_TexCoord.xy + flowUVOffset2.xy),
					texSample2D(g_Texture0, v_TexCoord.xy + flowUVOffset2.zw),
					blend2);

	flowAlbedo = mix(flowAlbedo, flowAlbedo2, smoothstep(0.2, 0.8, flowPhase));
	gl_FragColor = mix(albedo, flowAlbedo, flowAmount);
}
