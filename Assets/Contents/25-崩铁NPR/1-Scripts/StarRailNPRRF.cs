using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class StarRailNPRRF : ScriptableRendererFeature
{
  class CustomRenderPass : ScriptableRenderPass
  {
    private LayerMask hairLayerMask;
    private Material hairShadowOverrideMat;
    private Color hairShadowColor;
    private float offset;

    public CustomRenderPass(Material hairShadowOverrideMat, Color hairShadowColor, float offset, LayerMask hairLayerMask)
    {
      this.hairShadowOverrideMat = hairShadowOverrideMat;
      this.hairShadowColor = hairShadowColor;
      this.offset = offset;
      this.hairLayerMask = hairLayerMask;
    }


    public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
    {
    }


    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
      // var visibleLight = renderingData.cullResults.visibleLights[0];
      // Vector2 lightDirSS = renderingData.cameraData.camera.worldToCameraMatrix * visibleLight.localToWorldMatrix.GetColumn(2);
      // hairShadowOverrideMat.SetVector("_LightDirSS", lightDirSS);
      hairShadowOverrideMat.SetColor("_Color", hairShadowColor);
      hairShadowOverrideMat.SetFloat("_Offset", offset);

      CommandBuffer cmd = CommandBufferPool.Get();
      using (new ProfilingScope(cmd, new ProfilingSampler("StarRailNPRRF")))
      {
        var filtering = new FilteringSettings(RenderQueueRange.opaque, hairLayerMask);
        var drawSettings = CreateDrawingSettings(new ShaderTagId("UniversalForward"),
                                                 ref renderingData,
                                                 renderingData.cameraData.defaultOpaqueSortFlags);
        drawSettings.overrideMaterial = hairShadowOverrideMat;
        drawSettings.overrideMaterialPassIndex = 0;

        context.DrawRenderers(renderingData.cullResults, ref drawSettings, ref filtering);
      }
      context.ExecuteCommandBuffer(cmd);
      cmd.Clear();
      CommandBufferPool.Release(cmd);
    }

    public override void OnCameraCleanup(CommandBuffer cmd)
    {
    }
  }

  public LayerMask hairLayerMask;
  public Material hairShadowOverrideMat;
  public Color hairShadowColor = Color.black;
  public float offset = 0.02f;

  private CustomRenderPass m_ScriptablePass;

  public override void Create()
  {
    m_ScriptablePass = new CustomRenderPass(hairShadowOverrideMat, hairShadowColor, offset, hairLayerMask);

    m_ScriptablePass.renderPassEvent = RenderPassEvent.AfterRenderingOpaques;
  }

  public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
  {
    if (hairShadowOverrideMat == null) return;
    renderer.EnqueuePass(m_ScriptablePass);
  }
}
