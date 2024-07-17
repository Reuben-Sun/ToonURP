#ifndef TOON_LIGHTING_INCLUDED
#define TOON_LIGHTING_INCLUDED

#include "Packages/com.reubensun.toonurp/Shaders/ToonLitInput.hlsl"
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
    float halfLambert;
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
    lightData.halfLambert = 0.5 * (lightData.NoL + 1);
    lightData.NoVClamp = saturate(dot(normalWS, viewDir));
    half3 halfDir = SafeNormalize(lightData.lightDir + viewDir);
    lightData.halfDir = halfDir;
    lightData.NoHClamp = saturate(dot(normalWS, halfDir));
    lightData.LoHClamp = saturate(dot(lightData.lightDir, halfDir));
    lightData.shadowAttenuation = mainLight.shadowAttenuation * mainLight.distanceAttenuation;
    return lightData;
}

half LightingRadiance(ToonLightingData lightingData, half useHalfLambert, half occlusion, half useRadianceOcclusion)
{
    half radiance = lerp(lightingData.NoLClamp, lightingData.halfLambert, useHalfLambert);
    radiance = saturate(lerp(radiance, (radiance + occlusion) * 0.5, useRadianceOcclusion)) * lightingData.shadowAttenuation;
    return radiance;
}

///////////////////////////////////////////////////////////////////////////////
//                      Lighting                                             //
///////////////////////////////////////////////////////////////////////////////

inline half3 CellShadingDiffuse(inout half radiance, half cellThreshold, half cellSmooth, half3 highColor, half3 darkColor)
{
    half3 diffuse = 0;
    radiance = saturate(1 + (radiance - cellThreshold - cellSmooth) / max(cellSmooth, 1e-3));
    diffuse = lerp(darkColor.rgb, highColor.rgb, radiance);
    return diffuse;
}

float3 NPRDiffuseLighting(BRDFData brdfData, ToonLightingData lightingData, half radiance)
{
    float3 diffuse = 0;
    #if _CELLSHADING
    diffuse = CellShadingDiffuse(radiance, _CellThreshold, _CellSmoothing, _HighColor.rgb, _DarkColor.rgb);
    // TODO: _SDFFACE
    #endif
    diffuse *= brdfData.diffuse;
    return diffuse;
}

float3 ToonMainLightDirectLighting(BRDFData brdfData, InputData inputData, ToonSurfaceData surfData, ToonLightingData lightData)
{
    half radiance = LightingRadiance(lightData, _UseHalfLambert, surfData.occlusion, _UseRadianceOcclusion);

    half3 diffuse = NPRDiffuseLighting(brdfData, lightData, radiance);
    // half3 specular = NPRSpecularLighting(brdfData, surfData, input, inputData, surfData.albedo, radiance, lightData);
    // half3 color = (diffuse + specular) * lightData.lightColor;
    float3 color = diffuse;
    return color;
}

///////////////////////////////////////////////////////////////////////////////
//                      Fragment Func                                        //
///////////////////////////////////////////////////////////////////////////////

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
    
    float4 color = 1;
    color.rgb = ToonMainLightDirectLighting(brdfData, inputData, toonSurfaceData, lightingData);
    // color.rgb += FernAdditionLightDirectLighting(brdfData, clearCoatbrdfData, input, inputData, surfaceData, addInputData, shadowMask, meshRenderingLayers, aoFactor);
    // color.rgb += FernIndirectLighting(brdfData, inputData, input, surfaceData.occlusion);
    // color.rgb += FernRimLighting(lightingData, inputData, input, addInputData); 

    // color.rgb += surfaceData.emission;
    color.rgb = MixFog(color.rgb, inputData.fogCoord);

    // color.a = surfaceData.alpha;
    // return color;
    return color;
}

#endif