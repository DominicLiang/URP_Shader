Shader "Custom/14-Bending/Bending"
{
  Properties
  {
    [NoScaleOffset]_MainTex ("主贴图", 2D) = "white" { }
    [HDR]_MainColor ("主颜色", Color) = (1, 1, 1, 1)
    _OffsetFactor ("弯曲系数", Float) = 1
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
      real _OffsetFactor;

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

        real3 positionWS = mul(UNITY_MATRIX_M, v.positionOS);
        real3 viewDir = positionWS - _WorldSpaceCameraPos;
        real4 offset = real4(0, pow(viewDir.x, 2) + pow(viewDir.z, 2), 0, 0) * - 0.001 * _OffsetFactor;
        offset = mul(UNITY_MATRIX_I_M, offset);
        v.positionOS += offset;
        o.positionCS = mul(UNITY_MATRIX_MVP, v.positionOS);

        
        
        o.uv = v.uv;

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
