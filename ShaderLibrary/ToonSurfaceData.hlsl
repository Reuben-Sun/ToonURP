#ifndef TOON_SURFACE_DATA_INCLUDED
#define TOON_SURFACE_DATA_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceData.hlsl"

struct ToonSurfaceData
{
    float3 albedo;
    float  metallic;
    float  roughness;
    float3 normalTS;     // default is (0, 0, 1)
    float3 emission;
    float  occlusion;    // 1.0 mean no occlusion        
    float  alpha;
    float3 diffuseModify;    // Only work on toon shader
    float3 specularModify;   // Only work on toon shader 
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
