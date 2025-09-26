using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class StarRailNPRShadowRF : ScriptableRendererFeature
{
  class PerObjectShadowCasterPass : ScriptableRenderPass
  {
    public RTHandle shadowRT;

    private static readonly int _PerObjSelfShadowCount = MemberNameHelpers.ShaderPropertyID();

    public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
    {

      ShadowUtils.ShadowRTReAllocateIfNeeded(ref shadowRT, 1024, 1024, 16);

      ConfigureTarget(shadowRT);
      ConfigureClear(ClearFlag.All, Color.black);
    }

    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
      var cmd = CommandBufferPool.Get();

      using (new ProfilingScope(cmd, new ProfilingSampler("PerObjectShadowCasterPass")))
      {
        RenderShadowMap(cmd, ref renderingData);
        SetShadowSamplingData(cmd);
        cmd.SetGlobalInt(_PerObjSelfShadowCount, 0);
      }

      context.ExecuteCommandBuffer(cmd);
      CommandBufferPool.Release(cmd);
    }

    private List<int> rendererIndexList = new List<int>();
    // private Dictionary<float,shadowcast>

    private void RenderShadowMap(CommandBuffer cmd, ref RenderingData renderingData)
    {
      cmd.SetGlobalDepthBias(1.0f, 2.5f);

      // ! 剔除
      rendererIndexList.Clear();

    }

    private void SetShadowSamplingData(CommandBuffer cmd)
    {

    }

    public override void OnCameraCleanup(CommandBuffer cmd)
    {
    }
  }

  PerObjectShadowCasterPass perObjectShadowPass;

  public override void Create()
  {
    perObjectShadowPass = new PerObjectShadowCasterPass();

    perObjectShadowPass.renderPassEvent = RenderPassEvent.BeforeRenderingGbuffer;
  }

  public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
  {
    renderer.EnqueuePass(perObjectShadowPass);
  }
}


