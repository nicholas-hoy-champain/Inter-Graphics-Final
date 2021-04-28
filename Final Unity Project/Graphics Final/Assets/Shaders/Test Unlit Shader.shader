Shader "Unlit/Test Unlit Shader"
{
    Properties
    {
        _Color("Color", Color) = (1, 1, 1, 1)
        _MainTex("Texture", 2D) = "white" {}
        _FilmIOR("Film IOR", Range(1.0,5.0)) = 1.4433
        _ObjIOR("Object IOR", Range(1.0,5.0)) = 1.333
        _Thickness("Film Thickness", Range(0.01,1.0)) = 1.0
        _WaveLength("Wavelength", Float) = 1.0
        //_LightPoint("Light Position", Vector) = (0,0,0,0);
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

            const float PI = 3.14159265;

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color;
            float _FilmIOR;
            float _ObjIOR;
            float _Thickness;
            float _WaveLength;

            v2f vert (appdata v)
            {
                v2f o;
                o.viewNormal = normalize(mul((float3x3)UNITY_MATRIX_MV, v.normal));
                o.viewPos = UnityObjectToViewPos(v.vertex);
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv) * _Color;

                float2 distanceFromCenter = i.uv - 0.5;

                float viewAngle = dot(i.viewNormal, normalize(-i.viewPos));
                
                float thickness = _Thickness * (1-cos(viewAngle));
                //float thickness = _Thickness * (1-cos(viewAngle));
                
                float isInverted = step(_ObjIOR, _FilmIOR) * PI / 2;

                float wavelength = _WaveLength;

                float reflectance = pow(cos(2 * PI * thickness * _FilmIOR / wavelength + isInverted), 2);
                
                col = float4(reflectance, reflectance, reflectance, reflectance);
                col.a = _Color.a;

                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}