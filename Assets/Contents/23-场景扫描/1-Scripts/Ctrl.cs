using System.Collections;
using UnityEngine;

public class Ctrl : MonoBehaviour
{
  [Range(0, 2000)]
  public float anim = 0;

  void Update()
  {
    if (Input.GetKeyDown(KeyCode.Space))
    {

      StartCoroutine(Animation());

      IEnumerator Animation()
      {
        anim = 0;
        while (anim < 2000)
        {
          if (anim < 30)
          {
            anim += 0.1f;
          }
          else if (anim < 50)
          {
            anim += 2f;
          }
          else if (anim < 100)
          {
            anim += 5f;
          }
          else
          {
            anim += 10f;
          }
          Debug.Log(anim);
          Shader.SetGlobalVector("_Center", new Vector3(136.9f, 0, 126.57f));
          Shader.SetGlobalFloat("_Threshold", anim);
          yield return new WaitForSeconds(0.01f);
        }
      }
    }



  }
}
