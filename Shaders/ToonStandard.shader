Shader "ToonURP/ToonStandard"
{
    Properties
    {
        _BaseColor("BaseColor", Color) = (1, 1, 1, 1)
    	
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
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline"
        }

        Pass
        {
            Tags{"LightMode" = "UniversalForward"}
            
        }
    }
    CustomEditor "LWGUI.LWGUI"
}