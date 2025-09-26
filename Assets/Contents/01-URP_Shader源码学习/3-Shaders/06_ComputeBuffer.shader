Shader "Custom/01-WriteShader/06_ComputeBuffer"
{

  Properties
  {
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

    Cull Back
    ZTest LEqual
    ZWrite On

    HLSLINCLUDE

    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

    CBUFFER_START(UnityPerMaterial)

      bool _IsUseMainTex;
      float4 _MainColor;
      float _ColorIntensity;

      TEXTURE2D(_MainTex);
      float4 _MainTex_ST;
      SamplerState NewRepeatPointSampler;

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
        float3 pos : POSITION;
        float2 uv : TEXCOORD0;
      };

      struct v2f
      {
        float4 pos : SV_POSITION;
        float2 uv : TEXCOORD0;
      };

      // ! ComputeBuffer

      // ! buffer用到的数据结构体
      // struct BufferElement {
      //   float3 f3;
      //   float f;
      // }

      // ! ComputeBuffer变量 c#把数据传进这里 尖括号里对应上面的结构体类型
      // ! 大坑 在普通shader中StructuredBuffer只有windows能用哦
      // ! 如果你希望支持mac 这一整节都不用看了 因为不支持
      // ! 在mac的metal下 StructuredBuffer只能用于ComputeShader!!!
      // StructuredBuffer<BufferElement> _ComputeBuffer;

      // void OutBufferValue(float index, out BufferElement elem) {
      //   // ! 提取第index个bufferElement
      //   elem = _ComputeBuffer[index];
      // }

      v2f vert(appdata v)
      {
        v2f o = (v2f)0;

        // ! 获取数据
        // BufferElement elem;
        // OutBufferValue(0, elem);

        // float3 posCompute = (v.pos + elem.f3) * elem.f; // ! 对物体顶点延特定方向偏移

        // o.pos = mul(UNITY_MATRIX_MVP, float4(posCompute, 1));

        o.pos = mul(UNITY_MATRIX_MVP, float4(v.pos, 1));

        o.uv = TRANSFORM_TEX(v.uv, _MainTex);

        return o;
      }

      float4 frag(v2f i) : SV_TARGET
      {
        float4 mainTexColor = float4(1, 1, 1, 1);

        if (_IsUseMainTex)
        {
          mainTexColor = SAMPLE_TEXTURE2D(_MainTex, NewRepeatPointSampler, i.uv);
        }
        
        return mainTexColor * _MainColor * _ColorIntensity;
      }

      ENDHLSL
    }
  }

  Fallback "Hidden/Universal Render Pipeline/FallbackError"
}
