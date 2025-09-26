Shader "Custom/Normal/BlinnPhong"
{
  Properties
  {
    // ! -------------------------------------
    // ! 面板属性
    [HDR]_MainColor ("主颜色", Color) = (1, 1, 1, 1)
    _Gloss ("光泽度", Range(8, 200)) = 10
    _SpecularColor ("高光颜色", Color) = (1, 1, 1, 1)
  }
  
  SubShader
  {
    LOD 100

    // ! -------------------------------------
    // ! Tags
    Tags
    {
      "Queue" = "Geometry"
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
      real4 _MainColor;
      real _Gloss;
      real4 _SpecularColor;

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
        real3 normalOS : NORMAL;
      };

      // ! -------------------------------------
      // ! 顶点着色器输出 片元着色器输入
      struct v2f
      {
        real2 uv : TEXCOORD0;
        real4 positionCS : SV_POSITION;
        real3 positionWS : TEXCOORD1;
        real3 normalWS : TEXCOORD2;
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

        return o;
      }

      half BlinnPhong(real3 positionWS, real3 lightDirWS, half3 normalWS, real gloss)
      {
        half3 viewDirWS = normalize(GetCameraPositionWS() - positionWS);
        half3 H = normalize(lightDirWS + viewDirWS);
        half specular = pow(max(0, dot(normalWS, H)), gloss);
        return specular;
      }

      // ! -------------------------------------
      // ! 片元着色器
      real4 frag(v2f i) : SV_TARGET
      {
        Light mainLight = GetMainLight();

        real3 N = normalize(i.normalWS);
        real3 L = normalize(mainLight.direction);
        real NdotL = dot(N, L) * 0.5 + 0.5;
        real3 color = mainLight.color * NdotL * _MainColor;

        // ! half3 LightingSpecular(half3 lightColor, half3 lightDir, half3 normal, half3 viewDir, half4 specular, half smoothness)
        // ! 在Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl

        // BlinnPhong
        // real3 V = normalize(GetCameraPositionWS() - i.positionWS);
        // real3 H = normalize(L + V);
        // real3 specular = pow(max(0, dot(N, H)), _Gloss);
        real3 specular = BlinnPhong(i.positionWS, L, N, _Gloss);
        specular *= mainLight.color * _SpecularColor;
        color += specular;

        return real4(color, 1);
      }

      ENDHLSL
    }
  }

  // ! -------------------------------------
  // ! 紫色报错fallback
  Fallback "Hidden/Universal Render Pipeline/FallbackError"
}
