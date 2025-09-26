Shader "Custom/01-WriteShader/14_Normal"
{
  Properties
  {
    _MainTex ("Main Texture", 2D) = "white" { }
    _MainColor ("Main Color", Color) = (1, 1, 1, 1)
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
      float4 _MainTex_ST;
      SamplerState NewRepeatPointSampler;

      float4 _MainColor;

    CBUFFER_END

    ENDHLSL

    pass
    {
      Tags
      {
        "LightMode" = "UniversalForward"
      }

      HLSLPROGRAM

      #pragma vertex vert
      #pragma fragment frag

      struct appdata
      {
        float4 posOS : POSITION;
        float4 nOS : NORMAL;
        float2 uv : TEXCOORD0;
        float4 color : COLOR;
      };

      struct v2f
      {
        float4 posCS : SV_POSITION;
        float3 nOS : TEXCOORD1;
        float2 uv : TEXCOORD0;
        float4 color : COLOR;
      };

      v2f vert(appdata v)
      {
        v2f o = (v2f)0;

        VertexPositionInputs posInputs = GetVertexPositionInputs(v.posOS.xyz);

        o.posCS = posInputs.positionCS;

        o.nOS = GetVertexNormalInputs(v.nOS.xyz).normalWS;

        o.uv = TRANSFORM_TEX(v.uv, _MainTex);
        o.color = v.color;

        return o;
      }

      float4 frag(v2f i) : SV_TARGET
      {
        float3 n = normalize(i.nOS);
        return float4(n * 0.5 + 0.5, 1);
      }

      ENDHLSL
    }
  }

  Fallback "Hidden/Universal Render Pipeline/FallbackError"
}