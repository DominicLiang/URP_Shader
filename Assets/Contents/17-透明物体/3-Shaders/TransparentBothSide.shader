Shader "Custom/Normal/TransparentBothSide"
{
  Properties
  {
    _BaseMap ("Main Texture", 2D) = "white" { }
    _BaseColor ("Main Color", Color) = (1, 1, 1, 1)
    _Cutoff ("Alpha Cutoff", Range(0, 1)) = 0.5
    [Toggle(_ALPHATEST_ON)] _AlphaTestToggle ("Alpha Clipping", float) = 0
    [Enum(Off, 0, Front, 1, Back, 2)]_Cull ("Cull Mode", float) = 2
  }

  SubShader
  {
    LOD 200

    Tags
    {
      "Queue" = "AlphaTest"
      "RenderPipeline" = "UniversalPipeline"
    }

    HLSLINCLUDE

    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

    CBUFFER_START(UnityPerMaterial)

      float4 _BaseMap_ST;
      SamplerState NewRepeatPointSampler;

      float4 _BaseColor;

      float _Cutoff;

    CBUFFER_END

    ENDHLSL

    pass
    {
      Name "AlphaClip"

      Cull Front
      Blend SrcAlpha OneMinusSrcAlpha

      Tags
      {
        "LightMode" = "UniversalForward"
      }

      HLSLPROGRAM

      TEXTURE2D(_BaseMap);

      #pragma shader_feature _ALPHATEST_ON

      #pragma vertex vert
      #pragma fragment frag

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
        o.uv = TRANSFORM_TEX(v.uv, _BaseMap);
        o.color = v.color;

        return o;
      }

      float4 frag(v2f i) : SV_TARGET
      {
        float4 mainTexColor = SAMPLE_TEXTURE2D(_BaseMap, NewRepeatPointSampler, i.uv);

        #ifdef _ALPHATEST_ON
          clip(mainTexColor.a - _Cutoff);
        #endif

        return mainTexColor * _BaseColor * i.color;
      }

      ENDHLSL
    }

    pass
    {
      Name "AlphaClip"

      Cull Back
      Blend SrcAlpha OneMinusSrcAlpha

      Tags
      {
        "LightMode" = "FrontSide"
      }

      HLSLPROGRAM

      TEXTURE2D(_BaseMap);

      #pragma shader_feature _ALPHATEST_ON

      #pragma vertex vert
      #pragma fragment frag

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
        o.uv = TRANSFORM_TEX(v.uv, _BaseMap);
        o.color = v.color;

        return o;
      }

      float4 frag(v2f i) : SV_TARGET
      {
        float4 mainTexColor = SAMPLE_TEXTURE2D(_BaseMap, NewRepeatPointSampler, i.uv);

        #ifdef _ALPHATEST_ON
          clip(mainTexColor.a - _Cutoff);
        #endif

        return mainTexColor * _BaseColor * i.color;
      }

      ENDHLSL
    }
  }

  Fallback "Hidden/Universal Render Pipeline/FallbackError"
}
