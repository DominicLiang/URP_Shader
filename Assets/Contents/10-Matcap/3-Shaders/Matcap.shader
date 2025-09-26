Shader "Custom/12-Matcap/Matcap"
{
  Properties
  {
    [NoScaleOffset]_MainTex ("主贴图", 2D) = "white" { }
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
    #include "Assets/ShaderLibrary/Utility/Node.hlsl"

    CBUFFER_START(UnityPerMaterial)

      TEXTURE2D(_MainTex);
      SAMPLER(sampler_MainTex);

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
        real3 normalOS : NORMAL;
      };

      struct v2f
      {
        real2 uv : TEXCOORD0;
        real4 positionCS : SV_POSITION;
        real3 normalVS : TEXCOORD1;
      };



      v2f vert(appdata v)
      {
        v2f o = (v2f)0;

        VertexPositionInputs positionInputs = GetVertexPositionInputs(v.positionOS.xyz);

        o.positionCS = positionInputs.positionCS;

        // float3 normalVS = mul(UNITY_MATRIX_IT_MV, v.normalOS);
        // float3 posVS = normalize(positionInputs.positionVS);
        // float3 vcn = cross(posVS, normalVS);
        // float2 uv = float2(-vcn.y, vcn.x);
        // o.uv = uv * 0.5 + 0.5;
        o.uv = MatCapUV(positionInputs.positionVS, v.normalOS);
        
        return o;
      }

      real4 frag(v2f i) : SV_TARGET
      {
        real4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);

        return color;
      }

      ENDHLSL
    }
  }

  Fallback "Hidden/Universal Render Pipeline/FallbackError"
}
