using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class HairShadowPass : ScriptableRenderPass
{
  private RTHandle hairShadowRT;
  private Material faceStencilMaterial;
  private Material hairShadowMaterial;

  private Color shadowColor;
  private float offset;

  public HairShadowPass(HairShadowSettings hairShadowSettings)
  {
    shadowColor = hairShadowSettings.shadowColor;
    offset = hairShadowSettings.offset;
  }

  public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
  {
    if (hairShadowMaterial == null)
    {
      hairShadowMaterial = new Material(Shader.Find("Hidden/HairShadow"));
    }
    hairShadowMaterial.SetColor("_ShadowColor", shadowColor);
    hairShadowMaterial.SetFloat("_Offset", offset);
  }

  public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
  {
    var cmd = CommandBufferPool.Get();
    using (new ProfilingScope(cmd, new ProfilingSampler("HairShadowPass")))
    {
      context.ExecuteCommandBuffer(cmd);
      cmd.Clear();

      var drawingSettings = CreateDrawingSettings(new ShaderTagId("UniversalForward"), ref renderingData, SortingCriteria.CommonOpaque);
      drawingSettings.overrideMaterial = hairShadowMaterial;
      var filteringSettings = new FilteringSettings(RenderQueueRange.opaque, LayerMask.GetMask("Hair"));
      context.DrawRenderers(renderingData.cullResults, ref drawingSettings, ref filteringSettings);
    }
    context.ExecuteCommandBuffer(cmd);
    CommandBufferPool.Release(cmd);
  }

  public override void OnCameraCleanup(CommandBuffer cmd)
  {
    if (hairShadowRT == null) return;
    cmd.ReleaseTemporaryRT(hairShadowRT.GetInstanceID());
  }
}