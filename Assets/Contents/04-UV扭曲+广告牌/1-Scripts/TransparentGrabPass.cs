using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class TransparentGrabPass : ScriptableRenderPass
{
    private static readonly int TransparentSceneColor = Shader.PropertyToID("_TransparentSceneColor");
    private RTHandle _sceneColorRT;

    public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
    {
        var desc = renderingData.cameraData.cameraTargetDescriptor;
        desc.depthBufferBits = 0;
        RenderingUtils.ReAllocateIfNeeded(ref _sceneColorRT, desc);

        cmd.SetGlobalTexture(TransparentSceneColor, _sceneColorRT);
        
        ConfigureTarget(_sceneColorRT);
        ConfigureClear(ClearFlag.Color, Color.clear);
    }

    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        var cmd = CommandBufferPool.Get();

        using (new ProfilingScope(cmd, new ProfilingSampler("TransparentGrabPass")))
        {
            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
            var source = renderingData.cameraData.renderer.cameraColorTargetHandle;
            Blit(cmd, source, _sceneColorRT);
        }

        context.ExecuteCommandBuffer(cmd);
        cmd.Clear();
        CommandBufferPool.Release(cmd);
    }

    public override void OnCameraCleanup(CommandBuffer cmd)
    {
        if (_sceneColorRT == null) return;
        cmd.ReleaseTemporaryRT(_sceneColorRT.GetInstanceID());
    }
}