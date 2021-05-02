#ifndef REFRACTION_GPR
#define REFRACTION_GPR

#include "UnityCG.cginc"
#include "UnityLightingCommon.cginc"

//Real Time Rendering Textbook, 14.5.2
float getRefractionVector(float relativeIOR, float3 dirToLight, float surfaceNormal)
{
	float w = relativeIOR * dot(dirToLight, surfaceNormal);
	float k = sqrt(1 + (w - relativeIOR) * (w + relativeIOR));
	float3 refractionVec = normalize((w - k) * surfaceNormal - relativeIOR * dirToLight);
	return refractionVec;
}

#endif