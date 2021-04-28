Shader "Oil Shaders/Unlit Bubble With Oil"
{
    Properties
    {
        [Header(Basics)]
        [Space]
        _Color("Color", Color) = (1, 1, 1, 1)
        _MainTex("Texture", 2D) = "white" {}
        [Header(Oil Characteristics)]
        [Space]
        _FilmIOR("Film IOR", Range(1.0,5.0)) = 1.4433
        _ObjIOR("Object IOR", Range(1.0,5.0)) = 1.333
        _Thickness("Film Thickness", Range(0.0,1.0)) = 1.0
        _WaveLength("Wavelength", Range(0.0,1.0)) = 1.0
        _SamplerTable("SamplerTable", 2D) = "white" {}
        [Space]
        _PoolStrength("Pooling Amount",  Range(0.0, 1.0)) = 0.0
        //_LightPoint("Light Position", Vector) = (0,0,0,0);

        // Display a popup with None,Add,Multiply choices,
        // and setup corresponding shader keywords.
        //[KeywordEnum(None, Add, Multiply)] _Overlay("Overlay mode", Float) = 0
        //_OverlayTex("Overlay", 2D) = "black" {}

        // Display as a toggle.
        //[Toggle] _Invert("Invert color?", Float) = 0
    }
    SubShader
    {
        Tags { "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType"="Transparent" }
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

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                half3 viewNormal : TEXCOORD0;
                float3 viewPos : TEXCOORD1;
                float2 uv : TEXCOORD2;
                float4 vertex : SV_POSITION;
                UNITY_FOG_COORDS(1)
            };

            

            sampler2D _MainTex;
            sampler2D _SamplerTable;
            float4 _MainTex_ST;
            fixed4 _Color;
            float _FilmIOR;
            float _ObjIOR;
            float _Thickness;
            float _WaveLength;
            float _PoolStrength;

            inline float4 UnityObjectToClipPosRespectW(in float4 pos)
            {
                return mul(UNITY_MATRIX_VP, mul(unity_ObjectToWorld, pos));
            }

            v2f vert (appdata v) // the vertex shader
            {
                v2f o;
                o.viewNormal = normalize(UnityObjectToViewPos(v.normal));
                //o.viewNormal = UnityObjectToClipPosRespectW(v.normal);
                //o.viewNormal = normalize(mul((float3x3)UNITY_MATRIX_MV, v.normal));
                o.viewPos = UnityObjectToViewPos(v.vertex);
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }


            float Pooling(float2 uv)
            {
                float pixelStrength = 1 - uv.y;
                pixelStrength += (1 - _PoolStrength);
                return min(pixelStrength, 1.0);
            }


            fixed4 frag (v2f i) : SV_Target   // the fragment shader
            {
                const float PI = 3.14159265;

                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv) * _Color;

                float2 distanceFromCenter = i.uv - 0.5;

                float viewAngle = dot(i.viewNormal, normalize(-i.viewPos));
                
                float thickness = _Thickness * (1-cos(viewAngle));
                //float thickness = _Thickness * (1-cos(viewAngle));
                
                float isInverted = step(_ObjIOR, _FilmIOR) * PI / 2;

                float wavelength = _WaveLength;

                float reflectance = pow(1.0 * cos(2 * PI * thickness * _FilmIOR / wavelength + isInverted), 2);

                //reflectance = (reflectance - 380);
                //reflectance = (reflectance-380) / 400;
                fixed4 oilCol = tex2D(_SamplerTable, float2(reflectance, reflectance));
                oilCol.a = _Color.a;
                
                col = lerp(col, oilCol, Pooling(i.uv));
                //col = oilCol;

                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
