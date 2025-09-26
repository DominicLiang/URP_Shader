using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class VolumeLightRF : ScriptableRendererFeature
{
  class VolumeLightPass : ScriptableRenderPass
  {
    private float downSampleScale;
    private int iteration;
    private float intensity;
    private RTHandle cameraColorRT;
    private RTHandle occlusionRT;
    private Material occlusionMat;
    private Material volumeLightMat;
    private readonly List<ShaderTagId> shaderTagIdList = new List<ShaderTagId>();


    public VolumeLightPass(float downSampleScale, int iteration, float intensity)
    {
      this.downSampleScale = downSampleScale;
      this.iteration = iteration;
      this.intensity = intensity;

      shaderTagIdList.Add(new ShaderTagId("UniversalForward"));
    }


    public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
    {
      occlusionMat = new Material(Shader.Find("Custom/Normal/UnlitColor"));
      volumeLightMat = new Material(Shader.Find("Custom/FullScreen/VolumeLight"));

      cameraColorRT = renderingData.cameraData.renderer.cameraColorTargetHandle;
      var desc = renderingData.cameraData.cameraTargetDescriptor;
      desc.depthBufferBits = 0;
      desc.width = Mathf.RoundToInt(desc.width * downSampleScale);
      desc.height = Mathf.RoundToInt(desc.height * downSampleScale);
      RenderingUtils.ReAllocateIfNeeded(ref occlusionRT, desc, name: "OcclusionRT");
      ConfigureTarget(occlusionRT);
    }


    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
      var cmd = CommandBufferPool.Get();

      using (new ProfilingScope(cmd, new ProfilingSampler("Occlusion Pass")))
      {
        cmd.SetRenderTarget(occlusionRT);
        // context.ExecuteCommandBuffer(cmd);
        // cmd.Clear();

        // * 渲染天空盒
        var camera = renderingData.cameraData.camera;
        context.DrawSkybox(camera);

        // * 将不透明物体全部用黑色渲染到RT
        var drawing = CreateDrawingSettings(shaderTagIdList,
        ref renderingData, SortingCriteria.CommonOpaque);
        drawing.overrideMaterial = occlusionMat;
        var filtering = new FilteringSettings(renderQueueRange: RenderQueueRange.opaque);
        context.DrawRenderers(renderingData.cullResults, ref drawing, ref filtering);

        // * 计算径向模糊的中心位置
        var sunDirectionWorldSpace = RenderSettings.sun.transform.forward;
        var cameraPositionWorldSpace = camera.transform.position;
        var sunPositionWorldSpace = cameraPositionWorldSpace + sunDirectionWorldSpace;
        var sunPositionViewportSpace = camera.WorldToViewportPoint(sunPositionWorldSpace);
        var center = new Vector2(sunPositionViewportSpace.x, sunPositionViewportSpace.y);

        // * 径向模糊材质赋值
        volumeLightMat.SetVector("_Center", center);
        volumeLightMat.SetFloat("_Iteration", iteration);
        volumeLightMat.SetFloat("_Intensity", intensity);

        // * Blit 到屏幕 用blend one one
        Blitter.BlitCameraTexture(cmd, occlusionRT, cameraColorRT, volumeLightMat, 0);
        // cmd.Blit(occlusionRT, cameraColorRT, volumeLightMat);
      }
      context.ExecuteCommandBuffer(cmd);
      cmd.Clear();
      CommandBufferPool.Release(cmd);
    }

    public override void OnCameraCleanup(CommandBuffer cmd)
    {
      cmd.ReleaseTemporaryRT(occlusionRT.GetInstanceID());
    }
  }

  public float downSampleScale;
  public int iteration;
  public float intensity;

  VolumeLightPass volumeLightPass;

  public override void Create()
  {
    volumeLightPass = new VolumeLightPass(downSampleScale, iteration, intensity);

    volumeLightPass.renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;
  }

  public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
  {
    renderer.EnqueuePass(volumeLightPass);
  }
}


