Shader "Custom/01-WriteShader/01_StencilObject"
{
  Properties
  {
    _ReadValue ("读取模版缓冲区的值", int) = 1
  }

  SubShader
  {
    LOD 200
    Tags
    {
      "Queue" = "Geometry"
      "RenderPipeline" = "UniversalPipeline"
    }

    // ! 模版测试显示物体
    Stencil
    {
      Ref [_ReadValue]
      Comp Equal
      Pass Keep
      Fail Keep
      ZFail Keep
    }

    pass
    {
      Tags
      {
        "LightMode" = "UniversalForward"
      }

      HLSLPROGRAM
      #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

      #pragma vertex vert
      #pragma fragment frag

      struct appdata
      {
        float3 pos : POSITION;
      };

      struct v2f
      {
        float4 pos : SV_POSITION;
      };

      v2f vert(appdata IN)
      {
        v2f OUT = (v2f)0;
        OUT.pos = mul(UNITY_MATRIX_MVP, float4(IN.pos, 1));
        return OUT;
      }

      float4 frag(v2f IN) : SV_TARGET
      {
        return float4(1, 0, 0, 1);
      }
      ENDHLSL
    }
  }
}