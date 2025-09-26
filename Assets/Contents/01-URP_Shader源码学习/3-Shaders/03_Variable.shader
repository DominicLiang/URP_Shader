Shader "Custom/01-WriteShader/03_Variable"
{
  Properties
  {
    // [IntRange]_IsUseMainTex ("Is Use Main Texture", Range(0, 1)) = 1
    [Toggle]_IsUseMainTex ("Is Use Main Texture", int) = 1
    _MainTex ("Main Texture", 2D) = "white" { }
    _MainColor ("Main Color", Color) = (1, 0, 0, 1)
    _ColorIntensity ("Color Intensity", float) = 1
  }

  SubShader
  {
    LOD 200

    Tags
    {
      "Queue" = "Geometry"
      "RenderPipeline" = "UniversalPipeline"
    }

    HLSLINCLUDE

    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    // ! 引用Core.hlsl就行 Core.hlsl里面包含了Common.hlsl和Input.hlsl
    // #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
    // #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"

    // ! CBUFFER 将所有变量写进去 开启SRPBatcher优化
    // ! 开启SRPBatcher之后 只要使用相同的shader的会合成一个批次 材质里的参数可以不一样
    CBUFFER_START(UnityPerMaterial)

      // ! 变量
      // bool _bool
      // float _float
      // float3 _float3
      // half _half
      // half3 _half3
      // real _real
      // real3 _real3
      // int _int
      // uint _uint

      // ! 矩阵 前一个数是行 后一个数是列
      // float4x4 _float4x4
      // int4x3 _int4x3
      // half2x1 _half2x1
      // float1x4 _float1x4
      

      bool _IsUseMainTex;
      TEXTURE2D(_MainTex);
      SAMPLER(sampler_MainTex);
      float4 _MainColor;
      float _ColorIntensity;

    CBUFFER_END

    ENDHLSL

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

      #pragma vertex vert
      #pragma fragment frag

      struct appdata
      {
        float3 pos : POSITION; // ! 系统带的position是对象空间的
        float2 uv : TEXCOORD0;
      };

      struct v2f
      {
        float4 pos : SV_POSITION;
        float2 uv : TEXCOORD0;
      };

      v2f vert(appdata v)
      {
        v2f o = (v2f)0;

        // ! unity自带的变换矩阵
        // ! 引用 Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl
        // UNITY_MATRIX_M 对象空间转世界空间
        // UNITY_MATRIX_V 世界空间转视图空间
        // UNITY_MATRIX_P 视图空间转投影空间
        // UNITY_MATRIX_MV 对象空间转视图空间
        // UNITY_MATRIX_VP 世界空间转投影空间
        // UNITY_MATRIX_MVP 对象空间转投影空间
        // ! 前面加I就是逆矩阵 如 UNITY_MATRIX_I_M
        o.pos = mul(UNITY_MATRIX_MVP, float4(v.pos, 1));
        o.uv = v.uv;
        return o;
      }

      float4 frag(v2f i) : SV_TARGET
      {
        // ! 变量
        // float4 f4 = float4(1, 2, 3, 4);
        // ! 变量的分量访问
        // float two = f4[2];
        // float three = f4.z;
        // float2 xy = f4.xy;
        // float3 zzz = f4.zzz;
        // float a = f4.a;
        // float3 rgb = f4.rgb;
        // float3 rrr = f4.rrr;

        // ! 矩阵
        // float4x4 m4 = {
        //   float4(1, 2, 3, 4),
        //   float4(1, 2, 3, 4),
        //   float4(1, 2, 3, 4),
        //   float4(1, 2, 3, 4),
        // }
        // float4x4 m4 = {
        //   1, 2, 3, 4,
        //   1, 2, 3, 4,
        //   1, 2, 3, 4,
        //   1, 2, 3, 4,
        // }
        // ! 矩阵的分量访问
        // 1 可以用索引访问
        // float two_three = m4[2][3]
        // 2 swizzle
        // float two_three = m4._m23
        // float2 two_three2 = m4._m23_m24

        float4 mainTexColor = float4(1, 1, 1, 1);

        if (_IsUseMainTex)
        {
          mainTexColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
        }

        return mainTexColor * _MainColor * _ColorIntensity;
      }

      ENDHLSL
    }
  }


  Fallback "Hidden/Universal Render Pipeline/FallbackError"
}