using UnityEngine;

[RequireComponent(typeof(SkinnedMeshRenderer))]
public class PlanarShadow : MonoBehaviour
{
  private SkinnedMeshRenderer smr;
  private Vector3 lastPos;

  private void Awake()
  {
    smr = GetComponent<SkinnedMeshRenderer>();
  }

  private void Update()
  {
    if (transform.position == lastPos) return;
    UpdateShadowCenter();
    lastPos = transform.position;
  }

  public void UpdateShadowCenter()
  {
    if (smr.material == null) return;
    var center = new Vector4(transform.position.x, transform.position.z);
    smr.material.SetVector("_ShadowCenter", center);
  }
}
