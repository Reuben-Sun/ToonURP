using ToonURP;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace ToonURP
{
    public class EdgeOutlineRenderFeature : ScriptableRendererFeature
    {
        class EdgeOutlineRenderPass : ScriptableRenderPass
        {
            private EdgeOutline m_EdgeOutlineSettings = null;
            private Material m_Material = null;
            private RTHandle m_OutlineRTHandle = null;
            private readonly bool m_SupportsR8RenderTextureFormat =  SystemInfo.SupportsRenderTextureFormat(RenderTextureFormat.R8);
            private static readonly int _TempTargetShaderId = Shader.PropertyToID("_TempTarget");
            
            public EdgeOutlineRenderPass(Shader outlineShader)
            {
                m_Material = CoreUtils.CreateEngineMaterial(outlineShader);
            }

            public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
            {
                var stack = VolumeManager.instance.stack;
                m_EdgeOutlineSettings = stack.GetComponent<EdgeOutline>();
                if (m_EdgeOutlineSettings == null || m_EdgeOutlineSettings.intensity.value <= 0)
                {
                    return;
                }
                
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
                var cmd = CommandBufferPool.Get("EdgeOutline");
                var width = renderingData.cameraData.camera.scaledPixelWidth;
                var height = renderingData.cameraData.camera.scaledPixelHeight;
                cmd.GetTemporaryRT(_TempTargetShaderId, width, height, 0, FilterMode.Point, RenderTextureFormat.Default);
                cmd.Blit(_TempTargetShaderId, m_OutlineRTHandle, m_Material, 0);
                cmd.SetGlobalTexture("_EdgeDetectionTexture", m_OutlineRTHandle.nameID);
                context.ExecuteCommandBuffer(cmd);
                CommandBufferPool.Release(cmd);
            }

            public override void OnCameraCleanup(CommandBuffer cmd)
            {
            }
            
        }

        EdgeOutlineRenderPass m_ScriptablePass;

        [SerializeField] private Shader edgeOutlineShader = null;

        public override void Create()
        {
            edgeOutlineShader = Shader.Find("Hidden/ToonURP/EdgeOutline");
            if (!edgeOutlineShader)
            {
                Debug.LogError("Can't find Hidden/ToonURP/EdgeOutline shader.");
                return;
            }

            m_ScriptablePass = new EdgeOutlineRenderPass(edgeOutlineShader);
            m_ScriptablePass.renderPassEvent = RenderPassEvent.AfterRenderingOpaques;
        }
        
        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            renderer.EnqueuePass(m_ScriptablePass);
        }
    }
}

