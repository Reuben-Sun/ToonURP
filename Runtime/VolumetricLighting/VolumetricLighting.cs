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
        public ClampedFloatParameter eachStepDistance = new ClampedFloatParameter(1f, 0, 5f);
        public ClampedFloatParameter maxDistance = new ClampedFloatParameter(1000f, 0, 10000f);
        public ClampedIntParameter maxStepCount = new ClampedIntParameter(200, 0, 1000);
        
        public BoolParameter enableBlur = new BoolParameter(true);
        [Tooltip("Blur Size, calc cout = (2 * value + 1)^2")]
        public ClampedIntParameter blurSize = new ClampedIntParameter(3, 0, 6);
        [Tooltip("多大距离的数据会影响模糊")]
        public ClampedIntParameter sigmaSpace = new ClampedIntParameter(4, 1, 10);
        [Tooltip("值差距多少才会影响模糊")]
        public ClampedIntParameter sigmaColor = new ClampedIntParameter(60, 1, 150);
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