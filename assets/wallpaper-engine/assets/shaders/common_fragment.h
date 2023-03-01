
vec3 DecompressNormal(vec4 normal)
{
	// Hack to compensate for DXT compression
#if COMPRESSEDNORMAL
	normal.yw = normal.yw * 2.0 - vec2(0.965, 1.0);
#else
	normal.yw = normal.yw * 2.0 - 1.0;
#endif
	// To support DXT3/DXT1
	//normal.x = normal.x * normal.a;
	normal.z = sqrt(saturate(1.0 - normal.w * normal.w - normal.y * normal.y));
	return normal.wyz;
}

vec4 DecompressNormalWithMask(vec4 normal)
{
	normal.xw = normal.wx;
	// Hack to compensate for DXT compression
#if COMPRESSEDNORMAL
	normal.xy = normal.xy * 2.0 - vec2(0.965, 1.0);
#else
	normal.xy = normal.xy * 2.0 - 1.0;
#endif
	normal.z = sqrt(saturate(1.0 - normal.x * normal.x - normal.y * normal.y));
	return normal;
}

float ComputeMaterialSpecularPower(const float roughness, const float metallic)
{
	return (1.01 - roughness) * mix(400.0, 250.0, metallic);
}

float ComputeMaterialSpecularStrength(const float roughness, const float metallic)
{
	return (0.5 + metallic * 0.5) * (1.0 - roughness * 0.9);
}

vec3 ComputeLight(const vec3 normal, const vec3 lightDelta, const vec3 color, const float radius)
{
	float lightDistance = length(lightDelta);
	float lightAttn = saturate((radius - lightDistance) / radius);
	return color * (saturate(dot(lightDelta / lightDistance, normal))) * lightAttn * lightAttn;
}

vec3 ComputeLightSpecular(const vec3 normal, const vec3 lightDelta, const vec3 color, const float radius, const vec3 viewDir, const float specularPower, const float specularStrength, const float halfLambert, const float metallicTerm, inout vec3 specularResult)
{
	float lightDistance = length(lightDelta);
	float lightAttn = saturate((radius - lightDistance) / radius);
	vec3 lightDir = lightDelta / lightDistance;
	float specular = max(0.0, dot(normalize(viewDir + lightDir), normal));
	specularResult += pow(specular, specularPower) * specularStrength * lightAttn * color;
	float lightDot = dot(lightDir, normal);
	float halfLambertLight = lightDot * 0.5 + 0.5;
	lightDot = mix(lightDot, halfLambertLight, halfLambert);
	float rim = metallicTerm * 2.0;
	rim = pow((1.0 - saturate(dot(normal, viewDir))) * pow(halfLambertLight, 0.25), 6.0 - rim) * rim;
	return color * (saturate(lightDot) + rim) * lightAttn * lightAttn;
}

#define FORMAT_RG88 8
#define FORMAT_R8 9
#define FORMAT_RG1616F 10
#define FORMAT_R16F 11
float ConvertSampleR8(vec4 _sample)
{
#if HLSL_SM30
		return _sample.a;
#else
		return _sample.r;
#endif
}

vec4 ConvertTexture0Format(vec4 _sample)
{
#if TEX0FORMAT == FORMAT_RG88 || TEX0FORMAT == FORMAT_RG1616F
#if HLSL_SM30
	return _sample.rrra;
#else
	return _sample.rrrg;
#endif
#endif

#if TEX0FORMAT == FORMAT_R8 || TEX0FORMAT == FORMAT_R16F
#if HLSL_SM30
	return vec4(1, 1, 1, _sample.a);
#else
	return vec4(1, 1, 1, _sample.r);
#endif
#endif
	return _sample;
}
