#if UNITY_EDITOR
using System.Collections.Generic;
using UnityEngine;
using System;
using System.Linq;

/// <summary>
/// 用于处理网格法线并将其存储到切线空间的工具类
/// </summary>
public class SetNormalsInTangent : MonoBehaviour
{
  // 导出网格的新路径
  public string NewMeshPath = "Assets/Toon/Export";

  /// <summary>
  /// 右键菜单项：导出共享法线模型（到切线分量）
  /// </summary>
  [ContextMenu("导出共享法线模型（到切线分量）")]
  void ExportSharedNormalsToTangent()
  {
    ExportSharedNormalsToTangentCo();
  }

  /// <summary>
  /// 导出共享法线到切线分量的核心方法
  /// </summary>
  public void ExportSharedNormalsToTangentCo()
  {
    // 获取Mesh
    Mesh mesh = new Mesh();
    // 优先获取蒙皮网格渲染器的共享网格
    if (GetComponent<SkinnedMeshRenderer>())
    {
      mesh = GetComponent<SkinnedMeshRenderer>().sharedMesh;
    }
    // 如果没有蒙皮网格渲染器，则尝试获取静态网格过滤器的共享网格
    if (GetComponent<MeshFilter>())
    {
      mesh = GetComponent<MeshFilter>().sharedMesh;
    }



    Debug.Log(mesh.name);

    // 处理平滑法线
    SmoothNormals(mesh);

    Debug.Log("Done: All finished!");
  }

  /// <summary>
  /// 计算并处理网格的平滑法线
  /// </summary>
  /// <param name="mesh">要处理的网格</param>
  private void SmoothNormals(Mesh mesh)
  {
    var matrix = mesh.GetBindposes();


    // 获取网格顶点数据
    Vector3[] vertices = mesh.vertices;
    // 获取网格颜色数据
    Color[] colors = mesh.colors;
    // 存储三角形索引的列表
    List<int> indices = new();
    // 存储计算后的法线数据
    Vector3[] normals = new Vector3[vertices.Length];
    // 存储加权法线的字典，键为顶点位置，值为累积的法线向量
    Dictionary<Vector3, Vector3> weightedNormals = new();
    Vector2[] uv = mesh.uv;

    // 一些 MMD 模型有背面顶点，如果整个 Mesh 一起计算平滑法线，正反法线会相互抵消，最后变成零向量
    // 有背面顶点是因为材质、法线和正面的不一样，所以背面顶点和对应的正面顶点不在一个 SubMesh 里
    // 下面，以 SubMesh 为单位分开计算
    for (int subMeshIndex = 0; subMeshIndex < mesh.subMeshCount; subMeshIndex++)
    {
      // 获取指定子网格的索引数据
      mesh.GetIndices(indices, subMeshIndex, applyBaseVertex: true);

      // 遍历当前子网格的所有三角形（每3个索引组成一个三角形）
      for (int i = 0; i <= indices.Count - 3; i += 3)
      {
        // 遍历三角形的3个顶点
        for (int j = 0; j < 3; j++)
        {
          // Unity 中满足左手定则
          // 根据当前顶点索引，确定另外两个顶点的索引偏移量
          (int offset1, int offset2) = j switch
          {
            0 => (1, 2),  // 当前顶点0，另外两个顶点是1和2
            1 => (2, 0),  // 当前顶点1，另外两个顶点是2和0
            2 => (0, 1),  // 当前顶点2，另外两个顶点是0和1
            _ => throw new NotImplementedException(),
          };

          // 获取当前顶点的世界坐标
          Vector3 vertex = vertices[indices[i + j]];
          // 计算从当前顶点到第一个相邻顶点的向量
          Vector3 vec1 = vertices[indices[i + offset1]] - vertex;
          // 计算从当前顶点到第二个相邻顶点的向量
          Vector3 vec2 = vertices[indices[i + offset2]] - vertex;

          // 计算加权法线（考虑角度权重）
          Vector3 smoothNormal = GetWeightedNormal(vec1, vec2);

          // 初始化顶点法线为零向量（如果尚未添加）
          weightedNormals.TryAdd(vertex, Vector3.zero);
          // 累积当前计算的法线到该顶点的法线中
          weightedNormals[vertex] += smoothNormal;
        }
      }

      // 对于当前子网格中的所有唯一顶点，将其累积的法线应用到最终法线数组中
      foreach (int vertexIndex in indices.Distinct())
      {
        Vector3 vertex = vertices[vertexIndex];
        normals[vertexIndex] += weightedNormals[vertex];
      }

      // 清空索引列表和加权法线字典，为下一个子网格做准备
      indices.Clear();
      weightedNormals.Clear();
    }

    // 归一化所有顶点的法线向量并转换为颜色数据
    for (int i = 0; i < normals.Length; i++)
    {
      // 没必要除以所有权重之和，它不会改变方向。直接归一化就行
      normals[i] = normals[i].normalized;
    }

    // 存储处理后的法线数据
    StoreNormals(normals, colors, mesh);
  }

  /// <summary>
  /// 计算带角度权重的法线
  /// </summary>
  /// <param name="vec1">第一个向量</param>
  /// <param name="vec2">第二个向量</param>
  /// <returns>加权后的法线向量</returns>
  private static Vector3 GetWeightedNormal(Vector3 vec1, Vector3 vec2)
  {
    // Vector3 在归一化的时候有做精度限制
    // 模型太小时，直接用 Vector3 算出来会有很多零向量
    // 这里用 double 先放大数倍然后再算
    const double scale = 1e8;

    // 将向量分量放大以提高精度
    double x1 = vec1.x * scale;
    double y1 = vec1.y * scale;
    double z1 = vec1.z * scale;
    // 计算第一个向量的长度
    double len1 = Math.Sqrt(x1 * x1 + y1 * y1 + z1 * z1);

    double x2 = vec2.x * scale;
    double y2 = vec2.y * scale;
    double z2 = vec2.z * scale;
    // 计算第二个向量的长度
    double len2 = Math.Sqrt(x2 * x2 + y2 * y2 + z2 * z2);

    // 计算两个向量的叉积得到法线向量
    double nx = y1 * z2 - z1 * y2;
    double ny = z1 * x2 - x1 * z2;
    double nz = x1 * y2 - y1 * x2;
    // 计算法线向量的长度
    double lenNormal = Math.Sqrt(nx * nx + ny * ny + nz * nz);

    // 计算两个向量之间的夹角
    double angle = Math.Acos((x1 * x2 + y1 * y2 + z1 * z2) / (len1 * len2));

    // 归一化并应用角度权重
    nx = nx * angle / lenNormal;
    ny = ny * angle / lenNormal;
    nz = nz * angle / lenNormal;
    // 返回计算后的法线向量
    return new Vector3((float)nx, (float)ny, (float)nz);
  }

  /// <summary>
  /// 存储处理后的法线数据
  /// </summary>
  /// <param name="newNormals">新的法线数据</param>
  /// <param name="colors">颜色数据</param>
  /// <param name="mesh">网格对象</param>
  private static void StoreNormals(Vector3[] newNormals, Color[] colors, Mesh mesh)
  {
    mesh.SetTangents(Array.ConvertAll(newNormals, n => (Vector4)n));

    mesh.SetUVs(7, newNormals);

    // 上传网格数据到GPU
    // mesh.UploadMeshData(false);
  }
}
#endif