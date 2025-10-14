Shader "CustomRTNoise/Value2D"
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
      Name "Value2D"

      CGPROGRAM
      #include "UnityCustomRenderTexture.cginc"

      #include "HLSL/NoiseUtils.hlsl"
      #include "HLSL/ValueNoise.hlsl"

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
          noise = tiledValueNoise2D(uv * _Resolution, _Resolution, _Seed).rrr;
        #else
          noise = valueNoise2D(uv * _Resolution, _Seed).rrr;
        #endif

        return float4(noise, 1);
      }
      ENDCG
    }
  }
}
