Shader "Oil Shaders/Unlit Bubble With Oil"
{
    Properties
    {
        [Header(Basics)]
        [Space]
        _Color("Color", Color) = (1, 1, 1, 1)
        _MainTex("Main Texture", 2D) = "white" {}
        _NormalMap("Normal Map", 2D) = "flat_normal" {}

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
        _TimeScale("Oil's drift speed", Range(0.0,1.0)) = 1.0

        [Header(Phong Base)]
        [Space]
        _LightRadius("Light Radius", Range(2.0,50.0)) = 15

        [Header(Morphing)]
        _MorphWavey("Morph Waveiness",Float) = 0
        _MorphRate("Morph Rate", Float) = 0
        _MorphAmplitude("Morph Amplitude", Float) = 0
        _HeightDisplace("Height", Float) = 0


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
            #include "MorphingPosition.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;

                //Specific use of 3 half3s seen on the unity doc blog that onboards writing custom chaders: https://docs.unity3d.com/Manual/SL-VertexFragmentShaderExamples.html
                half3 tspace0 : TEXCOORD1;
                half3 tspace1 : TEXCOORD2;
                half3 tspace2 : TEXCOORD3; 

                float3 worldPos : TEXCOORD4;
                float3 worldLightPos : TEXCOORD5;
                float4 vertex : SV_POSITION;

                // credits to http://kylehalladay.com/blog/tutorial/2014/02/18/Fresnel-Shaders-From-The-Ground-Up.html
                // and https://www.scratchapixel.com/lessons/3d-basic-rendering/introduction-to-shading/reflection-refraction-fresnel for the theory of the fresnel effect
                float fresnelValue : FRESNEL;

                float3 worldRefl : REFLECTION;

                UNITY_FOG_COORDS(1)
            };

            

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color;
            sampler2D _NormalMap;
            sampler2D _SamplerTable;

            float _FilmIOR;
            float _ObjIOR;
            float _Thickness;
            float _WaveLength;

            float _PoolStrength;
            float _SpreadMode;

            sampler2D _NoiseSample;
            float _TimeScale;

            float _LightRadius;

            float _MorphWavey;
            float _MorphRate;
            float _MorphAmplitude;

            float _HeightDisplace;


            inline float4 UnityObjectToClipPosRespectW(in float4 pos)
            {
                return float4(UnityObjectToViewPos(mul(unity_ObjectToWorld, pos)),1.0);
                //return mul(UNITY_MATRIX_VP, mul(unity_ObjectToWorld, pos));
            }

            v2f vert (appdata v) // the vertex shader
            {
                v2f o;

                float4 objPos = morphPos(v.vertex, v.normal, _Time.w * _MorphRate, _MorphAmplitude, _MorphWavey);

                half3 worldNormal = UnityObjectToWorldNormal(v.normal);

                //Specific use of 3 half3s seen on the unity doc blog that onboards writing custom chaders: https://docs.unity3d.com/Manual/SL-VertexFragmentShaderExamples.html
                half3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
                half tangentSign = v.tangent.w * unity_WorldTransformParams.w;
                half3 worldBitangent = cross(worldNormal, worldTangent) * tangentSign;
                o.tspace0 = half3(worldTangent.x, worldBitangent.x, worldNormal.x);
                o.tspace1 = half3(worldTangent.y, worldBitangent.y, worldNormal.y);
                o.tspace2 = half3(worldTangent.z, worldBitangent.z, worldNormal.z);

                o.worldPos = mul(unity_ObjectToWorld, objPos);

                float3 bobOffset = float3(0, _HeightDisplace, 0);
                o.vertex = UnityObjectToClipPos(objPos + bobOffset);

                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                // credits to Farfarer at https://forum.unity.com/threads/fresnel-cg-shader-code-using-vertex-normals.119984/ for this implementation for getting the fresnelValue 
                float3 viewDir = ObjSpaceViewDir(objPos);
                o.fresnelValue = 1 - saturate(dot(v.normal, viewDir));

                //Phong data
                o.worldLightPos = float3(unity_4LightPosX0.x, unity_4LightPosY0.x, unity_4LightPosZ0.x);

                //Reflection
                //credits to unity docs for showing me how to access the sky box reflections
                // https://docs.unity3d.com/Manual/SL-VertexFragmentShaderExamples.html
                o.worldRefl = reflect(-mul((float3x3)unity_ObjectToWorld, viewDir), worldNormal);

                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }



            fixed4 frag(v2f i) : SV_Target   // the fragment shader
            {
                fixed4 base = tex2D(_MainTex, i.uv) * _Color;

                //Normal Map
                //Specific use of 3 half3s seen on the unity doc blog that onboards writing custom chaders: https://docs.unity3d.com/Manual/SL-VertexFragmentShaderExamples.html
                half3 tnormal = UnpackNormal(tex2D(_NormalMap, i.uv));
                float3 worldNormal;
                worldNormal.x = dot(i.tspace0, tnormal);
                worldNormal.y = dot(i.tspace1, tnormal);
                worldNormal.z = dot(i.tspace2, tnormal);

                //Phong
                float3 light = phongEffect(i.worldPos, worldNormal, i.worldLightPos, _LightRadius);
                fixed4 phongCol = fixed4(light, 1);

                base = base * phongCol;

                phongCol = (light.x + light.y + light.z) / 3;

                //Oil
                float3 viewNormal = mul((float3x3)UNITY_MATRIX_V, worldNormal);
                float3 viewPos = mul((float3x3)UNITY_MATRIX_V, i.worldPos);

                fixed4 oilCol = thinFilmEffectWithNoise(_SpreadMode, i.uv, viewNormal,
                                                viewPos, _Thickness, _ObjIOR, 
                                                _FilmIOR, _WaveLength, _SamplerTable, 
                                                i.fresnelValue, _NoiseSample, _TimeScale);
                //DEBUGGING
                //oilCol = thinFilmEffect(_SpreadMode, i.uv, i.viewNormal,i.viewPos, _Thickness, _ObjIOR,_FilmIOR, _WaveLength, _SamplerTable,i.fresnelValue);

                //Reflection
                fixed4 reflectionCol = fixed4(reflectionSky(i.worldRefl), oilCol.a);

                // sample the texture
                fixed4 col = reflectionCol;
                //col = lerp(col, oilCol, 1-phongCol.a);

                float newAlpha = clamp( (Pooling(i.uv, _PoolStrength) - phongCol.a), 0.0, 1.0);

                col = lerp(col, oilCol, newAlpha );

                //col = lerp(col, oilCol, Pooling(i.uv, _PoolStrength));
                
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
