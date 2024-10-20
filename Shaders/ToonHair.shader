Shader "ToonURP/ToonHair"
{
    Properties
    {
        _BaseColor("BaseColor", Color) = (1, 1, 1, 1)
        // Surface
        [Main(Surface, _, off, off)] _SurfaceGroup("Surface", Float) = 0

        [SubToggle(Surface, _ALBEDOMAP)] _EnableAlbedoMap("Enable Albedo Map", Float) = 0.0
        [Tex(Surface_ALBEDOMAP)] [ShowIf(_EnableAlbedoMap, Equal, 1)] _MainTex ("Albedo", 2D) = "white" {}

        [Sub(Surface)]_Roughness("Roughness", Range(0,1.0)) = 1.0
        [SubToggle(Surface, _ROUGHNESSMAP)] _EnableRoughnessMap("Enable Roughness Map", Float) = 0.0
        [Tex(Surface_ROUGHNESSMAP)] [ShowIf(_EnableRoughnessMap, Equal, 1)] _RoughnessMap("RoughnessMap", 2D) = "white" {}

        [Sub(Surface)]_Metallic("Metallic", Range(0,1.0)) = 1.0
        [SubToggle(Surface, _METALLICMAP)] _EnableMetallicMap("Enable Metallic Map", Float) = 0.0
        [Tex(Surface_METALLICMAP)] [ShowIf(_EnableMetallicMap, Equal, 1)] _MetallicMap("MetallicMap", 2D) = "white" {}

        [SubToggle(Surface, _NORMALMAP)] _EnableNormalMap("Enable Normal Map", Float) = 0.0
        [Tex(Surface_NORMALMAP)] [ShowIf(_EnableNormalMap, Equal, 1)] _NormalMap("NormalMap", 2D) = "white" {}

        [SubToggle(Surface, _OCCLUSIONMAP)] _EnableOcclusionMap("Enable Occlusion", Float) = 0.0
        [Tex(Surface_OCCLUSIONMAP)] [ShowIf(_EnableOcclusionMap, Equal, 1)] _OcclusionMap("OcclusionMap", 2D) = "white" {}

        [SubToggle(Surface, _EMISSION)] _EnableEmission("Enable Emission", Float) = 0.0
        [Sub(Surface)] [ShowIf(_EnableEmission, Equal, 1)] [HDR]_EmissionColor("Emission Color", Color) = (0,0,0,1)

        // Lighting mode
        [Main(ShadingMode, _, off, off)] _ShadingModeGroup("ShadingMode", float) = 0
        [KWEnum(ShadingMode, CelShading, _CELLSHADING, PBRShading, _PBRSHADING, CelHair, _CUSTOMSHADING)] _EnumShadingMode ("Mode", float) = 2
        [SubToggle(ShadingMode)] _UseHalfLambert ("Use HalfLambert (More Flatter)", float) = 0
        [SubToggle(ShadingMode)] _UseRadianceOcclusion ("Radiance Occlusion", float) = 0
        [Sub(ShadingMode)] _SpecularColor ("Specular Color", Color) = (1,1,1,1)
        [Sub(ShadingMode)] [HDR] _HighColor ("Hight Color", Color) = (1,1,1,1)
        [Sub(ShadingMode)] _DarkColor ("Dark Color", Color) = (0,0,0,1)
        [Sub(ShadingMode)] [ShowIf(_EnumShadingMode, Equal, 0)] _CellThreshold ("Cell Threshold", Range(0.01,1)) = 0.5
        [Sub(ShadingMode)] [ShowIf(_EnumShadingMode, Equal, 0)] _CellSmoothing ("Cell Smoothing", Range(0.001,1)) = 0.001
        [Sub(ShadingMode)] [ShowIf(_EnumShadingMode, Equal, 0)] _SpecularIntensity ("Specular Intensity", Range(0,8)) = 1
        [Sub(ShadingMode)] [ShowIf(_EnumShadingMode, Equal, 0)] _SpecularSize ("Specular Size", Range(0,1)) = 0.1
        [Sub(ShadingMode)] [ShowIf(_EnumShadingMode, Equal, 0)] _SpecularSoftness ("Specular Softness", Range(0.001,1)) = 0.05
        [Sub(ShadingMode)] [ShowIf(_EnumShadingMode, Equal, 0)] _SpecularAlbedoWeight ("Color Albedo Weight", Range(0,1)) = 0
        [Sub(ShadingMode)] [ShowIf(_EnumShadingMode, Equal, 0)] _ScatterColor ("Scatter Color", Color) = (1,1,1,1)
        [Sub(ShadingMode)] [ShowIf(_EnumShadingMode, Equal, 0)] _ScatterWeight ("Scatter Weight", Range(4,20)) = 10
        [SubToggle(ShadingMode_CUSTOMSHADING)] _SDFDirectionReversal ("Direction Reversal",Float) = 0
        [Tex(ShadingMode_CUSTOMSHADING)] _SDFFaceMap("SDF Face Map", 2D) = "white" {}
        [Sub(ShadingMode_CUSTOMSHADING)] _SDFFaceArea ("Face Angle Range (0~360)",Range(0,360)) = 0
        [Sub(ShadingMode_CUSTOMSHADING)] _SDFShadingSoftness ("SDF Shading Softness",Range(0,1)) = 0.3

        // Rim
        [Main(Rim, _, off, off)] _RimGroup("RimSettings", float) = 0
        [KWEnum(Rim, None, _, FresnelRim, _FRESNELRIM)] _EnumRim ("Rim Mode", float) = 0
        [Sub(Rim)] [ShowIf(_EnumRim, NEqual, 0)] _RimDirectionLightContribution("DirLight Contribution", Range(0,1)) = 1.0
        [Sub(Rim)] [ShowIf(_EnumRim, NEqual, 0)] [HDR] _RimColor("Rim Color",Color) = (1,1,1,1)
        [Sub(Rim)] [ShowIf(_EnumRim, Equal, 1)] _RimThreshold("Rim Threshold",Range(0,1)) = 0.2
        [Sub(Rim)] [ShowIf(_EnumRim, Equal, 1)] _RimSoftness("Rim Softness",Range(0.001,1)) = 0.01

        // MultLightSetting
        [Main(MultLightSetting, _, off, off)] _MultipleLightGroup ("MultLightSetting", float) = 0
        [SubToggle(MultLightSetting)] _LimitAdditionLightNum("Limit Addition Light Number", Float) = 0
        [Sub(MultLightSetting)] [ShowIf(_LimitAdditionLightNum, Equal, 1)] _MaxAdditionLightNum("Max Additional Light Number", Range(0, 8)) = 1

        // Shadow
        [Main(ShadowSetting, _, off, off)] _ShadowSettingGroup ("ShadowSetting", float) = 1
        [SubToggle(ShadowSetting, _RECEIVE_SHADOWS_OFF)] _RECEIVE_SHADOWS_OFF("Receive Shadow Off", Float) = 0

        // RenderSetting
        [Main(RenderSetting, _, off, off)] _RenderSettingGroup("RenderSetting", float) = 0
        [Preset(RenderSetting, Toon_BlendModePreset)] _BlendMode ("Blend Mode Preset", float) = 0
        [SubEnum(RenderSetting, UnityEngine.Rendering.BlendMode)] _SrcBlend("Src Alpha", Float) = 1.0
        [SubEnum(RenderSetting, UnityEngine.Rendering.BlendMode)] _DstBlend("Dst Alpha", Float) = 0.0
        [SubEnum(RenderSetting, Off, 0, On, 1)] _ZWrite("Z Write", Float) = 1.0
        [SubEnum(RenderSetting, UnityEngine.Rendering.CullMode)] _Cull("Cull Mode", Float) = 2.0
    }
    SubShader
    {
        Pass
        {
            Name "Toon Hair"
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            Blend [_SrcBlend] [_DstBlend]
            ZWrite [_ZWrite]
            Cull [_Cull]

            HLSLPROGRAM
            #pragma vertex ToonStandardPassVertex
            #pragma fragment ToonShandardPassFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _ALBEDOMAP
            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local _ROUGHNESSMAP
            #pragma shader_feature_local _METALLICMAP
            #pragma shader_feature_local _OCCLUSIONMAP
            #pragma shader_feature_local _EMISSION

            #pragma shader_feature_local _CELLSHADING _PBRSHADING _CUSTOMSHADING
            #pragma shader_feature_local _ _FRESNELRIM
            #pragma shader_feature_local _RECEIVE_SHADOWS_OFF
            #pragma shader_feature_local_fragment _SURFACE_TYPE_TRANSPARENT

            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _LIGHT_LAYERS
            #pragma multi_compile_fragment _ _LIGHT_COOKIES
            #pragma multi_compile _ _FORWARD_PLUS
            #pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile_fragment _ _SHADOWS_SOFT _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile_fog
            #pragma multi_compile _ LIGHTMAP_ON

            // -------------------------------------
            // Universal Pipeline keywords
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            #include "Packages/com.reubensun.toonurp/Shaders/ToonStandardInput.hlsl"

            void PreProcessMaterial(inout InputData inputData, inout ToonSurfaceData surfaceData, float2 uv)
            {
            }

            float4 CustomFragment(InputData inputData, ToonSurfaceData toonSurfaceData, AdditionInputData additionInput)
            {
                // prepare main light
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
                half radiance = LightingRadiance(lightingData, _UseHalfLambert, toonSurfaceData.occlusion, _UseRadianceOcclusion);
                float3 diffuse = NPRDiffuseLighting(brdfData, lightingData, radiance, additionInput.uv);
                float3 specular = NPRSpecularLighting(brdfData, toonSurfaceData, inputData, toonSurfaceData.albedo, radiance, lightingData);
                color.rgb = (diffuse + specular) * lightingData.lightColor;

                color.rgb += ToonRimLighting(lightingData, inputData);
                color.rgb += ToonIndirectLighting(brdfData, inputData, toonSurfaceData.occlusion);
                color.rgb += ToonRimLighting(lightingData, inputData); 

                color.rgb += toonSurfaceData.emission;
                color.rgb = MixFog(color.rgb, inputData.fogCoord);

                color.a = toonSurfaceData.alpha;
                return color;
            }

            #include "Packages/com.reubensun.toonurp/Shaders/ToonStandardForwardPass.hlsl"
            ENDHLSL
        }

        UsePass "Hidden/ToonURP/ToonShadowCaster/ShadowCaster"

        UsePass "Hidden/ToonURP/ToonDepthNormal/DepthNormals"
    }
    CustomEditor "LWGUI.LWGUI"
}