Shader "ToonURP/ToonWater"
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

        // Feature
        [Main(FeatureMode, _, off, off)] _FeatureGroup("Feature", float) = 0
        [Sub(FeatureMode)] _CustomFloat2 ("Depth Max Distance", Float) = 1
        [Sub(FeatureMode)] _CustomFloat3 ("Depth Gradient Shore", Float) = 0.2
        [Sub(FeatureMode)] _CustomFloat4 ("Depth Disappear Shore", Float) = 50
        [Sub(FeatureMode)] _CustomFloat5 ("Fresnel Pow", Range(0.1,20)) = 5
        [Sub(FeatureMode)] _CustomVector1 ("Wave Speed", vector) = (1, 1, 1, 1)
        [Tex(FeatureMode)] _CustomMap2 ("Normal Distort Map", 2D) = "white" {}
        [Sub(FeatureMode)] _CustomFloat6 ("Normal Scale", Float) = 1
        [Sub(FeatureMode)] _CustomFloat7 ("Normal Strength", Float) = 1
        [Tex(FeatureMode)] _CustomCube1 ("Skybox Texture", Cube) = "_Skybox" {}
        [Sub(FeatureMode)] _CustomFloat8 ("Underwater Distortion", Range(0.01,1)) = 0.1


        // Lighting mode
        [Main(ShadingMode, _, off, off)] _ShadingModeGroup("ShadingMode", float) = 0
        [KWEnum(ShadingMode, CelShading, _CELLSHADING, PBRShading, _PBRSHADING, WetPlane, _CUSTOMSHADING)] _EnumShadingMode ("Mode", float) = 2
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
        [Sub(ShadingMode_CUSTOMSHADING)] _CustomFloat1 ("Noise Intensity",Range(-0.2,0.2)) = 0.0
        [Tex(ShadingMode_CUSTOMSHADING)] _CustomMap1("Noise Map", 2D) = "white" {}

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
            Name "Toon Water"
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
            #include "Packages/com.reubensun.toonurp/ShaderLibrary/SSPRInclude.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"

            SAMPLER(sampler_linear_clamp);

            #define _NoiseMap _CustomMap1
            #define _NoiseIntensity _CustomFloat1
            #define _DepthMaxDistance _CustomFloat2
            #define _DepthGradientShore _CustomFloat3
            #define _DepthDisappearShore _CustomFloat4
            #define _fresnelPow _CustomFloat5
            #define _WaveSpeed _CustomVector1
            #define _NormalDistortMap _CustomMap2
            #define _NormalScale _CustomFloat6
            #define _NormalStrength _CustomFloat7
            #define _SkyboxTexture _CustomCube1
            #define _UnderwaterDistortion _CustomFloat8

            float3 bump = 0;

            float SampleSceneDepth(float2 uv, TEXTURE2D_X_FLOAT(_Texture), SAMPLER(sampler_Texture))
            {
                return SAMPLE_TEXTURE2D_X(_Texture, sampler_Texture, UnityStereoTransformScreenSpaceTex(uv)).r;
            }

            float4 cosine_gradient(float x, float4 phase, float4 amp, float4 freq, float4 offset)
            {
                const float TAU = 2. * 3.14159265;
                phase *= TAU;
                x *= TAU;

                return float4(
                    offset.r + amp.r * 0.5 * cos(x * freq.r + phase.r) + 0.5,
                    offset.g + amp.g * 0.5 * cos(x * freq.g + phase.g) + 0.5,
                    offset.b + amp.b * 0.5 * cos(x * freq.b + phase.b) + 0.5,
                    offset.a + amp.a * 0.5 * cos(x * freq.a + phase.a) + 0.5
                );
            }

            float3 toRGB(float4 grad)
            {
                return grad.rgb;
            }
            float4 afterBlend(float4 waterColor, float waterDepth, float shoreDisappearDepth)
            {
                float3 color = waterColor.rgb;
                float alpha = lerp(0, waterColor.a, waterDepth);
                alpha = lerp(alpha, 1, shoreDisappearDepth);
                return float4(color, alpha);
            }
            
            float BRDF_FresnelTerm(float F0, float NdotV)
            {
                //F(l,h) = F0+(1-F0)(1-l·h)^5
                return F0 + (1 - F0) * pow(1 - NdotV, 5);
            }

            void PreProcessMaterial(inout InputData inputData, inout ToonSurfaceData surfaceData, float2 uv)
            {
                // distort normal
                float4 bumpUV = float4(1, 1, 1, 1);
                bumpUV.xy = uv.xy + float2(_SinTime.x * _WaveSpeed.x, _SinTime.x * _WaveSpeed.y);
                bumpUV.zw = uv.xy + float2(_CosTime.y * 1.2 * _WaveSpeed.z, _SinTime.x * 0.5 * _WaveSpeed.w);
                float4 bump10 = (SAMPLE_TEXTURE2D(_NormalDistortMap, sampler_CustomMap2, bumpUV.xy / _NormalScale) * 2 + 
                    SAMPLE_TEXTURE2D(_NormalDistortMap, sampler_CustomMap2, bumpUV.zw / _NormalScale) * 2) - 2;
                float3 offset = normalize(bump10 / 2);
                offset.xy *= _NormalStrength;
                bump = normalize(offset);
                float3 tangentWS_xyz = inputData.tangentToWorld[0];
                float tangentWS_w = inputData.tangentToWorld[1].x / cross(inputData.normalWS.xyz, tangentWS_xyz).x;
                tangentWS_w = abs(tangentWS_w - (-1)) < abs(1 - tangentWS_w) ? -1 : 1; 
                float3 bitangentWS = normalize(cross(inputData.normalWS, tangentWS_xyz) * tangentWS_w);
                float3x3 tangentTransform = float3x3(tangentWS_xyz, bitangentWS, inputData.normalWS);
                float3 bumpWorld = normalize(mul(bump, tangentTransform));
                inputData.normalWS = bumpWorld;
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
                ToonLightingData lightingData = InitializeLightingData(mainLight, inputData.normalWS,
                                                                  inputData.viewDirectionWS);

                float4 lightingColor = 1;
                lightingColor.rgb = ToonMainLightDirectLighting(brdfData, inputData, toonSurfaceData, lightingData, additionInput.uv);
                lightingColor.rgb += ToonRimLighting(lightingData, inputData);

                // ====================================
                // noise
                float4 noiseMap = SAMPLE_TEXTURE2D(_NoiseMap, sampler_CustomMap1, additionInput.uv.xy);
                float2 noise = noiseMap.xy;
                noise = noise * 2 - 1;
                noise.y = -abs(noise); //hide missing data, only allow offset to valid location
                noise.x *= 0.25;
                noise *= _NoiseIntensity;
                // SSPR
                ReflectionInput reflectionData = (ReflectionInput)0;
                reflectionData.posWS = inputData.positionWS;
                reflectionData.screenPos = float4(additionInput.screenPos.xy + bump.xy, 0, additionInput.screenPos.w);
                reflectionData.roughness = brdfData.roughness;
                reflectionData.SSPR_Usage = toonSurfaceData.alpha;
                reflectionData.screenSpaceNoise = noise;
                float3 reflectionColor = GetReflectionColor(reflectionData);
                float4 color = float4(1,1,1,1);
                color.rgb = lerp(lightingColor.rgb, reflectionColor, noiseMap.a);
                // ====================================
                color.rgb += toonSurfaceData.emission;
                color.rgb = MixFog(color.rgb, inputData.fogCoord);

                color.a = toonSurfaceData.alpha;

                //=====================================
                // skybox
                float3 viewDirWorld = normalize(_WorldSpaceCameraPos - inputData.positionWS);
                float3 reflDir = reflect(viewDirWorld, inputData.normalWS);
                reflDir.xyz *= -1;
                float4 skyColor = SAMPLE_TEXTURECUBE(_SkyboxTexture, sampler_CustomCube1, normalize(reflDir));
                color *= skyColor;

                //=====================================
                // color variation
                const float4 phases = float4(0.28, 0.50, 0.07, 0.);
                const float4 amplitudes = float4(4.02, 0.34, 0.65, 0.);
                const float4 frequencies = float4(0.00, 0.48, 0.08, 0.);
                const float4 offsets = float4(0.00, 0.16, 0.00, 0.);

                // calculate the color through depth of shadowmap
                float2 ScreenUV = additionInput.screenPos.xy / additionInput.screenPos.w;
                float shadowMapDepth = SampleSceneDepth(ScreenUV, _CameraDepthTexture, sampler_linear_clamp);
                float existingDepthLinear = LinearEyeDepth(shadowMapDepth, _ZBufferParams);
                float depthDifference = existingDepthLinear - additionInput.screenPos.w;
                float waterDepthDifference = saturate(depthDifference / _DepthMaxDistance);
                // calculate water color
                float4 cos_grad = cosine_gradient(1 - waterDepthDifference, phases, amplitudes, frequencies, offsets);
                cos_grad = saturate(cos_grad);
                float4 waterColor = float4(toRGB(cos_grad), 0.7);

                float shoreDepth = saturate(depthDifference / _DepthGradientShore);
                float shoreDisappearDepth = saturate(depthDifference / _DepthDisappearShore);
                waterColor = afterBlend(waterColor, shoreDepth, shoreDisappearDepth);
                color = afterBlend(color, shoreDepth, shoreDisappearDepth);

                // underwater distortion
                float4 blendStrength = float4(1, 1, 1, 1);
                blendStrength = afterBlend(blendStrength, shoreDepth, shoreDisappearDepth);
                float2 distortScreenUV = ScreenUV + -bump.xy * _UnderwaterDistortion * blendStrength.a;
                float4 sceneColor = _CameraOpaqueTexture.SampleLevel(sampler_linear_clamp, distortScreenUV, 0);
                
                // fresnel term
                float fTerm = saturate(BRDF_FresnelTerm(0.02 /*F0*/ , lightingData.NoVClamp) * _fresnelPow);
                color = lerp(waterColor, color, fTerm);
                color *= sceneColor;
                //======================================
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