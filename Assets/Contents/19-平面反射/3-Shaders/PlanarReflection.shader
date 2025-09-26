Shader "Custom/Normal/PlanarReflection"
{
  Properties
  {
    // ! -------------------------------------
    // ! 面板属性
    _ReflectColor ("反射颜色", Color) = (1, 1, 1, 1)
  }
  
  SubShader
  {
    LOD 100

    // ! -------------------------------------
    // ! Tags
    Tags
    {
      "Queue" = "Transparent"
      "RenderPipeline" = "UniversalPipeline"
    }

    HLSLINCLUDE

    // ! -------------------------------------
    // ! 全shader include
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

    CBUFFER_START(UnityPerMaterial)

      // ! -------------------------------------
      // ! 变量声明
      TEXTURE2D(_ReflectRT);
      SAMPLER(sampler_ReflectRT);
      real4 _ReflectColor;
      
    CBUFFER_END

    

    ENDHLSL

    Pass
    {
      // ! -------------------------------------
      // ! Pass名
      Name "BasePass"

      // ! -------------------------------------
      // ! tags
      Tags
      {
        "LightMode" = "UniversalForward"
      }

      // ! -------------------------------------
      // ! 渲染状态
      Cull Back
      ZTest LEqual
      ZWrite On
      Blend SrcAlpha OneMinusSrcAlpha

      HLSLPROGRAM

      // ! -------------------------------------
      // ! pass include

      // ! -------------------------------------
      // ! Shader阶段
      #pragma vertex vert
      #pragma fragment frag

      // ! -------------------------------------
      // ! 材质关键字 shader_feature

      // ! -------------------------------------
      // ! URP关键字 multi_compile

      // ! -------------------------------------
      // ! Unity关键字 multi_compile

      // ! -------------------------------------
      // ! GPU实例 multi_compile

      // ! -------------------------------------
      // ! 顶点着色器输入
      struct appdata
      {
        real2 uv : TEXCOORD0;
        real4 positionOS : POSITION;
      };

      // ! -------------------------------------
      // ! 顶点着色器输出 片元着色器输入
      struct v2f
      {
        real2 uv : TEXCOORD0;
        real4 positionCS : SV_POSITION;
      };

      // ! -------------------------------------
      // ! 顶点着色器
      v2f vert(appdata v)
      {
        v2f o = (v2f)0;

        VertexPositionInputs positionInputs = GetVertexPositionInputs(v.positionOS.xyz);
        
        o.uv = v.uv;

        o.positionCS = positionInputs.positionCS;

        return o;
      }

      // ! -------------------------------------
      // ! 片元着色器
      real4 frag(v2f i) : SV_TARGET
      {
        real2 screenUV = i.positionCS.xy / _ScreenParams.xy;

        real4 color = SAMPLE_TEXTURE2D(_ReflectRT, sampler_ReflectRT, screenUV);
        color *= _ReflectColor;
        
        return color;
      }

      ENDHLSL
    }
  }

  // ! -------------------------------------
  // ! 紫色报错fallback
  Fallback "Hidden/Universal Render Pipeline/FallbackError"
}
