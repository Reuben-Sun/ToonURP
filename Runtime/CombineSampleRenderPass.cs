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
        private float m_Intensity = 1.0f;
        
        public CombineSampleRenderPass(Material material)
        {
            m_Material = material;
            ConfigureInput(ScriptableRenderPassInput.Color);
        }

        public void SetupProperties(RTHandle cameraColorTarget, float intensity)
        {
            m_CameraColorTarget = cameraColorTarget;
            m_Intensity = intensity;
        }
        
        
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            var cmd = CommandBufferPool.Get("CombineSample");
            using (new ProfilingScope(cmd, m_ProfilingSampler))
            {
                cmd.SetGlobalFloat("_Intensity", m_Intensity);
                Blitter.BlitCameraTexture(cmd, m_CameraColorTarget, m_CameraColorTarget, m_Material, 0);
            }
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }
    }
}