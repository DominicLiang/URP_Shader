#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

// * from ShaderGraph -----------------------------

void Unity_Dither_float(float In, float4 ScreenPosition, out float Out)
{
  float2 uv = ScreenPosition.xy * _ScreenParams.xy;
  float DITHER_THRESHOLDS[16] = {
    1.0 / 17.0, 9.0 / 17.0, 3.0 / 17.0, 11.0 / 17.0,
    13.0 / 17.0, 5.0 / 17.0, 15.0 / 17.0, 7.0 / 17.0,
    4.0 / 17.0, 12.0 / 17.0, 2.0 / 17.0, 10.0 / 17.0,
    16.0 / 17.0, 8.0 / 17.0, 14.0 / 17.0, 6.0 / 17.0
  };
  uint index = (uint(uv.x) % 4) * 4 + uint(uv.y) % 4;
  Out = In - DITHER_THRESHOLDS[index];
}

real Unity_Remap_float4(real In, real2 InMinMax, real2 OutMinMax)
{
  return OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
}

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

void Unity_NormalFromHeight_World_float(float In, float Strength, float3 PositionWS, float3x3 tbnMatrix, out float3 Out)
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
  Out = normalize(tbnMatrix[2].xyz - (Strength * surfGrad));
}

// * from ShaderGraph -----------------------------

half2 MatCapUV(half3 positionVS, half3 normalOS)
{
  float3 posVS = normalize(positionVS);
  float3 normalVS = mul(UNITY_MATRIX_IT_MV, normalOS);
  float3 vcn = cross(posVS, normalVS);
  float2 uv = float2(-vcn.y, vcn.x);
  uv = uv * 0.5 + 0.5;
  return uv;
}

half3 QuickSSS(Light light, half3 N, half3 V, half thickness, half3 SSSColor, half nDistortIntensity, half power, half strength, half ambient)
{
  half3 L = light.direction;
  half3 LN = normalize(L + N * nDistortIntensity);

  half sss = pow(saturate(dot(V, -LN)), power) * strength + ambient;

  sss *= thickness;

  return sss * SSSColor * light.color * light.distanceAttenuation * light.shadowAttenuation;
}

half2 ParallaxOcclusionMapping(Texture2D tex, SamplerState texSampler, half3 viewDirTS, half2 uv, int numLayers, half parallaxScale)
{
  // 切线空间视方向
  half3 viewDir = normalize(viewDirTS);

  // 层的高度值(初始数最大值)
  half currentLayerHeight = 1.0;
  // 单层歩进的高度
  half layerStep = currentLayerHeight / numLayers;
  
  // uv最大偏移值
  half2 maxOffset = viewDir.xy / viewDir.z * parallaxScale;
  // 单步uv偏移值
  half2 offsetStep = maxOffset / numLayers;

  // 初始化
  half2 currentUV = uv + maxOffset;
  half2 finalOffset = uv;
  half mapHeight = saturate(SAMPLE_TEXTURE2D(tex, texSampler, currentUV).r);
  
  // 开始一步步逼近 直到找到步进点比高度图低(看不到)
  UNITY_LOOP
  for (int i = 0; i < numLayers; i++)
  {
    if (currentLayerHeight <= mapHeight)
    {
      break;
    }
    currentUV -= offsetStep;
    mapHeight = saturate(SAMPLE_TEXTURE2D(tex, texSampler, currentUV).r);
    currentLayerHeight -= layerStep;
  }

  // 计算 h1 和 h2
  half2 uvPrev = currentUV + offsetStep;
  half prevMapHeight = saturate(SAMPLE_TEXTURE2D(tex, texSampler, uvPrev).r);
  half prevLayerHeight = currentLayerHeight + layerStep;
  half beforeHeight = prevLayerHeight - prevMapHeight; // h1
  half afterHeight = mapHeight - currentLayerHeight; // h2

  // 利用h1和h2得到权重,在两个红点间使用权重进行插值
  half weight = afterHeight / (afterHeight + beforeHeight);
  finalOffset = lerp(uvPrev, currentUV, weight);
  finalOffset -= uv;

  return finalOffset;
}

float Random(float seed)
{
  return frac(sin(dot(seed.xx, float2(12.9898, 78.233))) * 43758.5453);
}

float RandomRange(float seed, float min, float max)
{
  return lerp(min, max, Random(seed));
}

float2 RandomVector2(float seed)
{
  float2 dir;
  dir.x = Random(seed) * 2.0 - 1.0;
  dir.y = Random(seed + 1.0) * 2.0 - 1.0;
  return normalize(dir);
}

float3 RandomVector3(float seed)
{
  float3 dir;
  dir.x = Random(seed) * 2.0 - 1.0;
  dir.y = Random(seed + 1.0) * 2.0 - 1.0;
  dir.z = Random(seed + 2.0) * 2.0 - 1.0;
  return normalize(dir);
}