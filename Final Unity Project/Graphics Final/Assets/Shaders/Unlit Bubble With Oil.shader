Shader "Oil Shaders/Unlit Bubble With Oil"
{
    Properties
    {
        [Header(Basics)]
        [Space]
        _Color("Color", Color) = (1, 1, 1, 1)
        _MainTex("Texture", 2D) = "white" {}

        [Header(Oil Type)]
        [Space]
        [KeywordEnum(Even, Bubble, Timed Bubble, Puddle)] _SpreadMode("Oil Spread Mode", Float) = 0        //_LightPoint("Light Position", Vector) = (0,0,0,0);
        
        [Header(Oil Characteristics)]
        [Space]
        _FilmIOR("Film IOR", Range(1.0,5.0)) = 1.4433
        _ObjIOR("Object IOR", Range(1.0,5.0)) = 1.333
        _Thickness("Film Thickness", Range(0.0,1.0)) = 1.0
        _WaveLength("Wavelength", Range(0.0,1.0)) = 1.0
        _SamplerTable("SamplerTable", 2D) = "white" {}

        [Space]
        _PoolStrength("Pooling Amount",  Range(0.0, 1.0)) = 0.0

        [Header(Noise Offst)]
        [Space]
        _NoiseSample("Noise Sample", 2D) = "white" {}

        [Header(Phong Base)]
        [Space]
        _LightRadius("Light Radius", Range(2.0,50.0)) = 15


        // Display a popup with None,Add,Multiply choices,
        // and setup corresponding shader keywords.
        //[KeywordEnum(None, Add, Multiply)] _Overlay("Overlay mode", Float) = 0
        //_OverlayTex("Overlay", 2D) = "black" {}

        // Display as a toggle.
        //[Toggle] _Invert("Invert color?", Float) = 0
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
            #include "PhongAndOil.cginc"
            #include "Reflection.cginc"
            #include "Refraction.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float3 viewNormal : TEXCOORD0;
                float3 viewPos : TEXCOORD1;
                float3 worldNormal : TEXCOORD2;
                float3 worldPos : TEXCOORD3;
                float3 worldLightPos : TEXCOORD4;
                float2 uv : TEXCOORD5;
                float4 vertex : SV_POSITION;

                // credits to http://kylehalladay.com/blog/tutorial/2014/02/18/Fresnel-Shaders-From-The-Ground-Up.html
                // and https://www.scratchapixel.com/lessons/3d-basic-rendering/introduction-to-shading/reflection-refraction-fresnel for the theory of the fresnel effect
                float fresnelValue : FRESNEL;

                float3 worldRefl : REFLECTION;

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
            float _SpreadMode;

            sampler2D _NoiseSample;

            float _LightRadius;

            inline float4 UnityObjectToClipPosRespectW(in float4 pos)
            {
                return mul(UNITY_MATRIX_VP, mul(unity_ObjectToWorld, pos));
            }

            v2f vert (appdata v) // the vertex shader
            {
                v2f o;
                //o.viewNormal = normalize(UnityObjectToViewPos(v.normal));
                //o.viewNormal = UnityObjectToClipPosRespectW(v.normal);
                o.viewNormal = normalize(mul((float3x3)UNITY_MATRIX_MV, v.normal));
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.viewPos = UnityObjectToViewPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                // credits to Farfarer at https://forum.unity.com/threads/fresnel-cg-shader-code-using-vertex-normals.119984/ for this implementation for getting the fresnelValue 
                float3 viewDir = ObjSpaceViewDir(v.vertex);
                o.fresnelValue = 1 - saturate(dot(v.normal, viewDir));

                //Phong data
                o.worldLightPos = float3(unity_4LightPosX0.x, unity_4LightPosY0.x, unity_4LightPosZ0.x);

                //Reflection
                //credits to unity docs for showing me how to access the sky box reflections
                // https://docs.unity3d.com/Manual/SL-VertexFragmentShaderExamples.html
                o.worldRefl = reflect(-mul((float3x3)unity_ObjectToWorld, viewDir), o.worldNormal);

                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }


            float Pooling(float2 uv)
            {
                float pixelStrength = 1 - uv.y;
                pixelStrength += (1 - _PoolStrength);
                return min(pixelStrength, 1.0);
            }


            fixed4 frag(v2f i) : SV_Target   // the fragment shader
            {
                fixed4 base = tex2D(_MainTex, i.uv) * _Color;

                //Phong
                float3 light = phongEffect(i.worldPos, i.worldNormal, i.worldLightPos, _LightRadius);
                fixed4 phongCol = fixed4(light, 1);

                base = base * phongCol;

                phongCol = (light.x + light.y + light.z) / 3;

                //Oil
                fixed4 oilCol = thinFilmEffectWithNoise(_SpreadMode, i.uv, i.viewNormal,
                                                i.viewPos, _Thickness, _ObjIOR, 
                                                _FilmIOR, _WaveLength, _SamplerTable, 
                                                i.fresnelValue, _NoiseSample);
                //DEBUGGING
                //oilCol = thinFilmEffect(_SpreadMode, i.uv, i.viewNormal,i.viewPos, _Thickness, _ObjIOR,_FilmIOR, _WaveLength, _SamplerTable,i.fresnelValue);

                //Reflection
                fixed4 reflectionCol = fixed4(reflectionSky(i.worldRefl), oilCol.a);

                // sample the texture
                fixed4 col = reflectionCol;
                col = lerp(col, oilCol, 1-phongCol.a);
                col = lerp(col, phongCol, phongCol.a * phongCol.a * phongCol.a);

                float a = col.a;

                // overlay the thinfilm over the floor
                col = lerp(base, col, a);

                col.a = base.a + a;

                //DEBUGGING
                //col = refractionCol;

                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
