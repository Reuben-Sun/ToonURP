using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace ToonURP
{
    [System.Serializable, VolumeComponentMenu("ToonURP/Edge Outline")]
    public class EdgeOutline : VolumeComponent, IPostProcessComponent
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
