#ifndef TOON_LIT_INPUT_INCLUDE
#define TOON_LIT_INPUT_INCLUDE

#include "Packages/com.reubensun.toonurp/ShaderLibrary/ToonSurfaceData.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/ParallaxMapping.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"

CBUFFER_START(UnityPerMaterial)
float4 _MainTex_ST;
half4 _BaseColor;
float _Roughness;
float _Metallic;
CBUFFER_END

TEXTURE2D(_MainTex);        SAMPLER(sampler_MainTex);
TEXTURE2D(_RoughnessMap);        SAMPLER(sampler_RoughnessMap);
TEXTURE2D(_MetallicMap);        SAMPLER(sampler_MetallicMap);
TEXTURE2D(_NormalMap);        SAMPLER(sampler_NormalMap);

inline void InitializeToonStandardLitSurfaceData(float2 uv, out ToonSurfaceData outSurfaceData)
{
    outSurfaceData.alpha = _BaseColor.a;
    outSurfaceData.albedo = _BaseColor.xyz;
    #if _ALBEDOMAP
    outSurfaceData.albedo *= SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv);;
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
    outSurfaceData.emission = half3(0.0h, 0.0h, 0.0h);
}



#endif