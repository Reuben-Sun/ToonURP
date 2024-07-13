#ifndef TOON_LIT_INPUT_INCLUDE
#define TOON_LIT_INPUT_INCLUDE

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

#endif