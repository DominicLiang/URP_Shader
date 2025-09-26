using UnityEngine;
using UVector3 = UnityEngine.Vector3;
using UMatrix4x4 = UnityEngine.Matrix4x4;

namespace ComputerGraphics
{
  public class Test : MonoBehaviour
  {
    private void Start()
    {
      // DotTest();
      // MatrixTest();

      // HomeworkOne();
    }

    private void DotTest()
    {
      var v1 = new Vector3(0, 1, 0);
      var v2 = new Vector3(1, 1, 0).Normalized;
      var v3 = new Vector3(1, 0, 0).Normalized;
      var v4 = new Vector3(1, -1, 0).Normalized;
      var v5 = new Vector3(0, -1, 0);

      print(Vector3.DotProduct(v1, v1));
      print(Vector3.DotProduct(v1, v2));
      print(Vector3.DotProduct(v1, v3));
      print(Vector3.DotProduct(v1, v4));
      print(Vector3.DotProduct(v1, v5));
    }

    private void MatrixTest()
    {
      var m1 = Matrix4x4.Zero;
      m1[1, 2] = 3;
      m1[2, 1] = 4;

      var m2 = Matrix4x4.Zero;
      m2[1, 2] = 5;
      m2[2, 1] = 6;

      print(m1 + m2);
      print(m1.Transpose);
      print(m1 * m2);

      // ! 位移
      var v = new Vector4(0, 0, 0, 1);
      var mTranslate = Matrix4x4.SetTranslate(1, 2, 3);
      print(mTranslate * v);

      // ! 旋转
      var v2 = new Vector4(1, 0, 0, 1);
      var mRotateY = Matrix4x4.SetRotateY(90);
      print(mRotateY * v2);

      // ! 缩放
      var v3 = new Vector4(1, 1.5f, 3, 1);
      var mScale = Matrix4x4.SetScale(3, 2, 1);
      print(mScale * v3);
    }

    private void HomeworkOne()
    {
      var v = new Vector4(0, 1, 0, 1);

      var mt = Matrix4x4.SetTranslate(5, 0, 0);
      var mrz = Matrix4x4.SetRotateZ(90);
      var ms = Matrix4x4.SetScale(0.5f, 0.5f, 0.5f);
      var vRes = mt * v;
      vRes = mrz * vRes;
      print(vRes);
      vRes = mrz * v;
      vRes = mt * vRes;
      print(vRes);
      vRes = ms * v;
      print(vRes);

      var umt = UMatrix4x4.Translate(new UVector3(5, 0, 0));
      var umrz = UMatrix4x4.Rotate(Quaternion.AngleAxis(90, new UVector3(0, 0, 1)));
      var ums = UMatrix4x4.Scale(new UVector3(0.5f, 0.5f, 0.5f));
      print(mt * mrz * ms);
      print(umt * umrz * ums);
    }
  }
}
