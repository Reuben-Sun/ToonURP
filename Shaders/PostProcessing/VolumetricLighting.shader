Shader "Hidden/ToonURP/VolumetricLighting"
{
    SubShader
    {
        Cull Off ZWrite Off ZTest Always
        Name "Volumetric Lighting"
        Tags { "RenderType"="UniversalPipeline" }
        Pass
        {
            HLSLPROGRAM
            
            #pragma vertex VolumetricLightingVertex
            #pragma fragment VolumetricLightingFragment

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
			#pragma multi_compile_fragment _ _SHADOWS_SOFT _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
			
            
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

            float GetShadow(float3 posWS)
            {
                half4 shadowMask = half4(1, 1, 1, 1);
                float4 shadowCoord = TransformWorldToShadowCoord(posWS);
                float shadowAttenuation = MainLightShadow(shadowCoord, posWS, shadowMask, _MainLightOcclusionProbes);
                return shadowAttenuation;
            }
            

            Varyings VolumetricLightingVertex (Attributes input)
            {
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                output.positionCS = GetFullScreenTriangleVertexPosition(input.vertexID);
                output.texcoord = GetFullScreenTriangleTexCoord(input.vertexID);
                return output;
            }
            
            void VolumetricLightingFragment(Varyings input, out float4 outColor: SV_Target0)
            {         
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                float2 uv = UnityStereoTransformScreenSpaceTex(input.texcoord);
                float depth = SampleSceneDepth(uv);
                float4 pos = float4(uv.x * 2 -1 , uv.y * 2 -1, 1, depth);
				float3 posWS = ComputeWorldSpacePosition(uv, depth, UNITY_MATRIX_I_VP);
                float shadow = GetShadow(posWS);
                outColor = float4(shadow, shadow, shadow, 1.0);
            }

            ENDHLSL
        }
    }
}