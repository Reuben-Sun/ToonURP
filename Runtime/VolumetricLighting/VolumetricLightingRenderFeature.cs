using UnityEngine.Rendering.Universal;

namespace ToonURP
{
    [DisallowMultipleRendererFeature("Volumetric Lighting")]
    public class VolumetricLightingRenderFeature: ScriptableRendererFeature
    {
        public override void Create()
        {
            
        }

        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            
        }
    }
}