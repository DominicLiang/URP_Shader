using UnityEngine.Rendering.Universal;

public class TransparentGrabRF : ScriptableRendererFeature
{
    private TransparentGrabPass _transparentGrabPass;

    public override void Create()
    {
        _transparentGrabPass = new TransparentGrabPass
        {
            renderPassEvent = RenderPassEvent.AfterRenderingTransparents
        };
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(_transparentGrabPass);
    }
}