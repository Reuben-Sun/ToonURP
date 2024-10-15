using UnityEditor;
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
        [SerializeField]
        private Shader combineSampleShader = null;
        private Material m_CombineMaterial = null;
        private CombineSampleRenderPass m_CombineSamplePass = null;
        [SerializeField] private ComputeShader blurCs = null;
        public override void Create()
        {
            volumetricLightingShader = Shader.Find("Hidden/ToonURP/VolumetricLighting");
            if (!volumetricLightingShader)
            {
                Debug.LogError("Can't find Hidden/ToonURP/VolumetricLighting shader.");
                return;
            }
            combineSampleShader = Shader.Find("Hidden/ToonURP/CombineSample");
            if(!combineSampleShader)
            {
                Debug.LogError("Can't find Hidden/ToonURP/CombineSample shader.");
                return;
            }
            blurCs = AssetDatabase.LoadAssetAtPath<ComputeShader>(
                "Packages/com.reubensun.toonurp/Shaders/PostProcessing/BilateralBlur.compute");
            if(ReferenceEquals(blurCs, null))
            {
                Debug.LogError("Can't find BoxBlur.compute");
                return;
            }
            
            m_LightingMatchingMaterial = CoreUtils.CreateEngineMaterial(volumetricLightingShader);
            m_VolumetricLightingPass = new VolumetricLightingRenderPass(m_LightingMatchingMaterial, blurCs)
            {
                renderPassEvent = RenderPassEvent.AfterRenderingOpaques
            };
            m_CombineMaterial = CoreUtils.CreateEngineMaterial(combineSampleShader);
            m_CombineSamplePass = new CombineSampleRenderPass(m_CombineMaterial)
            {
                renderPassEvent = RenderPassEvent.AfterRenderingTransparents
            };
        }

        public override void SetupRenderPasses(ScriptableRenderer renderer, in RenderingData renderingData)
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
                m_VolumetricLightingPass.SetupProperties(volumetricLighting.enableBlur.value, 
                    volumetricLighting.blurSize.value, volumetricLighting.sigmaSpace.value, volumetricLighting.sigmaColor.value);
                m_CombineSamplePass.SetupProperties(renderer.cameraColorTargetHandle, volumetricLighting.intensity.value);
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
                renderer.EnqueuePass(m_CombineSamplePass);
            }
        }

        protected override void Dispose(bool disposing)
        {
            base.Dispose(disposing);

            if (disposing)
            {
                CoreUtils.Destroy(m_LightingMatchingMaterial);
                CoreUtils.Destroy(m_CombineMaterial);
            }
        }
    }
}