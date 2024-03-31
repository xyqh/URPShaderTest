Shader "Unlit/ComicShaderCG"
{
    Properties
    {
        _LightDir ("Light Direction", Vector) = (1, 1, 1)
        [FloatRange]_Shading1 ("SmoothStep Edge1", Range(0, 1)) = 0.2
        [FloatRange]_Shading2 ("SmoothStep Edge1", Range(0, 1)) = 0.4
        _Scale ("Screen Position Scale", Float) = 10
        _DotSize ("Dot Size", Float) = 10
        _MainTex ("Main Texture", 2D) = "White" {}
    }
    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
        }

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
                float3 normal : TEXCOORD1;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };
            
            float3 _LightDir;
            float _Shading1;
            float _Shading2;
            float _Scale;
            float _DotSize;
            sampler2D _MainTex;
            float4 _MainTex_ST;

            void Unity_Ellipse_float(float2 UV, float Width, float Height, out float Out)
            {
                float d = length((UV * 2 - 1) / float2(Width, Height));
                Out = saturate((1 - d) / fwidth(d));
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float4 screenPos = ComputeScreenPos(i.vertex) / i.vertex.w;
                float4 m_screenPos = _Scale * screenPos;
                float2x2 m_rotate = float2x2
                (
                    cos(41), sin(41),
                    -sin(41), cos(41)
                );
                float2 r_m_screenPos = mul(m_rotate, m_screenPos);
                float2 screenPosFrac = frac(r_m_screenPos);
                float stepOutput = 1 - smoothstep(_Shading1, _Shading2, saturate(dot(normalize(i.normal), normalize(_LightDir))));
                float width = _DotSize * stepOutput;
                float height = _ScreenParams.x / _ScreenParams.y * _DotSize * stepOutput;
                float ellipse;
                Unity_Ellipse_float(screenPosFrac, width, height, ellipse);
                return lerp(tex2D(_MainTex, i.uv), float4(1, 1, 1, 1), 1 - ellipse);
            }
            ENDCG
        }
    }
}
