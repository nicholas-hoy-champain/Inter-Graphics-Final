// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Unlit/RefractionShader"
{
    Properties
    {
        _IOR("Relative IOR", Range(0.1,2)) = 1.4433
        _MainColor("Main Tint", Color) = (1, 1, 1, 1)

        _MorphWavey("Morph Waveiness",Float) = 0
        _MorphRate("Morph Rate", Float) = 0
        _MorphAmplitude("Morph Amplitude", Float) = 0
    }
    SubShader
    {
        Tags {"LightMode" = "ForwardBase"   "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent"}
        Blend SrcAlpha OneMinusSrcAlpha
        LOD 200

        GrabPass
        {
            "_WorldBehind"
        }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"
            #include "Refraction.cginc"
            #include "Reflection.cginc"
            #include "MorphingPosition.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float4 objPos : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _WorldBehind;
            float _IOR;
            float4 _MainColor;
            float4 _BackColor;

            float _MorphWavey;
            float _MorphRate;
            float _MorphAmplitude;

            v2f vert (appdata v)
            {
                v2f o;

                o.worldNormal = mul((float3x3)unity_ObjectToWorld, v.normal);
                o.objPos = morphPos(v.vertex, v.normal, _Time.w * _MorphRate, _MorphAmplitude, _MorphWavey);
                o.vertex = UnityObjectToClipPos(o.objPos);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                //ScreenPos Offset being attempted is inspired by the Real Time Rendering Textbook, 14.5.2
                float3 viewDir = -UnityWorldSpaceViewDir(i.objPos);
                float3 refractVec = refract(viewDir, normalize(i.worldNormal), _IOR);
                refractVec = mul(unity_WorldToObject, mul(unity_ObjectToWorld, i.objPos) + refractVec);
                float4 screenPos = ComputeGrabScreenPos(UnityObjectToClipPos(refractVec));
                float2 uv = (screenPos / screenPos.w).xy;
                float2 test = uv;


                float flipY = step(.5,uv.y * .5 - floor(uv.y * .5));
                float flipX = step(.5,uv.x * .5 - floor(uv.x * .5));
                uv = uv - floor(uv);
                uv.y = uv.y * (.5 - flipY) * 2;
                uv.x = uv.x * (.5 - flipX) * 2;

                fixed4 col = tex2D(_WorldBehind,uv);

                col.a = step(test.x, 1.0) * step(0.0, test.x) 
                        * step(test.y, 1.0) * step(0.0, test.y);

                col.a = col.a + (1 - col.a) * clamp(1-length(abs(test-.5)-.5)*2,0.0,1.0);

                col = col * _MainColor;

                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG 
        }
    }
}
