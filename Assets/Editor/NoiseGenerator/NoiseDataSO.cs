using UnityEngine;

namespace Noise
{
  public class PreviewData
  {
    public float brightness = 0.5f;
    public float contrast = 0.5f;
    public ColorChannel outputR = ColorChannel.R;
    public ColorChannel outputG = ColorChannel.R;
    public ColorChannel outputB = ColorChannel.R;
  }

  public class NoiseData
  {
    public int seed = 54321;
    public bool tiled = true;
    public Vector2 resolution = new Vector2(10, 10);
    public BaseNoiseType baseNoiseType = BaseNoiseType.Perlin;
    public Vector2 frequency = new Vector2(2, 2);
    public int octaves = 10;
    public float persistence = 0.5f;
    public float lacunarity = 2;
  }
}