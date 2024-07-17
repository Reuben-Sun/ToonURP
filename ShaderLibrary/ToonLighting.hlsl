#ifndef TOON_LIGHTING_INCLUDED
#define TOON_LIGHTING_INCLUDED

#include "Packages/com.reubensun.toonurp/ShaderLibrary/ToonSurfaceData.hlsl"
#include "Packages/com.reubensun.toonurp/ShaderLibrary/ToonBRDF.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

struct ToonLightingData
{
    float3 lightColor;
    float3 halfDir;
    float3 lightDir;
    float NoL;
    float NoLClamp;
    float HalfLambert;
    float NoVClamp;
    float NoHClamp;
    float LoHClamp;
    float VoHClamp;
    float shadowAttenuation;
};

ToonLightingData InitializeLightingData(Light mainLight, float3 normalWS, float3 viewDir)
{
    ToonLightingData lightData = (ToonLightingData)0;
    lightData.lightColor = mainLight.color;
    lightData.lightDir = mainLight.direction.xyz;
    lightData.NoL = dot(normalWS, lightData.lightDir);
    lightData.NoLClamp = saturate(lightData.NoL);
    lightData.HalfLambert = 0.5 * (lightData.NoL + 1);
    lightData.NoVClamp = saturate(dot(normalWS, viewDir));
    half3 halfDir = SafeNormalize(lightData.lightDir + viewDir);
    lightData.halfDir = halfDir;
    lightData.NoHClamp = saturate(dot(normalWS, halfDir));
    lightData.LoHClamp = saturate(dot(lightData.lightDir, halfDir));
    lightData.shadowAttenuation = mainLight.shadowAttenuation * mainLight.distanceAttenuation;
    return lightData;
}

float4 UniversalFragmentPBR(InputData inputData, ToonSurfaceData toonSurfaceData)
{
    SurfaceData surfaceData = ConvertToonSurfaceDataToURPSurfaceData(toonSurfaceData);
    return UniversalFragmentPBR(inputData, surfaceData);
}

float4 ToonFragment(InputData inputData, ToonSurfaceData toonSurfaceData)
{
    // prepare
    half4 shadowMask = CalculateShadowMask(inputData);
    uint meshRenderingLayers = GetMeshRenderingLayer();
    Light mainLight = GetMainLight(inputData.shadowCoord, inputData.positionWS, shadowMask);
    MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI);

    #if defined(_SCREEN_SPACE_OCCLUSION)
    AmbientOcclusionFactor aoFactor = GetScreenSpaceAmbientOcclusion(inputData.normalizedScreenSpaceUV);
    mainLight.color *= aoFactor.directAmbientOcclusion;
    surfaceData.occlusion = min(surfaceData.occlusion, aoFactor.indirectAmbientOcclusion);
    #else
    AmbientOcclusionFactor aoFactor;
    aoFactor.indirectAmbientOcclusion = 1;
    aoFactor.directAmbientOcclusion = 1;
    #endif

    BRDFData brdfData;
    InitializeToonBRDFData(toonSurfaceData, brdfData);

    // lighting
    ToonLightingData lightingData = InitializeLightingData(mainLight, inputData.normalWS, inputData.viewDirectionWS);
    
    half4 color = 1;
    // color.rgb = FernMainLightDirectLighting(brdfData, clearCoatbrdfData, input, inputData, surfaceData, lightingData);
    // color.rgb += FernAdditionLightDirectLighting(brdfData, clearCoatbrdfData, input, inputData, surfaceData, addInputData, shadowMask, meshRenderingLayers, aoFactor);
    // color.rgb += FernIndirectLighting(brdfData, inputData, input, surfaceData.occlusion);
    // color.rgb += FernRimLighting(lightingData, inputData, input, addInputData); 

    // color.rgb += surfaceData.emission;
    color.rgb = MixFog(color.rgb, inputData.fogCoord);

    // color.a = surfaceData.alpha;
    // return color;
    return float4(1, 0, 1, 1);
}

#endif