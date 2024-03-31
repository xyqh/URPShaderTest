Shader "Unlit/DissolveShaderCG"
{
    Properties
    {
        _WordTex("WordTex", 2D) = "white" {}
        _WordTexTiling ("WordTexTiling", Vector) = (1, 1, 0, 0)
        _Speed1 ("Speed1", Vector) = (0, 1, 0, 0)
        _Speed2 ("Speed2", Vector) = (1, 0, 0, 0)
        _Color ("Color", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
        Tags {
            "RenderType" = "Transparent"
            "RenderPipeline" = "UniversalPipeline"
        }
        LOD 100

        Pass
        {
            Blend SrcAlpha SrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float4 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float2 zw : TEXCOORD1;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _WordTex;
            float4 _WordTex_ST;
            float2 _WordTexTiling;
            float2 _Speed1;
            float2 _Speed2;
            float4 _Color;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _WordTex);
                o.zw = v.uv.zw;
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            inline float unity_noise_randomValue (float2 uv)
            {
                return frac(sin(dot(uv, float2(12.9898, 78.233)))*43758.5453);
            }

            inline float unity_noise_interpolate (float a, float b, float t)
            {
                return (1.0-t)*a + (t*b);
            }

            inline float unity_valueNoise (float2 uv)
            {
                float2 i = floor(uv);
                float2 f = frac(uv);
                f = f * f * (3.0 - 2.0 * f);

                uv = abs(frac(uv) - 0.5);
                float2 c0 = i + float2(0.0, 0.0);
                float2 c1 = i + float2(1.0, 0.0);
                float2 c2 = i + float2(0.0, 1.0);
                float2 c3 = i + float2(1.0, 1.0);
                float r0 = unity_noise_randomValue(c0);
                float r1 = unity_noise_randomValue(c1);
                float r2 = unity_noise_randomValue(c2);
                float r3 = unity_noise_randomValue(c3);

                float bottomOfGrid = unity_noise_interpolate(r0, r1, f.x);
                float topOfGrid = unity_noise_interpolate(r2, r3, f.x);
                float t = unity_noise_interpolate(bottomOfGrid, topOfGrid, f.y);
                return t;
            }

            float Unity_SimpleNoise_float(float2 UV, float Scale)
            {
                float t = 0.0;

                float freq = pow(2.0, float(0));
                float amp = pow(0.5, float(3-0));
                t += unity_valueNoise(float2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

                freq = pow(2.0, float(1));
                amp = pow(0.5, float(3-1));
                t += unity_valueNoise(float2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

                freq = pow(2.0, float(2));
                amp = pow(0.5, float(3-2));
                t += unity_valueNoise(float2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

                return t;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float time = _Time.y;
                float2 texOffset1 = time * _Speed1;
                float2 texUv1 = i.uv.xy + texOffset1;
                float2 texOffset2 = time * _Speed2;
                float2 texUv2 = i.uv.xy + texOffset2;
                float noise1 = Unity_SimpleNoise_float(texUv1, 20);
                float noise2 = Unity_SimpleNoise_float(texUv2, 50);
                float texNoise = Unity_SimpleNoise_float(i.uv, 50);
                float noises = step(i.zw.x, texNoise) * noise1 * noise2;
                
                half2 texWordUv = i.uv.xy * _WordTexTiling;
                fixed4 colWord = tex2D(_WordTex, texWordUv);

                fixed4 col = fixed4((_Color * colWord.w).xyz, colWord.w * noises);

                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
