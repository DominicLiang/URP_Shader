using System.Collections.Generic;
using System.Net.WebSockets;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class ScanRF : ScriptableRendererFeature
{
  class CustomRenderPass : ScriptableRenderPass
  {
    public Material ghostMat;
    public Material fullScreenMat;
    private RTHandle ghostRT;
    private RTHandle targetRT;

    public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
    {
      var desc = renderingData.cameraData.cameraTargetDescriptor;
      desc.depthBufferBits = 0;
      RenderingUtils.ReAllocateIfNeeded(ref ghostRT, desc, name: "GhostRT");
      RenderingUtils.ReAllocateIfNeeded(ref targetRT, desc, name: "TargetRT");
      cmd.SetGlobalTexture("_GhostRT", ghostRT);
    }

    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
      if (ghostMat == null || fullScreenMat == null) return;

      var cmd = CommandBufferPool.Get();

      using (new ProfilingScope(cmd, new ProfilingSampler("ScanRF")))
      {
        cmd.SetRenderTarget(ghostRT);
        context.ExecuteCommandBuffer(cmd);
        cmd.Clear();

        var camera = renderingData.cameraData.camera;
        context.DrawSkybox(camera);

        var shaderTagIdList = new List<ShaderTagId>() { new ShaderTagId("UniversalForward") };
        var drawingSettings = CreateDrawingSettings(shaderTagIdList, ref renderingData, SortingCriteria.CommonTransparent);
        drawingSettings.overrideMaterial = ghostMat;

        var layer = LayerMask.GetMask("real");
        var filteringSettings = new FilteringSettings(RenderQueueRange.all, layer);

        context.DrawRenderers(renderingData.cullResults, ref drawingSettings, ref filteringSettings);

        Blitter.BlitTexture(cmd, renderingData.cameraData.renderer.cameraColorTargetHandle, targetRT, fullScreenMat, 0);
        Blitter.BlitCameraTexture(cmd, targetRT, renderingData.cameraData.renderer.cameraColorTargetHandle);
      }
      context.ExecuteCommandBuffer(cmd);
      cmd.Clear();
      CommandBufferPool.Release(cmd);
    }

    // Cleanup any allocated resources that were created during the execution of this render pass.
    public override void OnCameraCleanup(CommandBuffer cmd)
    {
      cmd.ReleaseTemporaryRT(ghostRT.GetInstanceID());
      cmd.ReleaseTemporaryRT(targetRT.GetInstanceID());
    }
  }

  CustomRenderPass m_ScriptablePass;
  public Material ghostMat;
  public Material fullScreenMat;
  public bool enable = false;

  /// <inheritdoc/>
  public override void Create()
  {
    m_ScriptablePass = new CustomRenderPass();

    m_ScriptablePass.renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;

    m_ScriptablePass.ghostMat = ghostMat;
    m_ScriptablePass.fullScreenMat = fullScreenMat;
  }

  public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
  {
    if (!enable) return;
    renderer.EnqueuePass(m_ScriptablePass);
  }
}


