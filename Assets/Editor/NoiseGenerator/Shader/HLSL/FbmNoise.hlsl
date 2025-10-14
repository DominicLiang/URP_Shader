float3 fbmTiledValueNoise2D(float2 pos, float2 scale, float frequency, int octaves, float persistence, float lacunarity, float seed)
{
  float3 value = 0.0;
  float amplitude = 0.5;
  float frequencyValue = frequency;
  
  for (int i = 0; i < octaves; i++)
  {
    float3 noise = tiledValueNoise2D(pos * scale * frequencyValue, scale * frequencyValue, seed + i);
    value += noise * amplitude;
    amplitude *= persistence;
    frequencyValue *= lacunarity;
  }
  
  return value;
}

float3 fbmTiledPerlinNoise2D(float2 pos, float2 scale, float frequency, int octaves, float persistence, float lacunarity, float seed)
{
  float3 value = 0.0;
  float amplitude = 0.5;
  float frequencyValue = frequency;
  
  for (int i = 0; i < octaves; i++)
  {
    float3 noise = tiledPerlinNoise2D(pos * frequencyValue, scale * frequencyValue, seed + i);
    value += noise * amplitude;
    amplitude *= persistence;
    frequencyValue *= lacunarity;
  }
  
  return value;
}

float3 fbmTiledCellularNoise2D(float2 pos, float2 scale, float frequency, int octaves, float persistence, float lacunarity, float seed)
{
  float3 value = 0.0;
  float amplitude = 0.5;
  float frequencyValue = frequency;
  
  for (int i = 0; i < octaves; i++)
  {
    float3 noise = tiledCellularNoise2D(pos * scale * frequencyValue, scale * frequencyValue, seed + i);
    value += noise * amplitude;
    amplitude *= persistence;
    frequencyValue *= lacunarity;
  }
  
  return value;
}