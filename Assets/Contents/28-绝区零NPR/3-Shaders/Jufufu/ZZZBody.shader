Shader "Custom/ZZZNPR/ZZZBody"
{
  Properties
  {
    // ! -------------------------------------
    // ! 面板属性
    [NoScaleOffset]_MainTex ("主贴图", 2D) = "white" { }
    [NoScaleOffset]_BumpMap ("法线贴图", 2D) = "bump" { }
    [NoScaleOffset]_LightMap ("光照贴图", 2D) = "white" { }
    [NoScaleOffset]_LightMapA ("光照贴图A", 2D) = "white" { }
    [NoScaleOffset]_RampMap ("Ramp贴图", 2D) = "white" { }

    _Metallic ("金属度", Range(0, 1)) = 0.5
    _Smoothness ("光滑度", Range(0, 1)) = 0.5
    _BThreshold ("高光阈值", Range(0, 1)) = 0.5
    _BSmooth ("高光过渡", Range(0, 1)) = 0
    _HightLightColor ("高光颜色", Color) = (1, 1, 1, 1)

    _OutlineWidth ("描边宽度", Float) = 1
    _OutlineColor ("描边颜色", Color) = (0, 0, 0, 1)

    _SelfShadowStepEdge1 ("自阴影边缘1", Range(0, 1)) = 0.5
    _SelfShadowStepEdge2 ("自阴影边缘2", Range(0, 1)) = 0.5
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

    TEXTURE2D(_MainTex);
    SAMPLER(sampler_MainTex);
    TEXTURE2D(_BumpMap);
    SAMPLER(sampler_BumpMap);
    TEXTURE2D(_LightMap);
    SAMPLER(sampler_LightMap);
    TEXTURE2D(_LightMapA);
    SAMPLER(sampler_LightMapA);
    TEXTURE2D(_RampMap);
    SAMPLER(sampler_RampMap);

    CBUFFER_START(UnityPerMaterial)

      // ! -------------------------------------
      // ! 变量声明

      real _Metallic;
      real _Smoothness;

      real _BThreshold;
      real _BSmooth;
      real4 _HightLightColor;

      real _OutlineWidth;
      real4 _OutlineColor;

      real _SelfShadowStepEdge1;
      real _SelfShadowStepEdge2;

    CBUFFER_END

    int _PerObjSelfShadowIndex;

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
      #include "../../../25-崩铁NPR/1-Scripts/PerObjectShadow/Shader/PerObjectShadow.hlsl"

      // ! -------------------------------------
      // ! Shader阶段
      #pragma vertex vert
      #pragma fragment frag

      // ! -------------------------------------
      // ! 材质关键字

      // ! -------------------------------------
      // ! 顶点着色器输入
      struct appdata
      {
        real2 uv : TEXCOORD0;
        real4 positionOS : POSITION;
        real3 normalOS : NORMAL;
        real4 tangentOS : TANGENT;
        real4 vertexColor : COLOR;
      };

      // ! -------------------------------------
      // ! 顶点着色器输出 片元着色器输入
      struct v2f
      {
        real2 uv : TEXCOORD0;
        real4 positionCS : SV_POSITION;
        real3 positionWS : TEXCOORD1;
        real3 normalWS : TEXCOORD2;
        real4 tangentWS : TEXCOORD3;
        real3 bitangentWS : TEXCOORD4;
        real4 vertexColor : TEXCOORD5;
      };

      // ! -------------------------------------
      // ! 顶点着色器
      v2f vert(appdata v)
      {
        v2f o = (v2f)0;

        VertexPositionInputs positionInputs = GetVertexPositionInputs(v.positionOS.xyz);
        VertexNormalInputs normalInputs = GetVertexNormalInputs(v.normalOS, v.tangentOS);
        
        o.uv = v.uv;
        o.positionCS = positionInputs.positionCS;
        o.positionWS = positionInputs.positionWS;
        o.normalWS = normalInputs.normalWS;
        o.tangentWS = real4(normalInputs.tangentWS, 1.0);
        o.bitangentWS = normalInputs.bitangentWS;
        o.vertexColor = v.vertexColor;

        return o;
      }

      real4 GetMatColor(real halfLambert, real threshold, real smooth, real4 color1, real4 color2, real mask)
      {
        real edge1 = threshold;
        real edge2 = saturate(threshold + smooth);
        real stepValue = smoothstep(edge1, edge2, halfLambert);
        return lerp(color2, color1, stepValue) * mask;
      }

      Light GetCharacterMainLight(float4 shadowCoord, float3 positionWS)
      {
        Light light = GetMainLight();

        ShadowSamplingData shadowSamplingData = GetMainLightShadowSamplingData();
        half4 shadowParams = GetMainLightShadowParams();

        // 我自己试下来，在角色身上 LowQuality 比 Medium 和 High 好
        // Medium 和 High 采样数多，过渡的区间大，在角色身上更容易出现 Perspective aliasing
        shadowSamplingData.softShadowQuality = SOFT_SHADOW_QUALITY_LOW;
        light.shadowAttenuation = SampleShadowmap(TEXTURE2D_ARGS(_MainLightShadowmapTexture, sampler_LinearClampCompare), shadowCoord, shadowSamplingData, shadowParams, false);
        light.shadowAttenuation = lerp(light.shadowAttenuation, 1, GetMainLightShadowFade(positionWS));

        if (!IsMatchingLightLayer(light.layerMask, GetMeshRenderingLayer()))
        {
          // 偷个懒，直接把强度改成 0
          light.distanceAttenuation = 0;
          light.shadowAttenuation = 0;
        }

        return light;
      }

      // ! -------------------------------------
      // ! 片元着色器
      real4 frag(v2f i) : SV_TARGET
      {
        real4 mainTexColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
        real4 bumpMapColor = SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, i.uv);
        real4 lightMapColor = SAMPLE_TEXTURE2D(_LightMap, sampler_LightMap, i.uv);
        real4 lightMapColorA = SAMPLE_TEXTURE2D(_LightMapA, sampler_LightMapA, i.uv);

        real3x3 TBN = real3x3(i.tangentWS.xyz, i.bitangentWS, i.normalWS);
        real3 normalTS = UnpackNormal(bumpMapColor);
        half cascadeIndex = ComputeCascadeIndex(i.positionWS);
        float4 shadowCoord = float4(mul(_MainLightWorldToShadow[cascadeIndex], float4(i.positionWS, 1.0)).xyz, 0.0);
        Light mainLight = GetCharacterMainLight(shadowCoord, i.positionWS);

        real3 N = normalize(TransformTangentToWorld(normalTS, TBN));
        real3 L = normalize(mainLight.direction);
        real3 V = normalize(GetWorldSpaceViewDir(i.positionWS));
        real3 H = normalize(L + V);

        real NdotL = dot(N, L); // 兰伯特
        real NdotV = dot(N, V); // 菲尼尔
        real NdotH = dot(N, H); // 布林冯

        real orgHalfLambert = dot(i.normalWS, L) * 0.5 + 0.5;
        real halfLambert = NdotL * 0.5 + 0.5;

        real orgShadow = orgHalfLambert;

        real selfShadow = MainLightPerObjectSelfShadow(i.positionWS, _PerObjSelfShadowIndex);
        selfShadow = smoothstep(_SelfShadowStepEdge1, _SelfShadowStepEdge2, selfShadow);

        real2 rampUV = real2(orgHalfLambert, lightMapColor.r * 0.8 + 0.1);
        real4 rampColor = SAMPLE_TEXTURE2D(_RampMap, sampler_RampMap, rampUV);
        
        
        
        // return finalColor;
        
        real highLight = pow(max(NdotH, 0.01), _Metallic);
        highLight = smoothstep(_BThreshold, saturate(_BThreshold + _BSmooth), highLight);
        highLight *= lightMapColorA.g;
        real4 highColor = highLight * _HightLightColor;
        
        real4 finalColor = mainTexColor * rampColor + highColor;

        return finalColor;
        


        InputData inputData = (InputData)0;
        inputData.positionWS = i.positionWS;
        half3 viewDirWS = GetWorldSpaceNormalizeViewDir(i.positionWS);
        float sgn = i.tangentWS.w;      // should be either +1 or -1
        float3 bitangent = sgn * cross(i.normalWS.xyz, i.tangentWS.xyz);
        half3x3 tangentToWorld = half3x3(i.tangentWS.xyz, bitangent.xyz, i.normalWS.xyz);
        inputData.tangentToWorld = tangentToWorld;
        inputData.normalWS = TransformTangentToWorld(normalTS, tangentToWorld);
        inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
        inputData.viewDirectionWS = viewDirWS;
        inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
        inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(i.positionCS);
        // 重要：添加雾效和光照相关数据
        inputData.fogCoord = 0;
        // inputData.vertexLighting = half3(0, 0, 0);
        inputData.bakedGI = real3(1, 1, 1); // 使用球谐光照而不是固定值
        
        
        SurfaceData surfaceData = (SurfaceData)0;
        
        // 金属工作流配置 - 使用光照贴图控制
        
        // 确保 albedo 在正确的颜色空间
        surfaceData.albedo = mainTexColor.rgb; // 只使用RGB分量
        surfaceData.specular = half3(1, 1, 1); // metallic workflow
        surfaceData.metallic = _Metallic;
        surfaceData.normalTS = normalTS;
        surfaceData.smoothness = _Smoothness; // 确保不为0
        
        surfaceData.emission = half3(0.0, 0.0, 0.0);
        surfaceData.alpha = mainTexColor.a;
        surfaceData.occlusion = 1; // 使用R通道作为AO
        
        real4 pbrColor = UniversalFragmentPBR(inputData, surfaceData);
        
        return pbrColor;
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

      // ! -------------------------------------
      // ! Shader阶段
      #pragma vertex vert
      #pragma fragment frag

      // ! -------------------------------------
      // ! 材质关键字

      // ! -------------------------------------
      // ! 顶点着色器输入
      struct appdata
      {
        float3 positionOS : POSITION;

        float3 normalOS : NORMAL;
        float4 tangentOS : TANGENT;
        float4 color : COLOR;
        float2 uv1 : TEXCOORD0;
        float2 uv2 : TEXCOORD1;
      };


      // ! -------------------------------------
      // ! 顶点着色器输出 片元着色器输入
      struct v2f
      {
        real2 uv : TEXCOORD0;
        real4 positionCS : SV_POSITION;
      };

      // ! -------------------------------------
      // ! 顶点着色器
      v2f vert(appdata v)
      {
        v2f o = (v2f)0;

        real3 dist = distance(mul(UNITY_MATRIX_M, real4(v.positionOS, 1)), _WorldSpaceCameraPos);
        dist = lerp(1, dist, 0.5);

        real3 avgNormal = v.color * 2 - 1;

        real3 offset = _OutlineWidth * 0.0001 * avgNormal * dist;

        v.positionOS.xyz += offset;

        VertexPositionInputs vertexInputs = GetVertexPositionInputs(v.positionOS);

        o.positionCS = vertexInputs.positionCS;

        return o;
      }

      // ! -------------------------------------
      // ! 片元着色器
      real4 frag(v2f i) : SV_TARGET
      {
        return _OutlineColor;
      }

      ENDHLSL
    }

    Pass
    {
      Name "BodyShadow"
      Tags
      {
        "LightMode" = "PerObjectSelfShadowCaster"
      }

      ColorMask 0
      Cull Off
      ZWrite On
      ZTest LEqual

      HLSLPROGRAM

      #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
      // #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
      #include "../../../25-崩铁NPR/3-Shaders/ShadowCaster.hlsl"

      #pragma target 2.0

      #pragma shader_feature _ALPHATEST_ON
      #pragma shader_feature _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
      #pragma multi_compile_instancing

      #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW
      #pragma multi_compile_vertex _ _CASTING_SELF_SHADOW

      #pragma vertex vert
      #pragma fragment frag

      ENDHLSL
    }
  }

  // ! -------------------------------------
  // ! 紫色报错fallback
  Fallback "Hidden/Universal Render Pipeline/FallbackError"
}
