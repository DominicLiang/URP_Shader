// * ShaderGraph 依赖 -----------------------------

void Hash_Tchou_2_2_float(float2 p, out float2 hash)
{
  // 标准的哈希实现
  p = frac(p * float2(0.16632, 0.17369));
  p += dot(p.xy, p.yx + 19.19);
  hash = frac(float2(p.x * p.y * 95.55, p.x * p.y * 97.77));
}

float2 Unity_Voronoi_RandomVector_Deterministic_float(float2 UV, float offset)
{
  Hash_Tchou_2_2_float(UV, UV);
  return float2(sin(UV.y * offset), cos(UV.x * offset)) * 0.5 + 0.5;
}

// * from ShaderGraph -----------------------------

// Dither效果
// 输入: In 透明度, ScreenPosition 屏幕坐标
// 输出: Out Dither后效果 用于clip
float Unity_Dither_float(float In, float4 ScreenPosition)
{
  float2 uv = ScreenPosition.xy * _ScreenParams.xy;
  float DITHER_THRESHOLDS[16] = {
    1.0 / 17.0, 9.0 / 17.0, 3.0 / 17.0, 11.0 / 17.0,
    13.0 / 17.0, 5.0 / 17.0, 15.0 / 17.0, 7.0 / 17.0,
    4.0 / 17.0, 12.0 / 17.0, 2.0 / 17.0, 10.0 / 17.0,
    16.0 / 17.0, 8.0 / 17.0, 14.0 / 17.0, 6.0 / 17.0
  };
  uint index = (uint(uv.x) % 4) * 4 + uint(uv.y) % 4;
  return In - DITHER_THRESHOLDS[index];
}

// Remap
float Unity_Remap_float(real In, real2 InMinMax, real2 OutMinMax)
{
  return OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
}

// 高度图到法线图
float3 Unity_NormalFromHeight_World_float(float In, float Strength, float3 PositionWS, float3x3 tbnMatrix)
{
  float3 worldDerivativeX = ddx(PositionWS);
  float3 worldDerivativeY = ddy(PositionWS);

  float3 crossX = cross(tbnMatrix[2].xyz, worldDerivativeX);
  float3 crossY = cross(worldDerivativeY, tbnMatrix[2].xyz);
  float d = dot(worldDerivativeX, crossY);
  float sgn = d < 0.0 ? (-1.0f) : 1.0f;
  float surface = sgn / max(0.000000000000001192093f, abs(d));

  float dHdx = ddx(In);
  float dHdy = ddy(In);
  float3 surfGrad = surface * (dHdx * crossY + dHdy * crossX);
  return normalize(tbnMatrix[2].xyz - (Strength * surfGrad));
}

// * 噪声 from ShaderGraph -----------------------------

// Voronoi噪声图
void Unity_Voronoi_Deterministic_float(float2 UV, float AngleOffset, float CellDensity, out float Out, out float Cells)
{
  float2 g = floor(UV * CellDensity);
  float2 f = frac(UV * CellDensity);
  float t = 8.0;
  float3 res = float3(8.0, 0.0, 0.0);
  for (int y = -1; y <= 1; y++)
  {
    for (int x = -1; x <= 1; x++)
    {
      float2 lattice = float2(x, y);
      float2 offset = Unity_Voronoi_RandomVector_Deterministic_float(lattice + g, AngleOffset);
      float d = distance(lattice + offset, f);
      if (d < res.x)
      {
        res = float3(d, offset.x, offset.y);
        Out = res.x;
        Cells = res.y;
      }
    }
  }
}

