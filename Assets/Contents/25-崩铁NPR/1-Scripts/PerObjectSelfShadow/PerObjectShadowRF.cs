using System;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[Serializable]
public class Settings
{
  public RenderPassEvent eventType = RenderPassEvent.AfterRenderingShadows;
  public int maxShadowCount = 16;
  public int singleResolution = 1024;
  public DepthBits depthBits = DepthBits.Depth16;
}

public class PerObjectShadowRF : ScriptableRendererFeature
{
  public Settings selfShadowSettings = new Settings();
  public Settings sceneShadowSettings = new Settings();
  private PerObjectShadowPass perObjectSelfShadowPass;
  private PerObjectShadowPass perObjectSceneShadowPass;
  private PerObjectScreenSpaceShadowPass perObjectScreenSpaceShadowPass;

  public override void Create()
  {
    perObjectSceneShadowPass = new PerObjectShadowPass(sceneShadowSettings, false);
    perObjectSceneShadowPass.renderPassEvent = sceneShadowSettings.eventType;
    perObjectSelfShadowPass = new PerObjectShadowPass(selfShadowSettings, true);
    perObjectSelfShadowPass.renderPassEvent = selfShadowSettings.eventType;
    perObjectScreenSpaceShadowPass = new PerObjectScreenSpaceShadowPass();
    perObjectScreenSpaceShadowPass.renderPassEvent = RenderPassEvent.AfterRenderingGbuffer;
  }

  public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
  {
    renderer.EnqueuePass(perObjectSceneShadowPass);
    renderer.EnqueuePass(perObjectSelfShadowPass);
    renderer.EnqueuePass(perObjectScreenSpaceShadowPass);
  }
}