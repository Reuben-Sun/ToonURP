using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace ToonURP
{
    /// <summary>
    /// 使用屏幕深度和法线进行边缘检测，将检测结果保存到_EdgeDetectionTexture上
    /// </summary>
    class EdgeDetectionRenderPass : ScriptableRenderPass
    {
        private Material m_Material = null;
        private RTHandle m_OutlineRTHandle = null;

        private readonly bool m_SupportsR8RenderTextureFormat =
            SystemInfo.SupportsRenderTextureFormat(RenderTextureFormat.R8);

        private ProfilingSampler m_ProfilingSampler = new ProfilingSampler("EdgeDetectionRenderPass");
        private Vector4 m_Threshold = Vector4.zero;

        static class DetectionShaderIDs
        {
            internal static readonly int Threshold = Shader.PropertyToID("_EdgeThreshold");
        }

        public EdgeDetectionRenderPass(Material material)
        {
            m_Material = material;
            ConfigureInput(ScriptableRenderPassInput.Depth | ScriptableRenderPassInput.Normal);
        }

        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            var descriptor = renderingData.cameraData.cameraTargetDescriptor;
            descriptor.msaaSamples = 1;
            descriptor.useMipMap = false;
            descriptor.autoGenerateMips = false;
            descriptor.depthBufferBits = 0;
            descriptor.colorFormat =
                m_SupportsR8RenderTextureFormat ? RenderTextureFormat.R8 : RenderTextureFormat.ARGB32;
            RenderingUtils.ReAllocateIfNeeded(ref m_OutlineRTHandle, descriptor, FilterMode.Bilinear,
                TextureWrapMode.Clamp, name: "_EdgeDetectionTexture");
        }

        public void SetupProperties(Vector4 threshold)
        {
            m_Threshold = threshold;
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            var cmd = CommandBufferPool.Get("EdgeDetection");
            using (new ProfilingScope(cmd, m_ProfilingSampler))
            {
                cmd.SetGlobalVector(DetectionShaderIDs.Threshold, m_Threshold);
                Blitter.BlitTexture(cmd, m_OutlineRTHandle, m_OutlineRTHandle, m_Material, 0);
                cmd.SetGlobalTexture("_EdgeDetectionTexture", m_OutlineRTHandle.nameID);
            }

            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }

    }
}