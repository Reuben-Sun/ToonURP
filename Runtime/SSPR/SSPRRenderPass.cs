using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace ToonURP
{
    public class SSPRRenderPass: ScriptableRenderPass
    {
        private SSPR m_SSPR;
        private ComputeShader m_CS;
        private RTHandle m_ReflectionColorRTHandle = null;
        private RTHandle m_UVRTHandle = null;
        private RTHandle m_PosYRTHandle = null;     // World Space Y Position
        private ProfilingSampler m_MobileSinglePassProfilingSampler = new ProfilingSampler("MobileSinglePass");
        private ProfilingSampler m_ClearRTProfilingSampler = new ProfilingSampler("ClearRT");
        private ProfilingSampler m_RenderUVProfilingSampler = new ProfilingSampler("RenderUV");
        private ProfilingSampler m_RenderColorProfilingSampler = new ProfilingSampler("RenderColor");
        private ProfilingSampler m_FixHoleProfilingSampler = new ProfilingSampler("FixHole");
        private int m_RTWidth;
        private int m_RTHeight;

        
        const int SHADER_NUMTHREAD_X = 8; 
        const int SHADER_NUMTHREAD_Y = 8;
        
        
        public SSPRRenderPass(ComputeShader cs)
        {
            m_CS = cs;
            ConfigureInput(ScriptableRenderPassInput.Depth | ScriptableRenderPassInput.Color);   
        }
        
        private bool UseMobileAPI()
        {
            return SystemInfo.graphicsDeviceType == GraphicsDeviceType.Metal;
        }

        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            var stack = VolumeManager.instance.stack;
            m_SSPR = stack.GetComponent<SSPR>();
            if (m_SSPR == null)
            {
                return;
            }

            if (!m_SSPR.IsActive())
            {
                return;
            }
            
            int size = m_SSPR.textureSize.value == TextureSizeEnum.Low ? 512 : 1024;
            m_RTHeight = Mathf.CeilToInt(size / (float)SHADER_NUMTHREAD_Y) * SHADER_NUMTHREAD_Y;
            float aspect = (float)Screen.width / Screen.height;
            m_RTWidth = Mathf.CeilToInt(m_RTHeight * aspect / (float)SHADER_NUMTHREAD_X) * SHADER_NUMTHREAD_X;

            // create rt
            var descriptor = new RenderTextureDescriptor(m_RTWidth, m_RTHeight, RenderTextureFormat.ARGB32, 0, 0,
                RenderTextureReadWrite.Linear)
            {
                enableRandomWrite = true
            };
            RenderingUtils.ReAllocateIfNeeded(ref m_ReflectionColorRTHandle, descriptor, FilterMode.Bilinear,
                TextureWrapMode.Clamp, name: "_ReflectionColorTexture");
            
            if (UseMobileAPI())
            {
                descriptor.colorFormat = RenderTextureFormat.RFloat;
                RenderingUtils.ReAllocateIfNeeded(ref m_PosYRTHandle, descriptor, FilterMode.Bilinear,
                    TextureWrapMode.Clamp, name: "_PosYTexture");
            }
            descriptor.colorFormat = RenderTextureFormat.RInt;
            RenderingUtils.ReAllocateIfNeeded(ref m_UVRTHandle, descriptor, FilterMode.Bilinear,
                TextureWrapMode.Clamp, name: "_ReflectionUVTexture");
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            var cmd = CommandBufferPool.Get("SSPR");
            
            int dispatchThreadGroupXCount = m_RTWidth / SHADER_NUMTHREAD_X; 
            int dispatchThreadGroupYCount = m_RTHeight / SHADER_NUMTHREAD_Y; 
            int dispatchThreadGroupZCount = 1; 
            Camera camera = renderingData.cameraData.camera;
            Matrix4x4 VP = GL.GetGPUProjectionMatrix(camera.projectionMatrix, true) * camera.worldToCameraMatrix;

            #region Convert Uniform

            cmd.SetComputeVectorParam(m_CS, Shader.PropertyToID("_RTSize"), new Vector2(m_RTWidth, m_RTHeight));
            cmd.SetComputeFloatParam(m_CS, Shader.PropertyToID("_HorizontalPlaneHeightWS"), m_SSPR.planeHeight.value);
            cmd.SetComputeMatrixParam(m_CS, "_VPMatrix", VP);
            cmd.SetComputeFloatParam(m_CS, Shader.PropertyToID("_ScreenLRStretchIntensity"), m_SSPR.stretchIntensity.value);
            cmd.SetComputeFloatParam(m_CS, Shader.PropertyToID("_ScreenLRStretchThreshold"), m_SSPR.stretchThreshold.value);
            cmd.SetComputeFloatParam(m_CS, Shader.PropertyToID("_FadeOutScreenBorderWidthVertical"), m_SSPR.verticalFadeOutDistance.value);
            cmd.SetComputeFloatParam(m_CS, Shader.PropertyToID("_FadeOutScreenBorderWidthHorizontal"), m_SSPR.horizontalFadeOutDistance.value);
            cmd.SetComputeVectorParam(m_CS, Shader.PropertyToID("_CameraDirection"), camera.transform.forward);
            cmd.SetComputeVectorParam(m_CS, Shader.PropertyToID("_FinalTintColor"), m_SSPR.tintColor.value);

            #endregion
            
            if (UseMobileAPI())
            {
                using (new ProfilingScope(cmd, m_MobileSinglePassProfilingSampler))
                {
                    int kernel_MobileSinglePass = m_CS.FindKernel("MobileSinglePass");
                    cmd.SetComputeTextureParam(m_CS, kernel_MobileSinglePass, "PosYRT", m_PosYRTHandle);
                    cmd.SetComputeTextureParam(m_CS, kernel_MobileSinglePass, "ColorRT", m_ReflectionColorRTHandle);
                    cmd.DispatchCompute(m_CS, kernel_MobileSinglePass, dispatchThreadGroupXCount, dispatchThreadGroupYCount, dispatchThreadGroupZCount);
                }
            }
            else
            {
                using (new ProfilingScope(cmd, m_ClearRTProfilingSampler))
                {
                    int kernel_ClearRT = m_CS.FindKernel("ClearRT");
                    cmd.SetComputeTextureParam(m_CS, kernel_ClearRT, "UVRT", m_UVRTHandle);
                    cmd.SetComputeTextureParam(m_CS, kernel_ClearRT, "ColorRT", m_ReflectionColorRTHandle);
                    cmd.DispatchCompute(m_CS, kernel_ClearRT, dispatchThreadGroupXCount, dispatchThreadGroupYCount, dispatchThreadGroupZCount);
                }

                using (new ProfilingScope(cmd, m_RenderUVProfilingSampler))
                {
                    int kernel_RenderUV = m_CS.FindKernel("RenderUV");
                    cmd.SetComputeTextureParam(m_CS, kernel_RenderUV, "UVRT", m_UVRTHandle);
                    cmd.DispatchCompute(m_CS, kernel_RenderUV, dispatchThreadGroupXCount, dispatchThreadGroupYCount, dispatchThreadGroupZCount);

                }

                using (new ProfilingScope(cmd, m_RenderColorProfilingSampler))
                {
                    int kernel_RenderColor = m_CS.FindKernel("RenderColor");
                    cmd.SetComputeTextureParam(m_CS, kernel_RenderColor, "ColorRT", m_ReflectionColorRTHandle);
                    cmd.SetComputeTextureParam(m_CS, kernel_RenderColor, "UVRT", m_UVRTHandle);
                    cmd.DispatchCompute(m_CS, kernel_RenderColor, dispatchThreadGroupXCount, dispatchThreadGroupYCount, dispatchThreadGroupZCount);

                }

            }
            
            using (new ProfilingScope(cmd, m_FixHoleProfilingSampler))
            {
                int kernel_FixHole = m_CS.FindKernel("FixHole");
                cmd.SetComputeTextureParam(m_CS, kernel_FixHole, "ColorRT", m_ReflectionColorRTHandle);
                cmd.SetComputeTextureParam(m_CS, kernel_FixHole, "UVRT", m_UVRTHandle);
                cmd.DispatchCompute(m_CS, kernel_FixHole, Mathf.CeilToInt(dispatchThreadGroupXCount / 2f), Mathf.CeilToInt(dispatchThreadGroupYCount / 2f), dispatchThreadGroupZCount);

            }
            // sent global texture
            cmd.SetGlobalTexture("_SSPRGlobalColorRT", m_ReflectionColorRTHandle);
            
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }
    }
}