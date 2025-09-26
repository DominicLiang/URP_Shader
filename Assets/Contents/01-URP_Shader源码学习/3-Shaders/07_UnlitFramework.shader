Shader "Custom/01-WriteShader/07_UnlitFramework"
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
      Name "Unlit" // ! pass名 可以在framedebug中看到

      Tags
      {
        "LightMode" = "UniversalForward"
      }

      HLSLPROGRAM

      #pragma vertex vert
      #pragma fragment frag

      struct appdata
      {
        // ! 主要position需要float4 用float3不行哦

        float4 posOS : POSITION; // ! 物体空间position
        float2 uv : TEXCOORD0; // ! uv
        float4 color : COLOR; // ! 顶点色

      };

      struct v2f
      {
        float4 posCS : SV_POSITION; // ! 裁剪空间position 用于输出语义要带SV_
        float2 uv : TEXCOORD0; // ! uv
        float4 color : COLOR; // ! 顶点色

      };

      v2f vert(appdata v)
      {
        v2f o = (v2f)0;

        // ! URP提供的 GetVertexPositionInputs 方法 一次过获取所有空间坐标
        // struct VertexPositionInputs
        // {
        //   float3 positionWS; // ! 世界空间坐标
        //   float3 positionVS; // ! 观察空间坐标
        //   float4 positionCS; // ! 裁剪空间坐标
        //   float4 positionNDC;// ! 归一化设备坐标

        // };
        VertexPositionInputs posInputs = GetVertexPositionInputs(v.posOS.xyz);

        o.posCS = posInputs.positionCS;
        o.uv = TRANSFORM_TEX(v.uv, _MainTex);
        o.color = v.color;

        return o;
      }

      float4 frag(v2f i) : SV_TARGET
      {
        float4 mainTexColor = SAMPLE_TEXTURE2D(_MainTex, NewRepeatPointSampler, i.uv);

        return mainTexColor * _MainColor * i.color;
      }

      ENDHLSL
    }
  }

  Fallback "Hidden/Universal Render Pipeline/FallbackError"
}