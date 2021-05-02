// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Unlit/RefractionShader"
{
    Properties
    {
        _IOR("Relative IOR", Range(0.1,10)) = 1.4433
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

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float4 screenPos : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float3x3 tbn : TBN;
            };

            sampler2D _MainTex;
            sampler2D _WorldBehind;
            float4 _MainTex_ST;
            float _IOR;

            v2f vert (appdata v)
            {
                v2f o;
                float3 worldNormal = mul(unity_ObjectToWorld,v.normal);
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.screenPos = ComputeGrabScreenPos(UnityObjectToClipPos(v.vertex));
                UNITY_TRANSFER_FOG(o,o.vertex);
                
                float3 refractVec = refract(normalize(UnityWorldSpaceViewDir(v.vertex)), normalize(worldNormal), _IOR);
                refractVec = getRefractionVector(_IOR, normalize(worldNormal), normalize(worldNormal));
                
                //Macro found on forum about how to go from world -> tangent https://forum.unity.com/threads/world-space-view-direction-in-surface-shader.88583/
                TANGENT_SPACE_ROTATION;

                o.tbn = rotation;
                refractVec = mul(unity_WorldToObject, refractVec);
                refractVec = mul(rotation, refractVec);

                //ScreenPos Offset being attempted is inspired by the Real Time Rendering Textbook, 14.5.2
                o.screenPos = o.screenPos - fixed4(refractVec, 0);



                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                //Refraction
                //i.screenPos = i.screenPos - floor(i.screenPos);

                fixed4 col = tex2Dproj(_WorldBehind, i.screenPos);

                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG 
        }
    }
}
