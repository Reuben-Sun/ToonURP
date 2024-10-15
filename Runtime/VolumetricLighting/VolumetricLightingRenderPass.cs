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
        private VolumetricLighting m_VolumetricLighting = null;
        
        private int m_RTWidth;
        private int m_RTHeight;
        private float m_EachStepDistance;
        private float m_MaxDistance;
        private int m_MaxStepCount;
        const int SHADER_NUMTHREAD_X = 8; 
        const int SHADER_NUMTHREAD_Y = 8;
        
        public VolumetricLightingRenderPass(Material material)
        {
            m_LightingMatchingMaterial = material;
            ConfigureInput(ScriptableRenderPassInput.Depth);
        }

        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            var stack = VolumeManager.instance.stack;
            m_VolumetricLighting = stack.GetComponent<VolumetricLighting>();
            if (m_VolumetricLighting == null || !m_VolumetricLighting.IsActive())
            {
                return;
            }
 
            int size = m_VolumetricLighting.textureSize.value == TextureSizeEnum.Low ? 512 : 1024;
            m_RTHeight = Mathf.CeilToInt(size / (float)SHADER_NUMTHREAD_Y) * SHADER_NUMTHREAD_Y;
            float aspect = (float)Screen.width / Screen.height;
            m_RTWidth = Mathf.CeilToInt(m_RTHeight * aspect / (float)SHADER_NUMTHREAD_X) * SHADER_NUMTHREAD_X;
            m_EachStepDistance = m_VolumetricLighting.eachStepDistance.value;
            m_MaxDistance = m_VolumetricLighting.maxDistance.value;
            m_MaxStepCount = m_VolumetricLighting.maxStepCount.value;
            
            var descriptor = new RenderTextureDescriptor(m_RTWidth, m_RTHeight, RenderTextureFormat.ARGB32, 0, 0,
                RenderTextureReadWrite.Linear)
            {
                enableRandomWrite = true
            };
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
                cmd.SetGlobalFloat("_EachStepDistance", m_EachStepDistance);
                cmd.SetGlobalFloat("_MaxDistance", m_MaxDistance);
                cmd.SetGlobalInt("_MaxStepCount", m_MaxStepCount);
                Blitter.BlitTexture(cmd, m_LightingMatchingRTHandle, m_LightingMatchingRTHandle, m_LightingMatchingMaterial, 0);
                cmd.SetGlobalTexture("_SourceMap", m_LightingMatchingRTHandle.nameID);
            }
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }
    }
}