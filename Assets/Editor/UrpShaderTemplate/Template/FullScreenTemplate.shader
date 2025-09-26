Shader "Custom/FullScreen/Template"
{
  SubShader
  {
    LOD 100

    // ! -------------------------------------
    // ! Tags
    Tags
    {
      "Queue" = "Overlay"
      "RenderPipeline" = "UniversalPipeline"
    }

    HLSLINCLUDE

    // ! -------------------------------------
    // ! 全shader include
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"

    // ! -------------------------------------
    // ! 变量声明

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
      Cull Off
      ZWrite Off

      HLSLPROGRAM

      // ! -------------------------------------
      // ! pass include

      // ! -------------------------------------
      // ! Shader阶段
      #pragma vertex Vert
      #pragma fragment frag

      // ! -------------------------------------
      // ! 材质关键字

      // ! -------------------------------------
      // ! 片元着色器
      real4 frag(Varyings input) : SV_TARGET
      {
        real2 uv = input.texcoord.xy;
        real4 color = SAMPLE_TEXTURE2D(_BlitTexture, sampler_LinearClamp, uv);

        return color;
      }

      ENDHLSL
    }
  }

  // ! -------------------------------------
  // ! 紫色报错fallback
  Fallback "Hidden/Universal Render Pipeline/FallbackError"
}

