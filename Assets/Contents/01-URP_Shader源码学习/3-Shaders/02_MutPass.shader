Shader "Custom/01-WriteShader/02_MutPass"
{
  Properties
  {
    _MainTex ("Main Texture", 2D) = "white" { }
    _MainColor ("Main Color", Color) = (1, 0, 0, 1)
    _ColorIntensity ("Color Intensity", float) = 1
    _OutlineColor ("Outline Color", Color) = (0, 0, 0, 1)
  }

  SubShader
  {
    LOD 200

    Tags
    {
      "Queue" = "Geometry"
      "RenderPipeline" = "UniversalPipeline"
    }

    pass
    {
      Tags
      {
        "LightMode" = "UniversalForward"
      }

      Cull Back
      ZTest LEqual
      ZWrite On

      HLSLPROGRAM

      #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

      #pragma vertex vert
      #pragma fragment frag

      TEXTURE2D(_MainTex);
      SAMPLER(sampler_MainTex);
      float4 _MainColor;
      float _ColorIntensity;

      struct appdata
      {
        float3 pos : POSITION;
        float2 uv : TEXCOORD0;
      };

      struct v2f
      {
        float4 pos : SV_POSITION;
        float2 uv : TEXCOORD0;
      };

      v2f vert(appdata IN)
      {
        v2f OUT = (v2f)0;

        OUT.pos = mul(UNITY_MATRIX_MVP, float4(IN.pos, 1));
        OUT.uv = IN.uv;

        return OUT;
      }

      float4 frag(v2f IN) : SV_TARGET
      {
        float4 mainTexColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
        return mainTexColor * _MainColor * _ColorIntensity;
      }

      ENDHLSL
    }

    // ! 在URP下编写多Pass Shader的方法
    // ! 1 RenderObject (可视化)
    // ! 2 RenderFeature (C#)

    // ! RenderObject里面使用lightmode来设置多pass 对所有材质shader里带指定lightmode的物体生效
    // ! 如果用材质override 对所有物体生效 可以用layermask来指定
    pass
    {
      Tags
      {
        "LightMode" = "Outline"
      }

      // ! 剔除前面 用背面来渲染描边
      Cull Front
      ZTest LEqual
      ZWrite On

      HLSLPROGRAM

      #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

      #pragma vertex vert
      #pragma fragment frag

      TEXTURE2D(_MainTex);
      SAMPLER(sampler_MainTex);
      float4 _MainColor;
      float _ColorIntensity;
      float4 _OutlineColor;

      struct appdata
      {
        float3 pos : POSITION;
        float2 uv : TEXCOORD0;
      };

      struct v2f
      {
        float4 pos : SV_POSITION;
        float2 uv : TEXCOORD0;
      };

      v2f vert(appdata IN)
      {
        v2f OUT = (v2f)0;

        float3 pos2 = IN.pos * 1.05;

        OUT.pos = mul(UNITY_MATRIX_MVP, float4(pos2, 1));
        OUT.uv = IN.uv;

        return OUT;
      }

      float4 frag(v2f IN) : SV_TARGET
      {
        return _OutlineColor;
      }

      ENDHLSL
    }
  }

  Fallback "Hidden/Universal Render Pipeline/FallbackError"
}