using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace ToonURP
{
    [DisallowMultipleRendererFeature("Volumetric Lighting")]
    public class VolumetricLightingRenderFeature: ScriptableRendererFeature
    {
        [SerializeField]
        private Shader volumetricLightingShader = null;
        private Material m_LightingMatchingMaterial = null;
        private VolumetricLightingRenderPass m_VolumetricLightingPass = null;
        public override void Create()
        {
            volumetricLightingShader = Shader.Find("Hidden/ToonURP/VolumetricLighting");
            if (!volumetricLightingShader)
            {
                Debug.LogError("Can't find Hidden/ToonURP/VolumetricLighting shader.");
                return;
            }
            m_LightingMatchingMaterial = CoreUtils.CreateEngineMaterial(volumetricLightingShader);
            m_VolumetricLightingPass = new VolumetricLightingRenderPass(m_LightingMatchingMaterial)
            {
                renderPassEvent = RenderPassEvent.AfterRenderingOpaques
            };
        }

        public override void SetupRenderPasses(ScriptableRenderer renderer, in RenderingData renderingData)
        {
            if (renderingData.cameraData.cameraType == CameraType.Game ||
                renderingData.cameraData.cameraType == CameraType.SceneView)
            {
            }
        }

        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            if (renderingData.cameraData.cameraType == CameraType.Game ||
                renderingData.cameraData.cameraType == CameraType.SceneView)
            {
                var stack = VolumeManager.instance.stack;
                VolumetricLighting volumetricLighting = stack.GetComponent<VolumetricLighting>();
                if (volumetricLighting == null || !volumetricLighting.IsActive())
                {
                    return;
                }
                renderer.EnqueuePass(m_VolumetricLightingPass);
            }
        }

        protected override void Dispose(bool disposing)
        {
            base.Dispose(disposing);

            if (disposing)
            {
                CoreUtils.Destroy(m_LightingMatchingMaterial);
            }
        }
    }
}