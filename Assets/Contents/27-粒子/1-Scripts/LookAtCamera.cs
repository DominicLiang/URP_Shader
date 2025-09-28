#if UNITY_EDITOR
using UnityEditor;
#endif
using UnityEngine;

[ExecuteInEditMode]
public class LookAtCamera : MonoBehaviour
{
  // Start is called once before the first execution of Update after the MonoBehaviour is created
  void Start()
  {

  }

  void Update()
  {
    Camera targetCamera = Camera.main;

    // 在编辑器中尝试获取场景摄像机
#if UNITY_EDITOR
    if (SceneView.lastActiveSceneView != null)
    {
      targetCamera = SceneView.lastActiveSceneView.camera;
    }
#endif

    if (targetCamera == null) return;

    transform.LookAt(-targetCamera.transform.position);
  }
}
