namespace ComputerGraphics
{
  public struct Vector4
  {
    public float x;
    public float y;
    public float z;
    public float w;

    public Vector4(Vector3 v, float w)
    {
      x = v.x;
      y = v.y;
      z = v.z;
      this.w = w;
    }

    public Vector4(float x, float y, float z, float w)
    {
      this.x = x;
      this.y = y;
      this.z = z;
      this.w = w;
    }

    public override string ToString()
    {
      return $"{x:F2}, {y:F2}, {z:F2}, {w:F2}";
    }
  }
}
