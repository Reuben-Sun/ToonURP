using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace ToonURP
{
    public class VolumetricLightingRenderPass: ScriptableRenderPass
    {
        private Material m_LightingMatchingMaterial = null;
        private RTHandle m_LightingMatchingRTHandle = null;
        private ProfilingSampler m_ProfilingSampler = new ProfilingSampler("VolumetricLightingRenderPass");
        
        public VolumetricLightingRenderPass(Material material)
        {
            m_LightingMatchingMaterial = material;
            ConfigureInput(ScriptableRenderPassInput.Depth);
        }

        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            var descriptor = renderingData.cameraData.cameraTargetDescriptor;
            descriptor.msaaSamples = 1;
            descriptor.useMipMap = false;
            descriptor.autoGenerateMips = false;
            descriptor.depthBufferBits = 0;
            descriptor.colorFormat = RenderTextureFormat.ARGB32;
            RenderingUtils.ReAllocateIfNeeded(ref m_LightingMatchingRTHandle, descriptor, FilterMode.Bilinear,
                TextureWrapMode.Clamp, name: "_LightingMatchingTexture");
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            // 1. 屏幕 UV -> 世界坐标，利用深度图做 ray matching，如果某点世界坐标不再阴影中，则累计光照
            // 2. 对累计光照进行高斯模糊
            // 3. 将高斯模糊后的光照叠加到场景中
            var cmd = CommandBufferPool.Get("VolumetricLighting");
            using (new ProfilingScope(cmd, m_ProfilingSampler))
            {
                Blitter.BlitTexture(cmd, m_LightingMatchingRTHandle, m_LightingMatchingRTHandle, m_LightingMatchingMaterial, 0);
                cmd.SetGlobalTexture("_VolumetricLightingTexture", m_LightingMatchingRTHandle.nameID);
            }
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }
    }
}