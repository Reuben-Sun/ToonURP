Shader "ToonURP/ToonUnlit"
{
    Properties
    {
        _BaseColor("BaseColor", Color) = (1, 1, 1, 1)
        // Surface
        [Main(Surface, _, off, off)] _SurfaceGroup("Surface", Float) = 0
        [SubToggle(Surface, _ALBEDOMAP)] _EnableAlbedoMap("Enable Albedo Map", Float) = 0.0
        [Tex(Surface_ALBEDOMAP)] [ShowIf(_EnableAlbedoMap, Equal, 1)] _MainTex ("Albedo", 2D) = "white" {}

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
            Name "Toon Unlit"
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            Blend [_SrcBlend] [_DstBlend]
            ZWrite [_ZWrite]
            Cull [_Cull]

            HLSLPROGRAM
            #pragma vertex ToonUnlitPassVertex
            #pragma fragment ToonUnlitPassFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _ALBEDOMAP

            // -------------------------------------
            // Universal Pipeline keywords

            // -------------------------------------
            // Global Material keywords

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

            #include "Packages/com.reubensun.toonurp/Shaders/ToonUnlitInput.hlsl"

            void PreProcessMaterial(inout InputData inputData, inout ToonSurfaceData surfaceData, float2 uv)
            {
            }

            #include "Packages/com.reubensun.toonurp/Shaders/ToonUnlitPass.hlsl"
            ENDHLSL
        }
    }
    CustomEditor "LWGUI.LWGUI"
}