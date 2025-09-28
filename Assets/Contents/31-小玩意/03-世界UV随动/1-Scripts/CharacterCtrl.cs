using UnityEngine;

[ExecuteAlways]
public class CharacterCtrl : MonoBehaviour
{
  void Update()
  {
    var pos = new Vector4(transform.position.x, transform.position.y, transform.position.z, 1);
    Shader.SetGlobalVector("_CharacterPosition", pos);
    Debug.Log(pos);
  }
}
