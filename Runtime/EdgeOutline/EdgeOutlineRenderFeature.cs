using ToonURP;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace ToonURP
{
    [DisallowMultipleRendererFeature("Edge Outline")]
    public class EdgeOutlineRenderFeature : ScriptableRendererFeature
    {
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

