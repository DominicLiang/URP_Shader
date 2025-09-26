// ! 计算specular和smoothness的值
half4 SampleSpecularSmoothness(float2 uv, half alpha, half4 specColor, TEXTURE2D_PARAM(specMap, sampler_specMap))
{
  half4 specularSmoothness = half4(0.0h, 0.0h, 0.0h, 1.0h);

  #ifdef _SPECGLOSSMAP
    // ! 如果定义了贴图 使用贴图乘颜色
    specularSmoothness = SAMPLE_TEXTURE2D(specMap, sampler_specMap, uv) * specColor;
  #elif defined(_SPECULAR_COLOR)
    specularSmoothness = specColor;
  #endif

  #ifdef _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
    specularSmoothness.a = exp2(10 * alpha + 1);
  #else
    specularSmoothness.a = exp2(10 * specularSmoothness.a + 1);
  #endif
  return specularSmoothness;
}



