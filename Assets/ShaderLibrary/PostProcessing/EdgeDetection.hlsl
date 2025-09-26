float Intensity(in float4 color)
{
  return sqrt((color.x * color.x) + (color.y * color.y) + (color.z * color.z));
}

void SampleNeighborIntensity(
  Texture2D tex, SamplerState tex_sampler, float stepX, float stepY, float2 center,
  out float topLeft, out float midLeft, out float bottomLeft,
  out float midTop, out float midBottom,
  out float topRight, out float midRight, out float bottomRight)
{
  topLeft = Intensity(tex.Sample(tex_sampler, center + float2(-stepX, stepY)));
  midLeft = Intensity(tex.Sample(tex_sampler, center + float2(-stepX, 0)));
  bottomLeft = Intensity(tex.Sample(tex_sampler, center + float2(-stepX, -stepY)));
  midTop = Intensity(tex.Sample(tex_sampler, center + float2(0, stepY)));
  midBottom = Intensity(tex.Sample(tex_sampler, center + float2(0, -stepY)));
  topRight = Intensity(tex.Sample(tex_sampler, center + float2(stepX, stepY)));
  midRight = Intensity(tex.Sample(tex_sampler, center + float2(stepX, 0)));
  bottomRight = Intensity(tex.Sample(tex_sampler, center + float2(stepX, -stepY)));
}

void SampleNeighborRGB(
  Texture2D tex, SamplerState tex_sampler, float stepX, float stepY, float2 center,
  out float3 topLeft, out float3 midLeft, out float3 bottomLeft,
  out float3 midTop, out float3 midBottom,
  out float3 topRight, out float3 midRight, out float3 bottomRight)
{
  topLeft = tex.Sample(tex_sampler, center + float2(-stepX, stepY)).rgb;
  midLeft = tex.Sample(tex_sampler, center + float2(-stepX, 0)).rgb;
  bottomLeft = tex.Sample(tex_sampler, center + float2(-stepX, -stepY)).rgb;
  midTop = tex.Sample(tex_sampler, center + float2(0, stepY)).rgb;
  midBottom = tex.Sample(tex_sampler, center + float2(0, -stepY)).rgb;
  topRight = tex.Sample(tex_sampler, center + float2(stepX, stepY)).rgb;
  midRight = tex.Sample(tex_sampler, center + float2(stepX, 0)).rgb;
  bottomRight = tex.Sample(tex_sampler, center + float2(stepX, -stepY)).rgb;
}

void SampleNeighborIntensity_4Tap(
  Texture2D tex, SamplerState tex_sampler, float stepX, float stepY, float2 center,
  out float topLeft, out float bottomLeft, out float topRight, out float bottomRight)
{
  topLeft = Intensity(tex.Sample(tex_sampler, center + float2(-stepX, stepY)));
  bottomLeft = Intensity(tex.Sample(tex_sampler, center + float2(-stepX, -stepY)));
  topRight = Intensity(tex.Sample(tex_sampler, center + float2(stepX, stepY)));
  bottomRight = Intensity(tex.Sample(tex_sampler, center + float2(stepX, -stepY)));
}

void SampleNeighborRGB_4Tap(
  Texture2D tex, SamplerState tex_sampler, float stepX, float stepY, float2 center,
  out float3 topLeft, out float3 bottomLeft, out float3 topRight, out float3 bottomRight)
{
  topLeft = tex.Sample(tex_sampler, center + float2(-stepX, stepY)).rgb;
  bottomLeft = tex.Sample(tex_sampler, center + float2(-stepX, -stepY)).rgb;
  topRight = tex.Sample(tex_sampler, center + float2(stepX, stepY)).rgb;
  bottomRight = tex.Sample(tex_sampler, center + float2(stepX, -stepY)).rgb;
}

// -----------------------------------------------------------------------------------------------

float Roberts_Gray(Texture2D tex, SamplerState tex_sampler, float stepX, float stepY, float2 center)
{
  float topLeft, bottomLeft, topRight, bottomRight;
  SampleNeighborIntensity_4Tap(tex, tex_sampler, stepX, stepY, center,
  topLeft, bottomLeft, topRight, bottomRight);

  float Gx = -1.0 * topLeft + 1.0 * bottomRight;
  float Gy = -1.0 * topRight + 1.0 * bottomLeft;

  float sobelGradient = sqrt((Gx * Gx) + (Gy * Gy));
  return sobelGradient;
}

float Roberts_Color(Texture2D tex, SamplerState tex_sampler, float stepX, float stepY, float2 center)
{
  float3 topLeft, bottomLeft, topRight, bottomRight;
  SampleNeighborRGB_4Tap(tex, tex_sampler, stepX, stepY, center,
  topLeft, bottomLeft, topRight, bottomRight);

  float3 Gx = -1.0 * topLeft + 1.0 * bottomRight;
  float3 Gy = -1.0 * topRight + 1.0 * bottomLeft;
  
  float3 sobelGradient = sqrt((Gx * Gx) + (Gy * Gy));
  return sobelGradient;
}

float Sobel_Gray(Texture2D tex, SamplerState tex_sampler, float stepX, float stepY, float2 center)
{
  float topLeft, midLeft, bottomLeft, midTop, midBottom, topRight, midRight, bottomRight;
  SampleNeighborIntensity(tex, tex_sampler, stepX, stepY, center,
  topLeft, midLeft, bottomLeft, midTop, midBottom, topRight, midRight, bottomRight);

  float Gx = topLeft + 2.0 * midLeft + bottomLeft - topRight - 2.0 * midRight - bottomRight;
  float Gy = -topLeft - 2.0 * midTop - topRight + bottomLeft + 2.0 * midBottom + bottomRight;
  float sobelGradient = sqrt((Gx * Gx) + (Gy * Gy));
  return sobelGradient;
}

float3 Sobel_Color(Texture2D tex, SamplerState tex_sampler, float stepX, float stepY, float2 center)
{
  float3 topLeft, midLeft, bottomLeft, midTop, midBottom, topRight, midRight, bottomRight;
  SampleNeighborRGB(tex, tex_sampler, stepX, stepY, center,
  topLeft, midLeft, bottomLeft, midTop, midBottom, topRight, midRight, bottomRight);

  float3 Gx = topLeft + 2.0 * midLeft + bottomLeft - topRight - 2.0 * midRight - bottomRight;
  float3 Gy = -topLeft - 2.0 * midTop - topRight + bottomLeft + 2.0 * midBottom + bottomRight;
  float3 sobelGradient = sqrt((Gx * Gx) + (Gy * Gy));
  return sobelGradient;
}

float Scharr_Gray(Texture2D tex, SamplerState tex_sampler, float stepX, float stepY, float2 center)
{
  float topLeft, midLeft, bottomLeft, midTop, midBottom, topRight, midRight, bottomRight;
  SampleNeighborIntensity(tex, tex_sampler, stepX, stepY, center,
  topLeft, midLeft, bottomLeft, midTop, midBottom, topRight, midRight, bottomRight);

  float Gx = 3.0 * topLeft + 10.0 * midLeft + 3.0 * bottomLeft - 3.0 * topRight - 10.0 * midRight - 3.0 * bottomRight;
  float Gy = 3.0 * topLeft + 10.0 * midTop + 3.0 * topRight - 3.0 * bottomLeft - 10.0 * midBottom - 3.0 * bottomRight;

  float scharrGradient = sqrt((Gx * Gx) + (Gy * Gy));
  return scharrGradient;
}

float Scharr_Color(Texture2D tex, SamplerState tex_sampler, float stepX, float stepY, float2 center)
{
  float3 topLeft, midLeft, bottomLeft, midTop, midBottom, topRight, midRight, bottomRight;
  SampleNeighborRGB(tex, tex_sampler, stepX, stepY, center,
  topLeft, midLeft, bottomLeft, midTop, midBottom, topRight, midRight, bottomRight);

  float3 Gx = 3.0 * topLeft + 10.0 * midLeft + 3.0 * bottomLeft - 3.0 * topRight - 10.0 * midRight - 3.0 * bottomRight;
  float3 Gy = 3.0 * topLeft + 10.0 * midTop + 3.0 * topRight - 3.0 * bottomLeft - 10.0 * midBottom - 3.0 * bottomRight;
  
  float3 scharrGradient = sqrt((Gx * Gx) + (Gy * Gy)).rgb;
  return scharrGradient;
}

// -----------------------------------------------------------------------------------------------

float4 EdgeDetection(Texture2D tex, SamplerState tex_sampler, float2 uv, float edgeWidth, float4 edgeColor, float4 backgroundColor, float backgroundFade)
{
  half4 sceneColor = tex.Sample(tex_sampler, uv);

  float sobelGradient = 0;

  #ifdef SCHARR
    sobelGradient = Scharr_Gray(tex, tex_sampler, edgeWidth / _ScreenParams.x, edgeWidth / _ScreenParams.y, uv);
  #elif ROBERTS
    sobelGradient = Roberts_Gray(tex, tex_sampler, edgeWidth / _ScreenParams.x, edgeWidth / _ScreenParams.y, uv);
  #else
    sobelGradient = Sobel_Gray(tex, tex_sampler, edgeWidth / _ScreenParams.x, edgeWidth / _ScreenParams.y, uv);
  #endif

  half4 background = lerp(sceneColor, backgroundColor, backgroundFade);
  float3 edge = lerp(background.rgb, edgeColor.rgb, sobelGradient);

  return float4(edge, 1);
}

float4 EdgeDetectionNeon(Texture2D tex, SamplerState tex_sampler, float2 uv, float edgeWidth, float4 backgroundColor, float backgroundFade, float brightness)
{
  half4 sceneColor = tex.Sample(tex_sampler, uv);

  float sobelGradient = 0;

  #ifdef SCHARR
    sobelGradient = Scharr_Gray(tex, tex_sampler, edgeWidth / _ScreenParams.x, edgeWidth / _ScreenParams.y, uv);
  #elif ROBERTS
    sobelGradient = Roberts_Gray(tex, tex_sampler, edgeWidth / _ScreenParams.x, edgeWidth / _ScreenParams.y, uv);
  #else
    sobelGradient = Sobel_Gray(tex, tex_sampler, edgeWidth / _ScreenParams.x, edgeWidth / _ScreenParams.y, uv);
  #endif

  half4 background = lerp(sceneColor, backgroundColor, backgroundFade);
  float3 edgeColor = lerp(background.rgb, sceneColor.rgb, sobelGradient);

  return float4(edgeColor * brightness, 1);
}

float4 EdgeDetectionNeonV2(Texture2D tex, SamplerState tex_sampler, float2 uv, float edgeWidth, float edgeNeonFade, float4 backgroundColor, float backgroundFade, float brightness)
{
  half4 sceneColor = tex.Sample(tex_sampler, uv);

  float3 sobelGradient = float3(0, 0, 0);

  #ifdef SCHARR
    sobelGradient = Scharr_Color(tex, tex_sampler, edgeWidth / _ScreenParams.x, edgeWidth / _ScreenParams.y, uv);
  #elif ROBERTS
    sobelGradient = Roberts_Color(tex, tex_sampler, edgeWidth / _ScreenParams.x, edgeWidth / _ScreenParams.y, uv);
  #else
    sobelGradient = Sobel_Color(tex, tex_sampler, edgeWidth / _ScreenParams.x, edgeWidth / _ScreenParams.y, uv);
  #endif

  half3 background = lerp(backgroundColor.rgb, sceneColor.rgb, backgroundFade);
  float3 edgeColor = lerp(background.rgb, sobelGradient.rgb, edgeNeonFade);

  return float4(edgeColor * brightness, 1);
}


