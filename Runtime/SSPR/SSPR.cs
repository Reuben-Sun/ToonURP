using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace ToonURP
{
    [Serializable]
    public sealed class TextureSizeEnumParameter : VolumeParameter<TextureSizeEnum> { }
    public enum TextureSizeEnum { Low, High }
    
    [System.Serializable, VolumeComponentMenu("ToonURP/SSPR")]
    public class SSPR : VolumeComponent, IPostProcessComponent
    {
        public BoolParameter enable = new BoolParameter(false);
        [Tooltip("RT Size, low is 512, high is 1024")]
        public TextureSizeEnumParameter textureSize = new TextureSizeEnumParameter { value = TextureSizeEnum.Low };
        [Tooltip("Reflection Plane Height in World Space")]
        public FloatParameter planeHeight = new FloatParameter(0.01f);
        public ClampedFloatParameter stretchIntensity = new ClampedFloatParameter(4f, 0, 8f);
        public ClampedFloatParameter stretchThreshold = new ClampedFloatParameter(0.7f, -1f, 1f);
        public ClampedFloatParameter verticalFadeOutDistance = new ClampedFloatParameter(0.25f, 0.01f, 1f);
        public ClampedFloatParameter horizontalFadeOutDistance = new ClampedFloatParameter(0.35f, 0.01f, 1f);

        public ColorParameter tintColor = new ColorParameter(Color.white);
        
        
        public bool IsActive()
        {
            return enable.value;
        }

        public bool IsTileCompatible()
        {
            return false;
        }
    }
}