#ifndef TOON_SURFACE_DATA_INCLUDED
#define TOON_SURFACE_DATA_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceData.hlsl"

struct ToonSurfaceData
{
    half3 albedo;
    half  metallic;
    half  roughness;
    half3 normalTS;     // default is (0, 0, 1)
    half3 emission;
    half  occlusion;    // 1.0 mean no occlusion        
    half  alpha;
};

SurfaceData ConvertToonSurfaceDataToURPSurfaceData(ToonSurfaceData toonSurfaceData)
{
    SurfaceData surfaceData = (SurfaceData)0;
    surfaceData.albedo = toonSurfaceData.albedo;
    surfaceData.alpha = toonSurfaceData.alpha;
    surfaceData.emission = toonSurfaceData.emission;
    surfaceData.smoothness = 1.0f - toonSurfaceData.roughness;
    surfaceData.normalTS = toonSurfaceData.normalTS;
    surfaceData.metallic = toonSurfaceData.metallic;
    surfaceData.occlusion = toonSurfaceData.occlusion;
    return  surfaceData;
}

#endif
