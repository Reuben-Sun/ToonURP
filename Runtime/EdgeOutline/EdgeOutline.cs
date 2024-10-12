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
        
        [Tooltip("Controls the edge color.")]
        public ColorParameter color = new ColorParameter(Color.black, true, false, true);
        
        [Tooltip("Controls the edge thickness.")]
        public ClampedFloatParameter thickness = new ClampedFloatParameter(0, 0, 1);
        
        [Tooltip("Controls the threshold of the normal difference in degrees.")]
        public ClampedFloatParameter angleThreshold = new ClampedFloatParameter(1, 1, 179.9f);

        [Tooltip("Controls the threshold of the depth difference in world units.")]
        public ClampedFloatParameter depthThreshold = new ClampedFloatParameter(0.01f, 0.001f, 1);
        
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
