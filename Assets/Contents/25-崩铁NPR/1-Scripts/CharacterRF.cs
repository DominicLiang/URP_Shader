using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[Serializable]
public class PerObjectShadowSettings
{
  public RenderPassEvent eventType = RenderPassEvent.AfterRenderingShadows;
  public int maxShadowCount = 16;
  public int singleResolution = 1024;
  public DepthBits depthBits = DepthBits.Depth16;
}

[Serializable]
public class HairShadowSettings
{
  public Color shadowColor;
  public float offset;
}

public class CharacterRF : ScriptableRendererFeature
{
  public PerObjectShadowSettings selfShadowSettings = new PerObjectShadowSettings();
  public PerObjectShadowSettings sceneShadowSettings = new PerObjectShadowSettings();
  public HairShadowSettings hairShadowSettings = new HairShadowSettings();

  private PerObjectShadowPass perObjectSelfShadowPass;
  private PerObjectShadowPass perObjectSceneShadowPass;
  private PerObjectScreenSpaceShadowPass perObjectScreenSpaceShadowPass;
  private HairShadowPass hairShadowPass;

  public override void Create()
  {
    perObjectSceneShadowPass = new PerObjectShadowPass(sceneShadowSettings, false);
    perObjectSceneShadowPass.renderPassEvent = sceneShadowSettings.eventType;
    perObjectSelfShadowPass = new PerObjectShadowPass(selfShadowSettings, true);
    perObjectSelfShadowPass.renderPassEvent = selfShadowSettings.eventType;
    perObjectScreenSpaceShadowPass = new PerObjectScreenSpaceShadowPass();
    perObjectScreenSpaceShadowPass.renderPassEvent = RenderPassEvent.BeforeRenderingOpaques;
    hairShadowPass = new HairShadowPass(hairShadowSettings);
    hairShadowPass.renderPassEvent = RenderPassEvent.AfterRenderingOpaques;
  }

  public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
  {
    renderer.EnqueuePass(perObjectSceneShadowPass);
    renderer.EnqueuePass(perObjectSelfShadowPass);
    renderer.EnqueuePass(perObjectScreenSpaceShadowPass);
    renderer.EnqueuePass(hairShadowPass);
  }
}