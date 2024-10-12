using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering.Universal;

namespace ToonURP
{
    [DisallowMultipleRendererFeature("Screen Space Planar Reflections")]
    public class SSPRRenderFeature: ScriptableRendererFeature
    {
        [SerializeField] private ComputeShader cs = null;
        public override void Create()
        {
            cs = AssetDatabase.LoadAssetAtPath<ComputeShader>(
                "Packages/com.reubensun.toonurp/Shaders/PostProcessing/SSPR.compute");
            if(ReferenceEquals(cs, null))
            {
                Debug.LogError("Can't find SSPR.compute");
                return;
            }
        }

        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            
        }
    }
}