Shader "Custom/09-Fur/FurUnder"
{
  Properties
  {
    [NoScaleOffset]_MainTex ("主贴图", 2D) = "white" { }
    [HDR]_MainColor ("主颜色", Color) = (1, 1, 1, 1)

    _FurFactor ("毛发外扩系数", Range(0.0002, 1)) = 0.25
  }
  SubShader
  {
    LOD 200

    Tags
    {
      "Queue" = "Geometry"
      "RenderPipeline" = "UniversalPipeline"
    }

    Cull Back
    ZTest LEqual
    ZWrite On

    HLSLINCLUDE

    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

    CBUFFER_START(UnityPerMaterial)

      TEXTURE2D(_MainTex);
      SAMPLER(sampler_MainTex);
      real4 _MainColor;

      real _FurFactor;

    CBUFFER_END

    ENDHLSL

    Pass
    {
      Name "BasePass"

      Tags
      {
        "LightMode" = "UniversalForward"
      }

      HLSLPROGRAM

      #pragma vertex vert
      #pragma fragment frag

      struct appdata
      {
        real2 uv : TEXCOORD0;
        real4 positionOS : POSITION;
      };

      struct v2f
      {
        real2 uv : TEXCOORD0;
        real4 positionCS : SV_POSITION;
      };

      v2f vert(appdata v)
      {
        v2f o = (v2f)0;

        VertexPositionInputs positionInputs = GetVertexPositionInputs(v.positionOS.xyz);
        
        o.uv = v.uv;

        o.positionCS = positionInputs.positionCS;

        return o;
      }

      real4 frag(v2f i) : SV_TARGET
      {
        real4 baseColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
        
        return baseColor * _MainColor;
      }

      ENDHLSL
    }
  }

  Fallback "Hidden/Universal Render Pipeline/FallbackError"
}
