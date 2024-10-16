Shader "Hidden/ToonURP/CombineSample"
{
    SubShader
    {
        Cull Off ZWrite Off ZTest Always
        Name "Combine Sample"
        Tags
        {
            "RenderType"="UniversalPipeline"
        }
        Pass
        {
            HLSLPROGRAM
            #pragma vertex CombineSampleVertex
            #pragma fragment CombineSampleFragment

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"


            struct Attributes
            {
                uint vertexID : SV_VertexID;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 texcoord : TEXCOORD0;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            TEXTURE2D(_SourceMap);
            SAMPLER(sampler_SourceMap);
            float _Intensity;

            Varyings CombineSampleVertex(Attributes input)
            {
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                output.positionCS = GetFullScreenTriangleVertexPosition(input.vertexID);
                output.texcoord = GetFullScreenTriangleTexCoord(input.vertexID);
                return output;
            }

            void CombineSampleFragment(Varyings input, out float4 outColor: SV_Target0)
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                float2 uv = UnityStereoTransformScreenSpaceTex(input.texcoord);
                float4 sourceColor = SAMPLE_TEXTURE2D(_SourceMap, sampler_SourceMap, uv);
                float3 opaqueColor = SampleSceneColor(uv);
                outColor = float4(sourceColor * _Intensity + opaqueColor, 1.0);
            }
            ENDHLSL
        }
    }
}