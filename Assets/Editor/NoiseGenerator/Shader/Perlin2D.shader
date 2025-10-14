Shader "CustomRTNoise/Perlin2D"
{
  Properties
  {
    _Seed ("种子", Float) = 54321
    [Toggle(_TILED)]_Tiled ("四方连续", Float) = 1
    _Resolution ("分辨率", Vector) = (10, 10, 0, 0)
  }

  SubShader
  {
    Blend One Zero

    Pass
    {
      Name "Perlin2D"

      CGPROGRAM
      #include "UnityCustomRenderTexture.cginc"

      #include "HLSL/NoiseUtils.hlsl"
      #include "HLSL/PerlinNoise.hlsl"

      #pragma vertex CustomRenderTextureVertexShader
      #pragma fragment frag
      #pragma target 3.0

      #pragma shader_feature _TILED

      float _Seed;
      float2 _Resolution;

      float4 frag(v2f_customrendertexture IN) : SV_Target
      {
        float2 uv = IN.localTexcoord.xy ;

        float3 noise = 0;

        #ifdef _TILED
          noise = tiledPerlinNoise2D(uv, _Resolution, _Seed);
        #else
          noise = perlinNoise2D(uv * _Resolution, _Seed);
        #endif

        noise = noise * 0.5 + 0.5;

        return float4(noise, 1);
      }
      ENDCG
    }
  }
}
