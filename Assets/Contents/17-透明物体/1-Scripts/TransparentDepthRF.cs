using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class TransparentDepthRF : ScriptableRendererFeature
{
  class TransparentDepthPass : ScriptableRenderPass
  {
    private RTHandle cameraDepthRT;
    private RTHandle customRT;

    /// <summary>
    /// * 1.获取目标(颜色/深度) 
    /// * 2.申请RT
    /// * 3.设置目标 初始化
    /// </summary>
    /// <param name="cmd"></param>
    /// <param name="renderingData"></param>
    public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
    {
      // * 1.获取目标(颜色/深度) 
      // ! 设置深度目标 获取相机的深度rt
      cameraDepthRT = renderingData.cameraData.renderer.cameraDepthTargetHandle;

      // * 2.申请RT 看情况申请 这里直接渲染的摄像机深度图 不需要RT
      // var downSampleScale = 0.5f;
      // RenderTextureDescriptor desc = renderingData.cameraData.cameraTargetDescriptor;
      // desc.depthBufferBits = 32;
      // desc.width = Mathf.RoundToInt(desc.width * downSampleScale);
      // desc.height = Mathf.RoundToInt(desc.height * downSampleScale);
      // RenderingUtils.ReAllocateIfNeeded(ref customRT, desc, wrapMode: TextureWrapMode.Clamp);

      // * 3.设置目标 初始化 它主要用于 Unity 内部的渲染状态管理和优化
      ConfigureTarget(cameraDepthRT);
      ConfigureClear(ClearFlag.Depth, Color.black);
    }

    /// <summary>
    /// * 1. 从commandBuffer池获取一个commandBuffer
    /// * 2. using(new ProfilingScope) 包裹
    /// * 3. 设置目标 初始化 真正改变硬件渲染目标
    /// * 4. 渲染
    /// * 5. 提交绘制
    /// </summary>
    /// <param name="context"></param>
    /// <param name="renderingData"></param>
    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
      // * 1. 从commandBuffer池获取一个commandBuffer
      CommandBuffer cmd = CommandBufferPool.Get("Transparent Depth Pass");

      // * 2. using(new ProfilingScope) 包裹
      using (new ProfilingScope(cmd, new ProfilingSampler("Transparent Depth Pass")))
      {
        // * 3. 设置目标 初始化 真正改变硬件渲染目标
        cmd.SetRenderTarget(cameraDepthRT);

        // * 4. 渲染

        // * 第一次执行CommandBuffer 清除深度缓冲
        cmd.ClearRenderTarget(true, false, Color.black);
        context.ExecuteCommandBuffer(cmd);
        cmd.Clear();

        // * 4.1 渲染指定的Pass指定队列还可以指定layerMask
        // * 只筛选 LightMode 为 TransparentDepth 的 Pass
        var drawingSettings = CreateDrawingSettings(new ShaderTagId("TransparentDepth"),
                                                    ref renderingData,
                                                    renderingData.cameraData.defaultOpaqueSortFlags);

        // * 为物体使用覆盖材质
        // drawingSettings.overrideMaterial= material;

        // * 只筛选透明队列的物体
        var m_FilteringSettings = new FilteringSettings(RenderQueueRange.transparent);

        // * 绘制指定物体
        context.DrawRenderers(renderingData.cullResults, ref drawingSettings, ref m_FilteringSettings);


      }

      // * 5. 提交绘制
      context.ExecuteCommandBuffer(cmd);
      cmd.Clear();
      CommandBufferPool.Release(cmd);
    }

    /// <summary>
    /// * 释放
    /// </summary>
    /// <param name="cmd"></param>
    public override void OnCameraCleanup(CommandBuffer cmd)
    {
      // cmd.ReleaseTemporaryRT(customRT.GetInstanceID());
    }
  }

  TransparentDepthPass m_ScriptablePass;

  public override void Create()
  {
    m_ScriptablePass = new TransparentDepthPass();
    m_ScriptablePass.renderPassEvent = RenderPassEvent.BeforeRenderingTransparents;
  }

  public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
  {
    // 只在非Scene视图的相机上执行
    if (!renderingData.cameraData.isSceneViewCamera)
    {

    }

    renderer.EnqueuePass(m_ScriptablePass);
  }
}