// Hash functions
uint ihash1D(uint q)
{
  // hash by Hugo Elias, Integer Hash - I, 2017
  q = (q << 13u) ^ q;
  return q * (q * q * 15731u + 789221u) + 1376312589u;
}

uint2 ihash1D(uint2 q)
{
  // hash by Hugo Elias, Integer Hash - I, 2017
  q = (q << 13u) ^ q;
  return q * (q * q * 15731u + 789221u) + 1376312589u;
}

uint4 ihash1D(uint4 q)
{
  // hash by Hugo Elias, Integer Hash - I, 2017
  q = (q << 13u) ^ q;
  return q * (q * q * 15731u + 789221u) + 1376312589u;
}

// generates 2 random numbers for each of the 4 cell corners
void multiHash2D(float4 cell, out float4 hashX, out float4 hashY)
{
  uint4 i = uint4(cell) + 101323u;
  uint4 hash0 = ihash1D(ihash1D(i.xzxz) + i.yyww);
  uint4 hash1 = ihash1D(hash0 ^ 1933247u);
  hashX = float4(hash0) * (1.0 / float(0xffffffffu));
  hashY = float4(hash1) * (1.0 / float(0xffffffffu));
}

float Distance(float3 p)
{
  float d;

  d = length(p);

  return d;
}

float Distance(float2 p)
{
  return Distance(float3(p, 0));
}