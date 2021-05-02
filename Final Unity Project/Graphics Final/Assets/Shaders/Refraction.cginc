#ifndef REFRACTION_GPR
#define REFRACTION_GPR

#include "UnityCG.cginc"
#include "UnityLightingCommon.cginc"

//Equation found in the Real Time Rendering Textbook, 14.5.2
float getRefractionVector(float relativeIOR, float3 dirToLight, float surfaceNormal)
{
	float w = relativeIOR * dot(dirToLight, surfaceNormal);
	float k = sqrt(1 + (w - relativeIOR) * (w + relativeIOR));
	float3 refractionVec = (w - k) * surfaceNormal - relativeIOR * dirToLight;
	return normalize(refractionVec);
}

#endif