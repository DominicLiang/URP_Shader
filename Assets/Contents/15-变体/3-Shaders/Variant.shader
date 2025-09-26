Shader "Custom/Normal/Variant"
{
  Properties
  {
    // ! -------------------------------------
    // ! 面板属性
    [KeywordEnum(Low, Medium, High, Best)]_Quality ("质量模式", Float) = 0
    [KeywordEnum(ReflectDotView, HalfAngle)]_Specular ("高光模式", Float) = 0

    [NoScaleOffset]_MainTex ("主贴图", 2D) = "white" { }
    [HDR]_MainColor ("主颜色", Color) = (1, 1, 1, 1)
    _HalfLamberIntensity ("半兰伯特强度", Range(0, 1)) = 0.5
    _RimIntensity ("轮廓光强度", Range(0, 2)) = 0.5
    _SpecularIntensity ("高光强度1", Range(0, 100)) = 1
    _SpecularStrengthen ("高光强度2", Range(0, 1)) = 1
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
      TEXTURE2D(_MainTex);
      SAMPLER(sampler_MainTex);
      real4 _MainColor;
      real _HalfLamberIntensity;
      real _RimIntensity;
      real _SpecularIntensity;
      real _SpecularStrengthen;

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

      // * 如果要运行时切换就用multi_compile 不需要运行时切换用shader_feature
      // * multi_compile所有变体都会被打包
      // * shader_feature如果没有启动的变体会被排除
      #pragma multi_compile __ _QUALITY_LOW _QUALITY_MEDIUM _QUALITY_HIGH _QUALITY_BEST
      #pragma shader_feature __ _SPECULAR_REFLECTDOTVIEW _SPECULAR_HALFANGLE



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
        real3 positionWS : TEXCOORD3;
        real3 normalWS : TEXCOORD4;
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

      real GetNdotL(Light light, real3 normalWS)
      {
        real3 N = normalize(normalWS);
        real3 L = normalize(light.direction);
        real NdotL = dot(N, L);
        return NdotL;
      }

      // ! -------------------------------------
      // ! 片元着色器
      real4 frag(v2f i) : SV_TARGET
      {
        real4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);

        Light light = GetMainLight();
        
        #if _QUALITY_LOW
          
          color.rgb *= _MainColor.rgb;
          
        #elif _QUALITY_MEDIUM
          
          real NdotL = GetNdotL(light, i.normalWS);
          _HalfLamberIntensity = 1 - _HalfLamberIntensity;
          color.rgb *= NdotL * _HalfLamberIntensity * 0.5 + (1 - _HalfLamberIntensity) * 0.5;

        #elif _QUALITY_HIGH

          real NdotL = GetNdotL(light, i.normalWS);
          _HalfLamberIntensity = 1 - _HalfLamberIntensity;
          color.rgb *= NdotL * _HalfLamberIntensity * 0.5 + (1 - _HalfLamberIntensity) * 0.5;

          real3 viewDirWS = normalize(_WorldSpaceCameraPos.xyz - i.positionWS);
          real3 reflectDir = reflect(-light.direction, i.normalWS);
          real3 specular = pow(saturate(dot(reflectDir, viewDirWS)), _SpecularIntensity) * light.color;
          
          color.rgb += specular;
          
          real3 rimLight = (1 - max(0, dot(normalize(i.normalWS), viewDirWS))) * _RimIntensity * light.color;
          
          color.rgb += rimLight;
          
        #elif _QUALITY_BEST

          real NdotL = GetNdotL(light, i.normalWS);
          _HalfLamberIntensity = 1 - _HalfLamberIntensity;
          color.rgb *= NdotL * _HalfLamberIntensity * 0.5 + (1 - _HalfLamberIntensity) * 0.5;

          real3 viewDirWS = normalize(_WorldSpaceCameraPos.xyz - i.positionWS);

          #if _SPECULAR_HALFANGLE // Blinn-Phong

            real3 LV = light.direction + viewDirWS;
            real blinnPhong = saturate(dot(normalize(i.normalWS), normalize(LV)));
            real3 specular = pow(blinnPhong, _SpecularIntensity) * light.color;
            
          #else // Phong

            real3 Phong = reflect(-light.direction, i.normalWS);
            real3 specular = pow(saturate(dot(Phong, viewDirWS)), _SpecularIntensity) * light.color;

          #endif

          color.rgb += specular;

          real3 rimLight = (1 - max(0, dot(normalize(i.normalWS), viewDirWS))) * _RimIntensity * light.color;
          
          color.rgb += rimLight;
          
        #endif

        return color;
      }

      ENDHLSL
    }
  }

  // ! -------------------------------------
  // ! 紫色报错fallback
  Fallback "Hidden/Universal Render Pipeline/FallbackError"
}
