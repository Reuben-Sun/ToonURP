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
            var descriptor = renderingData.cameraData.cameraTargetDescriptor;
            descriptor.width = m_RTWidth;
            descriptor.height = m_RTHeight;
            descriptor.msaaSamples = 1;
            descriptor.useMipMap = false;
            descriptor.autoGenerateMips = false;
            descriptor.depthBufferBits = 0;
            descriptor.colorFormat = RenderTextureFormat.ARGB32;
            RenderingUtils.ReAllocateIfNeeded(ref m_ReflectionColorRTHandle, descriptor, FilterMode.Bilinear,
                TextureWrapMode.Clamp, name: "_ReflectionColorTexture");
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

            using (new ProfilingScope(cmd, m_ClearRTProfilingSampler))
            {
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
                
                int kernel_ClearRT = m_CS.FindKernel("ClearRT");
                cmd.SetComputeTextureParam(m_CS, kernel_ClearRT, "UVRT", m_UVRTHandle);
                cmd.SetComputeTextureParam(m_CS, kernel_ClearRT, "ColorRT", m_ReflectionColorRTHandle);
                cmd.DispatchCompute(m_CS, kernel_ClearRT, dispatchThreadGroupXCount, dispatchThreadGroupYCount, dispatchThreadGroupZCount);
            }

            using (new ProfilingScope(cmd, m_RenderUVProfilingSampler))
            {
                int kernel_RenderUV = m_CS.FindKernel("RenderUV");
                cmd.SetComputeTextureParam(m_CS, kernel_RenderUV, "UVRT", m_UVRTHandle);
                // cmd.SetComputeTextureParam(m_CS, kernel_RenderUV, "_CameraDepthTexture", new RenderTargetIdentifier("_CameraDepthTexture"));
                cmd.DispatchCompute(m_CS, kernel_RenderUV, dispatchThreadGroupXCount, dispatchThreadGroupYCount, dispatchThreadGroupZCount);

            }
        }
    }
}