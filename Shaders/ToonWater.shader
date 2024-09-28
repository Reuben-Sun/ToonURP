Shader "ToonURP/ToonWater"
{
    Properties
    {
        [Header(shading)]
        _DepthGradientShallow("Depth Gradient Shallow", Color) = (0.325, 0.807, 0.971, 0.725)
        _DepthGradientDeep("Depth Gradient Deep", Color) = (0.086, 0.407, 1, 0.749)
        _DepthMaxDistance("Depth Max Distance", Float) = 1
        _FoamColor("Foam Color", Color) = (1,1,1,1)
        [Header(wave)]
        _SurfaceNoise("Surface Noise",2D) = "white" {}
        _SurfaceNoiseCutoff("Surface Noise Cutoff", Range(0, 1)) = 0.5
        // _FoamDistance("Foam Distance", Float) = 0.4
        _SurfaceNoiseScroll("Surface Noise Scroll Amount", Vector) = (0.03, 0.03, 0, 0)
        _SurfaceDistortion("Surface Distortion", 2D) = "white" {}
        _SurfaceDistortionAmount("Surface Distortion Amount", Range(0, 1)) = 0.27
        _FoamMaxDistance("Foam Maximum Distance", Float) = 0.4
        _FoamMinDistance("Foam Minimum Distance", Float) = 0.04
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" }
        LOD 100
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
			#pragma target 4.6
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
			#pragma multi_compile _ _SHADOWS_SOFT

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareNormalsTexture.hlsl"

            #define SMOOTH_AA 0.01
            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal: NORMAL;
                float2 uv: TEXCOORD0;
            };

            struct v2f
            {
                float4 posCS : SV_POSITION;
                float3 posWS: TEXCOORD0;
                float3 viewNormal: NORMAL;
                float4 screenPosition: TEXCOORD1;
                float2 noiseUV: TEXCOORD2;
                float2 distortUV: TEXCOORD3;
            };

            SAMPLER(sampler_linear_clamp);

            float4 _DepthGradientShallow;
            float4 _DepthGradientDeep;
            float _DepthMaxDistance;

            sampler2D _SurfaceNoise;
            float4 _SurfaceNoise_ST;

            float _SurfaceNoiseCutoff;
            // float _FoamDistance;
            float2 _SurfaceNoiseScroll;

            sampler2D _SurfaceDistortion;
            float4 _SurfaceDistortion_ST;
            float _SurfaceDistortionAmount;
            float _FoamMaxDistance;
            float _FoamMinDistance;

            float4 _FoamColor;

            v2f vert (appdata v)
            {
                v2f o;
                o.posCS = TransformObjectToHClip(v.vertex);
                o.posWS = TransformObjectToWorld(v.vertex);
                o.viewNormal = mul(UNITY_MATRIX_IT_MV, v.normal);
                o.screenPosition = ComputeScreenPos(o.posCS);
                o.noiseUV = TRANSFORM_TEX(v.uv, _SurfaceNoise);
                o.distortUV = TRANSFORM_TEX(v.uv, _SurfaceDistortion);
                return o;
            }

            float SampleSceneDepth(float2 uv, TEXTURE2D_X_FLOAT(_Texture), SAMPLER(sampler_Texture))
            {
                return SAMPLE_TEXTURE2D_X(_Texture, sampler_Texture, UnityStereoTransformScreenSpaceTex(uv)).r;
            }

            float SampleSceneNormals(float2 uv, TEXTURE2D_X_FLOAT(_Texture), SAMPLER(sampler_Texture))
            {
                return SAMPLE_TEXTURE2D_X(_Texture, sampler_Texture, UnityStereoTransformScreenSpaceTex(uv)).r;
            }

            float4 alphaBlend(float4 top, float4 bottom) {
                float3 color = (top.rgb * top.a) + (bottom.rgb * (1- top.a));
                float alpha = top.a +bottom.a * (1- top.a);
                return float4(color,alpha);
            }

            float4 frag (v2f i) : SV_Target
            {
                // calculate the color through depth of shadowmap
                float2 uv = i.screenPosition.xy / i.screenPosition.w;
                float shadowMapDepth = SampleSceneDepth(uv, _CameraDepthTexture, sampler_linear_clamp); 
                float existingDepthLinear = LinearEyeDepth(shadowMapDepth, _ZBufferParams);
                // calculate scene normals
                float3 existingNormal = SampleSceneNormals(uv, _CameraNormalsTexture, sampler_linear_clamp);
                float3 normalDot = saturate(dot(existingNormal, i.viewNormal));
                float foamDistance = lerp(_FoamMaxDistance, _FoamMinDistance, normalDot);

                float depthDifference = existingDepthLinear - i.screenPosition.w;

                float waterDepthDifference = saturate(depthDifference / _DepthMaxDistance);
                float4 waterColor = lerp(_DepthGradientShallow, _DepthGradientDeep, waterDepthDifference);
                
                float foamDepthDifference = saturate(depthDifference / foamDistance);

                // sample the noise texture
                float2 distortSample = (tex2D(_SurfaceDistortion, i.distortUV).xy * 2 - 1) * _SurfaceDistortionAmount;

                float2 noiseUV = float2(i.noiseUV.x + _Time.y * _SurfaceNoiseScroll.x + distortSample.x, 
                    i.noiseUV.y + _Time.y * _SurfaceNoiseScroll.y + distortSample.y);
                float surfaceNoiseSample = tex2D(_SurfaceNoise, noiseUV).r;
                float surfaceNoiseCutoff = foamDepthDifference * _SurfaceNoiseCutoff;
                float surfaceNoise = smoothstep(surfaceNoiseCutoff - SMOOTH_AA, surfaceNoiseCutoff + SMOOTH_AA, surfaceNoiseSample);
                float4 surfaceNoiseColor = _FoamColor;
                surfaceNoiseColor.a *= surfaceNoise;
                float4 col = alphaBlend(surfaceNoiseColor, waterColor);

                return col;
            }
            ENDHLSL
        }
    }
}
