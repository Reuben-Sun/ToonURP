#ifndef TOON_LIGHTING_INCLUDED
#define TOON_LIGHTING_INCLUDED

#include "Packages/com.reubensun.toonurp/ShaderLibrary/ToonSurfaceData.hlsl"
#include "Packages/com.reubensun.toonurp/ShaderLibrary/ToonBRDF.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

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
    BRDFData brdfData, clearCoatbrdfData;
    // InitializeBRDFData(surfaceData, brdfData, clearCoatbrdfData);

    // lighting
    // LightingData lightingData = InitializeLightingData(mainLight, input, inputData.normalWS, inputData.viewDirectionWS, addInputData);

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