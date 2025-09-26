using UnityEngine;

namespace ComputerGraphics
{
  public class ShowPosition : MonoBehaviour
  {
    public Matrix4x4 m;

    private void Awake()
    {
      // Test();
    }

    private void Test()
    {
      print(transform.position);

      var mrx = Matrix4x4.SetRotateX(30);
      var mry = Matrix4x4.SetRotateY(90);
      var mrz = Matrix4x4.SetRotateZ(45);

      var m = mry * mrx * mrz;
      var v = new Vector4(0, 5, 0, 1);
      print(m * v);
      this.m = m;

      var mm = Matrix4x4.Identity;
      var x = 30 * Mathf.Deg2Rad;
      var y = 90 * Mathf.Deg2Rad;
      var z = 45 * Mathf.Deg2Rad;
      mm[0, 0] = -Mathf.Cos(y) * Mathf.Cos(z) + Mathf.Sin(x) * Mathf.Sin(y) * Mathf.Sin(z);
      mm[0, 1] = Mathf.Cos(y) * Mathf.Sin(z) + Mathf.Sin(x) * Mathf.Sin(y) * Mathf.Cos(z);
      mm[0, 2] = Mathf.Cos(x) * Mathf.Sin(y);
      mm[1, 0] = Mathf.Cos(x) * Mathf.Sin(z);
      mm[1, 1] = Mathf.Cos(x) * Mathf.Cos(z);
      mm[1, 2] = -Mathf.Sin(x);
      mm[2, 0] = -Mathf.Sin(y) * Mathf.Cos(z) - Mathf.Sin(x) * Mathf.Cos(y) * Mathf.Sin(z);
      mm[2, 1] = Mathf.Sin(y) * Mathf.Sin(z) - Mathf.Sin(x) * Mathf.Cos(y) * Mathf.Cos(z);
      mm[2, 2] = Mathf.Cos(x) * Mathf.Cos(y);
      print(mm * v);
    }
  }
}
