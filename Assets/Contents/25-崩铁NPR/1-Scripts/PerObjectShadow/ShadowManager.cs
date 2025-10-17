using System.Collections.Generic;
using Unity.Mathematics;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class ShadowManager
{
  private static List<ShadowCasterController> casters;
  public List<CullResult> cullResults;

  public int VisibleCount => cullResults.Count;

  public ShadowManager()
  {
    cullResults = new List<CullResult>();
  }

  public static void RegisterCaster(ShadowCasterController casterController)
  {
    casters ??= new List<ShadowCasterController>();
    casters.Add(casterController);

  }

  public static void UnregisterCaster(ShadowCasterController casterController)
  {
    if (casters == null) return;
    casters.Remove(casterController);
  }

  private static readonly float4x4 flipZMatrix = new(
    1, 0, 0, 0,
    0, 1, 0, 0,
    0, 0, -1, 0,
    0, 0, 0, 1
  );

  public void Cull(ref RenderingData renderingData, int maxShadowCount, bool isSelfShadow)
  {
    cullResults.Clear();
    if (casters == null || casters.Count <= 0) return;
    if (renderingData.lightData.visibleLights.Length <= 0) return;

    // 相机数据
    var camera = renderingData.cameraData.camera;
    var frustumPlanes = GeometryUtility.CalculateFrustumPlanes(camera);

    // 灯光数据
    var mainLightIndex = renderingData.lightData.mainLightIndex;
    var mainLight = renderingData.lightData.visibleLights[mainLightIndex];
    mainLight.lightType = LightType.Directional;

    for (int i = 0; i < Mathf.Min(maxShadowCount, casters.Count); i++)
    {
      var caster = casters[i];

      if (!caster.isActiveAndEnabled) continue;


      var renderers = caster.Renderers;

      if (!TryGetCasterBounds(caster, out var casterBounds)) continue;
      caster.casterBounds = casterBounds; // Debug数据

      // 剔除掉不在相机视锥内的caster
      if (!GeometryUtility.TestPlanesAABB(frustumPlanes, casterBounds)) continue;

      var center = casterBounds.center;

      var lightRotation = GetLightRotation(camera,
                                           ref mainLight,
                                           caster,
                                           center,
                                           isSelfShadow);

      var shadowViewMatrix = GetViewMatrix(lightRotation, center);
      var shadowProjectionMatrix = GetProjectionMatrix(casterBounds,
                                                       shadowViewMatrix,
                                                       isSelfShadow,
                                                       out var lightSpaceBounds);

      caster.lightSpaceBounds = lightSpaceBounds; // Debug数据
      caster.shadowViewMatrix = shadowViewMatrix; // Debug数据

      var renderDatas = GetRenderDatas(renderers);

      var distance = Vector3.Distance(camera.transform.position, center);
      var cameraForward = math.normalizesafe(camera.transform.forward);
      var priority = distance * (math.dot(center - camera.transform.position, cameraForward) * 0.5f + 0.5f);

      cullResults.Add(new CullResult
      {
        priority = priority,
        renderDatas = renderDatas,
        viewMatrix = shadowViewMatrix,
        projectionMatrix = shadowProjectionMatrix
      });
    }

    cullResults.Sort((a, b) => a.priority.CompareTo(b.priority));
  }

  private static quaternion GetLightRotation(Camera camera, ref VisibleLight mainLight, ShadowCasterController caster, Vector3 center, bool isSelfShadow)
  {
    if (isSelfShadow)
    {
      var cameraPosition = camera.transform.position + new Vector3(0, 0.2f, 0);
      var cameraUp = camera.transform.up;
      var viewForward = math.normalizesafe(center - cameraPosition);
      var lightForward = ((float4x4)mainLight.localToWorldMatrix).c2.xyz;
      var forward = math.normalize(math.lerp(viewForward, lightForward, 0.15f));
      var casterUp = (float3)caster.transform.up;
      float cosAngle = math.dot(forward, casterUp);
      float cosAngleClamped = math.clamp(cosAngle, -0.866f, 0); // 限制在 90° ~ 150° 之间
      forward = math.normalize(forward + (cosAngleClamped - cosAngle) * casterUp);
      var lightRotation = quaternion.LookRotation(forward, cameraUp);
      return lightRotation;
    }
    else
    {
      return math.quaternion(mainLight.localToWorldMatrix);
    }
  }

  /// <summary>
  /// 获取渲染数据
  /// </summary>
  /// <param name="renderers"></param>
  /// <returns></returns>
  private List<RenderData> GetRenderDatas(Renderer[] renderers)
  {
    var renderDatas = new List<RenderData>();
    for (int j = 0; j < renderers.Length; j++)
    {
      var renderer = renderers[j];
      var renderData = new RenderData();
      renderData.renderer = renderer;

      var drawDatas = new List<DrawData>();
      renderData.drawDatas = drawDatas;

      var materials = new List<Material>();
      renderer.GetSharedMaterials(materials);
      for (int k = 0; k < materials.Count; k++)
      {
        var material = materials[k];
        var shadowPassIndex = GetShadowPassIndex(material);
        if (shadowPassIndex == -1) continue;
        var drawData = new DrawData();
        drawData.material = material;
        drawData.subMeshIndex = k;
        drawData.passIndex = shadowPassIndex;
        drawDatas.Add(drawData);
      }
      renderDatas.Add(renderData);
    }

    return renderDatas;
  }

  /// <summary>
  /// 获取阴影pass索引 
  /// </summary>
  /// <param name="material"></param>
  /// <returns></returns>
  private int GetShadowPassIndex(Material material)
  {
    var shader = material.shader;
    for (int i = 0; i < shader.passCount; i++)
    {
      var lightMode = new ShaderTagId("LightMode");
      var shadowLightMode = new ShaderTagId("PerObjectSelfShadowCaster");
      if (shader.FindPassTagValue(i, lightMode) == shadowLightMode)
      {
        return i;
      }
    }
    return -1;
  }

  /// <summary>
  /// 获取整个Caster的包围盒
  /// </summary>
  /// <param name="caster"></param>
  /// <param name="casterBounds"></param>
  /// <returns></returns>
  private bool TryGetCasterBounds(ShadowCasterController caster, out Bounds casterBounds)
  {
    var renderers = caster.Renderers;
    casterBounds = default;

    for (int i = 0; i < renderers.Length; i++)
    {
      var bounds = renderers[i].bounds;
      if (i == 0)
      {
        casterBounds = bounds;
      }
      else
      {
        casterBounds.Encapsulate(bounds);
      }

    }
    return casterBounds != default;
  }

  /// <summary>
  /// 获取视图矩阵
  /// </summary>
  /// <param name="lightRotation"></param>
  /// <param name="center"></param>
  /// <returns></returns>
  private Matrix4x4 GetViewMatrix(quaternion lightRotation, Vector3 center)
  {
    var shadowViewMatrix = math.inverse(float4x4.TRS(center, lightRotation, 1));
    shadowViewMatrix = math.mul(flipZMatrix, shadowViewMatrix);
    return shadowViewMatrix;
  }

  /// <summary>
  /// 获取投影矩阵
  /// </summary>
  /// <param name="casterBounds"></param>
  /// <param name="shadowViewMatrix"></param>
  /// <returns></returns>
  private Matrix4x4 GetProjectionMatrix(Bounds casterBounds, Matrix4x4 shadowViewMatrix, bool isSelfShadow, out Bounds lightSpaceBounds)
  {
    lightSpaceBounds = TransformBoundsToLightSpace(casterBounds, shadowViewMatrix, isSelfShadow);

    float width = lightSpaceBounds.max.x * 2;
    float height = lightSpaceBounds.max.y * 2;
    float zNear = -lightSpaceBounds.max.z;
    float zFar = -lightSpaceBounds.min.z;

    Matrix4x4 shadowProjectionMatrix = float4x4.Ortho(width, height, zNear, zFar);
    return shadowProjectionMatrix;
  }

  /// <summary>
  /// 将包围盒转换到光空间
  /// </summary>
  /// <param name="worldBounds"></param>
  /// <param name="viewMatrix"></param>
  /// <returns></returns>
  private Bounds TransformBoundsToLightSpace(Bounds worldBounds, Matrix4x4 viewMatrix, bool isSelfShadow)
  {
    var min = worldBounds.min;
    var max = worldBounds.max;

    // 获取包围盒的8个顶点
    var corners = new Vector3[8]
    {
      new Vector3(min.x, min.y, min.z),
      new Vector3(min.x, min.y, max.z),
      new Vector3(min.x, max.y, min.z),
      new Vector3(min.x, max.y, max.z),
      new Vector3(max.x, min.y, min.z),
      new Vector3(max.x, min.y, max.z),
      new Vector3(max.x, max.y, min.z),
      new Vector3(max.x, max.y, max.z)
    };

    // 将所有顶点转换到光空间
    var lightSpaceBounds = new Bounds();
    var first = true;

    for (int i = 0; i < corners.Length; i++)
    {
      var lightSpacePoint = viewMatrix.MultiplyPoint3x4(corners[i]);

      if (first)
      {
        lightSpaceBounds = new Bounds(lightSpacePoint, Vector3.zero);
        first = false;
      }
      else
      {
        lightSpaceBounds.Encapsulate(lightSpacePoint);
      }
    }

    if (!isSelfShadow)
    {
      // 缩放包围盒
      var z = math.min(lightSpaceBounds.min.z, lightSpaceBounds.min.z - 10);
      lightSpaceBounds.min = new Vector3(lightSpaceBounds.min.x, lightSpaceBounds.min.y, z);
    }

    return lightSpaceBounds;
  }
}