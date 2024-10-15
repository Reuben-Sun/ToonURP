using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace ToonURP
{
    public class CombineSampleRenderPass: ScriptableRenderPass
    {
        private Material m_Material;
        private ProfilingSampler m_ProfilingSampler = new ProfilingSampler("CombineSampleRenderPass");
        private RTHandle m_CameraColorTarget;
        
        public CombineSampleRenderPass(Material material)
        {
            m_Material = material;
            ConfigureInput(ScriptableRenderPassInput.Color);
        }

        public void SetupProperties(RTHandle cameraColorTarget)
        {
            m_CameraColorTarget = cameraColorTarget;
        }
        
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            var cmd = CommandBufferPool.Get("CombineSample");
            using (new ProfilingScope(cmd, m_ProfilingSampler))
            {
                Blitter.BlitCameraTexture(cmd, m_CameraColorTarget, m_CameraColorTarget, m_Material, 0);
            }
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }
    }
}