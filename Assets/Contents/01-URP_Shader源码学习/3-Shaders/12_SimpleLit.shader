Shader "Custom/01-WriteShader/12_SimpleLit"
{
  Properties
  {
    // ! 模式选择
    [Enum(Off, 0, Front, 1, Back, 2)]_Cull ("Cull Mode", Float) = 2
    // ! 基础
    _MainTex ("Main Texture", 2D) = "white" { }
    _MainColor ("Main Color", Color) = (1, 1, 1, 1)
    // ! Alphaclip
    [Toggle(ALPHATEST_ON)]_AlphaClip ("Alpha Clip", Float) = 0
    _Cutoff ("Alpha Clip Threshold", Range(0, 1)) = 0.5
    // ! 法线贴图
    [Toggle(_NORMALMAP)]_NormalMapToggle ("Use Normal Map", Float) = 0
    [NoScaleOffset]_BumpMap ("Normal Map", 2D) = "bump" { }
    // ! 自发光
    [Toggle(_EMISSION)]_EmissionToggle ("Use Emission", Float) = 0
    [HDR]_EmissionColor ("Emission Color", Color) = (0, 0, 0, 0)
    [NoScaleOffset]_EmissionMap ("Emission Map", 2D) = "white" { }
    // ! Specular
    [Toggle(_SPECGLOSSMAP)]_SpecularMapToggle ("Use Specular Map", Float) = 0
    _SpecualrColor ("Specualr Color", Color) = (0.5, 0.5, 0.5, 0.5)
    [NoScaleOffset]_SpecGlosMap ("Specular Map", 2D) = "white" { }
    // ! Glossiness
    [Toggle(_GLOSSINESS_FROM_BASE_ALPHA))]_GlossinessSource ("Glossiness From Base Alpha", Float) = 0
    _Glossiness ("Glossiness", Range(0, 2)) = 1
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
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"

    CBUFFER_START(UnityPerMaterial)

      TEXTURE2D(_MainTex);
      float4 _MainTex_ST;
      SamplerState NewRepeatPointSampler;

      float4 _MainColor;

      float _Cutoff;

      float4 _EmissionColor;
      float4 _SpecualrColor;
      float _Glossiness;

      TEXTURE2D(_SpecGlosMap);
      SAMPLER(sampler_SpecGlosMap);

    CBUFFER_END

    ENDHLSL

    pass
    {
      Name "ForwardLit"

      Tags
      {
        "LightMode" = "UniversalForward"
      }

      HLSLPROGRAM

      #pragma shader_feature ALPHATEST_ON
      // ! 这个关键字只能用_NORMALMAP哦 因为urp内置的SampleNormal方法只认这个
      #pragma shader_feature _NORMALMAP
      // ! 这个同样只能用_EMISSION 内置的SampleEmission同样用到
      #pragma shader_feature _EMISSION
      #pragma shader_feature _SPECGLOSSMAP
      #pragma shader_feature _GLOSSINESS_FROM_BASE_ALPHA

      #pragma multi_compile LIGHTMAP_ON
      // ! 主灯阴影支持
      #pragma multi_compile _MAIN_LIGHT_SHADOWS
      #pragma multi_compile _MAIN_LIGHT_SHADOWS_CASCADE
      // ! 点光源支持
      #pragma multi_compile _ADDITIONAL_LIGHTS
      // ! 点光源投射阴影
      #pragma multi_compile _ADDITIONAL_LIGHT_SHADOWS

      #pragma vertex vert
      #pragma fragment frag

      struct appdata
      {
        float4 posOS : POSITION;
        float4 normalOS : NORMAL;
        
        // ! 物体空间的切线 NormalMap需要用到
        #ifdef _NORMALMAP
          float4 tangentOS : TANGENT;
        #endif
        
        float2 uv : TEXCOORD0;
        float2 lightmapUV : TEXCOORD1;
        float4 color : COLOR;
      };

      struct v2f
      {
        float4 posCS : SV_POSITION;
        float2 uv : TEXCOORD0;
        DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 1);

        float3 posWS : TEXCOORD2;

        // ! 世界空间的切线 NormalMap需要用到
        #ifdef _NORMALMAP
          float4 normalWS : TEXCOORD3;
          float4 tangentWS : TEXCOORD4;
          float4 bitangentWS : TEXCOORD5;
        #else
          float3 normalWS : TEXCOORD3;
        #endif

        // ! x: 雾效信息 yzw: 顶点光照信息
        #ifdef _ADDITIONAL_LIGHTS_VERTEX
          float4 fogFactorAndVertexLight : TEXCOORD6;
        #else
          float fogFactor : TEXCOORD6;
        #endif

        // ! 点光源阴影
        #ifdef REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR
          float4 shadowCoord : TEXCOORD7;
        #endif

        float4 color : COLOR;
      };

      v2f vert(appdata v)
      {
        v2f o = (v2f)0;

        VertexPositionInputs posInputs = GetVertexPositionInputs(v.posOS.xyz);

        o.posCS = posInputs.positionCS;
        o.posWS = posInputs.positionWS;

        // ! 获得视觉方向
        float3 viewDir = GetWorldSpaceViewDir(posInputs.positionWS);

        // ! 法线贴图相关
        #ifdef _NORMALMAP
          // ! GetVertexNormalInputs的重载 参数加tangentOS可以额外获得tangentWS和bitangentWS
          VertexNormalInputs normalInputs = GetVertexNormalInputs(v.normalOS.xyz, v.tangentOS);

          // ! 将视觉方向拆分存入
          o.normalWS = float4(normalInputs.normalWS, viewDir.x);
          o.tangentWS = float4(normalInputs.tangentWS, viewDir.y);
          o.bitangentWS = float4(normalInputs.bitangentWS, viewDir.z);
        #else
          VertexNormalInputs normalInputs = GetVertexNormalInputs(v.normalOS.xyz);

          o.normalWS = NormalizeNormalPerVertex(normalInputs.normalWS);
        #endif

        // ! 计算雾的系数
        float fogFactor = ComputeFogFactor(posInputs.positionCS.z);
        // ! 点光源
        float3 vertexLight = VertexLighting(posInputs.positionWS, normalInputs.normalWS);

        // ! 额外光源雾效相关
        #ifdef _ADDITIONAL_LIGHTS_VERTEX
          o.fogFactorAndVertexLight = float4(fogFactor, vertexLight);
        #else
          o.fogFactor = fogFactor;
        #endif

        // ! 获取阴影坐标
        #ifdef REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR
          o.shadowCoord = GetShadowCoord(posInputs);
        #endif

        OUTPUT_LIGHTMAP_UV(v.lightmapUV, unity_LightmapST, o.lightmapUV);
        OUTPUT_SH(o.normalWS, o.vertexSH);

        o.uv = TRANSFORM_TEX(v.uv, _MainTex);
        o.color = v.color;

        return o;
      }

      // ! 计算specular和smoothness的值
      half4 SampleSpecularSmoothness(float2 uv, half alpha, half4 specColor, TEXTURE2D_PARAM(specMap, sampler_specMap))
      {
        half4 specularSmoothness = half4(0.0h, 0.0h, 0.0h, 1.0h);

        #ifdef _SPECGLOSSMAP
          // ! 如果定义了贴图 使用贴图乘颜色
          specularSmoothness = SAMPLE_TEXTURE2D(specMap, sampler_specMap, uv) * specColor;
        #elif defined(_SPECULAR_COLOR)
          specularSmoothness = specColor;
        #endif

        #ifdef _GLOSSINESS_FROM_BASE_ALPHA
          specularSmoothness.a = exp2(10 * alpha + 1);
        #else
          specularSmoothness.a = exp2(10 * specularSmoothness.a + 1);
        #endif
        return specularSmoothness;
      }

      void InitSurfaceData(v2f i, out SurfaceData surfaceData)
      {
        surfaceData = (SurfaceData)0;

        // ! 采样基础贴图获取albedo颜色
        float4 mainTexColor = SAMPLE_TEXTURE2D(_MainTex, NewRepeatPointSampler, i.uv);
        float4 diffuse = mainTexColor * _MainColor * i.color;
        surfaceData.albedo = diffuse.rgb;

        #ifdef ALPHATEST_ON
          clip(mainTexColor.a - _Cutoff);
        #endif

        // ! 采样法线贴图 注意SampleNormal方法里面的关键字
        surfaceData.normalTS = SampleNormal(i.uv, _BumpMap, sampler_BumpMap);

        // ! 采样自发光贴图 注意SampleEmission方法里面的关键字
        surfaceData.emission = SampleEmission(i.uv, _EmissionColor.rgb, _EmissionMap, sampler_EmissionMap);

        // ! AO
        surfaceData.occlusion = 1.0;

        // ! 获取Specular和Smoothness 查看上一个方法
        float4 specular = SampleSpecularSmoothness(i.uv, mainTexColor.a, _SpecualrColor, _SpecGlosMap, sampler_SpecGlosMap);
        surfaceData.specular = specular.rgb;
        surfaceData.smoothness = specular.a * _Glossiness;
      }

      void InitInputData(v2f i, float3 noramlTS, out InputData inputData)
      {
        inputData = (InputData)0;

        inputData.positionWS = i.posWS;
        inputData.positionCS = i.posCS;

        #ifdef _NORMALMAP
          // ! 切线空间到世界空间的转换矩阵
          float3x3 tangentToWorld = float3x3(i.tangentWS.xyz, i.bitangentWS.xyz, i.normalWS.xyz);
          // ! 法线从切线空间转换到世界空间
          inputData.normalWS = TransformTangentToWorld(noramlTS, tangentToWorld);
          inputData.tangentToWorld = tangentToWorld;

          // ! 从vert方法传下来的数据中的w分量获取视图方向
          float3 viewDirWS = float3(i.normalWS.w, i.tangentWS.w, i.bitangentWS.w);
        #else
          inputData.normalWS = i.normalWS;

          // ! 没法线贴图直接计算视图方向
          float3 viewDirWS = GetWorldSpaceViewDir(i.posWS);
        #endif

        // ! 单位化
        inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
        inputData.viewDirectionWS = SafeNormalize(viewDirWS);

        // ! 阴影
        #ifdef REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR
          inputData.shadowCoord = i.shadowCoord;
        #elif defined(MAIN_LIGHT_CALCULATE_SHADOW)
          inputData.shadowCoord = TransformWorldToShadowCoord(i.posWS);
        #else
          inputData.shadowCoord = float4(0, 0, 0, 0);
        #endif

        // ! 点光源
        #ifdef _ADDITIONAL_LIGHTS_VERTEX
          inputData.vertexLighting = i.fogFactorAndVertexLight.yzw;
          inputData.fogCoord = i.fogFactorAndVertexLight.x;
        #else
          inputData.vertexLighting = half3(0, 0, 0);
          inputData.fogCoord = i.fogFactor.x;
        #endif

        // ! GI
        inputData.bakedGI = SAMPLE_GI(i.lightmapUV, i.vertexSH, i.normalWS);

        inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(i.posCS);

        inputData.shadowMask = SAMPLE_SHADOWMASK(i.lightmapUV);
      }

      float4 frag(v2f i) : SV_TARGET
      {
        SurfaceData surfaceData;
        InitSurfaceData(i, surfaceData);

        InputData inputData;
        InitInputData(i, surfaceData.normalTS, inputData);

        float4 color = UniversalFragmentBlinnPhong(inputData, surfaceData);

        return color;
      }

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
  }

  Fallback "Hidden/Universal Render Pipeline/FallbackError"
}