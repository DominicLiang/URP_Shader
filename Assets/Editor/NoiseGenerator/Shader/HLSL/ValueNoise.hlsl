// from unity Shader Graph

float random2DWithSeed(float2 uv, float seed)
{
  return frac(sin(dot(uv, float2(12.9898, 78.233)) + seed) * 43758.5453);
}

float unity_noise_interpolate(float a, float b, float t)
{
  return (1.0 - t) * a + (t * b);
}

float valueNoise2D(float2 uv, float seed)
{
  float2 i = floor(uv);
  float2 f = frac(uv);
  f = f * f * (3.0 - 2.0 * f);

  uv = abs(frac(uv) - 0.5);

  float2 c0 = i + float2(0.0, 0.0);
  float2 c1 = i + float2(1.0, 0.0);
  float2 c2 = i + float2(0.0, 1.0);
  float2 c3 = i + float2(1.0, 1.0);

  float r0 = random2DWithSeed(c0, seed);
  float r1 = random2DWithSeed(c1, seed);
  float r2 = random2DWithSeed(c2, seed);
  float r3 = random2DWithSeed(c3, seed);

  float bottomOfGrid = unity_noise_interpolate(r0, r1, f.x);
  float topOfGrid = unity_noise_interpolate(r2, r3, f.x);
  float t = unity_noise_interpolate(bottomOfGrid, topOfGrid, f.y);
  return t;
}

float tiledValueNoise2D(float2 uv, float2 tileSize, float seed)
{
  float2 i = floor(uv);
  float2 f = frac(uv);
  f = f * f * (3.0 - 2.0 * f);

  uv = abs(frac(uv) - 0.5);

  float2 c0 = fmod(i + float2(0.0, 0.0), tileSize) + 0.5;
  float2 c1 = fmod(i + float2(1.0, 0.0), tileSize) + 0.5;
  float2 c2 = fmod(i + float2(0.0, 1.0), tileSize) + 0.5;
  float2 c3 = fmod(i + float2(1.0, 1.0), tileSize) + 0.5;

  float r0 = random2DWithSeed(c0, seed);
  float r1 = random2DWithSeed(c1, seed);
  float r2 = random2DWithSeed(c2, seed);
  float r3 = random2DWithSeed(c3, seed);

  float bottomOfGrid = unity_noise_interpolate(r0, r1, f.x);
  float topOfGrid = unity_noise_interpolate(r2, r3, f.x);
  float t = unity_noise_interpolate(bottomOfGrid, topOfGrid, f.y);
  return t;
}
