#ifndef TOON_LIGHTING_INCLUDED
#define TOON_LIGHTING_INCLUDED

#include "Packages/com.reubensun.toonurp/Shaders/ToonStandardInput.hlsl"
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
    radiance = saturate(lerp(radiance, (radiance + occlusion) * 0.5, useRadianceOcclusion));
    return radiance;
}

///////////////////////////////////////////////////////////////////////////////
//                      Cell  Lighting                                       //
///////////////////////////////////////////////////////////////////////////////

inline float3 CellShadingDiffuse(inout float radiance, ToonLightingData lightingData, float cellThreshold, float cellSmooth, float3 highColor, float3 darkColor, float3 scatterColor, float scatterWeight)
{
    float3 diffuse = 0;
    radiance = saturate(1 + (radiance - cellThreshold - cellSmooth) / max(cellSmooth, 1e-3));
    diffuse = lerp(darkColor.rgb, highColor.rgb, radiance);
    float scatter = saturate(pow(radiance - 0.5, 2) * scatterWeight);
    diffuse = lerp(diffuse * scatterColor, diffuse, scatter);
    // only high color receive shadow
    float shadow = lerp(1, lightingData.shadowAttenuation, radiance);
    
    return diffuse * shadow;
}



inline float3 StylizedSpecular(float3 albedo, float NoHClamp, float specularSize, float specularSoftness, float albedoWeight)
{
    float specSize = 1 - (specularSize * specularSize);
    float NoHStylized = (NoHClamp - specSize * specSize) / (1 - specSize);
    half3 specular = LinearStep(0, specularSoftness, NoHStylized);
    specular = lerp(specular, albedo * specular, albedoWeight);
    return specular;
}



///////////////////////////////////////////////////////////////////////////////
//                       PBR  Lighting                                       //
///////////////////////////////////////////////////////////////////////////////

float4 UniversalFragmentPBR(InputData inputData, ToonSurfaceData toonSurfaceData)
{
    SurfaceData surfaceData = ConvertToonSurfaceDataToURPSurfaceData(toonSurfaceData);
    return UniversalFragmentPBR(inputData, surfaceData);
}

///////////////////////////////////////////////////////////////////////////////
//                      SDF Face Lighting                                    //
///////////////////////////////////////////////////////////////////////////////

void SDFFaceUV(half reversal, half faceArea, out half2 result)
{
    Light mainLight = GetMainLight();
    half2 lightDir = normalize(mainLight.direction.xz);

    half2 Front = normalize(unity_ObjectToWorld._13_33);
    half2 Right = normalize(unity_ObjectToWorld._11_31);

    float FdotL = dot(Front, lightDir);
    float RdotL = dot(Right, lightDir) * lerp(1, -1, reversal);
    result.x = 1 - max(0,-(acos(FdotL) * INV_PI * 90.0 /(faceArea) -0.5) * 2);
    result.y = 1 - 2 * step(RdotL, 0);
}

half3 SDFFaceDiffuse(half4 uv, ToonLightingData lightData, half SDFShadingSoftness, half3 highColor, half3 darkColor, TEXTURE2D_X_PARAM(_SDFFaceMap, sampler_SDFFaceMap))
{
    half FdotL = uv.z;
    half sign = uv.w;
    half SDFMap = SAMPLE_TEXTURE2D(_SDFFaceMap, sampler_SDFFaceMap, uv.xy * float2(-sign, 1)).r;
    half diffuseRadiance = smoothstep(-SDFShadingSoftness * 0.1, SDFShadingSoftness * 0.1, (abs(FdotL) - SDFMap)) * lightData.shadowAttenuation;
    half3 diffuseColor = lerp(darkColor.rgb, highColor.rgb, diffuseRadiance);
    return diffuseColor;
}

float3 NPRDiffuseSDFLighting(BRDFData brdfData, ToonLightingData lightingData, float radiance, float4 uv)
{
    float3 diffuse = SDFFaceDiffuse(uv, lightingData, _SDFShadingSoftness, _HighColor.rgb, _DarkColor.rgb, TEXTURECUBE_ARGS(_SDFFaceMap, sampler_SDFFaceMap));
    diffuse *= brdfData.diffuse;
    return diffuse;
}


///////////////////////////////////////////////////////////////////////////////
//                      Standard Cel Lighting                                //
///////////////////////////////////////////////////////////////////////////////

float3 NPRDiffuseLighting(BRDFData brdfData, ToonLightingData lightingData, float radiance, float4 uv)
{
    float3 diffuse = 0;
    #if _CELLSHADING
    diffuse = CellShadingDiffuse(radiance, lightingData, _CellThreshold, _CellSmoothing, _HighColor.rgb, _DarkColor.rgb, _ScatterColor.rgb, _ScatterWeight);
    #elif _SDFFACE
    diffuse = SDFFaceDiffuse(uv, lightingData, _SDFShadingSoftness, _HighColor.rgb, _DarkColor.rgb, TEXTURECUBE_ARGS(_SDFFaceMap, sampler_SDFFaceMap));
    #endif
    diffuse *= brdfData.diffuse;
    return diffuse;
}

float3 NPRSpecularLighting(BRDFData brdfData, ToonSurfaceData surfData, InputData inputData, float3 albedo, half radiance, ToonLightingData lightData)
{
    float3 specular = 0;
    specular = StylizedSpecular(albedo, lightData.NoHClamp, _SpecularSize, _SpecularSoftness, _SpecularAlbedoWeight) * _SpecularIntensity;
    specular *= _SpecularColor.rgb * radiance * brdfData.specular;
    return specular;
}


///////////////////////////////////////////////////////////////////////////////
//                      Lighting modes                                       //
///////////////////////////////////////////////////////////////////////////////

// For Standard Cel Lighting
float3 ToonMainLightDirectLighting(BRDFData brdfData, InputData inputData, ToonSurfaceData surfData, ToonLightingData lightData, float4 uv)
{
    half radiance = LightingRadiance(lightData, _UseHalfLambert, surfData.occlusion, _UseRadianceOcclusion);

    float3 diffuse = NPRDiffuseLighting(brdfData, lightData, radiance, uv);
    float3 specular = NPRSpecularLighting(brdfData, surfData, inputData, surfData.albedo, radiance, lightData);
    // float shadow = lerp(0, lightData.shadowAttenuation, lightData.NoLClamp);
    float3 color = (diffuse + specular) * lightData.lightColor;
    return color;
}

float3 NPRAdditionLighting(Light light, BRDFData brdfData, InputData inputData, ToonSurfaceData surfData, float4 uv)
{
    ToonLightingData lightingData = InitializeLightingData(light, inputData.normalWS, inputData.viewDirectionWS);
    float pureIntencity = 0.299 * lightingData.lightColor.r + 0.587 * lightingData.lightColor.g + 0.114 * lightingData.lightColor.b;
    lightingData.lightColor = max(0, lerp(lightingData.lightColor, min(lightingData.lightColor, lightingData.lightColor / pureIntencity * _MaxAdditionLightNum), _LimitAdditionLightNum));
    half3 addLightColor = ToonMainLightDirectLighting(brdfData, inputData, surfData, lightingData, uv);
    return addLightColor;
}

// For SDF face lighting
float3 ToonMainLightSDFDirectLighting(BRDFData brdfData, InputData inputData, ToonSurfaceData surfData, ToonLightingData lightData, float4 uv)
{
    half radiance = LightingRadiance(lightData, _UseHalfLambert, surfData.occlusion, _UseRadianceOcclusion);

    float3 diffuse = NPRDiffuseSDFLighting(brdfData, lightData, radiance, uv);
    float3 specular = NPRSpecularLighting(brdfData, surfData, inputData, surfData.albedo, radiance, lightData);
    float3 color = (diffuse + specular) * lightData.lightColor;
    return color;
}


float3 ToonAdditionLightDirectLighting(BRDFData brdfData, InputData inputData, ToonSurfaceData surfData, half4 shadowMask, half meshRenderingLayers, AmbientOcclusionFactor aoFactor, float4 uv)
{
    half3 additionLightColor = 0;
    float pureIntensityMax = 0;
    #if defined(_ADDITIONAL_LIGHTS)
    uint pixelLightCount = GetAdditionalLightsCount();

    #if USE_FORWARD_PLUS
    for (uint lightIndex = 0; lightIndex < min(URP_FP_DIRECTIONAL_LIGHTS_COUNT, MAX_VISIBLE_LIGHTS); lightIndex++)
    {
        FORWARD_PLUS_SUBTRACTIVE_LIGHT_CHECK

        Light light = GetAdditionalLight(lightIndex, inputData, shadowMask, aoFactor);

    #ifdef _LIGHT_LAYERS
        if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
    #endif
        {
            additionLightColor += NPRAdditionLighting(light, brdfData, inputData, surfData, uv);
        }
    }
    #endif

    #if USE_CLUSTERED_LIGHTING
    for (uint lightIndex = 0; lightIndex < min(_AdditionalLightsDirectionalCount, MAX_VISIBLE_LIGHTS); lightIndex++)
    {
        Light light = GetAdditionalLight(lightIndex, inputData, shadowMask, aoFactor);
    #ifdef _LIGHT_LAYERS
        if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
    #endif
        {
            additionLightColor += NPRAdditionLighting(light, brdfData, inputData, surfData, uv);
        }
    }
    #endif

    LIGHT_LOOP_BEGIN(pixelLightCount)
        Light light = GetAdditionalLight(lightIndex, inputData, shadowMask, aoFactor);
    #ifdef _LIGHT_LAYERS
        if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
    #endif
        {
            additionLightColor += NPRAdditionLighting(light, brdfData, inputData, surfData, uv);
        }
    LIGHT_LOOP_END
    #endif
    

    return additionLightColor;
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

float3 ToonRimLighting(ToonLightingData lightingData, InputData inputData)
{
    float3 rimColor = 0;
    #if _FRESNELRIM
    float NoV4 = Pow4(1 - lightingData.NoVClamp);
    rimColor = LinearStep(_RimThreshold, _RimThreshold + _RimSoftness, NoV4);
    rimColor *= LerpWhiteTo(lightingData.NoLClamp, _RimDirectionLightContribution);
    rimColor *= _RimColor.rgb;
    #endif
    // TODO: _SCREENSPACERIM
    return rimColor;
}


///////////////////////////////////////////////////////////////////////////////
//                      Fragment Func                                        //
///////////////////////////////////////////////////////////////////////////////

float4 ToonFragment(InputData inputData, ToonSurfaceData toonSurfaceData, float4 uv)
{
    // prepare
    half4 shadowMask = CalculateShadowMask(inputData);
    uint meshRenderingLayers = GetMeshRenderingLayer();
    Light mainLight = GetMainLight(inputData.shadowCoord, inputData.positionWS, shadowMask);
    MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI);

    #if defined(_SCREEN_SPACE_OCCLUSION)
    AmbientOcclusionFactor aoFactor = GetScreenSpaceAmbientOcclusion(inputData.normalizedScreenSpaceUV);
    mainLight.color *= aoFactor.directAmbientOcclusion;
    toonSurfaceData.occlusion = min(toonSurfaceData.occlusion, aoFactor.indirectAmbientOcclusion);
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
    color.rgb = ToonMainLightDirectLighting(brdfData, inputData, toonSurfaceData, lightingData, uv);
    color.rgb += ToonAdditionLightDirectLighting(brdfData, inputData, toonSurfaceData, shadowMask, meshRenderingLayers, aoFactor, uv);
    color.rgb += ToonIndirectLighting(brdfData, inputData, toonSurfaceData.occlusion);
    color.rgb += ToonRimLighting(lightingData, inputData); 

    color.rgb += toonSurfaceData.emission;
    color.rgb = MixFog(color.rgb, inputData.fogCoord);

    color.a = toonSurfaceData.alpha;
    return color;
}

#endif