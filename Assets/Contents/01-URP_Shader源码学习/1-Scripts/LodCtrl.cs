using UnityEngine;

namespace WriteShader
{
  public class LodCtrl : MonoBehaviour
  {
    public bool switcher;
    public int lodLevel = 200;

    private void OnValidate()
    {
      if (!switcher) return;

      Shader.globalMaximumLOD = lodLevel;
    }
  }
}
