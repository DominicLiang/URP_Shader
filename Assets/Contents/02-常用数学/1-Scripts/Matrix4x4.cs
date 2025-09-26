using System;
using System.Text;
using UnityEngine;

namespace ComputerGraphics
{
  public struct Matrix4x4
  {
    // ! 1 c#不允许结构体的变量带默认值 
    // !   不写默认值的话默认值默认为default 
    // !   如果要写默认值必须在构造函数上写
    // ! 2 c#结构体的构造函数必须带参数
    private readonly float[,] m;

    public static Matrix4x4 Zero => new(new float[4, 4]);

    public static Matrix4x4 Identity
    {
      get
      {
        var m = Zero;
        m[0, 0] = 1;
        m[1, 1] = 1;
        m[2, 2] = 1;
        m[3, 3] = 1;
        return m;
      }
    }

    private Matrix4x4(float[,] m)
    {
      this.m = m;
    }

    // ! 索引器
    public float this[int row, int col]
    {
      get
      {
        if (row < 0 || row >= 4 || col < 0 || col >= 4)
          throw new IndexOutOfRangeException();
        return m[row, col];
      }
      set
      {
        if (row < 0 || row >= 4 || col < 0 || col >= 4)
          throw new IndexOutOfRangeException();
        m[row, col] = value;
      }
    }

    public override string ToString()
    {
      var sb = new StringBuilder();
      for (int r = 0; r < 4; r++)
      {
        for (int c = 0; c < 4; c++)
        {
          sb.Append(c == 3 ? $"{m[r, c]:F5} \n" : $"{m[r, c]:F5} , ");
        }
      }
      return sb.ToString();
    }

    // ! 判断矩阵相等
    public static bool operator ==(Matrix4x4 a, Matrix4x4 b)
    {
      for (int r = 0; r < 4; r++)
      {
        for (int c = 0; c < 4; c++)
        {
          if (a[r, c] != b[r, c]) return false;
        }
      }
      return true;
    }

    public static bool operator !=(Matrix4x4 a, Matrix4x4 b)
    {
      return !(a == b);
    }

    public override bool Equals(object obj)
    {
      if (!(obj is Matrix4x4))
        return false;
      Matrix4x4 other = (Matrix4x4)obj;
      return this == other;
    }

    public override int GetHashCode()
    {
      int hash = 17;
      for (int r = 0; r < 4; r++)
      {
        for (int c = 0; c < 4; c++)
        {
          hash = hash * 31 + this[r, c].GetHashCode();
        }
      }
      return hash;
    }

    // ! 矩阵加法
    public static Matrix4x4 operator +(Matrix4x4 a, Matrix4x4 b)
    {
      var m = Zero;
      for (int r = 0; r < 4; r++)
      {
        for (int c = 0; c < 4; c++)
        {
          m[r, c] = a[r, c] + b[r, c];
        }
      }
      return m;
    }

    // ! 矩阵减法
    public static Matrix4x4 operator -(Matrix4x4 a, Matrix4x4 b)
    {
      return a + (b * -1);
    }

    // ! 矩阵和标量乘法
    public static Matrix4x4 operator *(Matrix4x4 a, float k)
    {
      var m = Zero;
      for (int r = 0; r < 4; r++)
      {
        for (int c = 0; c < 4; c++)
        {
          m[r, c] = a[r, c] * k;
        }
      }
      return m;
    }

    public static Matrix4x4 operator *(float k, Matrix4x4 a)
    {
      return a * k;
    }

    // ! 矩阵和标量除法
    public static Matrix4x4 operator /(Matrix4x4 a, float k)
    {
      return a * (1 / k);
    }

    // ! 矩阵之间的乘法
    // ! 不满足交换律
    public static Matrix4x4 operator *(Matrix4x4 a, Matrix4x4 b)
    {
      var m = Zero;

      for (int r = 0; r < 4; r++)
      {
        for (int c = 0; c < 4; c++)
        {
          for (int i = 0; i < 4; i++)
          {
            m[r, c] += a[r, i] * b[i, c];
          }
        }
      }

      return m;
    }

    // ! 转置矩阵
    // ! (AB)T = AT*BT
    public Matrix4x4 Transpose
    {
      get
      {
        var m = Zero;

        for (int r = 0; r < 4; r++)
        {
          for (int c = 0; c < 4; c++)
          {
            m[r, c] = this[c, r];
          }
        }

        return m;
      }
    }

    // ! 坐标基向量
    // ! 坐标基向量是代表坐标轴方向的方向向量(w值为0)
    // ! 对于一个4x4的矩阵
    // * - D3D使用行矩阵,unity使用列矩阵(OpenGL也是) 
    // * (下面按unity列向量为例)
    // * - D3D行矩阵是向量乘矩阵,unity列矩阵是矩阵乘向量
    // * - 第一二三列分别表示坐标系xyz轴的坐标基向量(代表了对物体的旋转)
    // * - 第四列代表平移分量(代表了对物体的平移)
    // * - m11,m22,m33 分别代表对物体xyz轴的缩放
    // * - m41,m42,m43 均为0
    // * - m44 为1
    // ! 一个矩阵可以同时代表位移旋转和缩放
    // * M = M translate * M rotate * M scale(必须按此顺序相乘,等于把物体的顶点从局部坐标系转换到世界坐标系)
    // * 位移旋转缩放组合一起时 unity是 先缩放 然后旋转 最后位移
    // * 矩阵相乘之后是先执行最后乘的那个矩阵 所以是 M translate * M rotate * M scale
    // ! xyz轴旋转组合
    // * Mr = MrY * MrX * MrZ(必须按此顺序相乘)
    // * 当三轴同时旋转时 unity是 选转Z轴 然后转X轴 最后转Y轴
    // * 同上矩阵先执行最后乘的那个矩阵 所以是 MrY * MrX * MrZ
    // ! 要把物体的顶点从世界坐标系转换到局部坐标系 需要乘以转换矩阵M的逆矩阵
    // * 位移矩阵的逆矩阵 = -M translate
    // * 旋转矩阵的逆矩阵 = M rotate.Transpose
    // * 缩放矩阵的逆矩阵 * M scale(1/x, 1/y , 1/z) xyz为三轴原缩放倍率

    // ! 单位矩阵
    // ! 方形矩阵,左上到右下都是1,其他都是0
    // * 任何矩阵乘以单位矩阵等于本身

    // ! 逆矩阵 用于逆变换
    // ! 只有方形矩阵才有用逆矩阵
    // ! 任何矩阵和逆矩阵相乘 结果为单位矩阵
    // * 但矩阵和逆矩阵相乘时满足交换律

    // ! 正交矩阵
    // ! 即此矩阵与此矩阵的转置矩阵相乘等于单位矩阵
    // * 当矩阵是正交矩阵时 他的转置矩阵等于他的逆矩阵 比如旋转矩阵就是正交矩阵

    private static float GetVectorValue(Vector4 v, int index) => index switch
    {
      0 => v.x,
      1 => v.y,
      2 => v.z,
      3 => v.w,
      _ => 0
    };

    // ! D3D行矩阵是向量乘矩阵 行向量*行矩阵 Vr*Mr1*Mr2...*Mrn
    public static Vector4 operator *(Vector4 v, Matrix4x4 m)
    {
      float[] res = new float[4];
      for (int c = 0; c < 4; c++)
      {
        for (int r = 0; r < 4; r++)
        {
          float vr = GetVectorValue(v, r);
          res[c] += vr * m[r, c];
        }
      }
      return new Vector4(res[0], res[1], res[2], res[3]);
    }

    // ! unity列矩阵是矩阵乘向量 列矩阵*列向量 Mcn*...(Mc2*(Mc1*Vc))
    public static Vector4 operator *(Matrix4x4 m, Vector4 v)
    {
      float[] res = new float[4];
      for (int r = 0; r < 4; r++)
      {
        for (int c = 0; c < 4; c++)
        {
          float vc = GetVectorValue(v, c);
          res[r] += m[r, c] * vc;
        }
      }
      return new Vector4(res[0], res[1], res[2], res[3]);
    }

    // ! 设置位移矩阵(Unity) xyz代表三方向位移
    // *    1      0      0      x
    // *    0      1      0      y
    // *    0      0      1      x
    // *    0      0      0      1
    public static Matrix4x4 SetTranslate(float x, float y, float z)
    {
      var m = Identity;
      m[0, 3] = x;
      m[1, 3] = y;
      m[2, 3] = z;
      return m;
    }

    // ! x轴旋转(Unity) R代表旋转的弧度
    // *    1      0      0      0
    // *    0     cosR   -sinR   0
    // *    0     sinR   cosR    0
    // *    0      0      0      1
    public static Matrix4x4 SetRotateX(float deg)
    {
      var m = Identity;
      float rad = deg * Mathf.Deg2Rad; // !注意 旋转用的是弧度 不是角度

      m[1, 1] = Mathf.Cos(rad);
      m[1, 2] = -Mathf.Sin(rad);
      m[2, 1] = Mathf.Sin(rad);
      m[2, 2] = Mathf.Cos(rad);

      return m;
    }

    // ! y轴旋转(Unity) R代表旋转的弧度
    // *   cosR    0     sinR    0
    // *    0      1      0      0
    // *   -sinR   0     cosR    0
    // *    0      0      0      1
    public static Matrix4x4 SetRotateY(float deg)
    {
      var m = Identity;
      float rad = deg * Mathf.Deg2Rad;

      m[0, 0] = Mathf.Cos(rad);
      m[0, 2] = Mathf.Sin(rad);
      m[2, 0] = -Mathf.Sin(rad);
      m[2, 2] = Mathf.Cos(rad);

      return m;
    }

    // ! z轴旋转(Unity) R代表旋转的弧度
    // *   cosR   -sinR   0      0
    // *   sinR   cosR    0      0
    // *    0      0      1      0
    // *    0      0      0      1
    public static Matrix4x4 SetRotateZ(float deg)
    {
      var m = Identity;
      float rad = deg * Mathf.Deg2Rad;

      m[0, 0] = Mathf.Cos(rad);
      m[0, 1] = -Mathf.Sin(rad);
      m[1, 0] = Mathf.Sin(rad);
      m[1, 1] = Mathf.Cos(rad);

      return m;
    }

    // ! 三轴同时旋转(Unity)
    // ! 先 z  然后 x  最后 y
    // ! 可以根据旋转矩阵反推四元数和欧拉角 看: Test/ShowPositionOutside.cs
    // *    -cosY*cosZ + sinX*sinY*sinZ     cosY*sinZ + sinX*sinY*cosZ    cosX*sinY      0
    // *          cosX*sinZ                      cosX*cosZ                 -sinX         0
    // *    -sinY*cosZ - sinX*cosY*sinZ    sinY*sinZ - sinX*cosY*cosZ     cosX*cosY      0
    // *             0                              0                        0           1
    public static Matrix4x4 SetRotate(float x, float y, float z)
    {
      var mrx = SetRotateX(x);
      var mry = SetRotateY(y);
      var mrz = SetRotateZ(z);

      var m = mry * mrx * mrz;

      return m;
    }

    // ! 设置缩放矩阵(Unity) xyz代表三方向缩放
    // *    x      0      0      0
    // *    0      y      0      0
    // *    0      0      z      0
    // *    0      0      0      1
    public static Matrix4x4 SetScale(float x, float y, float z)
    {
      var m = Identity;

      m[0, 0] = x;
      m[1, 1] = y;
      m[2, 2] = z;

      return m;
    }

    // ! 视图变换矩阵 (DX 行向量 unity不适用 了解就行)
    // * zAxis = normalized(at - eye)
    // * xAxis = normalized(cross(up, zAxis))
    // * yAxis = cross(zAxis, xAxis);
    // ! 视图变换矩阵
    // *        xAxis.x            yAxis.x            zAxis.x        0
    // *        xAxis.y            yAxis.y            zAxis.y        0
    // *        xAxis.z            yAxis.z            zAxis.z        0
    // *    -dot(xAxis, eye)   -dot(yAxis, eye)   -dot(zAxis, eye)   1
    /// <summary>
    /// 构建视图变换矩阵（LookAt矩阵）
    /// </summary>
    /// <param name="eye">相机位置（观察点）</param>
    /// <param name="at">目标点（被观察点）</param>
    /// <param name="up">上方向向量</param>
    public static Matrix4x4 MakeView(Vector3 eye, Vector3 at, Vector3 up)
    {
      var zAxis = (at - eye).Normalized;
      var xAxis = Vector3.CrossProduct(up, zAxis).Normalized;
      var yAxis = Vector3.CrossProduct(zAxis, xAxis);

      var m = Identity;

      m[0, 0] = xAxis.x;
      m[0, 1] = yAxis.x;
      m[0, 2] = zAxis.x;

      m[1, 0] = xAxis.y;
      m[1, 1] = yAxis.y;
      m[1, 2] = zAxis.y;

      m[2, 0] = xAxis.z;
      m[2, 1] = yAxis.z;
      m[2, 2] = zAxis.z;

      m[3, 0] = -Vector3.DotProduct(xAxis, eye);
      m[3, 1] = -Vector3.DotProduct(yAxis, eye);
      m[3, 2] = -Vector3.DotProduct(zAxis, eye);

      return m;
    }

    // ! 投影变换矩阵 (DX 行向量 unity不适用 了解就行)
    // * yScale = cos(fovY / 2)
    // * xScale = yScale / AspectRatio
    // ! 投影变换矩阵
    // *    xScale    0           0         0
    // *      0     yScale        0         0
    // *      0       0      zf/(zf-zn)     1
    // *      0       0    -zn*zf/(zf-zn)   0
    /// <summary>
    /// 构建透视投影矩阵
    /// </summary>
    /// <param name="fovY">视场角（弧度，绕Y轴）</param>
    /// <param name="aspect">宽高比（宽/高）</param>
    /// <param name="zn">近平面距离</param>
    /// <param name="zf">远平面距离</param>
    public static Matrix4x4 MakeProject(float fovY, float aspect, float zn, float zf)
    {
      float yScale = Mathf.Cos(fovY / 2);
      float xScale = yScale / aspect;

      var m = Zero;

      m[0, 0] = xScale;
      m[1, 1] = yScale;
      m[2, 2] = zf / (zf - zn);
      m[2, 3] = 1;
      m[3, 2] = -zn * zf / (zf - zn);

      return m;
    }

    // ! 屏幕变换矩阵 (DX 行向量 unity不适用 了解就行)
    // *    w/2     0      0    0
    // *     0     -h/2    0    0
    // *     0      0      1    0
    // *    w/2    h/2     0    1
    /// <summary>
    /// 构建屏幕变换矩阵
    /// </summary>
    /// <param name="w">屏幕宽度（像素）</param>
    /// <param name="h">屏幕高度（像素）</param>
    public static Matrix4x4 MakeScreen(int w, int h)
    {
      var m = Identity;

      m[0, 0] = w / 2;
      m[3, 0] = w / 2;

      m[1, 1] = -h / 2;
      m[3, 1] = h / 2;

      return m;
    }
  }
}
