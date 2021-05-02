Shader "Oil Shaders/Bubble with noise"
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
                float2 uv : TEXCOORD0;
                float3 viewPos : TEXCOORD1;
                half3 viewNormal : TEXCOORD2;
                float4 vertex : SV_POSITION;

                // credits to http://kylehalladay.com/blog/tutorial/2014/02/18/Fresnel-Shaders-From-The-Ground-Up.html
                // and https://www.scratchapixel.com/lessons/3d-basic-rendering/introduction-to-shading/reflection-refraction-fresnel for the theory of the fresnel effect

                float fresnelValue : FRESNEL;
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


            inline float4 UnityObjectToClipPosRespectW(in float4 pos)
            {
                //return mul(UNITY_MATRIX_VP, mul(unity_ObjectToWorld, pos));
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

                // credits to Farfarer at https://forum.unity.com/threads/fresnel-cg-shader-code-using-vertex-normals.119984/ for this implementation for getting the fresnelValue 
                float3 viewDir = ObjSpaceViewDir(v.vertex);
                o.fresnelValue = 1 - saturate(dot(v.normal, viewDir));

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
                
                //set up spread mode 
                float isPuddle = step(_SpreadMode, 3.0) * step(3.0, _SpreadMode);
                float isBubbleTimed = step(_SpreadMode, 2.0) * step(2.0, _SpreadMode);
                float isBubble = step(_SpreadMode, 1.0) * step(1.0, _SpreadMode) + isBubbleTimed;
                float isEven = step(_SpreadMode, 0.0) * step(0.0, _SpreadMode);

                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv) * _Color;

                float2 distanceFromCenter = i.uv - 0.5;

                float viewAngle = dot(i.viewNormal, normalize(-i.viewPos));
                
                float thickness = _Thickness;

                float bubbleParam = i.uv.y * i.uv.y * i.uv.y * i.uv.y; //Pooling(i.uv);;

                thickness = isEven * thickness +
                            isBubble * lerp(0, thickness, bubbleParam);

                thickness = thickness * (1-cos(viewAngle));
                
                float isInverted = step(_ObjIOR, _FilmIOR) * PI / 2;

                float wavelength = _WaveLength;

                float reflectance = pow(1.0 * cos(2 * PI * thickness * _FilmIOR / wavelength + isInverted), 2);



                //reflectance = (reflectance - 380);
                //reflectance = (reflectance-380) / 400;

                float noiseOffset = tex2D(_NoiseSample, i.uv + _SinTime/50);
                float2 offsetReflectance = float2(reflectance, reflectance);
                offsetReflectance.x = offsetReflectance.x + noiseOffset;

                fixed4 oilCol = tex2D(_SamplerTable, offsetReflectance);
                oilCol.a = _Color.a;

                oilCol.a = i.fresnelValue * reflectance;

                col = lerp(col, oilCol, Pooling( i.uv ));
                //col = oilCol;

                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
