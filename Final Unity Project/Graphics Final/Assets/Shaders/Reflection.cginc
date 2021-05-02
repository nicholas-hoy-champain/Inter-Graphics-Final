#ifndef REFLECTION_GPR
#define REFLECTION_GPR

#include "UnityCG.cginc"
#include "UnityLightingCommon.cginc"

//credits to unity docs for showing me how to access the sky box reflections
// https://docs.unity3d.com/Manual/SL-VertexFragmentShaderExamples.html
float3 reflectionSky(float3 worldRefl)
{
	float4 skyData = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, worldRefl);
	return DecodeHDR(skyData, unity_SpecCube0_HDR);
}

#endif