#ifndef TOON_UNLIT_INPUT_INCLUDE
#define TOON_UNLIT_INPUT_INCLUDE

#include "Packages/com.reubensun.toonurp/ShaderLibrary/ToonSurfaceData.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/ParallaxMapping.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"


CBUFFER_START(UnityPerMaterial)

// Surface
float4 _MainTex_ST;
float4 _BaseColor;

CBUFFER_END


TEXTURE2D(_MainTex);        SAMPLER(sampler_MainTex);

inline void InitializeToonMapSurfaceData(float2 uv, out ToonSurfaceData outSurfaceData)
{
    outSurfaceData = (ToonSurfaceData)0;
    outSurfaceData.alpha = _BaseColor.a;
    outSurfaceData.albedo = _BaseColor.xyz;
    #if _ALBEDOMAP
    outSurfaceData.albedo *= SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv).rgb;
    #endif
}



#endif