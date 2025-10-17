using UnityEngine;

[ExecuteAlways]
public class ShadowCasterController : MonoBehaviour
{
  private Renderer[] renderers;
  public Renderer[] Renderers => renderers;

  [HideInInspector] public Bounds casterBounds;
  [HideInInspector] public Bounds lightSpaceBounds;
  [HideInInspector] public Matrix4x4 shadowViewMatrix;

#if UNITY_EDITOR
  [Header("Gizmos设置")]
  [SerializeField] private bool showCasterBounds = false;
  [SerializeField] private Color casterBoundsColor = Color.red;
  [SerializeField] private bool showLightSpaceBounds = false;
  [SerializeField] private Color lightSpaceBoundsColor = Color.green;
#endif

  private void OnEnable()
  {
    UpdateRenderers();
    ShadowManager.RegisterCaster(this);
  }

  private void OnDisable()
  {
    ShadowManager.UnregisterCaster(this);
  }

  public void UpdateRenderers()
  {
    renderers = GetComponentsInChildren<Renderer>();
  }

#if UNITY_EDITOR
  private void OnDrawGizmos()
  {
    if (renderers == null || renderers.Length == 0)
      return;

    // 绘制原始包围盒（红色）
    if (showCasterBounds)
    {
      DrawCasterBounds(casterBounds);
    }

    // 绘制光空间包围盒
    if (showLightSpaceBounds)
    {
      DrawLightSpaceBounds(lightSpaceBounds, shadowViewMatrix);
    }
  }

  private void DrawCasterBounds(Bounds bounds)
  {
    // 设置Gizmos颜色为红色
    Gizmos.color = casterBoundsColor;

    // 获取包围盒的8个顶点
    Vector3 min = bounds.min;
    Vector3 max = bounds.max;

    Vector3[] corners = new Vector3[8]
    {
      new Vector3(min.x, min.y, min.z), // 0: min corner
      new Vector3(max.x, min.y, min.z), // 1: max x, min y,z
      new Vector3(max.x, max.y, min.z), // 2: max x,y, min z
      new Vector3(min.x, max.y, min.z), // 3: min x, max y, min z
      new Vector3(min.x, min.y, max.z), // 4: min x,y, max z
      new Vector3(max.x, min.y, max.z), // 5: max x,z, min y
      new Vector3(max.x, max.y, max.z), // 6: max corner
      new Vector3(min.x, max.y, max.z)  // 7: min x, max y,z
    };

    // 绘制底面的4条边 (z = min.z)
    Gizmos.DrawLine(corners[0], corners[1]); // min -> max x
    Gizmos.DrawLine(corners[1], corners[2]); // max x -> max x,y
    Gizmos.DrawLine(corners[2], corners[3]); // max x,y -> max y
    Gizmos.DrawLine(corners[3], corners[0]); // max y -> min

    // 绘制顶面的4条边 (z = max.z)
    Gizmos.DrawLine(corners[4], corners[5]); // min xy, max z -> max x,z
    Gizmos.DrawLine(corners[5], corners[6]); // max x,z -> max corner
    Gizmos.DrawLine(corners[6], corners[7]); // max corner -> max y,z
    Gizmos.DrawLine(corners[7], corners[4]); // max y,z -> min xy, max z

    // 绘制连接底面和顶面的4条边
    Gizmos.DrawLine(corners[0], corners[4]); // min -> min xy, max z
    Gizmos.DrawLine(corners[1], corners[5]); // max x -> max x,z
    Gizmos.DrawLine(corners[2], corners[6]); // max x,y -> max corner
    Gizmos.DrawLine(corners[3], corners[7]); // max y -> max y,z
  }

  private void DrawLightSpaceBounds(Bounds lightSpaceBounds, Matrix4x4 shadowViewMatrix)
  {
    // 设置Gizmos颜色
    Gizmos.color = lightSpaceBoundsColor;

    // 计算光空间包围盒的8个顶点
    Vector3 min = lightSpaceBounds.min;
    Vector3 max = lightSpaceBounds.max;

    Vector3[] lightSpaceCorners = new Vector3[8]
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

    // 将光空间顶点转换回世界空间
    Matrix4x4 worldMatrix = shadowViewMatrix.inverse;
    Vector3[] worldCorners = new Vector3[8];

    for (int i = 0; i < 8; i++)
    {
      worldCorners[i] = worldMatrix.MultiplyPoint3x4(lightSpaceCorners[i]);
    }

    // 绘制包围盒的12条边
    // 底面的4条边 (near plane)
    Gizmos.DrawLine(worldCorners[0], worldCorners[1]); // min -> min+z
    Gizmos.DrawLine(worldCorners[1], worldCorners[3]); // min+z -> min+y+z
    Gizmos.DrawLine(worldCorners[3], worldCorners[2]); // min+y+z -> min+y
    Gizmos.DrawLine(worldCorners[2], worldCorners[0]); // min+y -> min

    // 顶面的4条边 (far plane)
    Gizmos.DrawLine(worldCorners[4], worldCorners[5]); // max-y-z -> max-y
    Gizmos.DrawLine(worldCorners[5], worldCorners[7]); // max-y -> max
    Gizmos.DrawLine(worldCorners[7], worldCorners[6]); // max -> max-z
    Gizmos.DrawLine(worldCorners[6], worldCorners[4]); // max-z -> max-y-z

    // 连接底面和顶面的4条边
    Gizmos.DrawLine(worldCorners[0], worldCorners[4]); // min -> max-y-z
    Gizmos.DrawLine(worldCorners[1], worldCorners[5]); // min+z -> max-y
    Gizmos.DrawLine(worldCorners[2], worldCorners[6]); // min+y -> max-z
    Gizmos.DrawLine(worldCorners[3], worldCorners[7]); // min+y+z -> max
  }
#endif
}