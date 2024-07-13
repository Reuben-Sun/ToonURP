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
    	// [SubEnum(RenderSetting, UnityEngine.Rendering.CullMode)] _Cull("Cull Mode", Float) = 2.0
        [Preset(RenderSetting, ToonURP_BlendModePreset)] _BlendMode ("Blend Mode Preset", float) = 0
    	[SubEnum(RenderSetting, UnityEngine.Rendering.BlendMode)] _SrcBlend("Src Alpha", Float) = 1.0
        [SubEnum(RenderSetting, UnityEngine.Rendering.BlendMode)] _DstBlend("Dst Alpha", Float) = 0.0
    	[SubEnum(RenderSetting, Off, 0, On, 1)] _ZWrite("Z Write", Float) = 1.0
    }
    SubShader
    {
        Pass
        {
        	Name "Toon Forward Pass"
            Tags{"LightMode" = "UniversalForward"}
            
            Blend [_SrcBlend] [_DstBlend]
            ZWrite [_ZWrite]
            Cull [_Cull]
            
            HLSLPROGRAM

			#pragma shader_feature_local _ALBEDOMAP
            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local _ROUGHNESSMAP
            #pragma shader_feature_local _METALLICMAP

			#pragma vertex ToonStandardPassVertex
            #pragma fragment ToonShandardPassFragment
			
			#include "Packages/com.reubensun.toonurp/Shaders/ToonLitInput.hlsl"
			#include "Packages/com.reubensun.toonurp/Shaders/ToonStandardForwardPass.hlsl"
			
			ENDHLSL
        }
    }
    CustomEditor "LWGUI.LWGUI"
}