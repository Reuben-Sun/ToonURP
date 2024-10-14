using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace ToonURP
{
    [DisallowMultipleRendererFeature("Screen Space Planar Reflections")]
    public class SSPRRenderFeature: ScriptableRendererFeature
    {
        [SerializeField] private ComputeShader cs = null;
        SSPRRenderPass m_SSPRRenderPass;
        public override void Create()
        {
            cs = AssetDatabase.LoadAssetAtPath<ComputeShader>(
                "Packages/com.reubensun.toonurp/Shaders/PostProcessing/SSPR.compute");
            if(ReferenceEquals(cs, null))
            {
                Debug.LogError("Can't find SSPR.compute");
                return;
            }

            m_SSPRRenderPass = new SSPRRenderPass(cs)
            {
                renderPassEvent = RenderPassEvent.AfterRenderingOpaques
            };
        }
        
        public override void SetupRenderPasses(ScriptableRenderer renderer, in RenderingData renderingData)
        {
            var stack = VolumeManager.instance.stack;
            SSPR sspr = stack.GetComponent<SSPR>();
            if (sspr == null || !sspr.IsActive())
            {
                return;
            }
        }

        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            var stack = VolumeManager.instance.stack;
            SSPR sspr = stack.GetComponent<SSPR>();
            if (sspr == null || !sspr.IsActive())
            {
                return;
            }
            renderer.EnqueuePass(m_SSPRRenderPass);
        }
    }
}