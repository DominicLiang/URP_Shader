Shader "Hidden/PerObjectScreenSpaceShadow"
{
  SubShader
  {
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

    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
    #include "PerObjectShadow.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
    #include "Assets/ShaderLibrary/Utility/Node.hlsl"

    // ! -------------------------------------
    // ! 变量声明

    ENDHLSL

    Pass
    {
      // ! -------------------------------------
      // ! Pass名
      Name "BasePass"

      // ! -------------------------------------
      // ! 渲染状态
      ZTest Always
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
      #pragma multi_compile _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE
      #pragma multi_compile_fragment _ _SHADOWS_SOFT _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH

      // ! -------------------------------------
      // ! 片元着色器
      real4 frag(Varyings input) : SV_TARGET
      {
        // UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

        #if UNITY_REVERSED_Z
          float deviceDepth = SAMPLE_TEXTURE2D_X(_CameraDepthTexture, sampler_PointClamp, input.texcoord.xy).r;
        #else
          float deviceDepth = SAMPLE_TEXTURE2D_X(_CameraDepthTexture, sampler_PointClamp, input.texcoord.xy).r;
          deviceDepth = deviceDepth * 2.0 - 1.0;
        #endif
        

        // Fetch shadow coordinates for cascade.
        float3 positionWS = ComputeWorldSpacePosition(input.texcoord.xy, deviceDepth, UNITY_MATRIX_I_VP);
        float4 shadowCoord = input.positionCS / GetScaledScreenParams();
        half realtimeShadow = half(SAMPLE_TEXTURE2D(_ScreenSpaceShadowmapTexture, sampler_PointClamp, shadowCoord.xy).x);

        // // Screenspace shadowmap is only used for directional lights which use orthogonal projection.
        // half realtimeShadow = MainLightRealtimeShadow();

        float perObjShadow = MainLightPerObjectSceneShadow(positionWS);


        
        return min(realtimeShadow, perObjShadow);
        // return realtimeShadow;

      }

      ENDHLSL
    }
  }

  // ! -------------------------------------
  // ! 紫色报错fallback
  Fallback "Hidden/Universal Render Pipeline/FallbackError"
}

