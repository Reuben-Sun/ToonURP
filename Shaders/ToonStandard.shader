Shader "ToonURP/ToonStandard"
{
    Properties
    {
        _BaseColor("BaseColor", Color) = (1, 1, 1, 1)
    	// PBR
    	[Main(Surface, _, off, off)] _group("PBR", float) = 0
    	
    	[SubToggle(Surface, _ALBEDOMAP)] _EnableAlbedoMap("Enable Albedo Map", Float) = 0.0
        [Tex(Surface_ALBEDOMAP)] [ShowIf(_EnableAlbedoMap, Equal, 1)] 
    	_MainTex ("Albedo", 2D) = "white" {}
        
    	[Sub(Surface)]_Roughness("Roughness", Range(0,1.0)) = 1.0
    	[SubToggle(Surface, _ROUGHNESSMAP)] _EnableRoughnessMap("Enable Roughness Map", Float) = 0.0
        [Tex(Surface_ROUGHNESSMAP)] [ShowIf(_EnableRoughnessMap, Equal, 1)] 
    	_RoughnessMap("RoughnessMap", 2D) = "white" {}
    	
    	[Sub(Surface)]_Metallic("Metallic", Range(0,1.0)) = 1.0
    	[SubToggle(Surface, _METALLICMAP)] _EnableMetallicMap("Enable Metallic Map", Float) = 0.0
        [Tex(Surface_METALLICMAP)] [ShowIf(_EnableMetallicMap, Equal, 1)] 
    	_MetallicMap("MetallicMap", 2D) = "white" {}
    	
        [SubToggle(Surface, _NORMALMAP)] _EnableNormalMap("Enable Normal Map", Float) = 0.0
    	[Tex(Surface_NORMALMAP)] [ShowIf(_EnableNormalMap, Equal, 1)] 
    	_NormalMap("NormalMap", 2D) = "white" {}
    	
    	// RenderSetting
    	[Main(RenderSetting, _, off, off)] _settingGroup("RenderSetting", float) = 0
        [Preset(RenderSetting, LWGUI_BlendModePreset)] _BlendMode ("Blend Mode Preset", float) = 0
    	[SubEnum(RenderSetting, UnityEngine.Rendering.BlendMode)] _SrcBlend("Src Alpha", Float) = 1.0
        [SubEnum(RenderSetting, UnityEngine.Rendering.BlendMode)] _DstBlend("Dst Alpha", Float) = 0.0
    	[SubEnum(RenderSetting, Off, 0, On, 1)] _ZWrite("Z Write", Float) = 1.0
    	[SubEnum(RenderSetting, UnityEngine.Rendering.CullMode)] _Cull("Cull Mode", Float) = 2.0
    }
    SubShader
    {
        Pass
        {
        	Name "Toon Forward"
            Tags{"LightMode" = "UniversalForward"}
            
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

			// -------------------------------------
            // Unity defined keywords
			#pragma multi_compile_fog
			
			#include "Packages/com.reubensun.toonurp/Shaders/ToonLitInput.hlsl"
			#include "Packages/com.reubensun.toonurp/Shaders/ToonStandardForwardPass.hlsl"
			
			ENDHLSL
        }

		Pass
        {
            Name "ShadowCaster"
            Tags{ "LightMode" = "ShadowCaster"}
            
            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull[_Cull]

            HLSLPROGRAM
            #pragma target 2.0

            // -------------------------------------
            // Shader Stages
            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE

            // This is used during shadow map generation to differentiate between directional and punctual light shadows, as they use different formulas to apply Normal Bias
            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW

            // -------------------------------------
            // Includes
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
            ENDHLSL
        }
    }
    CustomEditor "LWGUI.LWGUI"
}