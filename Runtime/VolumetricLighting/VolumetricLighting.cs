using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace ToonURP
{
    [System.Serializable, VolumeComponentMenu("ToonURP/Volumetric Lighting")]
    public class VolumetricLighting: VolumeComponent, IPostProcessComponent
    {
        [Tooltip("Controls the Effect Intensity")]
        public ClampedFloatParameter intensity = new ClampedFloatParameter(0, 0, 1);

        public bool IsActive()
        {
            return intensity.value > 0;
        }

        public bool IsTileCompatible()
        {
            return false;
        }
    }
}