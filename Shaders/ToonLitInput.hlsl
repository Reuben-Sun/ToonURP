#ifndef TOON_LIT_INPUT_INCLUDE
#define TOON_LIT_INPUT_INCLUDE

#include "Packages/com.reubensun.toonurp/ShaderLibrary/ToonSurfaceData.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/ParallaxMapping.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"

CBUFFER_START(UnityPerMaterial)
// Surface
float4 _MainTex_ST;
float4 _BaseColor;
float4 _SpecularColor;
float4 _EmissionColor;
float _Roughness;
float _Metallic;
// Lighting mode
float _UseHalfLambert;
float _UseRadianceOcclusion;

// remove #if for srp batcher
// #if _CELLSHADING
float4 _HighColor;
float4 _DarkColor;
float _CellThreshold;
float _CellSmoothing;
float _SpecularIntensity;
float _SpecularSize;
float _SpecularSoftness;
float _SpecularAlbedoWeight;
float4 _ScatterColor;
float _ScatterWeight;
// #endif

// Rim Setting
float _RimDirectionLightContribution;
float _RimThreshold;
float _RimSoftness;
// float padding2;
float4 _RimColor;

// MultLight Setting
float _LimitAdditionLightNum;
float _MaxAdditionLightNum;

CBUFFER_END

TEXTURE2D(_MainTex);        SAMPLER(sampler_MainTex);
TEXTURE2D(_RoughnessMap);        SAMPLER(sampler_RoughnessMap);
TEXTURE2D(_MetallicMap);        SAMPLER(sampler_MetallicMap);
TEXTURE2D(_NormalMap);        SAMPLER(sampler_NormalMap);
TEXTURE2D(_OcclusionMap);        SAMPLER(sampler_OcclusionMap);

inline void InitializeToonStandardLitSurfaceData(float2 uv, out ToonSurfaceData outSurfaceData)
{
    outSurfaceData.alpha = _BaseColor.a;
    outSurfaceData.albedo = _BaseColor.xyz;
    #if _ALBEDOMAP
    outSurfaceData.albedo *= SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv).rgb;
    #endif
    
    outSurfaceData.metallic = _Metallic;
    #if _METALLICMAP
    outSurfaceData.metallic *= SAMPLE_TEXTURE2D(_MetallicMap, sampler_MetallicMap, uv).r;
    #endif

    outSurfaceData.roughness = _Roughness;
    #if _ROUGHNESSMAP
    outSurfaceData.roughness *= SAMPLE_TEXTURE2D(_RoughnessMap, sampler_RoughnessMap, uv).r;
    #endif

    outSurfaceData.normalTS = half3(0.0h, 0.0h, 1.0h);
    #if _NORMALMAP
    outSurfaceData.normalTS = SampleNormal(uv, TEXTURE2D_ARGS(_NormalMap, sampler_NormalMap));
    #endif
    
    outSurfaceData.occlusion = 1.0;
    #if _OCCLUSIONMAP
    outSurfaceData.occlusion = SAMPLE_TEXTURE2D(_OcclusionMap, sampler_OcclusionMap, uv).r;
    #endif
    
    outSurfaceData.emission = half3(0.0h, 0.0h, 0.0h);
    #if _EMISSION
    outSurfaceData.emission = _EmissionColor.rgb;
    #endif
}



#endif