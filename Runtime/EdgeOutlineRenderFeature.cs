using ToonURP;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace ToonURP
{
    public class EdgeOutlineRenderFeature : ScriptableRendererFeature
    {
        class EdgeDetectionRenderPass : ScriptableRenderPass
        {
            private EdgeOutline m_EdgeOutlineSettings = null;
            private Material m_Material = null;
            private RTHandle m_OutlineRTHandle = null;
            private readonly bool m_SupportsR8RenderTextureFormat =  SystemInfo.SupportsRenderTextureFormat(RenderTextureFormat.R8);
            static class OutlineShaderIDs {
                internal static readonly int Threshold = Shader.PropertyToID("_EdgeThreshold");
                internal static readonly int Color = Shader.PropertyToID("_EdgeColor");
                internal static readonly int TempTarget = Shader.PropertyToID("_TempTarget");
            }
            
            public EdgeDetectionRenderPass(Shader outlineShader)
            {
                m_Material = CoreUtils.CreateEngineMaterial(outlineShader);
                ConfigureInput(ScriptableRenderPassInput.Depth | ScriptableRenderPassInput.Normal);
            }
            
            public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
            {
                var descriptor = renderingData.cameraData.cameraTargetDescriptor;
                descriptor.msaaSamples = 1;
                descriptor.useMipMap = false;
                descriptor.autoGenerateMips = false;
                descriptor.depthBufferBits = 0;
                descriptor.colorFormat = m_SupportsR8RenderTextureFormat ? RenderTextureFormat.R8 : RenderTextureFormat.ARGB32;
                RenderingUtils.ReAllocateIfNeeded(ref m_OutlineRTHandle, descriptor, FilterMode.Bilinear, TextureWrapMode.Clamp, name: "_EdgeDetectionTexture");
            }

            public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
            {
                var stack = VolumeManager.instance.stack;
                m_EdgeOutlineSettings = stack.GetComponent<EdgeOutline>();
                if (m_EdgeOutlineSettings == null || m_EdgeOutlineSettings.intensity.value <= 0)
                {
                    return;
                }
                
                var cmd = CommandBufferPool.Get("EdgeDetection");
                // create temp rt
                var width = renderingData.cameraData.camera.scaledPixelWidth;
                var height = renderingData.cameraData.camera.scaledPixelHeight;
                cmd.GetTemporaryRT(OutlineShaderIDs.TempTarget, width, height, 0, FilterMode.Point, RenderTextureFormat.Default);
                // pass value
                float angleThreshold = m_EdgeOutlineSettings.angleThreshold.value;
                float depthThreshold = m_EdgeOutlineSettings.depthThreshold.value;
                Vector4 threshold = new Vector4(Mathf.Cos(angleThreshold * Mathf.Deg2Rad), m_EdgeOutlineSettings.thickness.value, depthThreshold, m_EdgeOutlineSettings.intensity.value);
                cmd.SetGlobalVector(OutlineShaderIDs.Threshold, threshold);
                // cmd.SetGlobalColor(OutlineShaderIDs.Color, m_EdgeOutlineSettings.color.value);
                // blit
                cmd.Blit(OutlineShaderIDs.TempTarget, m_OutlineRTHandle, m_Material, 0);
                cmd.SetGlobalTexture("_EdgeDetectionTexture", m_OutlineRTHandle.nameID);
                context.ExecuteCommandBuffer(cmd);
                CommandBufferPool.Release(cmd);
            }

            public override void OnCameraCleanup(CommandBuffer cmd)
            {
                if (m_OutlineRTHandle != null)
                {
                    m_OutlineRTHandle.Release();
                    m_OutlineRTHandle = null;
                }
            }
            
        }

        EdgeDetectionRenderPass m_EdgeDetectionPass;

        [SerializeField] private Shader edgeDetectionShader = null;

        public override void Create()
        {
            edgeDetectionShader = Shader.Find("Hidden/ToonURP/EdgeDetection");
            if (!edgeDetectionShader)
            {
                Debug.LogError("Can't find Hidden/ToonURP/EdgeDetection shader.");
                return;
            }

            m_EdgeDetectionPass = new EdgeDetectionRenderPass(edgeDetectionShader);
            m_EdgeDetectionPass.renderPassEvent = RenderPassEvent.AfterRenderingOpaques;
            
        }
        
        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            renderer.EnqueuePass(m_EdgeDetectionPass);
        }
    }
}

