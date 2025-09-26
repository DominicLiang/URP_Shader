using UnityEngine;

namespace ComputerGraphics
{
  public struct Vector3
  {
    public float x;
    public float y;
    public float z;

    public Vector3(float x, float y, float z)
    {
      this.x = x;
      this.y = y;
      this.z = z;
    }

    public override string ToString()
    {
      return $"{x:F2}, {y:F2}, {z:F2}";
    }

    // ! 隐式转换 写了这个就可以自动转换 
    public static implicit operator UnityEngine.Vector3(Vector3 v)
    {
      return new UnityEngine.Vector3(v.x, v.y, v.z);
    }

    // ! 向量加法 得到从向量1起点到向量2终点的向量
    // * 当向量1和向量2都是单位向量时 这两个向量相加得到的向量3和v1v2的夹角都相等
    public static Vector3 operator +(Vector3 v1, Vector3 v2)
    {
      return new Vector3(v1.x + v2.x, v1.y + v2.y, v1.z + v2.z);
    }

    // ! 向量减法 得到从向量2的终点指向向量1的终点的向量
    public static Vector3 operator -(Vector3 v1, Vector3 v2)
    {
      return v1 + (v2 * -1);
    }

    // ! 向量和标量乘法 得到通过标量放大后的向量
    public static Vector3 operator *(Vector3 v, float k)
    {
      return new Vector3(v.x * k, v.y * k, v.z * k);
    }

    public static Vector3 operator *(float k, Vector3 v)
    {
      return v * k;
    }

    // ! 向量和标量除法 得到通过标量缩小后的向量
    public static Vector3 operator /(Vector3 v, float k)
    {
      return v * (1 / k);
    }

    // ! 向量的长度
    public float Magnitude
    {
      get
      {
        return Mathf.Sqrt(x * x + y * y + z * z);
      }
    }

    // ! 单位化
    public Vector3 Normalized
    {
      get
      {
        return this / Magnitude;
      }
    }

    public void Normalize()
    {
      this = Normalized;
    }

    // ! 两个向量终点(两个点)距离
    public static float Distance(Vector3 v1, Vector3 v2)
    {
      return (v1 - v2).Magnitude;
    }

    // ! 点乘
    // ! 几何意义:
    // ! 一 计算两个向量夹角的余弦值 (两个向量必须为单位向量)
    // !    1 光照计算 两个向量越接近0度返回越接近1, 90度返回0, 180度返回-1
    // !    2 背面裁剪 正面返回正数 背面返回负数
    // ! 二 计算向量u在单位向量v上的投影 投影向量为v*(dot(u,v)) 
    // ! v必须为单位向量 得到的投影向量方向跟v相同 长度为dot(u,v)
    public static float DotProduct(Vector3 v1, Vector3 v2)
    {
      return v1.x * v2.x + v1.y * v2.y + v1.z * v2.z;
    }

    // ! 叉乘
    // ! 叉乘具有反交换律 cross(a,b) = -cross(b,a) 交换ab 叉乘结果是两个方向的相反向量
    // ! 几何意义:
    // ! 一 计算与向量uv都垂直的第三个向量 即计算结果为uv平面的垂直向量
    // !    1 计算三角形的法线 比如有三个点v1,v2,v3 三角形法线就是 cross((v2-v1),(v3-v1))
    // !    2 从三角形法线生成顶点法线
    // ! 二 计算由向量uv构成的平行四边形A的面积 A=cross(u,v).Magnitude 
    public static Vector3 CrossProduct(Vector3 v1, Vector3 v2)
    {
      var x = v1.y * v2.z - v1.z * v2.y;
      var y = v1.z * v2.x - v1.x * v2.z;
      var z = v1.x * v2.y - v1.y * v2.x;
      return new Vector3(x, y, z);
    }
  }
}


