using UnityEngine;
using UnityEngine.Rendering;

[ExecuteInEditMode]
public class PlanarReflection : MonoBehaviour
{
  private Camera reflectCam;

  public Vector3 T = Vector3.zero;
  public Vector3 R = Vector3.zero;
  public Vector3 S = new(1, -1, 1);

  [SerializeField] private RenderTexture reflectRT;

  private void Start()
  {
    var reflectCamObj = GameObject.Find("ReflectionCamera");
    if (reflectCamObj != null)
    {
      reflectCam = reflectCamObj.GetComponent<Camera>();
    }
    else
    {
      var go = new GameObject("ReflectionCamera", new[] { typeof(Camera) });
      go.transform.parent = transform;
      reflectCam = go.GetComponent<Camera>();
    }

    reflectRT = RenderTexture.GetTemporary(Screen.width, Screen.height, 0);
    reflectRT.name = "ReflectRT";
    reflectRT.SetGlobalShaderProperty("_ReflectRT");

    RenderPipelineManager.beginCameraRendering += OnBeginCameraRendering;
  }

  private void OnBeginCameraRendering(ScriptableRenderContext context, Camera camera)
  {
    if (camera != reflectCam)
    {
      GL.invertCulling = false;
    }
    else
    {
      // 初始化相机
      reflectCam.CopyFrom(Camera.main); // 相机参数拷贝工作应该每帧执行

      reflectCam.clearFlags = CameraClearFlags.Color;
      reflectCam.backgroundColor = Color.clear;
      reflectCam.cullingMask = ~(LayerMask.GetMask("NonReflectable") | LayerMask.GetMask("P")); // 排除NonReflectable // ! ~号取反
      GL.invertCulling = true; // 反射相机渲染的是物体表面的背面, 所以要开启反向剔除

      // 相机变换矩阵
      reflectCam.worldToCameraMatrix = Camera.main.worldToCameraMatrix * Matrix4x4.TRS(T, Quaternion.Euler(R), S);

      // ! 不能在start设置rt 因为reflectCam.CopyFrom(Camera.main)会覆盖掉start的设置 所有反射相机的初始化必须在复制设置之后
      reflectCam.targetTexture = reflectRT;
    }
  }

  private void OnDisable()
  {
    if (reflectRT != null) reflectRT.Release();
  }
}
