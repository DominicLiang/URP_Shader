Shader "Custom/01-WriteShader/08_AlphaClip"
{
  Properties
  {
    _MainTex ("Main Texture", 2D) = "white" { }
    _MainColor ("Main Color", Color) = (1, 1, 1, 1)

    _Cutoff ("Alpha Cutoff", Range(0, 1)) = 0.5
    // ! 在Properties定义Toggle和Enum关键字
    [Toggle(ALPHATEST_ON)] _AlphaTestToggle ("Alpha Clipping", float) = 0
    [Enum(Off, 0, Front, 1, Back, 2)]_Cull ("Cull Mode", float) = 2
  }

  SubShader
  {
    LOD 200

    Tags
    {
      "Queue" = "Geometry"
      "RenderPipeline" = "UniversalPipeline"
    }

    // ! cull可以直接使用枚举
    Cull [_Cull]
    ZTest LEqual
    ZWrite On

    HLSLINCLUDE

    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

    CBUFFER_START(UnityPerMaterial)

      TEXTURE2D(_MainTex);
      float4 _MainTex_ST;
      SamplerState NewRepeatPointSampler;

      float4 _MainColor;

      float _Cutoff;

    CBUFFER_END

    ENDHLSL

    pass
    {
      Name "AlphaClip"

      Tags
      {
        "LightMode" = "UniversalForward"
      }

      HLSLPROGRAM

      #pragma vertex vert
      #pragma fragment frag

      // ! 定义shader_feature
      #pragma shader_feature ALPHATEST_ON

      struct appdata
      {
        float4 posOS : POSITION;
        float2 uv : TEXCOORD0;
        float4 color : COLOR;
      };

      struct v2f
      {
        float4 posCS : SV_POSITION;
        float2 uv : TEXCOORD0;
        float4 color : COLOR;
      };

      v2f vert(appdata v)
      {
        v2f o = (v2f)0;

        VertexPositionInputs posInputs = GetVertexPositionInputs(v.posOS.xyz);

        o.posCS = posInputs.positionCS;
        o.uv = TRANSFORM_TEX(v.uv, _MainTex);
        o.color = v.color;

        return o;
      }

      float4 frag(v2f i) : SV_TARGET
      {
        float4 mainTexColor = SAMPLE_TEXTURE2D(_MainTex, NewRepeatPointSampler, i.uv);

        // ! 使用shader_feature
        #ifdef ALPHATEST_ON
          // ! 第一种AlphaClip的方法 用if了 不推荐
          // if (mainTexColor.a < 0.5)
          // {
          //   discard;
          // }

          // ! 第二种 clip方法 clip方法内的值小于0就clip掉 大于等于0保留
          // ! 写法 clip(alpha值 - 阈值)
          clip(mainTexColor.a - _Cutoff);
        #endif

        return mainTexColor * _MainColor * i.color;
      }

      ENDHLSL
    }
  }

  Fallback "Hidden/Universal Render Pipeline/FallbackError"
}