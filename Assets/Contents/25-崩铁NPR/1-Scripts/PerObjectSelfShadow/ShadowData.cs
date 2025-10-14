using System.Collections.Generic;
using UnityEngine;

/// <summary>
/// 剔除结果 每一个Caster对应一个CullResult
/// </summary>
public struct CullResult
{
  public float priority;
  public Matrix4x4 viewMatrix;
  public Matrix4x4 projectionMatrix;
  public List<RenderData> renderDatas;
}

/// <summary>
/// 渲染数据
/// </summary>
public struct RenderData
{
  public Renderer renderer;
  public List<DrawData> drawDatas;
}

/// <summary>
/// 绘制数据
/// </summary>
public struct DrawData
{
  public Material material;
  public int subMeshIndex;
  public int passIndex;
}