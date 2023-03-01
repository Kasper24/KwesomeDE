
struct PS_OUTPUT
{
	float4 gl_FragColor : SV_TARGET;
};

struct VS_OUTPUT
{
	float4 gl_Position : SV_POSITION;
	float2 v_TexCoord : TEXCOORD0;
};

Texture2D g_Texture0:register(t0);
SamplerState g_Texture0SamplerState:register(s0);

PS_OUTPUT main(VS_OUTPUT IN)
{
	PS_OUTPUT OUT;
	OUT.gl_FragColor = float4(1, 0, 0, 1);
	return OUT;
}
