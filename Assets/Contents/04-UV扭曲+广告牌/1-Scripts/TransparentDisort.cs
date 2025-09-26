using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class TransparentDisort : ScriptableRendererFeature
{
  class CustomRenderPass : ScriptableRenderPass
  {
    private RTHandle sceneColorRT;
    public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
    {
      var desc = renderingData.cameraData.cameraTargetDescriptor;
      desc.depthBufferBits = 0;

      RenderingUtils.ReAllocateIfNeeded(ref sceneColorRT, desc, wrapMode: TextureWrapMode.Clamp);

    }

    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
      CommandBuffer cmd = CommandBufferPool.Get();
      using (new ProfilingScope(cmd, new ProfilingSampler("Transparent Disort")))
      {
        cmd.SetRenderTarget(sceneColorRT);
        cmd.ClearRenderTarget(true, true, Color.black);
        Blitter.BlitCameraTexture(cmd, renderingData.cameraData.renderer.cameraColorTargetHandle, sceneColorRT);
        cmd.SetGlobalTexture("_TransparentSceneColor", sceneColorRT);
      }
      context.ExecuteCommandBuffer(cmd);
      cmd.Clear();
      CommandBufferPool.Release(cmd);
    }

    public override void OnCameraCleanup(CommandBuffer cmd)
    {
      cmd.ReleaseTemporaryRT(sceneColorRT.GetInstanceID());
    }
  }

  CustomRenderPass m_ScriptablePass;

  public override void Create()
  {
    m_ScriptablePass = new CustomRenderPass();
    m_ScriptablePass.renderPassEvent = RenderPassEvent.AfterRenderingTransparents;
  }

  public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
  {
    renderer.EnqueuePass(m_ScriptablePass);
  }
}


