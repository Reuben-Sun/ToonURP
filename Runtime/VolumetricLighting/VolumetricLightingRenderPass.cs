using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace ToonURP
{
    public class VolumetricLightingRenderPass: ScriptableRenderPass
    {
        private Material m_RayMatchingMaterial = null;
        private ComputeShader m_CS = null;
        private RTHandle m_RayMatchingRTHandle = null;
        private ProfilingSampler m_RayMatchingProfilingSampler = new ProfilingSampler("RayMatchingRenderPass");
        private ProfilingSampler m_BlurProfilingSampler = new ProfilingSampler("BlurPass");
        private VolumetricLighting m_VolumetricLighting = null;
        private bool m_EnableBlur = true;
        private int m_BlurSize = 1;
        private float m_SigmaSpace = 1;
        private float m_SigmaColor = 10;
        
        private int m_RTWidth;
        private int m_RTHeight;
        private float m_EachStepDistance;
        private float m_MaxDistance;
        private int m_MaxStepCount;
        const int SHADER_NUMTHREAD_X = 8; 
        const int SHADER_NUMTHREAD_Y = 8;
        
        public VolumetricLightingRenderPass(Material material, ComputeShader cs)
        {
            m_RayMatchingMaterial = material;
            m_CS = cs;
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
            RenderingUtils.ReAllocateIfNeeded(ref m_RayMatchingRTHandle, descriptor, FilterMode.Bilinear,
                TextureWrapMode.Clamp, name: "_LightingMatchingTexture");
        }
        
        public void SetupProperties(bool enableBlur, int blurSize, float sigmaSpace, float sigmaColor)
        {
            m_EnableBlur = enableBlur;
            m_BlurSize = blurSize;
            m_SigmaSpace = sigmaSpace;
            m_SigmaColor = sigmaColor;
        }


        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            var cmd = CommandBufferPool.Get("VolumetricLighting");
            using (new ProfilingScope(cmd, m_RayMatchingProfilingSampler))
            {
                cmd.SetGlobalFloat("_EachStepDistance", m_EachStepDistance);
                cmd.SetGlobalFloat("_MaxDistance", m_MaxDistance);
                cmd.SetGlobalInt("_MaxStepCount", m_MaxStepCount);
                Blitter.BlitTexture(cmd, m_RayMatchingRTHandle, m_RayMatchingRTHandle, m_RayMatchingMaterial, 0);
            }

            if (m_EnableBlur)
            {
                using (new ProfilingScope(cmd, m_BlurProfilingSampler))
                {
                    int dispatchThreadGroupXCount = m_RTWidth / SHADER_NUMTHREAD_X; 
                    int dispatchThreadGroupYCount = m_RTHeight / SHADER_NUMTHREAD_Y; 
                    int dispatchThreadGroupZCount = 1; 
                    int kernel = m_CS.FindKernel("BoxBlur");
                    cmd.SetComputeIntParam(m_CS, "BlurSize", m_BlurSize);
                    cmd.SetComputeFloatParam(m_CS, "SigmaSpace", m_SigmaSpace);
                    cmd.SetComputeFloatParam(m_CS, "SigmaColor", m_SigmaColor);
                    cmd.SetComputeTextureParam(m_CS, kernel, "SourceRT", m_RayMatchingRTHandle);
                    cmd.DispatchCompute(m_CS, kernel, dispatchThreadGroupXCount, dispatchThreadGroupYCount, dispatchThreadGroupZCount);
                }
            }
            
            cmd.SetGlobalTexture("_SourceMap", m_RayMatchingRTHandle.nameID);
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }
    }
}