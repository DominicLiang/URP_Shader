using UnityEngine;

namespace ComputerGraphics
{
  public class ShowPositionOutside : MonoBehaviour
  {
    public ShowPosition s;

    private void Start()
    {
      // Test();
    }

    private void Test()
    {
      var m = s.m;
      var q = MatrixToQuaternion(m);
      // transform.rotation = q;
      Vector3 euler = QuaternionToEulerAngles(q);
      Debug.Log($"欧拉角（度）: {euler}");
    }

    // ! 旋转矩阵反推四元数
    Quaternion MatrixToQuaternion(Matrix4x4 m)
    {
      float trace = m[0, 0] + m[1, 1] + m[2, 2];
      float qw, qx, qy, qz;
      if (trace > 0)
      {
        float s = Mathf.Sqrt(trace + 1.0f) * 2f;
        qw = 0.25f * s;
        qx = (m[2, 1] - m[1, 2]) / s;
        qy = (m[0, 2] - m[2, 0]) / s;
        qz = (m[1, 0] - m[0, 1]) / s;
      }
      else if ((m[0, 0] > m[1, 1]) && (m[0, 0] > m[2, 2]))
      {
        float s = Mathf.Sqrt(1.0f + m[0, 0] - m[1, 1] - m[2, 2]) * 2f;
        qw = (m[2, 1] - m[1, 2]) / s;
        qx = 0.25f * s;
        qy = (m[0, 1] + m[1, 0]) / s;
        qz = (m[0, 2] + m[2, 0]) / s;
      }
      else if (m[1, 1] > m[2, 2])
      {
        float s = Mathf.Sqrt(1.0f + m[1, 1] - m[0, 0] - m[2, 2]) * 2f;
        qw = (m[0, 2] - m[2, 0]) / s;
        qx = (m[0, 1] + m[1, 0]) / s;
        qy = 0.25f * s;
        qz = (m[1, 2] + m[2, 1]) / s;
      }
      else
      {
        float s = Mathf.Sqrt(1.0f + m[2, 2] - m[0, 0] - m[1, 1]) * 2f;
        qw = (m[1, 0] - m[0, 1]) / s;
        qx = (m[0, 2] + m[2, 0]) / s;
        qy = (m[1, 2] + m[2, 1]) / s;
        qz = 0.25f * s;
      }
      return new Quaternion(qx, qy, qz, qw);
    }

    // ! 四元数转欧拉角（ZXY顺序，单位：度）
    Vector3 QuaternionToEulerAngles(Quaternion q)
    {
      float qw = q.w;
      float qx = q.x;
      float qy = q.y;
      float qz = q.z;

      // 参考ZXY顺序的推导
      float x, y, z;

      // X轴
      float sinX = 2f * (qw * qx - qy * qz);
      if (sinX > 1f) sinX = 1f;
      if (sinX < -1f) sinX = -1f;
      x = Mathf.Asin(sinX);

      // Z轴
      float sinZ = 2f * (qw * qz + qx * qy);
      float cosZ = 1f - 2f * (qx * qx + qz * qz);
      z = Mathf.Atan2(sinZ, cosZ);

      // Y轴
      float sinY = 2f * (qw * qy + qx * qz);
      float cosY = 1f - 2f * (qx * qx + qy * qy);
      y = Mathf.Atan2(sinY, cosY);

      return new Vector3(
          x * Mathf.Rad2Deg,
          y * Mathf.Rad2Deg,
          z * Mathf.Rad2Deg
      );
    }
  }
}
