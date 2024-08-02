Shader "Hidden/ToonURP/EdgeOutline"
{
    SubShader
    {
        Cull Off ZWrite Off ZTest Always
        Name "Edge Detection"
        Tags { "RenderType"="UniversalPipeline" }
        Pass
        {
            HLSLPROGRAM
            
            #pragma vertex EdgeOutlineVertex
            #pragma fragment EdgeOutlineFragment

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"

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

            Varyings EdgeOutlineVertex (Attributes input)
            {
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                output.positionCS = GetFullScreenTriangleVertexPosition(input.vertexID);
                output.texcoord = GetFullScreenTriangleTexCoord(input.vertexID);
                return output;
            }
            
            CBUFFER_START(UnityPerMaterial)
            float4 _EdgeColor;
            float4 _EdgeThreshold;
            CBUFFER_END

            SAMPLER(sampler_linear_clamp);
            TEXTURE2D(_EdgeDetectionTexture);        SAMPLER(sampler_EdgeDetectionTexture);
            

            void EdgeOutlineFragment(Varyings input, out float4 outColor: SV_Target0)
            {         
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                float2 uv = UnityStereoTransformScreenSpaceTex(input.texcoord);
                float3 sceneColor = SampleSceneColor(uv);
                float edgeDetect = SAMPLE_TEXTURE2D(_EdgeDetectionTexture, sampler_EdgeDetectionTexture, uv).r;
                float3 color = lerp(sceneColor.rgb, _EdgeColor, edgeDetect * _EdgeThreshold.w);
                outColor = float4(color, 1);
            }
            
            ENDHLSL
        }
    }
}