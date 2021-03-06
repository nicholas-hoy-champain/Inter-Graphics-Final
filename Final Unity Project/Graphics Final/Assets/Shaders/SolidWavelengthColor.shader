Shader "Unlit/SolidWavelengthColor"
{
    Properties
    {
        _Wavelength ("Color Wavelength", Range(380,750)) = 500
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

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
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            float _Wavelength;
            float4 _MainTex_ST;

            //CIE XYZ functions were referenced in nearly every source from the RTR textbook, 
            //but had to dig for the actual equation and found them on the wikipedia page for 
            //CIE 1931 color space.
            //https://en.wikipedia.org/wiki/CIE_1931_color_space

            float pieceWiseGausian(float x, float scale, float peak, float leftSpread, float rightSpread)
            {
                float spread = step(x,peak) * leftSpread + step(peak, x) * rightSpread;
                float t = (x - peak) / spread;
                return scale * exp(-(t*t) / 2);
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float3x3 CIEtoRGB = float3x3(.41847,-0.15866,-0.082835,
                                                    -0.091169, 0.25243, 0.015708,
                                                    0.00092090,-0.0025498,0.17860);
                CIEtoRGB = transpose(CIEtoRGB);

                float3 CIExyz;

                float wavelen = _Wavelength * 10; //convert to angstrom

                CIExyz.x = pieceWiseGausian(wavelen,  1.056, 5998, 379, 310) +
                    pieceWiseGausian(wavelen,  0.362, 4420, 160, 267) +
                    pieceWiseGausian(wavelen, -0.065, 5011, 204, 262);
                CIExyz.y = pieceWiseGausian(wavelen,  0.821, 5688, 469, 405) +
                    pieceWiseGausian(wavelen,  0.286, 5309, 163, 311);
                CIExyz.z = pieceWiseGausian(wavelen, 1.217, 4370, 118, 360) +
                    pieceWiseGausian(wavelen, 0.681, 4590, 260, 138);

                float CIExyz_sum = CIExyz.x + CIExyz.y + CIExyz.z;
                float2 CIExy;
                CIExy.x = CIExyz.x / CIExyz_sum;
                CIExy.y = CIExyz.y / CIExyz_sum;

                float3 CIErgb = mul(CIExyz, CIEtoRGB);
                float CIErgb_sum = CIErgb.x+ CIErgb.y+ CIErgb.z;

                float3 CIErg;
                CIErg.x = CIErgb.x / CIErgb_sum;
                CIErg.y = CIErgb.y / CIErgb_sum;
                CIErg.z = CIErgb.y;

                /*float done = step(0.0, CIErgb.x) * step(CIErgb.x, 1.0)
                    * step(0.0, CIErgb.y) * step(CIErgb.y, 1.0)
                    * step(0.0, CIErgb.z) * step(CIErgb.z, 1.0);

                float3 dir = float3(1.0/3.0, 1.0 / 3.0, 1.0 / 3.0) - CIErgb;
                int steps = 200;
                dir = dir / steps;
                for (int i = 0; i < steps && done < 1.0; i++)
                {
                    CIErgb = CIErgb + dir;
                    done = step(0.0, CIErgb.x) * step(CIErgb.x, 1.0)
                        * step(0.0, CIErgb.y) * step(CIErgb.y, 1.0)
                        * step(0.0, CIErgb.z) * step(CIErgb.z, 1.0);
                }*/

                CIErgb = CIErgb * 1/max(max(CIErgb.x, CIErgb.y), CIErgb.z);
 
                fixed4 col = float4(CIErgb, 1);

                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
