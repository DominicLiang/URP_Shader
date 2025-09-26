Shader "Custom/Normal/TransparentDepth"
{
  Properties
  {
    // ! -------------------------------------
    // ! 面板属性
    [NoScaleOffset]_MainTex ("主贴图", 2D) = "white" { }
    [HDR]_MainColor ("主颜色", Color) = (1, 1, 1, 1)
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
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

    CBUFFER_START(UnityPerMaterial)

      // ! -------------------------------------
      // ! 变量声明
      TEXTURE2D(_MainTex);
      SAMPLER(sampler_MainTex);
      real4 _MainColor;

    CBUFFER_END

    ENDHLSL

    Pass
    {
      // ! -------------------------------------
      // ! Pass名
      Name "DepthPass"

      // ! -------------------------------------
      // ! tags
      Tags
      {
        "LightMode" = "TransparentDepth"
      }

      // ! -------------------------------------
      // ! 渲染状态
      ZWrite On
      ColorMask 0
    }

    Pass
    {
      // ! -------------------------------------
      // ! Pass名
      Name "ColorPass"

      // ! -------------------------------------
      // ! tags
      Tags
      {
        "LightMode" = "UniversalForward"
      }

      // ! -------------------------------------
      // ! 渲染状态
      ZWrite Off
      Blend SrcAlpha OneMinusSrcAlpha

      HLSLPROGRAM

      // ! -------------------------------------
      // ! pass include
      #pragma multi_compile LIGHTMAP_ON

      // ! -------------------------------------
      // ! Shader阶段
      #pragma vertex vert
      #pragma fragment frag

      // ! -------------------------------------
      // ! 顶点着色器输入
      struct appdata
      {
        real2 uv : TEXCOORD0;
        real4 positionOS : POSITION;
        real3 normalOS : NORMAL;
        real2 lightmapUV : TEXCOORD1;
      };

      // ! -------------------------------------
      // ! 顶点着色器输出 片元着色器输入
      struct v2f
      {
        real2 uv : TEXCOORD0;
        real4 positionCS : SV_POSITION;
        DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 1);
        real3 positionWS : TEXCOORD2;
        real3 normalWS : TEXCOORD3;
      };

      // ! -------------------------------------
      // ! 顶点着色器
      v2f vert(appdata v)
      {
        v2f o = (v2f)0;

        VertexPositionInputs positionInputs = GetVertexPositionInputs(v.positionOS.xyz);
        VertexNormalInputs normalInputs = GetVertexNormalInputs(v.normalOS);
        
        o.uv = v.uv;

        o.positionCS = positionInputs.positionCS;
        o.positionWS = positionInputs.positionWS;
        o.normalWS = normalInputs.normalWS;

        OUTPUT_LIGHTMAP_UV(v.lightmapUV, unity_LightmapST, o.lightmapUV);
        OUTPUT_SH(v.normalOS, o.vertexSH);

        

        return o;
      }

      // ! -------------------------------------
      // ! 片元着色器
      real4 frag(v2f i) : SV_TARGET
      {
        real4 tex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv) * _MainColor;

        real3 N = normalize(i.normalWS);
        real3 V = normalize(GetCameraPositionWS() - i.positionWS);
        real NdotV = saturate(dot(N, V));

        real3 bakedGI = SAMPLE_GI(i.lightmapUV, i.vertexSH, i.normalWS);

        tex.rgb *= NdotV.rrr;
        tex.rgb *= bakedGI;
        
        return tex;
      }

      ENDHLSL
    }
  }

  // ! -------------------------------------
  // ! 紫色报错fallback
  Fallback "Hidden/Universal Render Pipeline/FallbackError"
}
