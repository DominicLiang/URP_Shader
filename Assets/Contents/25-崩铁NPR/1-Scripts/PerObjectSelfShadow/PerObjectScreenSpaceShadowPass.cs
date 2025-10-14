using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class PerObjectScreenSpaceShadowPass : ScriptableRenderPass
{
  private Material shadowMaterial;
  private RTHandle targetRT;

  public PerObjectScreenSpaceShadowPass()
  {
    shadowMaterial = new Material(Shader.Find("Hidden/PerObjectScreenSpaceShadow"));
  }

  public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
  {
    if (shadowMaterial == null) return;

    var desc = renderingData.cameraData.cameraTargetDescriptor;
    desc.depthBufferBits = 0;
    desc.msaaSamples = 1;
    desc.graphicsFormat = GraphicsFormat.B8G8R8A8_UNorm;

    RenderingUtils.ReAllocateIfNeeded(ref targetRT, desc, name: "PerObjectScreenSpaceShadow");


    ConfigureInput(ScriptableRenderPassInput.Depth);
    ConfigureTarget(targetRT);
    ConfigureClear(ClearFlag.None, Color.white);
  }

  public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
  {
    if (shadowMaterial == null) return;

    var cmd = CommandBufferPool.Get();

    using (new ProfilingScope(cmd, new ProfilingSampler("PerObjectScreenSpaceShadow")))
    {
      Blitter.BlitCameraTexture(cmd, targetRT, targetRT, shadowMaterial, 0);
      CoreUtils.SetKeyword(cmd, ShaderKeywordStrings.MainLightShadows, false);
      CoreUtils.SetKeyword(cmd, ShaderKeywordStrings.MainLightShadowCascades, false);
      CoreUtils.SetKeyword(cmd, ShaderKeywordStrings.MainLightShadowScreen, true);
      cmd.SetGlobalTexture("_ScreenSpaceShadowmapTexture", targetRT);
    }

    context.ExecuteCommandBuffer(cmd);
    cmd.Clear();
    CommandBufferPool.Release(cmd);
  }

  public override void OnCameraCleanup(CommandBuffer cmd)
  {
    if (targetRT == null) return;
    cmd.ReleaseTemporaryRT(targetRT.GetInstanceID());
  }
}