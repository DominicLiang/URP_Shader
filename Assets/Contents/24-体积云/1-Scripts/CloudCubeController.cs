using UnityEngine;

public class CloudCubeController : MonoBehaviour
{
    private BoxCollider boxCollider;
    private MeshRenderer meshRenderer;

    private void Awake()
    {
        Init();
        SetValue();
    }

    private void OnValidate()
    {
        Init();
        SetValue();
    }

    private void Init()
    {
        boxCollider = GetComponent<BoxCollider>();
        meshRenderer = GetComponent<MeshRenderer>();
    }

    private void SetValue()
    {
        var min = new Vector4(boxCollider.bounds.min.x, boxCollider.bounds.min.y, boxCollider.bounds.min.z);
        var max = new Vector4(boxCollider.bounds.max.x, boxCollider.bounds.max.y, boxCollider.bounds.max.z);
        meshRenderer.sharedMaterial.SetVector("_BoundsMin", min);
        meshRenderer.sharedMaterial.SetVector("_BoundsMax", max);
    }
}