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

        [Tooltip("RT Size, low is 512, high is 1024")]
        public TextureSizeEnumParameter textureSize = new TextureSizeEnumParameter { value = TextureSizeEnum.Low };
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