Shader "CustomRTNoise/Cellular2D"
{
  Properties
  {
    _Seed ("种子", Float) = 54321
    _Resolution ("分辨率", Vector) = (10, 10, 0, 0)
  }

  SubShader
  {
    Blend One Zero

    Pass
    {
      Name "Cellular2D"

      CGPROGRAM
      #include "UnityCustomRenderTexture.cginc"

      #include "HLSL/NoiseUtils.hlsl"
      #include "HLSL/CellularNoise.hlsl"

      #pragma vertex CustomRenderTextureVertexShader
      #pragma fragment frag
      #pragma target 3.0

      #pragma shader_feature _TILED

      float _Seed;
      float2 _Resolution;

      float4 frag(v2f_customrendertexture IN) : SV_Target
      {
        float2 uv = IN.localTexcoord.xy ;

        float4 noise = 0;

        noise = tiledCellularNoise2D(uv * _Resolution, _Resolution, _Seed);

        return noise;
      }
      ENDCG
    }
  }
}
