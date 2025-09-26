Shader "Custom/13-CDRom/CDRom"
{
  Properties
  {
    [Enum(Off, 0, Front, 1, Back, 2)]_Cull ("Cull Mode", Float) = 2
    _MainTex ("Main Texture", 2D) = "white" { }
    _MainColor ("Main Color", Color) = (1, 1, 1, 1)
    [Toggle(ALPHATEST_ON)]_AlphaClip ("Alpha Clip", Float) = 0
    _Cutoff ("Alpha Clip Threshold", Range(0, 1)) = 0.5
    [Toggle(_NORMALMAP)]_NormalMapToggle ("Use Normal Map", Float) = 0
    [NoScaleOffset]_BumpMap ("Normal Map", 2D) = "bump" { }
    [Toggle(_EMISSION)]_EmissionToggle ("Use Emission", Float) = 0
    [HDR]_EmissionColor ("Emission Color", Color) = (0, 0, 0, 0)
    [NoScaleOffset]_EmissionMap ("Emission Map", 2D) = "white" { }
    [Toggle(_SPECULAR_SETUP)] _MetallicSpecToggle ("Is Specular Workflow", Float) = 0

    [Toggle(_METALLICSPECGLOSSMAP)]_MetallicSpecularMapToggle ("Use Metallic/Specular Map", Float) = 0
    [NoScaleOffset]_MetallicSpecularMap ("Metallic/Specular Map", 2D) = "white" { }
    _Metallic ("Metallic", Range(0, 1)) = 0
    _SpecualrColor ("Specualr Color", Color) = (0.5, 0.5, 0.5, 0.5)
    _SmoothnessGlossiness ("Smoothness/Glossiness", Range(0, 1)) = 0
    [Toggle(_SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A))]_SmoothnessGlossinessSource ("Smoothness/Glossiness From Base Alpha", Float) = 0

    [Toggle(_OCCLUSIONMAP)] _OcclusionToggle ("Use Occlusion Map", Float) = 0
    [NoScaleOffset]_OcclusionMap ("Occlusion Map", 2D) = "white" { }
    _OcclusionStrength ("Occlusion Strength", Range(0, 1)) = 1

    [Toggle(_SPECULARHIGHLIGHTS_OFF)]_SpecularHighlights ("Specular Highlights Off", Float) = 0
    [Toggle(_ENVIRONMENTREFLECTIONS_OFF)]_EnvironmentReflections ("Environment Reflections Off", Float) = 0
    [Toggle(_RECEIVE_SHADOWS_OFF)]_ReceiveShadows ("Receive Shadows Off", Float) = 0

    _Distance ("Distance", Range(100, 10000)) = 1600
    _Length ("Length", Range(1, 20)) = 2
    _ColorAlpha ("ColorAlpha", Range(0, 1)) = 1
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

    #include "Assets/Contents/13-各向异性/3-Shaders/spectral.hlsl"

    CBUFFER_START(UnityPerMaterial)

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

      float _Distance;
      float _ColorAlpha;
      float _Length;

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
      #pragma shader_feature _NORMALMAP
      #pragma shader_feature _EMISSION

      #pragma shader_feature _SPECULAR_SETUP
      #pragma shader_feature _METALLICSPECGLOSSMAP
      #pragma shader_feature _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
      #pragma shader_feature _OCCLUSIONMAP

      #pragma shader_feature_local_fragment _SPECULARHIGHLIGHTS_OFF
      #pragma shader_feature_local_fragment _ENVIRONMENTREFLECTIONS_OFF
      #pragma shader_feature_local_fragment _RECEIVE_SHADOWS_OFF

      #pragma multi_compile _MAIN_LIGHT_SHADOWS
      #pragma multi_compile _MAIN_LIGHT_SHADOWS_CASCADE
      #pragma multi_compile _ADDITIONAL_LIGHTS
      #pragma multi_compile _ADDITIONAL_LIGHT_SHADOWS
      #pragma multi_compile_fog



      #pragma vertex vert
      #pragma fragment frag

      struct appdata
      {
        float4 posOS : POSITION;
        float4 normalOS : NORMAL;
        
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

        // #ifdef _NORMALMAP
        //   // ! _NORMALMAP ON viewDir float3(normalWS.x,tangentWS.y,bitangentWS.z)
        
        // #else
        //   float3 normalWS : TEXCOORD3;
        // #endif

        float4 normalWS : TEXCOORD3;
        float4 tangentWS : TEXCOORD4;
        float4 bitangentWS : TEXCOORD5;

        #ifdef _ADDITIONAL_LIGHTS_VERTEX
          float4 fogFactorAndVertexLight : TEXCOORD6;
        #else
          float fogFactor : TEXCOORD6;
        #endif

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

        float3 viewDir = GetWorldSpaceViewDir(posInputs.positionWS);

        #ifdef _NORMALMAP
          VertexNormalInputs normalInputs = GetVertexNormalInputs(v.normalOS.xyz, v.tangentOS);

          o.normalWS = float4(normalInputs.normalWS, viewDir.x);
          o.tangentWS = float4(normalInputs.tangentWS, viewDir.y);
          o.bitangentWS = float4(normalInputs.bitangentWS, viewDir.z);
        #else
          VertexNormalInputs normalInputs = GetVertexNormalInputs(v.normalOS.xyz);

          o.normalWS = float4(NormalizeNormalPerVertex(normalInputs.normalWS), 1);
        #endif

        float fogFactor = ComputeFogFactor(posInputs.positionCS.z);
        float3 vertexLight = VertexLighting(posInputs.positionWS, normalInputs.normalWS);

        #ifdef _ADDITIONAL_LIGHTS_VERTEX
          o.fogFactorAndVertexLight = float4(fogFactor, vertexLight);
        #else
          o.fogFactor = fogFactor;
        #endif

        #ifdef REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR
          o.shadowCoord = GetShadowCoord(posInputs);
        #endif

        OUTPUT_LIGHTMAP_UV(v.lightmapUV, unity_LightmapST, o.lightmapUV);
        OUTPUT_SH(o.normalWS.xyz, o.vertexSH);

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

        half4 albedoAlpha = SampleAlbedoAlpha(i.uv, _MainTex, NewRepeatPointSampler);
        float3 diffuse = albedoAlpha.rgb * _MainColor.rgb * i.color.rgb;
        surfaceData.albedo = diffuse.rgb;
        surfaceData.alpha = Alpha(albedoAlpha.a, _MainColor, _Cutoff);

        surfaceData.normalTS = SampleNormal(i.uv, _BumpMap, sampler_BumpMap);

        surfaceData.emission = SampleEmission(i.uv, _EmissionColor.rgb, _EmissionMap, sampler_EmissionMap);

        surfaceData.occlusion = SampleOcclusion(i.uv);

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
          float3x3 tangentToWorld = float3x3(i.tangentWS.xyz, i.bitangentWS.xyz, i.normalWS.xyz);
          inputData.normalWS = TransformTangentToWorld(noramlTS, tangentToWorld);
          inputData.tangentToWorld = tangentToWorld;

          float3 viewDirWS = float3(i.normalWS.w, i.tangentWS.w, i.bitangentWS.w);
        #else
          inputData.normalWS = i.normalWS.xyz;

          float3 viewDirWS = GetWorldSpaceViewDir(i.posWS);
        #endif

        inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
        inputData.viewDirectionWS = SafeNormalize(viewDirWS);

        #ifdef REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR
          inputData.shadowCoord = i.shadowCoord;
        #elif defined(MAIN_LIGHT_CALCULATE_SHADOW)
          inputData.shadowCoord = TransformWorldToShadowCoord(i.posWS);
        #else
          inputData.shadowCoord = float4(0, 0, 0, 0);
        #endif

        #ifdef _ADDITIONAL_LIGHTS_VERTEX
          inputData.vertexLighting = i.fogFactorAndVertexLight.yzw;
          inputData.fogCoord = i.fogFactorAndVertexLight.x;
        #else
          inputData.vertexLighting = half3(0, 0, 0);
          inputData.fogCoord = i.fogFactor.x;
        #endif

        inputData.bakedGI = SAMPLE_GI(i.lightmapUV, i.vertexSH, i.normalWS.xyz);

        inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(i.posCS);

        inputData.shadowMask = SAMPLE_SHADOWMASK(i.lightmapUV);
      }

      // ! 各向异性
      float4 LightingDiffraction(float4 pbrColor, float3 viewDir, float3 lightDir, float3 tangentWS)
      {
        float3 L = lightDir;
        float3 V = viewDir;
        float3 T = tangentWS;

        float d = _Distance;

        float cos_ThetaL = dot(L, T);
        float cos_ThetaV = dot(V, T);
        float u = abs(cos_ThetaL - cos_ThetaV);

        if (u == 0)
          return pbrColor;

        float3 resultColor = 0;

        for (int n = 1; n < _Length; n++)
        {
          float waveLength = u * d / n;
          resultColor += spectral_ymck6(waveLength);
        }
        resultColor = saturate(resultColor);
        pbrColor += float4(resultColor * _ColorAlpha, 1);
        return pbrColor;
      }

      float4 frag(v2f i) : SV_TARGET
      {
        SurfaceData surfaceData;
        InitSurfaceData(i, surfaceData);

        InputData inputData;
        InitInputData(i, surfaceData.normalTS, inputData);

        // ! PBR Color
        float4 color = UniversalFragmentPBR(inputData, surfaceData);

        // ! viewDir
        float3 viewDir = float3(i.normalWS.w, i.tangentWS.w, i.bitangentWS.w);

        // ! 根据uv计算tangent
        float2 uv = i.uv;
        float2 uv_orthogonal = normalize(uv);
        float3 uv_tangent = float3(-uv_orthogonal.y, 0, uv_orthogonal.x);
        float3 tangentWS = normalize(mul(UNITY_MATRIX_M, float4(uv_tangent, 0))).xyz;

        // ! lightDir
        Light light = GetMainLight();
        float3 lightDir = light.direction;
        
        // ! 各向异性
        color = LightingDiffraction(color, viewDir, lightDir, tangentWS);


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
