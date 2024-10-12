using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace ToonURP
{
    /// <summary>
    /// 将_EdgeDetectionTexture和屏幕颜色进行混合
    /// </summary>
    class EdgeOutlineRenderPass : ScriptableRenderPass
    {
        private Material m_Material = null;
        private ProfilingSampler m_ProfilingSampler = new ProfilingSampler("EdgeOutlineRenderPass");
        private RTHandle m_CameraColorTarget;
        private Vector4 m_Threshold = Vector4.zero;
        private Color m_Color = Color.black;

        static class OutlineShaderIDs
        {
            internal static readonly int Threshold = Shader.PropertyToID("_EdgeThreshold");
            internal static readonly int Color = Shader.PropertyToID("_EdgeColor");
        }

        public EdgeOutlineRenderPass(Material material)
        {
            m_Material = material;
            ConfigureInput(ScriptableRenderPassInput.Color);
        }

        public void SetupProperties(Vector4 threshold, Color color, RTHandle cameraColorTarget)
        {
            m_Threshold = threshold;
            m_Color = color;
            m_CameraColorTarget = cameraColorTarget;
        }

        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            var cmd = CommandBufferPool.Get("EdgeOutline");
            using (new ProfilingScope(cmd, m_ProfilingSampler))
            {
                cmd.SetGlobalVector(OutlineShaderIDs.Threshold, m_Threshold);
                cmd.SetGlobalColor(OutlineShaderIDs.Color, m_Color);
                Blitter.BlitCameraTexture(cmd, m_CameraColorTarget, m_CameraColorTarget, m_Material, 0);
            }

            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }
    }
}