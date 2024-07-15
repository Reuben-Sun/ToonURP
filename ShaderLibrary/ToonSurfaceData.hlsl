#ifndef TOON_SURFACE_DATA_INCLUDED
#define TOON_SURFACE_DATA_INCLUDED

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

#endif
