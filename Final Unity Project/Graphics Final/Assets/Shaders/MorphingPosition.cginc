#ifndef MORPHING_GPR
#define MORPHING_GPR

#include "UnityCG.cginc"

//credits to unity docs for showing me how to access the sky box reflections
// https://docs.unity3d.com/Manual/SL-VertexFragmentShaderExamples.html
float4 morphPos(float4 pos, float3 normal, float time, float depth = .01, float waveiness = 10)
{
	return pos + float4(normal, 0) * sin(time + pos.y * waveiness) * depth;
}

#endif