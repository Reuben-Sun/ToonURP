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
// end Surface

// Lighting mode
float _UseHalfLambert;
float _UseRadianceOcclusion;
// end Lighting mode

// _CELLSHADING
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
// end _CELLSHADING

// _SDFFACE
float _SDFDirectionReversal;
float _SDFFaceArea;
float _SDFShadingSoftness;
// end _SDFFACE

// Rim Setting
float _RimDirectionLightContribution;
float _RimThreshold;
float _RimSoftness;
float4 _RimColor;
// end Rim Setting

// MultLight Setting
float _LimitAdditionLightNum;
float _MaxAdditionLightNum;
// end MultLight Setting


// Feature Custom Value
float _CustomFloat1;
float _CustomFloat2;
float _CustomFloat3;
float _CustomFloat4;
float _CustomFloat5;
float _CustomFloat6;
float _CustomFloat7;
float _CustomFloat8;

float4 _CustomVector1;
float4 _CustomVector2;
float4 _CustomVector3;
float4 _CustomVector4;
// end Feature Custom Value

CBUFFER_END

TEXTURE2D(_MainTex);        SAMPLER(sampler_MainTex);
TEXTURE2D(_RoughnessMap);        SAMPLER(sampler_RoughnessMap);
TEXTURE2D(_MetallicMap);        SAMPLER(sampler_MetallicMap);
TEXTURE2D(_NormalMap);        SAMPLER(sampler_NormalMap);
TEXTURE2D(_OcclusionMap);        SAMPLER(sampler_OcclusionMap);
TEXTURE2D(_SDFFaceMap);      SAMPLER(sampler_SDFFaceMap);

TEXTURE2D(_CustomMap1);        SAMPLER(sampler_CustomMap1);
TEXTURE2D(_CustomMap2);        SAMPLER(sampler_CustomMap2);
TEXTURE2D(_CustomMap3);        SAMPLER(sampler_CustomMap3);
TEXTURE2D(_CustomMap4);        SAMPLER(sampler_CustomMap4);

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