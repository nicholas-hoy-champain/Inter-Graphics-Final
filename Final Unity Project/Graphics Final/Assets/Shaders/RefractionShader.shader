// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Unlit/RefractionShader"
{
    Properties
    {
        _IOR("Relative IOR", Range(0.1,2)) = 1.4433
        _MainColor("Main Tint", Color) = (1, 1, 1, 1)
       // _BackColor("Fadding Color", Color) = (0, 0, 0, 0)
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

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float4 screenPos : TEXCOORD0;
                float4 objPos : TEXCOORD1;
                float3 worldNormal : TEXCOORD2;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float3x3 tbn : TBN;
                float4x4 fixer : FIXTHIS;
            };

            sampler2D _WorldBehind;
            float _IOR;
            float4 _MainColor;
            float4 _BackColor;

            v2f vert (appdata v)
            {
                v2f o;
                o.worldNormal = mul((float3x3)unity_ObjectToWorld, v.normal);
                o.objPos = v.vertex;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.screenPos = ComputeGrabScreenPos(UnityObjectToClipPos(v.vertex));
                UNITY_TRANSFER_FOG(o,o.vertex);
                
                float3 refractVec = refract(-UnityWorldSpaceViewDir(v.vertex), normalize(o.worldNormal), _IOR);
                //refractVec = getRefractionVector(_IOR, normalize(o.worldNormal), normalize(o.worldNormal));
                
                //Macro found on forum about how to go from world -> tangent https://forum.unity.com/threads/world-space-view-direction-in-surface-shader.88583/
                TANGENT_SPACE_ROTATION;

                o.tbn = rotation;

                o.fixer = unity_WorldToObject;
                //ScreenPos Offset being attempted is inspired by the Real Time Rendering Textbook, 14.5.2
                //o.screenPos = o.screenPos - fixed4(refractVec, 0);

                refractVec = mul(unity_WorldToObject, mul(unity_ObjectToWorld, v.vertex) + refractVec);
                o.screenPos = ComputeGrabScreenPos(UnityObjectToClipPos(refractVec));

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                ////Refraction
                //float3 viewDir = -UnityWorldSpaceViewDir(i.objPos);
                //float3 refractVec = refract(normalize(viewDir), normalize(i.worldNormal), _IOR);
                ////refractVec = getRefractionVector(_IOR, normalize(worldNormal), normalize(worldNormal));
                //refractVec = viewDir;
                ////refractVec = mul(UNITY_MATRIX_V, refractVec);

                ////float3 norm = normalize(mul(unity_CameraToWorld, float3(0, 0, 1)) - _WorldSpaceCameraPos);
                //float3 norm = normalize(viewDir);
                //float3 tan = float3(-viewDir.x, viewDir.y, viewDir.z);
                //float3 binormal = cross(norm, tan);
                //float3x3 rotation = float3x3(tan, binormal, norm);

                //float3 ref = mul(rotation,normalize(refractVec));

                ////ScreenPos Offset being attempted is inspired by the Real Time Rendering Textbook, 14.5.
                //float4 proj = UnityObjectToClipPos(i.objPos);
                //float4 screenPos = ComputeGrabScreenPos(proj);
                //float2 uv = (screenPos / screenPos.w).xy;

                //float3 test = reflect(-viewDir, viewDir);

                //fixed4 col = tex2D(_WorldBehind, uv + test);

                //col.xyz = ref * .5 + .5;
                //col.z = 1;
                //col.a = 1;

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
                //col = tex2Dproj(_WorldBehind, screenPos);

                col.a = step(test.x, 1.0) * step(0.0, test.x) 
                        * step(test.y, 1.0) * step(0.0, test.y);

                col.a = col.a + (1 - col.a) * clamp(1-length(abs(test-.5)-.5)*2,0.0,1.0);

                //col = lerp(_BackColor, col, col.a);

                col = col * _MainColor;

                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG 
        }
    }
}
