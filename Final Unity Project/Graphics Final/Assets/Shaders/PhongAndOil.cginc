#ifndef PHONG_OIL_GPR
#define PHONG_OIL_GPR

#include "UnityCG.cginc"
#include "UnityLightingCommon.cginc"

float3 phongEffect(float3 wPos, float3 wNormal, float3 wLightPos, float lightRadius)
{
    float radiusInvSqr = 1 / (lightRadius * lightRadius);

    wNormal = normalize(wNormal);
    float3 L = wLightPos - wPos;
    float lightDistance = length(L);
    L = L / lightDistance;

    float lmbCoeff = max(0.0, dot(wNormal, L));
    float attenuation = 1 / (1 + radiusInvSqr * lightDistance);

    float3 V = normalize(_WorldSpaceCameraPos - wPos);
    float3 R = reflect(-L, wNormal);
    float phongCoeff = max(0.0, dot(R, V));

    return unity_LightColor[0] * (lmbCoeff + phongCoeff) * attenuation;
}

float determineReflectance(float spreadMode, float2 uv, float3 viewNormal, float3 viewPos, float thickness, float objectIOR, float filmIOR, float wavelength)
{
    const float PI = 3.14159265;

    //set up spread mode 
    float isPuddle = step(spreadMode, 3.0) * step(3.0, spreadMode);
    float isBubbleTimed = step(spreadMode, 2.0) * step(2.0, spreadMode);
    float isBubble = step(spreadMode, 1.0) * step(1.0, spreadMode) + isBubbleTimed;
    float isEven = step(spreadMode, 0.0) * step(0.0, spreadMode);

    float2 distanceFromCenter = uv - 0.5;

    float viewAngle = dot(viewNormal, normalize(-viewPos));

    float bubbleParam = uv.y * uv.y;

    thickness = isEven * thickness +
        isBubble * lerp(0, thickness, bubbleParam) +
        isPuddle * thickness * exp(-1 * length(distanceFromCenter) * length(distanceFromCenter));

    thickness = thickness * (1 - cos(viewAngle));

    float isInverted = step(objectIOR, filmIOR) * PI / 2;

    float reflectance = pow(1.0 * cos(2 * PI * thickness * filmIOR / wavelength + isInverted), 2);

    return reflectance;
}

fixed4 thinFilmEffect(float spreadMode, float2 uv, float3 viewNormal, float3 viewPos, float thickness, float objectIOR, float filmIOR, float wavelength, sampler2D samplerTable, float fresnelValue)
{
    float reflectance = determineReflectance(spreadMode, uv, viewNormal, viewPos, thickness, objectIOR, filmIOR, wavelength);
    
    fixed4 oilCol = tex2D(samplerTable, float2(reflectance, reflectance));
    oilCol.a = fresnelValue * reflectance;

    return oilCol;
}

fixed4 thinFilmEffectWithNoise(float spreadMode, float2 uv, float3 viewNormal, float3 viewPos, float thickness, float objectIOR, float filmIOR, float wavelength, sampler2D samplerTable, float fresnelValue, sampler2D noiseSample)
{
    //const float PI = 3.14159265;
    float4 timeScaled = _Time / 50;

    float noiseOffset = tex2D(noiseSample, float2(uv.x + timeScaled.x, uv.y + timeScaled.y));

    float portionAffectingThickness = 1; //Don't like these? set'em to 1!
    float rangeToChangeColor = 1; //Don't like these? set'em to 1!

    thickness = portionAffectingThickness * thickness * noiseOffset + (1 - portionAffectingThickness) * thickness;

    float reflectance = determineReflectance(spreadMode, uv, viewNormal, viewPos, thickness, objectIOR, filmIOR, wavelength);

    noiseOffset = tex2D(noiseSample, float2(uv.y - timeScaled.x, uv.x + timeScaled.y));

    float2 offsetReflectance = float2(reflectance, reflectance);
    offsetReflectance.x = offsetReflectance.x + noiseOffset * rangeToChangeColor;

    fixed4 oilCol = tex2D(samplerTable, offsetReflectance);
    oilCol.a = fresnelValue * reflectance;

    return oilCol;
}

#endif