#ifndef TOON_LIGHTING_INCLUDED
#define Toon_LIGHTING_INCLUDED

#include "Packages/com.reubensun.toonurp/ShaderLibrary/ToonSurfaceData.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

half4 UniversalFragmentPBR(InputData inputData, ToonSurfaceData toonSurfaceData)
{
    SurfaceData surfaceData = (SurfaceData)0;
    surfaceData.albedo = toonSurfaceData.albedo;
    surfaceData.alpha = toonSurfaceData.alpha;
    surfaceData.emission = toonSurfaceData.emission;
    surfaceData.smoothness = 1.0f - toonSurfaceData.roughness;
    surfaceData.normalTS = toonSurfaceData.normalTS;
    surfaceData.metallic = toonSurfaceData.metallic;
    surfaceData.occlusion = toonSurfaceData.occlusion;

    return UniversalFragmentPBR(inputData, surfaceData);
}

#endif