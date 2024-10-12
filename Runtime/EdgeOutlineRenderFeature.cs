using ToonURP;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace ToonURP
{
    public class EdgeOutlineRenderFeature : ScriptableRendererFeature
    {
        /// <summary>
        /// 使用屏幕深度和法线进行边缘检测，将检测结果保存到_EdgeDetectionTexture上
        /// </summary>
        class EdgeDetectionRenderPass : ScriptableRenderPass
        {
            private Material m_Material = null;
            private RTHandle m_OutlineRTHandle = null;
            private readonly bool m_SupportsR8RenderTextureFormat =  SystemInfo.SupportsRenderTextureFormat(RenderTextureFormat.R8);
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
                descriptor.colorFormat = m_SupportsR8RenderTextureFormat ? RenderTextureFormat.R8 : RenderTextureFormat.ARGB32;
                RenderingUtils.ReAllocateIfNeeded(ref m_OutlineRTHandle, descriptor, FilterMode.Bilinear, TextureWrapMode.Clamp, name: "_EdgeDetectionTexture");
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
        
        EdgeDetectionRenderPass m_EdgeDetectionPass;
        EdgeOutlineRenderPass m_EdgeOutlinePass;

        [SerializeField] private Shader edgeDetectionShader = null;
        [SerializeField] private Shader edgeOutlineShader = null;
        
        private Material m_EdgeDetectionMaterial = null;
        private Material m_EdgeOutlineMaterial = null;

        public override void Create()
        {
            edgeDetectionShader = Shader.Find("Hidden/ToonURP/EdgeDetection");
            edgeOutlineShader = Shader.Find("Hidden/ToonURP/EdgeOutline");
            if (!edgeDetectionShader)
            {
                Debug.LogError("Can't find Hidden/ToonURP/EdgeDetection shader.");
                return;
            }
            if (!edgeOutlineShader)
            {
                Debug.LogError("Can't find Hidden/ToonURP/EdgeOutline shader.");
                return;
            }

            m_EdgeDetectionMaterial = CoreUtils.CreateEngineMaterial(edgeDetectionShader);
            m_EdgeDetectionPass = new EdgeDetectionRenderPass(m_EdgeDetectionMaterial)
            {
                renderPassEvent = RenderPassEvent.AfterRenderingOpaques
            };

            m_EdgeOutlineMaterial = CoreUtils.CreateEngineMaterial(edgeOutlineShader);
            m_EdgeOutlinePass = new EdgeOutlineRenderPass(m_EdgeOutlineMaterial)
            {
                renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing
            };
        }

        public override void SetupRenderPasses(ScriptableRenderer renderer, in RenderingData renderingData)
        {
            if (renderingData.cameraData.cameraType == CameraType.Game ||
                renderingData.cameraData.cameraType == CameraType.SceneView)
            {
                var stack = VolumeManager.instance.stack;
                EdgeOutline edgeOutline = stack.GetComponent<EdgeOutline>();
                if (edgeOutline == null || edgeOutline.intensity.value <= 0)
                {
                    return;
                }
                float angleThreshold = edgeOutline.angleThreshold.value;
                float depthThreshold = edgeOutline.depthThreshold.value;
                Vector4 threshold = new Vector4(Mathf.Cos(angleThreshold * Mathf.Deg2Rad), edgeOutline.thickness.value, depthThreshold, edgeOutline.intensity.value);
                m_EdgeDetectionPass.SetupProperties(threshold);
                m_EdgeOutlinePass.SetupProperties(threshold, edgeOutline.color.value, renderer.cameraColorTargetHandle);
                
            }
        }

        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            if (renderingData.cameraData.cameraType == CameraType.Game || renderingData.cameraData.cameraType == CameraType.SceneView)
            {
                var stack = VolumeManager.instance.stack;
                EdgeOutline edgeOutline = stack.GetComponent<EdgeOutline>();
                if (edgeOutline == null || edgeOutline.intensity.value <= 0)
                {
                    return;
                }
                renderer.EnqueuePass(m_EdgeDetectionPass);
                renderer.EnqueuePass(m_EdgeOutlinePass);
            }
        }

        protected override void Dispose(bool disposing)
        {
            base.Dispose(disposing);
            
            if (disposing)
            {
                CoreUtils.Destroy(m_EdgeDetectionMaterial);
                CoreUtils.Destroy(m_EdgeOutlineMaterial);
            }
        }
    }
}

