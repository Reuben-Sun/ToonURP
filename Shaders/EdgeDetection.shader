﻿Shader "Hidden/ToonURP/EdgeDetection"
{
    SubShader
    {
        Cull Off ZWrite Off ZTest Always
        Name "Edge Detection"
        Tags { "RenderType"="UniversalPipeline" }
        Pass
        {
            HLSLPROGRAM
            
            #pragma vertex EdgeDetectionVertex
            #pragma fragment EdgeDetectionFragment

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareNormalsTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            struct Attributes
            {
                uint vertexID : SV_VertexID;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 texcoord   : TEXCOORD0;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            Varyings EdgeDetectionVertex (Attributes input)
            {
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                output.positionCS = GetFullScreenTriangleVertexPosition(input.vertexID);
                output.texcoord = GetFullScreenTriangleTexCoord(input.vertexID);
                return output;
            }
            
            CBUFFER_START(UnityPerMaterial)
            float4 _BlitTexture_TexelSize;
            float4 _EdgeThreshold;
            CBUFFER_END
            
            SAMPLER(sampler_linear_clamp);
            
            float3 SampleSceneNormals(float2 uv, TEXTURE2D_X_FLOAT(_Texture), SAMPLER(sampler_Texture))
            {
                return UnpackNormalOctRectEncode(SAMPLE_TEXTURE2D_X(_Texture, sampler_Texture, UnityStereoTransformScreenSpaceTex(uv)).xy) * float3(1.0, 1.0, -1.0);
            }

            float SampleSceneDepth(float2 uv, TEXTURE2D_X_FLOAT(_Texture), SAMPLER(sampler_Texture))
            {
                return SAMPLE_TEXTURE2D_X(_Texture, sampler_Texture, UnityStereoTransformScreenSpaceTex(uv)).r;
            }
            
            // this method from https://github.com/yahiaetman/URPCustomPostProcessingStack"
            float4 SampleSceneDepthNormal(float2 uv)
            {
                float depth = SampleSceneDepth(uv, _CameraDepthTexture, sampler_linear_clamp); 
                float depthEye = LinearEyeDepth(depth, _ZBufferParams);
                float3 normal = SampleSceneNormals(uv, _CameraNormalsTexture, sampler_linear_clamp);
                return float4(normal, depthEye);
            }
            
            float4 SampleNeighborhood(float2 uv, float thickness)
            {
                const float2 offsets[8] = {
                    float2(-1, -1),
                    float2(-1, 0),
                    float2(-1, 1),
                    float2(0, -1),
                    float2(0, 1),
                    float2(1, -1),
                    float2(1, 0),
                    float2(1, 1)
                };
                
                float2 delta = _BlitTexture_TexelSize.xy * thickness;
                float4 sum = 0;
                float weight = 0;
                // this method ref from https://github.com/yahiaetman/URPCustomPostProcessingStack"
                for(int i=0; i<8; i++){
                    float4 sample = SampleSceneDepthNormal(uv + delta * offsets[i]);
                    sum += sample / sample.w; // for perspective
                    weight += 1/sample.w;
                }
                sum /= weight;
                return sum;
            }

            void EdgeDetectionFragment(Varyings input, out float4 outColor: SV_Target0)
            {         
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                float2 uv = UnityStereoTransformScreenSpaceTex(input.texcoord);
                uv.y = 1 - uv.y;
                float4 center = SampleSceneDepthNormal(uv);
                float4 neighborhood = SampleNeighborhood(uv,  _EdgeThreshold.y);
                float normalSampler = smoothstep(_EdgeThreshold.x, 1, dot(center.xyz, neighborhood.xyz));
                float depthSampler = smoothstep(_EdgeThreshold.z * center.w, 0.0001f * center.w, abs(center.w - neighborhood.w));
                float edge = 1 - normalSampler * depthSampler;
                outColor = edge * _EdgeThreshold.w;
            }
            
            ENDHLSL
        }
    }
}