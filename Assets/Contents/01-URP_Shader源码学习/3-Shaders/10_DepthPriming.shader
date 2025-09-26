Shader "Custom/01-WriteShader/10_DepthPriming"
{
  Properties
  {
    _BaseMap ("Main Texture", 2D) = "white" { }
    _BaseColor ("Main Color", Color) = (1, 1, 1, 1)
    _Cutoff ("Alpha Cutoff", Range(0, 1)) = 0.5
    [Toggle(_ALPHATEST_ON)] _AlphaTestToggle ("Alpha Clipping", float) = 0
    [Enum(Off, 0, Front, 1, Back, 2)]_Cull ("Cull Mode", float) = 2
  }

  SubShader
  {
    LOD 200

    Tags
    {
      "Queue" = "Geometry"
      "RenderPipeline" = "UniversalPipeline"
    }

    Cull [_Cull]
    ZTest LEqual
    ZWrite On

    HLSLINCLUDE

    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

    CBUFFER_START(UnityPerMaterial)

      float4 _BaseMap_ST;
      SamplerState NewRepeatPointSampler;

      float4 _BaseColor;

      float _Cutoff;

    CBUFFER_END

    ENDHLSL

    pass
    {
      Name "AlphaClip"

      Tags
      {
        "LightMode" = "UniversalForward"
      }

      HLSLPROGRAM

      TEXTURE2D(_BaseMap);

      #pragma shader_feature _ALPHATEST_ON

      #pragma vertex vert
      #pragma fragment frag

      struct appdata
      {
        float4 posOS : POSITION;
        float2 uv : TEXCOORD0;
        float4 color : COLOR;
      };

      struct v2f
      {
        float4 posCS : SV_POSITION;
        float2 uv : TEXCOORD0;
        float4 color : COLOR;
      };

      v2f vert(appdata v)
      {
        v2f o = (v2f)0;

        VertexPositionInputs posInputs = GetVertexPositionInputs(v.posOS.xyz);

        o.posCS = posInputs.positionCS;
        o.uv = TRANSFORM_TEX(v.uv, _BaseMap);
        o.color = v.color;

        return o;
      }

      float4 frag(v2f i) : SV_TARGET
      {
        float4 mainTexColor = SAMPLE_TEXTURE2D(_BaseMap, NewRepeatPointSampler, i.uv);

        #ifdef _ALPHATEST_ON
          clip(mainTexColor.a - _Cutoff);
        #endif

        return mainTexColor * _BaseColor * i.color;
      }

      ENDHLSL
    }

    // UsePass "Universal Render Pipeline/Lit/ShadowCaster"

    pass
    {
      Name "ShadowCaster"
      Tags
      {
        "LightMode" = "ShadowCaster"
      }

      ColorMask 0
      Cull [_Cull]
      ZWrite On
      ZTest LEqual

      HLSLPROGRAM

      #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
      #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
      #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"

      #pragma shader_feature _ALPHATEST_ON
      #pragma shader_feature _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
      #pragma multi_compile_instancing
      #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW

      #pragma vertex ShadowPassVertex
      #pragma fragment ShadowPassFragment

      ENDHLSL
    }

    // ! 支持深度引动模式 如果在urp设置中开启了深度引动模式 不写这个pass无法显示哦
    pass
    {
      Name "DepthOnly"

      Tags
      {
        // ! LightMode一定要写对
        "LightMode" = "DepthOnly"
      }

      ZWrite On
      ZTest LEqual

      ColorMask 0

      HLSLPROGRAM

      #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
      #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
      // ! 注意这里引用DepthOnlyPass.hlsl
      #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"

      #pragma shader_feature _ALPHATEST_ON
      #pragma shader_feature _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
      #pragma multi_compile_instancing

      // ! 使用顶点片元着色器也要写对
      #pragma vertex DepthOnlyVertex
      #pragma fragment DepthOnlyFragment

      ENDHLSL
    }

    // ! 支持MSAA
    pass
    {
      Name "DepthNormals"

      Tags
      {
        // ! LightMode一定要写对
        "LightMode" = "DepthNormals"
      }

      ZWrite On
      ZTest LEqual

      HLSLPROGRAM

      #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
      #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
      // ! 注意这里引用DepthNormalsPass.hlsl
      #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthNormalsPass.hlsl"

      #pragma shader_feature _ALPHATEST_ON
      #pragma shader_feature _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
      #pragma multi_compile_instancing
      
      // ! 写入到normalmap中
      #pragma shader_feature_local _NORMAL_MAP

      // ! 使用顶点片元着色器也要写对
      #pragma vertex DepthNormalsVertex
      #pragma fragment DepthNormalsFragment

      ENDHLSL
    }
  }

  Fallback "Hidden/Universal Render Pipeline/FallbackError"
}