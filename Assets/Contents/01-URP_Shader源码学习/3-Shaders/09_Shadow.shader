Shader "Custom/01-WriteShader/09_Shadow"
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
      // ! 关键变量
      // ! 这里面已经包含_BaseMap的贴图定义 你不能使用这个变量名 但是你得有_BaseMap_ST这个变量
      // ! 你需要有_BaseColor这个变量
      // ! 如果你不是用_BaseColor可以用宏将_BaseColor隐射到你自己定义的变量上 如下
      // ! #define _BaseColor _MyColor
      

      // ! 使用URP自带的阴影顶点片元着色器 ShadowPassVertex ShadowPassFragment
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

      // ! 必须的三个include
      #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
      #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
      #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"

      // ! 所有pass通用 如果要alphatest 必须关键字 _ALPHATEST_ON 只要有这个shader_feature就行 其他不需要自己写
      #pragma shader_feature _ALPHATEST_ON
      // ! 所有pass通用 将颜色贴图的A通道作为PBR的平滑值来使用
      #pragma shader_feature _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
      // ! 所有pass通用 GPU实例化支持
      #pragma multi_compile_instancing

      // ! 阴影pass限定 更好的支持局部光照
      #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW

      

      #pragma vertex ShadowPassVertex
      #pragma fragment ShadowPassFragment

      ENDHLSL
    }
  }

  Fallback "Hidden/Universal Render Pipeline/FallbackError"
}