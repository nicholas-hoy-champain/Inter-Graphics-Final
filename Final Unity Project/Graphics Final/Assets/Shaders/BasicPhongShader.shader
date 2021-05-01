Shader "Unlit/BasicPhongShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _LightRadius ("Light Radius", float) = 1000
    }
    SubShader
    {
        Tags {"LightMode" = "ForwardBase"   "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent"}
        Blend SrcAlpha OneMinusSrcAlpha
        LOD 200

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float3 tangent : TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 normal : TEXCOORD3;
                float3 wPos : TEXCOORD2;
                float3 wLightPos : TEXCOORD1;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _LightRadius;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                o.normal = UnityObjectToWorldNormal(v.normal);
                o.wPos = mul(unity_ObjectToWorld, v.vertex);
                o.wLightPos = float3(unity_4LightPosX0.x, unity_4LightPosY0.x, unity_4LightPosZ0.x);
                //o.wLightPos = _WorldSpaceLightPos0;

                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float radiusInvSqr = 1/(_LightRadius * _LightRadius);

                float3 wNormal = normalize(i.normal);
                float3 L = i.wLightPos - i.wPos;
                float lightDistance = length(L);
                L = L / lightDistance;

                float lmbCoeff = max(0.0, dot(wNormal, L));
                float attenuation = lerp(1.0, 0.0, lightDistance * radiusInvSqr);

                float3 V = normalize(_WorldSpaceCameraPos - i.wPos);
                float3 R = reflect(-L, wNormal);
                float phongCoeff = max(0.0, dot(R, V));

                float3 effect = unity_LightColor[0] * (lmbCoeff + phongCoeff) * attenuation;

                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                col = col * float4(effect, col.a);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
