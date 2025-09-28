Shader "Custom/StarRail/Body"
{
  Properties
  {
    // ! -------------------------------------
    // ! 面板属性
    _DitherAlpha ("DitherAlpha", Range(0, 2)) = 2
    _AlphaTestThreshold ("透明裁剪阈值", Range(0, 1)) = 0.5

    [NoScaleOffset]_ColorMap ("颜色贴图", 2D) = "white" { }
    [NoScaleOffset]_LightMap ("光照贴图", 2D) = "white" { }

    _WarmOrCool ("暖调还是冷调", Range(0, 1)) = 0
    [NoScaleOffset]_WarmRamp ("暖光Ramp贴图", 2D) = "white" { }
    [NoScaleOffset]_CoolRamp ("冷光Ramp贴图", 2D) = "white" { }

    _Shininess ("高光", Range(0.1, 500)) = 10
    _Roughness ("粗糙度", Range(0, 1)) = 0.02
    _HightLightIntensity ("强度", Range(0, 100)) = 1

    _RimLight ("边缘光强度", Range(0, 1)) = 0.1

    _OutlineWidth ("描边宽度", Float) = 1
    _OutlineColor ("描边颜色", Color) = (0, 0, 0, 1)
  }
  
  SubShader
  {
    LOD 100

    // ! -------------------------------------
    // ! Tags
    Tags
    {
      "Queue" = "Geometry-30"
      "RenderPipeline" = "UniversalPipeline"
    }

    HLSLINCLUDE

    // ! -------------------------------------
    // ! 全shader include
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Macros.hlsl"
    #include "Assets/ShaderLibrary/Utility/NodeFromShaderGraph.hlsl"

    // ! -------------------------------------
    // ! 变量声明
    TEXTURE2D(_ColorMap); SAMPLER(sampler_ColorMap);
    TEXTURE2D(_LightMap); SAMPLER(sampler_LightMap);
    TEXTURE2D(_WarmRamp); SAMPLER(sampler_WarmRamp);
    TEXTURE2D(_CoolRamp); SAMPLER(sampler_CoolRamp);

    CBUFFER_START(UnityPerMaterial)

      // ! -------------------------------------
      // ! 变量声明
      real _WarmOrCool;
      real _Shininess;
      real _Roughness;
      real _HightLightIntensity;
      real _RimLight;
      real _OutlineWidth;
      real4 _OutlineColor;

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
      Cull Off
      ZTest LEqual
      ZWrite On
      Stencil
      {
        Ref 1
        Comp Always
        Pass Replace
        Fail Keep
      }

      HLSLPROGRAM

      // ! -------------------------------------
      // ! pass include

      // ! -------------------------------------
      // ! Shader阶段
      #pragma vertex vert
      #pragma fragment frag

      // ! -------------------------------------
      // ! 材质关键字
      // #pragma shader_feature _MAIN_LIGHT_SHADOWS_SCREEN
      // #pragma shader_feature _MAIN_LIGHT_SHADOWS
      // #pragma shader_feature _MAIN_LIGHT_SHADOWS_CASCADE
      // #pragma multi_compile_fragment _ _SHADOWS_SOFT

      // ! -------------------------------------
      // ! 顶点着色器输入
      struct appdata
      {
        real2 uv1 : TEXCOORD0;
        real2 uv2 : TEXCOORD1;
        real4 color : COLOR;
        real4 positionOS : POSITION;
        real3 normalOS : NORMAL;
      };

      // ! -------------------------------------
      // ! 顶点着色器输出 片元着色器输入
      struct v2f
      {
        real2 uv1 : TEXCOORD0;
        real2 uv2 : TEXCOORD1;
        real4 color : COLOR;
        real4 positionCS : SV_POSITION;
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
        
        o.uv1 = v.uv1;
        o.uv2 = v.uv2;
        o.color = v.color;
        o.positionCS = positionInputs.positionCS;
        o.positionWS = positionInputs.positionWS;
        o.normalWS = normalInputs.normalWS;

        return o;
      }

      // ! -------------------------------------
      // ! 片元着色器
      real4 frag(v2f i, FRONT_FACE_TYPE isFrontFace : FRONT_FACE_SEMANTIC) : SV_TARGET
      {
        // * 区分正反面uv
        real2 uv = lerp(i.uv1, i.uv2, IS_FRONT_VFACE(isFrontFace, 0, 1));

        // * 采样贴图
        real4 baseMapColor = SAMPLE_TEXTURE2D(_ColorMap, sampler_ColorMap, uv);
        real4 lightMapColor = SAMPLE_TEXTURE2D(_LightMap, sampler_LightMap, uv);
        // * lightmap
        // * r通道 高光强度
        // * g通道 ao
        // * b通道 高光遮罩 区别有高光的区域
        // * a通道 id 用来区别采集RampMap


        // * 获取必要信息
        real4 shadowCoord = TransformWorldToShadowCoord(i.positionWS);
        Light mainLight = GetMainLight(shadowCoord);
        real3 N = normalize(i.normalWS);
        real3 L = normalize(mainLight.direction);
        real3 V = normalize(GetWorldSpaceViewDir(i.positionWS));
        real3 H = normalize(L + V);
        real NdotL = dot(N, L); // 兰伯特
        real NdotH = dot(N, H); // 布林冯
        real NdotV = dot(N, V); // 菲尼尔

        // * 计算ramp贴图uv
        real ao = lightMapColor.g * i.color.r;
        real NdotL01 = NdotL * 0.5 + 0.5;
        float shadow = min(1.0f, dot(NdotL01.xx, 2 * ao.xx)); // ? dot(NdotL01.xx, 2 * ao.xx) 没看懂
        shadow = max(0.001f, shadow) * 0.75f + 0.25f; // ? 经验值
        shadow = (shadow > 1) ? 0.99f : shadow; // * 防止采样超出边界
        shadow = lerp(0.20, shadow, saturate(mainLight.shadowAttenuation + HALF_EPS));
        shadow = lerp(0, shadow, step(0.05, ao)); // AO < 0.05 的区域（自阴影区域）永远不受光
        shadow = lerp(1, shadow, step(ao, 0.95)); // AO > 0.95 的区域永远受最强光
        real2 rampUV = real2(shadow, lightMapColor.a + 0.05);

        // * 采样ramp贴图
        real4 warmRampColor = SAMPLE_TEXTURE2D(_WarmRamp, sampler_WarmRamp, rampUV);
        real4 coolRampColor = SAMPLE_TEXTURE2D(_CoolRamp, sampler_CoolRamp, rampUV);
        real4 rampColor = lerp(warmRampColor, coolRampColor, _WarmOrCool);

        // * 高光
        float attenuation = mainLight.shadowAttenuation * saturate(mainLight.distanceAttenuation);
        float blinnPhong = pow(max(0.01, NdotH), _Shininess) * attenuation;
        float threshold = 1.03 - lightMapColor.b; // * 高光材质阈值
        float specular = smoothstep(threshold - _Roughness, threshold + _Roughness, blinnPhong); // * 高光
        specular *= lightMapColor.r * _HightLightIntensity;
        real4 specularColor = real4(baseMapColor * mainLight.color * specular, 1);

        // * 边缘光
        real fresnel = pow(1.01 - saturate(NdotV), 10);
        real4 rimLight = step(_RimLight, fresnel * lightMapColor.g) * baseMapColor;

        real4 finalColor = baseMapColor * rampColor + specularColor + rimLight;

        // float s = MainLightRealtimeShadow(shadowCoord);
        // return s;

        return real4(finalColor.rgb, 1);
      }

      ENDHLSL
    }

    Pass
    {
      // ! -------------------------------------
      // ! Pass名
      Name "OutlinePass"

      // ! -------------------------------------
      // ! tags
      Tags
      {
        "LightMode" = "Outline"
      }

      // ! -------------------------------------
      // ! 渲染状态
      Cull Front
      ZTest LEqual
      ZWrite On

      HLSLPROGRAM

      // ! -------------------------------------
      // ! pass include
      #include "Outline.hlsl"

      // ! -------------------------------------
      // ! Shader阶段
      #pragma vertex vert
      #pragma fragment frag

      

      ENDHLSL
    }

    pass
    {
      Name "ShadowCaster"
      Tags
      {
        "LightMode" = "ShadowCaster"
      }

      ColorMask 0
      Cull Back
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

  // ! -------------------------------------
  // ! 紫色报错fallback
  Fallback "Hidden/Universal Render Pipeline/FallbackError"
}
