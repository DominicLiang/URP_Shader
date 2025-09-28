Shader "Custom/Normal/QuickSSSWithPBR"
{
  Properties
  {
    // ! -------------------------------------
    // ! 面板属性
    [Enum(Off, 0, Front, 1, Back, 2)]_Cull ("CullMode", Float) = 2

    _BaseMap ("主贴图", 2D) = "white" { }
    _BaseColor ("主颜色", Color) = (1, 1, 1, 1)

    [Toggle(_ALPHATEST_ON)]_AlphaTest_On ("AlphaClip", Float) = 0
    _Cutoff ("Clip阈值", Float) = 0.5

    [Toggle(_NORMALMAP)]_NormalMap_On ("开启法线贴图", Float) = 0
    [NoScaleOffset]_BumpMap ("法线贴图", 2D) = "bump" { }
    _BumpScale ("法线强度", Float) = 1.0
    
    
    [NoScaleOffset]_EmissionMap ("自发光贴图", 2D) = "black" { }
    [HDR]_EmissionColor ("自发光颜色", Color) = (0, 0, 0, 0)
    
    [NoScaleOffset]_MetallicGlossMap ("金属度贴图", 2D) = "white" { }
    _Metallic ("金属度强度", Range(0, 1)) = 0
    
    [NoScaleOffset]_SpecGlossMap ("光滑度贴图", 2D) = "white" { }
    [Toggle(_INVERSE_SMOOTHNESS)]_Inverse_Smoothness ("反转光滑度(粗糙度)", Float) = 0
    _Smoothness ("光滑度强度", Range(0, 1)) = 0

    [Toggle(_SSS_ON)]_SSS_Switch ("次表面漫反射开关", Float) = 1
    [NoScaleOffset]_ThicknessMap ("厚度贴图", 2D) = "white" { }
    _ThicknessFactor ("厚度贴图系数", Range(0, 1)) = 1
    _SSSColor ("次表面颜色", Color) = (1, 1, 1, 1)
    _DistortionFactor ("背光法线扰动系数", Range(0, 1)) = 1
    _BackPower ("背光集中度", Range(1, 4)) = 1
    _BackStrength ("背光强度", Range(1, 4)) = 1
    _BackAmbient ("背光环境光强度", Range(0, 4)) = 0
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
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

    // ! -------------------------------------
    // ! 全shader材质关键字
    #pragma shader_feature _ALPHATEST_ON  // * 所有pass通用 如果要alphatest 必须关键字 _ALPHATEST_ON
    
    #pragma shader_feature _NORMALMAP
    #pragma shader_feature _INVERSE_SMOOTHNESS

    #pragma multi_compile_instancing  // * 所有pass通用 GPU实例化支持
    #pragma multi_compile _ LIGHTMAP_ON
    #pragma multi_compile _MAIN_LIGHT_SHADOWS
    #pragma multi_compile _MAIN_LIGHT_SHADOWS_CASCADE
    // ! 点光源支持
    #pragma multi_compile _ADDITIONAL_LIGHTS
    // ! 点光源投射阴影
    #pragma multi_compile _ADDITIONAL_LIGHT_SHADOWS

    TEXTURE2D(_MetallicGlossMap);
    SAMPLER(sampler_MetallicGlossMap);
    TEXTURE2D(_SpecGlossMap);
    SAMPLER(sampler_SpecGlossMap);

    TEXTURE2D(_ThicknessMap);
    SAMPLER(sampler_ThicknessMap);

    CBUFFER_START(UnityPerMaterial)
      real4 _BaseMap_ST;
      real4 _BaseColor;
      real4 _EmissionColor;
      real _Cutoff;
      real _Smoothness;
      real _Metallic;
      real _BumpScale;

      // ! -------------------------------------
      // ! 自定义属性
      real _ThicknessFactor;
      real4 _SSSColor;
      real _DistortionFactor;
      real _BackPower;
      real _BackStrength;
      real _BackAmbient;
      
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
      Cull [_Cull]
      ZTest LEqual
      ZWrite On

      HLSLPROGRAM

      // ! -------------------------------------
      // ! pass include
      #include "Assets/Editor/UrpShaderTemplate/Template/HLSL/pass.hlsl"
      #include "Assets/ShaderLibrary/Utility/Node.hlsl"

      // ! -------------------------------------
      // ! Shader阶段
      #pragma vertex vert
      #pragma fragment frag

      // ! -------------------------------------
      // ! 材质关键字
      #pragma multi_compile _ _SSS_ON

      // ! -------------------------------------
      // ! 顶点着色器输入
      struct appdata { };

      // ! -------------------------------------
      // ! 顶点着色器输出 片元着色器输入
      struct v2f { };

      // ! -------------------------------------
      // ! 顶点着色器
      void vert(Attributes input, appdata v, out Varyings output, out v2f o)
      {
        InitVaryings(input, output);

        o = (v2f)0;
      }

      // ! 初始化SurfaceData 可自定义
      void InitializeStandardLitSurfaceDataCustom(float2 uv, out SurfaceData outSurfaceData)
      {
        outSurfaceData = (SurfaceData)0;

        half4 albedoAlpha = SampleAlbedoAlpha(uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap));
        outSurfaceData.alpha = Alpha(albedoAlpha.a, _BaseColor, _Cutoff);

        outSurfaceData.albedo = albedoAlpha.rgb * _BaseColor.rgb;
        outSurfaceData.albedo = AlphaModulate(outSurfaceData.albedo, outSurfaceData.alpha);
        
        half4 specGloss = SAMPLE_TEXTURE2D(_MetallicGlossMap, sampler_MetallicGlossMap, uv);
        outSurfaceData.metallic = specGloss.r * _Metallic;
        outSurfaceData.specular = half3(0.0, 0.0, 0.0);

        real smoothness = SAMPLE_TEXTURE2D(_SpecGlossMap, sampler_SpecGlossMap, uv).r;
        #ifdef _INVERSE_SMOOTHNESS
          smoothness = 1 - saturate(smoothness);
        #endif

        outSurfaceData.smoothness = smoothness * _Smoothness;

        outSurfaceData.normalTS = SampleNormal(uv, TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap), _BumpScale);
        outSurfaceData.occlusion = SampleOcclusion(uv);
        outSurfaceData.emission = SampleEmission(uv, _EmissionColor.rgb, TEXTURE2D_ARGS(_EmissionMap, sampler_EmissionMap));
      }

      // ! -------------------------------------
      // ! 片元着色器
      real4 frag(Varyings input, v2f i) : SV_TARGET
      {
        SurfaceData surfaceData;
        InitializeStandardLitSurfaceDataCustom(input.uv, surfaceData);
        InputData inputData;
        InitializeInputData(input, surfaceData.normalTS, inputData);

        real4 color = UniversalFragmentPBR(inputData, surfaceData);

        #ifdef _SSS_ON

          Light mainLight = GetMainLight();
          real3 N = inputData.normalWS;
          real3 V = inputData.viewDirectionWS;

          real thickness = SAMPLE_TEXTURE2D(_ThicknessMap, sampler_ThicknessMap, input.uv);
          thickness = thickness * _ThicknessFactor;
          
          real3 mainLightSSS = QuickSSS(mainLight.direction, N, V, thickness, _DistortionFactor, _BackPower, _BackStrength);
          color.rgb += mainLightSSS * _SSSColor.rgb * mainLight.color * mainLight.shadowAttenuation;

          for (int index = 0; index < GetAdditionalLightsCount(); index++)
          {
            Light light = GetAdditionalLight(index, inputData.positionWS);

            real3 lightSSS = QuickSSS(light.direction, N, V, thickness, _DistortionFactor, _BackPower, _BackStrength);
            color.rgb += lightSSS * _SSSColor.rgb * light.color * light.shadowAttenuation;
          }

        #endif

        return color ;
      }

      ENDHLSL
    }

    pass
    {
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

      // ! 必须的include
      #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
      #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
      #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"

      // ! 阴影pass限定 更好的支持局部光照
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

      // ! 注意这里引用DepthOnlyPass.hlsl
      #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
      #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
      #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"

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

      // ! 注意这里引用DepthNormalsPass.hlsl
      #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
      #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
      #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthNormalsPass.hlsl"

      // ! 写入到normalmap中
      #pragma shader_feature_local _NORMAL_MAP

      // ! 使用顶点片元着色器也要写对
      #pragma vertex DepthNormalsVertex
      #pragma fragment DepthNormalsFragment

      ENDHLSL
    }
  }

  // ! -------------------------------------
  // ! 紫色报错fallback
  Fallback "Hidden/Universal Render Pipeline/FallbackError"
}
