using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace ToonURP
{
    public class VolumetricLightingRenderPass: ScriptableRenderPass
    {
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            // 1. 屏幕 UV -> 世界坐标，利用深度图做 ray matching，如果某点世界坐标不再阴影中，则累计光照
            // 2. 对累计光照进行高斯模糊
            // 3. 将高斯模糊后的光照叠加到场景中
        }
    }
}