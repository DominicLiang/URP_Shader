Shader "Custom/FullScreen/VolumeLight"
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
    #include "Assets/ShaderLibrary/PostProcessing/Blur.hlsl"

    // ! -------------------------------------
    // ! 变量声明
    real _Intensity;
    real _Iteration;
    real2 _Center;
    // TEXTURE2D(_MainTex);
    

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
      Blend One One

      HLSLPROGRAM

      // ! -------------------------------------
      // ! pass include

      // ! -------------------------------------
      // ! Shader阶段
      #pragma vertex Vert
      #pragma fragment frag

      // ! -------------------------------------
      // ! 材质关键字 shader_feature
      
      // ! -------------------------------------
      // ! 片元着色器
      real4 frag(Varyings input) : SV_TARGET
      {
        real2 uv = input.texcoord.xy;
        real4 color = RadialBlur(_BlitTexture, sampler_LinearClamp, uv, _Intensity, _Iteration, _Center);
        // real4 color = RadialBlur(_MainTex, sampler_LinearClamp, uv, _Intensity, _Iteration, _Center);

        return real4(color.rgb, 1.0);
      }

      ENDHLSL
    }
  }

  // ! -------------------------------------
  // ! 紫色报错fallback
  Fallback "Hidden/Universal Render Pipeline/FallbackError"
}

