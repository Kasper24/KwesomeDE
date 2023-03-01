
#include "common_particles.h"

in vec3 v_Rotation;
in vec4 v_Color;
in vec4 gl_Position;

#if THICKFORMAT
in vec4 v_VelocityLifetime;
#endif

#if SPRITESHEET
out vec4 v_TexCoord;
out float v_TexCoordBlend;
#else
out vec2 v_TexCoord;
#endif

#if REFRACT
out vec3 v_ScreenCoord;
out vec4 v_ScreenTangents;
#endif

out vec4 v_Color;
out vec4 gl_Position;

#if SPRITESHEET
PS_INPUT CreateParticleVertex(vec2 sprite, float blend, mat3 mRotation, vec4 uvs, float textureRatio, in VS_OUTPUT IN, vec3 right, vec3 up)
#else
PS_INPUT CreateParticleVertex(vec2 sprite, float blend, mat3 mRotation, vec2 uvs, float textureRatio, in VS_OUTPUT IN, vec3 right, vec3 up)
#endif
{
	PS_INPUT v;

	vec3 position = ComputeParticlePosition(sprite, textureRatio, IN.gl_Position, right, up);

	v.gl_Position = mul(vec4(position, 1.0), g_ModelViewProjectionMatrix);
	v.v_TexCoord = uvs;
	v.v_Color = IN.v_Color;
	
#if SPRITESHEET
	v.v_TexCoordBlend = blend;
#endif

#if REFRACT
	ComputeScreenRefractionTangents(v.gl_Position.xyw, mRotation, v.v_ScreenCoord, v.v_ScreenTangents);
#endif
	
	return v;
}

[maxvertexcount(4)]
void main() {

	vec3 uvOffsets = vec3(1, 1, 0);
	float spriteBlend = 0.0;
	
#if SPRITESHEET
	float textureRatio = g_RenderVar1.w;
	vec4 uvs;
	ComputeSpriteFrame(IN[0].v_VelocityLifetime.w, uvs, uvOffsets.xy, spriteBlend);
#else
	vec2 uvs = vec2(0, 0);
	float textureRatio = g_Texture0Resolution.y / g_Texture0Resolution.x;
#endif

	// Compute tangent vectors
	vec3 right, up;
	mat3 mRotation;
#if TRAILRENDERER
	mRotation = CAST3X3(1.0);
	ComputeParticleTrailTangents(IN[0].gl_Position, IN[0].v_VelocityLifetime.xyz, right, up);
#else
	ComputeParticleTangents(IN[0].v_Rotation, mRotation, right, up);
#endif
	
	OUT.Append(CreateParticleVertex(vec2(0, 0), spriteBlend, mRotation, uvs,                  textureRatio, IN[0], right, up));
	OUT.Append(CreateParticleVertex(vec2(0, 1), spriteBlend, mRotation, uvs + uvOffsets.zyzy, textureRatio, IN[0], right, up));
	OUT.Append(CreateParticleVertex(vec2(1, 0), spriteBlend, mRotation, uvs + uvOffsets.xzxz, textureRatio, IN[0], right, up));
	OUT.Append(CreateParticleVertex(vec2(1, 1), spriteBlend, mRotation, uvs + uvOffsets.xyxy, textureRatio, IN[0], right, up));
}
