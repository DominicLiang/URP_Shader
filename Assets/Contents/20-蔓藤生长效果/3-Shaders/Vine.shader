Shader "Custom/Normal/Vine"
{
  Properties
  {
    _NormalOffset ("法线偏移", Float) = 0
    _Grow ("生长动画时间轴", Range(0, 1)) = 1
    _WeightEdge1 ("尖头权重边沿1", Range(0, 1)) = 0.7
    _WeightEdge2 ("尖头权重边沿2", Range(0, 1)) = 1
    [Space(20)]

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
    // ! Workflow
    [Toggle(_SPECULAR_SETUP)] _MetallicSpecToggle ("Is Specular Workflow", Float) = 0

    [Toggle(_METALLICSPECGLOSSMAP)]_MetallicSpecularMapToggle ("Use Metallic/Specular Map", Float) = 0
    [NoScaleOffset]_MetallicSpecularMap ("Metallic/Specular Map", 2D) = "white" { }
    _Metallic ("Metallic", Range(0, 1)) = 0
    _SpecualrColor ("Specualr Color", Color) = (0.5, 0.5, 0.5, 0.5)
    _SmoothnessGlossiness ("Smoothness/Glossiness", Range(0, 1)) = 0
    [Toggle(_SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A))]_SmoothnessGlossinessSource ("Smoothness/Glossiness From Base Alpha", Float) = 0

    // ! AO
    [Toggle(_OCCLUSIONMAP)] _OcclusionToggle ("Use Occlusion Map", Float) = 0
    [NoScaleOffset]_OcclusionMap ("Occlusion Map", 2D) = "white" { }
    _OcclusionStrength ("Occlusion Strength", Range(0, 1)) = 1

    [Toggle(_SPECULARHIGHLIGHTS_OFF)]_SpecularHighlights ("Specular Highlights Off", Float) = 0
    [Toggle(_ENVIRONMENTREFLECTIONS_OFF)]_EnvironmentReflections ("Environment Reflections Off", Float) = 0
    [Toggle(_RECEIVE_SHADOWS_OFF)]_ReceiveShadows ("Receive Shadows Off", Float) = 0
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

    #include "Assets/Contents/01-URP_Shader源码学习/3-Shaders/pbr.hlsl"

    CBUFFER_START(UnityPerMaterial)

      real _NormalOffset;
      real _Grow;
      real _WeightEdge1;
      real _WeightEdge2;



      TEXTURE2D(_MainTex);
      float4 _MainTex_ST;
      SamplerState NewRepeatPointSampler;

      float4 _MainColor;

      float _Cutoff;

      float4 _EmissionColor;

      float _Metallic;
      float4 _SpecualrColor;
      float _SmoothnessGlossiness;

      TEXTURE2D(_MetallicSpecularMap);
      SAMPLER(sampler_MetallicSpecularMap);

      TEXTURE2D(_OcclusionMap);
      SAMPLER(sampler_OcclusionMap);
      float _OcclusionStrength;

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

      #pragma shader_feature _SPECULAR_SETUP
      #pragma shader_feature _METALLICSPECGLOSSMAP
      #pragma shader_feature _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
      // ! AO
      #pragma shader_feature _OCCLUSIONMAP

      #pragma shader_feature_local_fragment _SPECULARHIGHLIGHTS_OFF
      #pragma shader_feature_local_fragment _ENVIRONMENTREFLECTIONS_OFF
      #pragma shader_feature_local_fragment _RECEIVE_SHADOWS_OFF

      // ! 如果需要从光照探针接受光照 不要写这句LIGHTMAP_ON
      // ! 特别注意如果是SkinMeshRenderer 不要写这个!
      // ! 如果写了 采样GI的时候无论你物体有没有设置成静态
      // ! 实际上有没有光照贴图 采样gi的时候 都会走lightmap路线
      // ! 这样会导致非使用光照贴图的物体无法接受光照探针的光照
      // ! 不写这个才可以从光照探针上接受光照
      // #pragma multi_compile LIGHTMAP_ON

      // ! 主灯阴影支持
      #pragma multi_compile _MAIN_LIGHT_SHADOWS
      #pragma multi_compile _MAIN_LIGHT_SHADOWS_CASCADE
      // ! 点光源支持
      #pragma multi_compile _ADDITIONAL_LIGHTS
      // ! 点光源投射阴影
      #pragma multi_compile _ADDITIONAL_LIGHT_SHADOWS
      // ! 启用雾效
      #pragma multi_compile_fog



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

        real alpha : TEXCOORD13;
        real a : TEXCOORD14;
      };

      v2f vert(appdata v)
      {
        v2f o = (v2f)0;

        // * alpha
        real a = v.uv.y - (_Grow - 1);
        real alpha = 1 - (a);
        o.alpha = alpha;
        o.a = a;

        real weight = smoothstep(_WeightEdge1, _WeightEdge2, a);
        real3 offset = v.normalOS * 0.01 * _NormalOffset * weight;
        v.posOS.xyz += offset;



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

      half SampleOcclusion(float2 uv)
      {
        #ifdef _OCCLUSIONMAP
          #ifdef SHADER_API_GLES
            return SAMPLE_TEXTURE2D(_OcclusionMap, sampler_OcclusionMap, uv).g;
          #else
            half occ = SAMPLE_TEXTURE2D(_OcclusionMap, sampler_OcclusionMap, uv).g;
            return LerpWhiteTo(occ, _OcclusionStrength);
          #endif
        #else
          return 1;
        #endif
      }

      half4 SampleMetallicSpecGloss(float2 uv, half albedoAlpha)
      {
        half4 specGloss;
        #ifdef _METALLICSPECGLOSSMAP
          specGloss = SAMPLE_TEXTURE2D(_MetallicSpecularMap, sampler_MetallicSpecularMap, uv);

          #ifdef _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            specGloss.a = albedoAlpha * _SmoothnessGlossiness;
          #else
            specGloss.a *= _SmoothnessGlossiness;
          #endif
        #else
          #if _SPECULAR_SETUP
            specGloss.rgb = _SpecualrColor.rgb;
          #else
            specGloss.rgb = _Metallic.rrr;
          #endif
          #ifdef _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            specGloss.a = albedoAlpha * _SmoothnessGlossiness;
          #else
            specGloss.a = _SmoothnessGlossiness;
          #endif
        #endif
        return specGloss;
      }

      void InitSurfaceData(v2f i, out SurfaceData surfaceData)
      {
        surfaceData = (SurfaceData)0;

        // ! 采样基础贴图获取albedo颜色
        half4 albedoAlpha = SampleAlbedoAlpha(i.uv, _MainTex, NewRepeatPointSampler);
        float3 diffuse = albedoAlpha.rgb * _MainColor * i.color;
        surfaceData.albedo = diffuse.rgb;
        surfaceData.alpha = Alpha(albedoAlpha.a, _MainColor, _Cutoff);

        // ! 采样法线贴图 注意SampleNormal方法里面的关键字
        surfaceData.normalTS = SampleNormal(i.uv, _BumpMap, sampler_BumpMap);

        // ! 采样自发光贴图 注意SampleEmission方法里面的关键字
        surfaceData.emission = SampleEmission(i.uv, _EmissionColor.rgb, _EmissionMap, sampler_EmissionMap);

        // ! AO
        surfaceData.occlusion = SampleOcclusion(i.uv);

        // ! 采样Metallic或Specular
        half4 specGloss = SampleMetallicSpecGloss(i.uv, albedoAlpha.a);
        #ifdef _SPECULAR_SETUP
          surfaceData.metallic = 0;
          surfaceData.specular = specGloss.rgb;
        #else
          surfaceData.metallic = specGloss.r ;
          surfaceData.specular = half3(0, 0, 0);
        #endif

        surfaceData.smoothness = specGloss.a;
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
        clip(i.alpha - 0.001);



        SurfaceData surfaceData;
        InitSurfaceData(i, surfaceData);

        InputData inputData;
        InitInputData(i, surfaceData.normalTS, inputData);

        // ! 更改使用PBR光照模型
        float4 color = UniversalFragmentPBR(inputData, surfaceData);

        // ! 应用雾效
        color.rgb = MixFog(color.rgb, inputData.fogCoord);

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