#ifndef TOON_LIGHTING_INCLUDED
#define TOON_LIGHTING_INCLUDED

#include "Packages/com.reubensun.toonurp/Shaders/ToonLitInput.hlsl"
#include "Packages/com.reubensun.toonurp/ShaderLibrary/ToonSurfaceData.hlsl"
#include "Packages/com.reubensun.toonurp/ShaderLibrary/ToonBRDF.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.reubensun.toonurp/ShaderLibrary/ToonShaderUtils.hlsl"

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
    float3 halfDir = SafeNormalize(lightData.lightDir + viewDir);
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

inline float3 CellShadingDiffuse(inout float radiance, float cellThreshold, float cellSmooth, float3 highColor, float3 darkColor)
{
    float3 diffuse = 0;
    radiance = saturate(1 + (radiance - cellThreshold - cellSmooth) / max(cellSmooth, 1e-3));
    diffuse = lerp(darkColor.rgb, highColor.rgb, radiance);
    return diffuse;
}

float3 NPRDiffuseLighting(BRDFData brdfData, ToonLightingData lightingData, float radiance)
{
    float3 diffuse = 0;
    #if _CELLSHADING
    diffuse = CellShadingDiffuse(radiance, _CellThreshold, _CellSmoothing, _HighColor.rgb, _DarkColor.rgb);
    // TODO: _SDFFACE
    #endif
    diffuse *= brdfData.diffuse;
    return diffuse;
}

inline float3 StylizedSpecular(float3 albedo, float NoHClamp, float specularSize, float specularSoftness, float albedoWeight)
{
    float specSize = 1 - (specularSize * specularSize);
    float NoHStylized = (NoHClamp - specSize * specSize) / (1 - specSize);
    half3 specular = LinearStep(0, specularSoftness, NoHStylized);
    specular = lerp(specular, albedo * specular, albedoWeight);
    return specular;
}

float3 NPRSpecularLighting(BRDFData brdfData, ToonSurfaceData surfData, InputData inputData, float3 albedo, half radiance, ToonLightingData lightData)
{
    float3 specular = 0;
    #if _CELLSHADING
    specular = StylizedSpecular(albedo, lightData.NoHClamp, _SpecularSize, _SpecularSoftness, _SpecularAlbedoWeight) * _SpecularIntensity;
    #endif
    specular *= _SpecularColor.rgb * radiance * brdfData.specular;
    return specular;
}

float3 ToonMainLightDirectLighting(BRDFData brdfData, InputData inputData, ToonSurfaceData surfData, ToonLightingData lightData)
{
    half radiance = LightingRadiance(lightData, _UseHalfLambert, surfData.occlusion, _UseRadianceOcclusion);

    float3 diffuse = NPRDiffuseLighting(brdfData, lightData, radiance);
    float3 specular = NPRSpecularLighting(brdfData, surfData, inputData, surfData.albedo, radiance, lightData);
    float3 color = (diffuse + specular) * lightData.lightColor;
    return color;
}


float3 ToonIndirectLighting(BRDFData brdfData, InputData inputData, float occlusion)
{
    float3 indirectDiffuse = inputData.bakedGI * occlusion;
    float3 reflectVector = reflect(-inputData.viewDirectionWS, inputData.normalWS);
    float NoV = saturate(dot(inputData.normalWS, inputData.viewDirectionWS));
    float fresnelTerm = Pow4(1.0 - NoV);
    half3 indirectSpecular = GlossyEnvironmentReflection(reflectVector, inputData.positionWS,
        brdfData.perceptualRoughness, occlusion, inputData.normalizedScreenSpaceUV);
    float3 indirectColor = EnvironmentBRDF(brdfData, indirectDiffuse, indirectSpecular, fresnelTerm);
    
    return indirectColor;
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
    color.rgb += ToonIndirectLighting(brdfData, inputData, toonSurfaceData.occlusion);
    // color.rgb += FernRimLighting(lightingData, inputData, input, addInputData); 

    // color.rgb += surfaceData.emission;
    color.rgb = MixFog(color.rgb, inputData.fogCoord);

    // color.a = surfaceData.alpha;
    // return color;
    return color;
}

#endif