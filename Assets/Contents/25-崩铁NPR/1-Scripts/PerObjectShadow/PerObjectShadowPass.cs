using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class PerObjectShadowPass : ScriptableRenderPass
{
  private ShadowManager manager;
  private bool isSelfShadow;

  private RTHandle shadowRT;
  private int maxShadowCount;
  private int singleResolution;
  private int rowAndColCount;
  private DepthBits depthBits;

  private Matrix4x4[] worldToShadowMatrixArray;
  private Vector4[] shadowRectArray;

  // 软阴影参数 - 建议范围 1.0-3.0
  public float softShadowRadius = 1f; // 可调节的软阴影半径

  public PerObjectShadowPass(PerObjectShadowSettings settings, bool isSelfShadow)
  {
    manager = new ShadowManager();
    this.isSelfShadow = isSelfShadow;

    maxShadowCount = settings.maxShadowCount;
    singleResolution = settings.singleResolution;
    depthBits = settings.depthBits;

    worldToShadowMatrixArray = new Matrix4x4[maxShadowCount];
    shadowRectArray = new Vector4[maxShadowCount];
  }

  public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
  {
    manager.Cull(ref renderingData, maxShadowCount, isSelfShadow);

    if (manager.VisibleCount <= 0) return;

    rowAndColCount = Mathf.CeilToInt(Mathf.Sqrt(manager.VisibleCount));
    var rtSize = rowAndColCount * singleResolution;

    ShadowUtils.ShadowRTReAllocateIfNeeded(ref shadowRT, rtSize, rtSize, (int)depthBits);

    ConfigureTarget(shadowRT);
    ConfigureClear(ClearFlag.All, Color.black);
  }

  public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
  {
    if (manager.VisibleCount <= 0) return;

    var cmd = CommandBufferPool.Get();

    using (new ProfilingScope(cmd, new ProfilingSampler(isSelfShadow ? "PerObjectSelfShadow" : "PerObjectSceneShadow")))
    {
      for (int i = 0; i < manager.VisibleCount; i++)
      {
        var result = manager.cullResults[i];

        if (!isSelfShadow)
        {
          var mainLightIndex = renderingData.lightData.mainLightIndex;
          var mainLight = renderingData.lightData.visibleLights[mainLightIndex];
          var shadowBias = ShadowUtils.GetShadowBias(ref mainLight,
                                                         mainLightIndex,
                                                         ref renderingData.shadowData,
                                                         result.projectionMatrix,
                                                         shadowRT.rt.width);
          ShadowUtils.SetupShadowCasterConstantBuffer(cmd, ref mainLight, shadowBias);
        }

        var tilePos = new Vector2Int(i % rowAndColCount, i / rowAndColCount);
        DrawShadow(cmd, tilePos, result, i);
        worldToShadowMatrixArray[i] = GetShadowMatrix(tilePos, result.viewMatrix, result.projectionMatrix);
        shadowRectArray[i] = GetShadowMapRect(tilePos);
      }
      SetShadowSamplingData(cmd);
      cmd.SetGlobalTexture(isSelfShadow ? "_PerObjSelfShadowMap" : "_PerObjSceneShadowMap", shadowRT);
      cmd.SetGlobalMatrixArray(isSelfShadow ? "_PerObjSelfShadowMatrixArray" : "_PerObjSceneShadowMatrixArray", worldToShadowMatrixArray);
      cmd.SetGlobalVectorArray(isSelfShadow ? "_PerObjSelfShadowRectArray" : "_PerObjSceneShadowRectArray", shadowRectArray);
      cmd.SetGlobalInteger("_PerObjShadowCount", manager.VisibleCount);
    }

    context.ExecuteCommandBuffer(cmd);
    cmd.Clear();
    CommandBufferPool.Release(cmd);
  }

  private void DrawShadow(CommandBuffer cmd, Vector2Int tilePos, CullResult result, int index)
  {
    cmd.SetGlobalDepthBias(1.0f, 2.5f); // these values match HDRP defaults (see https://github.com/Unity-Technologies/Graphics/blob/9544b8ed2f98c62803d285096c91b44e9d8cbc47/com.unity.render-pipelines.high-definition/Runtime/Lighting/Shadow/HDShadowAtlas.cs#L197 )

    cmd.SetViewProjectionMatrices(result.viewMatrix, result.projectionMatrix);
    var viewport = new Rect(tilePos.x * singleResolution, tilePos.y * singleResolution, singleResolution, singleResolution);
    cmd.SetViewport(viewport);

    cmd.EnableScissorRect(new Rect(viewport.x + 4, viewport.y + 4, viewport.width - 8, viewport.height - 8));

    Draw(cmd, result, index);

    cmd.DisableScissorRect();
    cmd.SetGlobalDepthBias(0.0f, 0.0f);
  }

  private void Draw(CommandBuffer cmd, CullResult result, int index)
  {
    for (int i = 0; i < result.renderDatas.Count; i++)
    {
      var renderData = result.renderDatas[i];
      var renderer = renderData.renderer;
      for (int j = 0; j < renderData.drawDatas.Count; j++)
      {
        var drawData = renderData.drawDatas[j];
        cmd.DrawRenderer(renderer, drawData.material, drawData.subMeshIndex, drawData.passIndex);
      }
      var indexPropertyBlock = new MaterialPropertyBlock();
      indexPropertyBlock.SetInteger("_PerObjSelfShadowIndex", index);
      renderer.SetPropertyBlock(indexPropertyBlock);
    }
  }

  /// <summary>
  /// 获取阴影矩阵
  /// </summary>
  /// <param name="tilePos"></param>
  /// <param name="viewMatrix"></param>
  /// <param name="projectionMatrix"></param>
  /// <returns></returns>
  private Matrix4x4 GetShadowMatrix(Vector2Int tilePos, in Matrix4x4 viewMatrix, Matrix4x4 projectionMatrix)
  {
    if (SystemInfo.usesReversedZBuffer)
    {
      projectionMatrix.m20 = -projectionMatrix.m20;
      projectionMatrix.m21 = -projectionMatrix.m21;
      projectionMatrix.m22 = -projectionMatrix.m22;
      projectionMatrix.m23 = -projectionMatrix.m23;
    }

    float oneOverTileCount = 1.0f / rowAndColCount;

    Matrix4x4 textureScaleAndBias = Matrix4x4.identity;
    textureScaleAndBias.m00 = 0.5f * oneOverTileCount;
    textureScaleAndBias.m11 = 0.5f * oneOverTileCount;
    textureScaleAndBias.m22 = 0.5f;
    textureScaleAndBias.m03 = (0.5f + tilePos.x) * oneOverTileCount;
    textureScaleAndBias.m13 = (0.5f + tilePos.y) * oneOverTileCount;
    textureScaleAndBias.m23 = 0.5f;

    return textureScaleAndBias * projectionMatrix * viewMatrix;
  }

  /// <summary>
  /// 获取阴影贴图矩形
  /// </summary>
  /// <param name="tilePos"></param>
  /// <returns></returns>
  private Vector4 GetShadowMapRect(Vector2Int tilePos)
  {
    // x: xMin
    // y: xMax
    // z: yMin
    // w: yMax
    return new Vector4(tilePos.x, 1 + tilePos.x, tilePos.y, 1 + tilePos.y) / rowAndColCount;
  }

  /// <summary>
  /// 设置阴影采样数据
  /// </summary>
  /// <param name="cmd"></param>
  private void SetShadowSamplingData(CommandBuffer cmd)
  {
    int renderTargetWidth = shadowRT.rt.width;
    int renderTargetHeight = shadowRT.rt.height;
    float invShadowAtlasWidth = 1.0f / renderTargetWidth;
    float invShadowAtlasHeight = 1.0f / renderTargetHeight;

    // 修正软阴影半径计算，避免重影
    // 原始是0.5个像素，现在使用更合理的范围
    float invHalfShadowAtlasWidth = 0.5f * softShadowRadius * invShadowAtlasWidth;
    float invHalfShadowAtlasHeight = 0.5f * softShadowRadius * invShadowAtlasHeight;

    var offset0 = new Vector4(-invHalfShadowAtlasWidth, -invHalfShadowAtlasHeight, invHalfShadowAtlasWidth, -invHalfShadowAtlasHeight);
    cmd.SetGlobalVector("_PerObjectShadowOffset0", offset0);
    var offset1 = new Vector4(-invHalfShadowAtlasWidth, invHalfShadowAtlasHeight, invHalfShadowAtlasWidth, invHalfShadowAtlasHeight);
    cmd.SetGlobalVector("_PerObjectShadowOffset1", offset1);
    var shadowSize = new Vector4(invShadowAtlasWidth, invShadowAtlasHeight, renderTargetWidth, renderTargetHeight);
    cmd.SetGlobalVector("_PerObjectShadowMapSize", shadowSize);
  }

  public override void OnCameraCleanup(CommandBuffer cmd)
  {
    if (shadowRT == null) return;
    cmd.ReleaseTemporaryRT(shadowRT.GetInstanceID());
  }
}