Shader "CustomRTNoise/FBM2D"
{
  Properties
  {
    _Seed ("种子", Float) = 54321
    [Enum(VALUE, 0, PERLIN, 1, Cell, 2)]_BaseType ("基础噪声类型", Float) = 0
    _Resolution ("分辨率", Vector) = (2, 2, 0, 0)
    _Frequency ("频率", Vector) = (4, 4, 0, 0)
    _Octaves ("迭代次数", Float) = 10
    _Persistence ("分型强度", Float) = 0.5
    _Lacunarity ("间隔", Float) = 2
  }

  SubShader
  {
    Blend One Zero

    Pass
    {
      Name "FBM2D"

      CGPROGRAM
      #include "UnityCustomRenderTexture.cginc"

      #include "HLSL/NoiseUtils.hlsl"
      #include "HLSL/ValueNoise.hlsl"
      #include "HLSL/PerlinNoise.hlsl"
      #include "HLSL/CellularNoise.hlsl"
      #include "HLSL/FbmNoise.hlsl"

      #pragma vertex CustomRenderTextureVertexShader
      #pragma fragment frag
      #pragma target 3.0

      #pragma shader_feature _TILED

      float _Seed;
      int _BaseType;
      float2 _Resolution;
      float2 _Frequency;
      int _Octaves;
      float _Persistence;
      float _Lacunarity;

      float4 frag(v2f_customrendertexture IN) : SV_Target
      {
        float2 uv = IN.localTexcoord.xy ;

        float3 noise = 0;

        switch(_BaseType)
        {
          case 0:
            noise = fbmTiledValueNoise2D(uv, _Resolution, _Frequency, _Octaves, _Persistence, _Lacunarity, _Seed);
            break;
          case 1:
            noise = fbmTiledPerlinNoise2D(uv, _Resolution, _Frequency, _Octaves, _Persistence, _Lacunarity, _Seed);
            break;
          case 2:
            noise = fbmTiledCellularNoise2D(uv, _Resolution, _Frequency, _Octaves, _Persistence, _Lacunarity, _Seed);
            break;
        }

        return float4(noise, 1);
      }
      ENDCG
    }
  }
}
