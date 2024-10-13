#ifndef SSPR_INCLUDE
#define SSPR_INCLUDE

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

TEXTURE2D(_SSPRGlobalColorRT);
sampler LinearClampSampler;

struct ReflectionInput
{
    float3 posWS;
    float4 screenPos;
    float2 screenSpaceNoise;
    float roughness;
    float SSPR_Usage;
};

half3 GetReflectionColor(ReflectionInput input)
{
    half3 viewWS = (input.posWS - _WorldSpaceCameraPos);
    viewWS = normalize(viewWS);
    half3 reflectDirWS = viewWS * half3(1,-1,1);
    half3 reflectionProbeResult = GlossyEnvironmentReflection(reflectDirWS,input.roughness,1);               
    half4 SSPRResult = 0;
    half2 screenUV = input.screenPos.xy / input.screenPos.w;
    SSPRResult = SAMPLE_TEXTURE2D(_SSPRGlobalColorRT, LinearClampSampler, screenUV + input.screenSpaceNoise);
    half3 finalReflection = lerp(reflectionProbeResult,SSPRResult.rgb, SSPRResult.a * input.SSPR_Usage);
    return finalReflection;
}
#endif
