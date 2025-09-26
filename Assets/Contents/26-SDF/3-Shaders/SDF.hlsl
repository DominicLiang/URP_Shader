void SmoothUnion_float(float a, float b, float k, out float dist)
{
  float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
  dist = lerp(b, a, h) - k * h * (1.0 - h);
}

void SmoothIntersection_float(float a, float b, float k, out float dist)
{
  float h = clamp(0.5 + 0.5 * (a - b) / k, 0.0, 1.0);
  dist = lerp(b, a, h) + k * h * (1.0 - h);
}

void SmoothDifference_float(float a, float b, float k, out float dist)
{
  float h = clamp(0.5 + 0.5 * (a - (-b)) / k, 0.0, 1.0);
  dist = lerp(-b, a, h) + k * h * (1.0 - h);
}