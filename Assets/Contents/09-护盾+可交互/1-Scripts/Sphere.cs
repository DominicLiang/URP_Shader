using System.Collections;
using UnityEngine;

public class Sphere : MonoBehaviour
{
  private Material material;

  private void Awake()
  {
    material = GetComponent<MeshRenderer>().material;
  }

  private void Update()
  {
    if (Input.GetMouseButtonDown(0))
    {
      var ray = Camera.main.ScreenPointToRay(Input.mousePosition);

      if (Physics.Raycast(ray, out var hit))
      {
        Debug.Log(hit.point);
        material.SetVector("_HitCenter", new Vector4(hit.point.x, hit.point.y, hit.point.z, 1));

        var startTime = Time.time;
        float alpha = 1;
        float t = 0;

        StartCoroutine(Anim());

        IEnumerator Anim()
        {
          while (true)
          {
            if (Time.time - startTime > 0.5) break;
            yield return new WaitForSeconds(0.01f);
            float alphaStep = 1f / 35;
            float tStep = 0.1f / 35;
            alpha = Mathf.Max(0, alpha - alphaStep);
            t = Mathf.Min(0.3f, t + tStep);
            material.SetFloat("_EdgeAlpha2", alpha);
            material.SetFloat("_Threshold", t);
          }
        }
      }
    }
  }
}
