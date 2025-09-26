Shader "Custom/Normal/Transparent"
{
  Properties
  {
    _BaseColor ("Main Color", Color) = (1, 1, 1, 1)
    _BaseMap ("Main Texture", 2D) = "white" { }
    _AlphaScale ("Alpha Scale", Range(0, 1)) = 1
  }

  SubShader
  {
    LOD 200

    Tags
    {
      "Queue" = "AlphaTest"
      "RenderPipeline" = "UniversalPipeline"
    }

    HLSLINCLUDE

    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

    CBUFFER_START(UnityPerMaterial)

      float4 _BaseMap_ST;
      SamplerState NewRepeatPointSampler;

      float4 _BaseColor;

      TEXTURE2D(_CameraDepthTexture);
      SAMPLER(sampler_CameraDepthTexture);


    CBUFFER_END

    ENDHLSL

    pass
    {
      Name "UniversalForward"

      Tags
      {
        "LightMode" = "UniversalForward"
      }

      ZWrite On
      ZTest LEqual
      Blend SrcAlpha OneMinusSrcAlpha

      HLSLPROGRAM

      TEXTURE2D(_BaseMap);

      #pragma vertex vert
      #pragma fragment frag

      struct appdata
      {
        float4 posOS : POSITION;
        float2 uv : TEXCOORD0;
        float3 normalOS : NORMAL;
      };

      struct v2f
      {
        float4 posCS : SV_POSITION;
        float2 uv : TEXCOORD0;
        float3 posWS : TEXCOORD1;
        float3 normalWS : TEXCOORD2;
      };

      v2f vert(appdata v)
      {
        v2f o = (v2f)0;

        VertexPositionInputs posInputs = GetVertexPositionInputs(v.posOS.xyz);
        VertexNormalInputs normalInputs = GetVertexNormalInputs(v.normalOS);

        o.posCS = posInputs.positionCS;
        o.posWS = posInputs.positionWS;
        o.normalWS = normalInputs.normalWS;
        o.uv = TRANSFORM_TEX(v.uv, _BaseMap);

        return o;
      }

      float4 frag(v2f i) : SV_TARGET
      {
        Light mainLight = GetMainLight();
        real3 normalWS = normalize(i.normalWS);
        real3 lightDirWS = normalize(mainLight.direction);

        float4 texColor = SAMPLE_TEXTURE2D(_BaseMap, NewRepeatPointSampler, i.uv);

        float3 diffuse = max(0, dot(normalWS, lightDirWS)) * 0.5 + 0.5;

        // ! urp设置中 深度模式必须为ForcePrepass才会正常
        // real2 screenUV = (i.posCS / GetScaledScreenParams()).xy;
        // float depth = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, screenUV);
        // clip(i.posCS.z - depth);

        return real4(texColor.rgb * diffuse, texColor.a);
      }

      ENDHLSL
    }

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
  }

  Fallback "Hidden/Universal Render Pipeline/FallbackError"
}
