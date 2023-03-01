
#include "common.h"

vec3 FresnelSchlick(float lightTheta, vec3 baseReflectance)
{
	return baseReflectance + (1.0 - baseReflectance) * pow(max(1.0 - lightTheta, 0.001), 5.0);
}

float Distribution_GGX(vec3 N, vec3 H, float roughness)
{
	float rSqr = roughness * roughness;
	float rSqr2 = rSqr * rSqr;

	float NH = max(dot(N, H), 0.0);
	float NH2 = NH * NH;

	float numerator = rSqr2;
	float denominator = (NH2 * (rSqr2 - 1.0) + 1.0);

	return numerator / (M_PI * denominator * denominator);
}

float Schlick_GGX(float NV, float roughness)
{
	float roughnessBase = roughness + 1.0;
	float roughnessScaled = (roughnessBase * roughnessBase) / 8.0;
	float denominator = NV * (1.0 - roughnessScaled) + roughnessScaled;
	return NV / denominator;
}

float GeoSmith(vec3 N, vec3 V, vec3 L, float roughness)
{
	float NV = max(dot(N, V), 0.001);
	float NL = max(dot(N, L), 0.001);
	return Schlick_GGX(NV, roughness) * Schlick_GGX(NL, roughness);
}

vec3 ComputePBRLight(vec3 normalVector, vec3 worldToLightVector, vec3 worldToViewVector,
	vec3 albedo, vec3 lightColor, vec3 baseReflectance, float roughness, float metallic)
{
	float distance = length(worldToLightVector);
	vec3 L = worldToLightVector / distance;
	vec3 H = normalize(worldToViewVector + L);
	vec3 N = normalVector;
	vec3 V = worldToViewVector;

	vec3 radiance = lightColor / (distance * distance);

	float NDF = Distribution_GGX(N, H, roughness);
	float G = GeoSmith(N, V, L, roughness);
	vec3 F = FresnelSchlick(max(dot(H, V), 0.0), baseReflectance);

	vec3 diffuse = CAST3(1.0) - F;
	diffuse *= 1.0 - metallic;

	vec3 numerator = NDF * G * F;
	float denominator = 4.0 * max(dot(N, V), 0.0) * max(dot(N, L), 0.0);
	vec3 specular = numerator / max(denominator, 0.001);

	float NL = max(dot(N, L), 0.0);
	return (diffuse * albedo / M_PI + specular) * radiance * NL;
}

vec3 CombineLighting(vec3 light, vec3 ambient)
{
#if HDR
	float lightLen = length(light);
	float overbright = (saturate(lightLen - 2.0) * 0.1) / max(0.01, lightLen);
	return saturate(ambient + light) + (light * overbright);
#else
	return ambient + light;
#endif
}
