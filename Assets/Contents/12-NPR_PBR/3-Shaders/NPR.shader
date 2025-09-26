Shader "Custom/18-NPR_PBR/NPR"
{
  Properties
  {
    // Specular vs Metallic workflow
    _WorkflowMode ("WorkflowMode", Float) = 1.0

    [MainTexture] _BaseMap ("Albedo", 2D) = "white" { }
    [MainColor] _BaseColor ("Color", Color) = (1, 1, 1, 1)

    _Cutoff ("Alpha Cutoff", Range(0.0, 1.0)) = 0.5

    _Smoothness ("Smoothness", Range(0.0, 1.0)) = 0.5
    _SmoothnessTextureChannel ("Smoothness texture channel", Float) = 0

    _Metallic ("Metallic", Range(0.0, 1.0)) = 0.0
    _MetallicGlossMap ("Metallic", 2D) = "white" { }

    _SpecColor ("Specular", Color) = (0.2, 0.2, 0.2)
    _SpecGlossMap ("Specular", 2D) = "white" { }

    [ToggleOff] _SpecularHighlights ("Specular Highlights", Float) = 1.0
    [ToggleOff] _EnvironmentReflections ("Environment Reflections", Float) = 1.0

    _BumpScale ("Scale", Float) = 1.0
    _BumpMap ("Normal Map", 2D) = "bump" { }

    _Parallax ("Scale", Range(0.005, 0.08)) = 0.005
    _ParallaxMap ("Height Map", 2D) = "black" { }

    _OcclusionStrength ("Strength", Range(0.0, 1.0)) = 1.0
    _OcclusionMap ("Occlusion", 2D) = "white" { }

    [HDR] _EmissionColor ("Color", Color) = (0, 0, 0)
    _EmissionMap ("Emission", 2D) = "white" { }

    _DetailMask ("Detail Mask", 2D) = "white" { }
    _DetailAlbedoMapScale ("Scale", Range(0.0, 2.0)) = 1.0
    _DetailAlbedoMap ("Detail Albedo x2", 2D) = "linearGrey" { }
    _DetailNormalMapScale ("Scale", Range(0.0, 2.0)) = 1.0
    [Normal] _DetailNormalMap ("Normal Map", 2D) = "bump" { }

    // SRP batching compatibility for Clear Coat (Not used in Lit)
    [HideInInspector] _ClearCoatMask ("_ClearCoatMask", Float) = 0.0
    [HideInInspector] _ClearCoatSmoothness ("_ClearCoatSmoothness", Float) = 0.0

    // Blending state
    _Surface ("__surface", Float) = 0.0
    _Blend ("__blend", Float) = 0.0
    _Cull ("__cull", Float) = 2.0
    [ToggleUI] _AlphaClip ("__clip", Float) = 0.0
    [HideInInspector] _SrcBlend ("__src", Float) = 1.0
    [HideInInspector] _DstBlend ("__dst", Float) = 0.0
    [HideInInspector] _SrcBlendAlpha ("__srcA", Float) = 1.0
    [HideInInspector] _DstBlendAlpha ("__dstA", Float) = 0.0
    [HideInInspector] _ZWrite ("__zw", Float) = 1.0
    [HideInInspector] _BlendModePreserveSpecular ("_BlendModePreserveSpecular", Float) = 1.0
    [HideInInspector] _AlphaToMask ("__alphaToMask", Float) = 0.0

    [ToggleUI] _ReceiveShadows ("Receive Shadows", Float) = 1.0
    // Editmode props
    _QueueOffset ("Queue offset", Float) = 0.0

    // ObsoleteProperties
    [HideInInspector] _MainTex ("BaseMap", 2D) = "white" { }
    [HideInInspector] _Color ("Base Color", Color) = (1, 1, 1, 1)
    [HideInInspector] _GlossMapScale ("Smoothness", Float) = 0.0
    [HideInInspector] _Glossiness ("Smoothness", Float) = 0.0
    [HideInInspector] _GlossyReflections ("EnvironmentReflections", Float) = 0.0

    [HideInInspector][NoScaleOffset]unity_Lightmaps ("unity_Lightmaps", 2DArray) = "" { }
    [HideInInspector][NoScaleOffset]unity_LightmapsInd ("unity_LightmapsInd", 2DArray) = "" { }
    [HideInInspector][NoScaleOffset]unity_ShadowMasks ("unity_ShadowMasks", 2DArray) = "" { }

    [Space(10)]
    [Header(NPR)]
    [Space(5)]

    _MedThreshold ("_MedThreshold", Range(0, 1)) = 0
    _MedSmooth ("_MedSmooth", Range(0, 1)) = 0
    _MedColor ("_MedColor", Color) = (1, 1, 1, 1)
    _ShadowThreshold ("_ShadowThreshold", Range(0, 1)) = 0
    _ShadowSmooth ("_ShadowSmooth", Range(0, 1)) = 0
    _ShadowColor ("_ShadowColor", Color) = (1, 1, 1, 1)
    _ReflectThreshold ("_ReflectThreshold", Range(0, 1)) = 0
    _ReflectSmooth ("_ReflectSmooth", Range(0, 1)) = 0
    _ReflectColor ("_ReflectColor", Color) = (1, 1, 1, 1)

    [Space(5)]

    _SpecularThreshold ("_SpecularThreshold", Range(0, 1)) = 0
    _SpecularSmooth ("_SpecularSmooth", Range(0, 1)) = 0
    _GGXSpecular ("_GGXSpecular", Range(0, 1)) = 0
    _SpecularIntensity ("_SpecularIntensity", Range(0, 10)) = 0

    [Space(5)]

    _FresnelThreshold ("_FresnelThreshold", Range(0, 1)) = 0
    _FresnelSmooth ("_FresnelSmooth", Range(0, 1)) = 0
    _FresnelIntensity ("_FresnelIntensity", Range(0, 10)) = 0

    [Space(5)]

    _ReflProbeIntensity ("_ReflProbeIntensity", Range(0, 1)) = 0
    _MetalReflProbeIntensity ("_MetalReflProbeIntensity", Range(0, 10)) = 0

    [Space(5)]
    [Toggle(_USEBRUSHTEX_ON)]USEBRUSHTEX_ON ("_USEBRUSHTEX_ON", Float) = 0
    _BrushTex ("_BrushTex", 2D) = "white" { }
    _BrushStrangeR ("_BrushStrangeR", Range(0, 1)) = 0
    _BrushStrangeG ("_BrushStrangeG", Range(0, 1)) = 0
    _BrushStrangeB ("_BrushStrangeB", Range(0, 1)) = 0
  }

  // * _ReflProbeIntensity _MetalReflProbeIntensity

  // * float _SpecularThreshold
  // * float _SpecularSmooth
  // * float _GGXSpecular
  // * float _SpecularIntensity

  // * _FresnelThreshold _FresnelSmooth _FresnelIntensity

  SubShader
  {
    // Universal Pipeline tag is required. If Universal render pipeline is not set in the graphics settings
    // this Subshader will fail. One can add a subshader below or fallback to Standard built-in to make this
    // material work with both Universal Render Pipeline and Builtin Unity Pipeline
    Tags
    {
      "RenderType" = "Opaque"
      "RenderPipeline" = "UniversalPipeline"
      "UniversalMaterialType" = "Lit"
      "IgnoreProjector" = "True"
    }
    LOD 300

    // ------------------------------------------------------------------
    //  Forward pass. Shades all light in a single pass. GI + emission + Fog
    Pass
    {
      // Lightmode matches the ShaderPassName set in UniversalRenderPipeline.cs. SRPDefaultUnlit and passes with
      // no LightMode tag are also rendered by Universal Render Pipeline
      Name "ForwardLit"
      Tags
      {
        "LightMode" = "UniversalForward"
      }

      // -------------------------------------
      // Render State Commands
      Blend[_SrcBlend][_DstBlend], [_SrcBlendAlpha][_DstBlendAlpha]
      ZWrite[_ZWrite]
      Cull[_Cull]
      AlphaToMask[_AlphaToMask]

      HLSLPROGRAM
      #pragma target 2.0

      // -------------------------------------
      // Shader Stages
      #pragma vertex LitPassVertex
      // ! 引用到LitPassFragment_NPR
      #pragma fragment LitPassFragment_NPR

      // -------------------------------------
      // Material Keywords
      #pragma shader_feature_local _NORMALMAP
      #pragma shader_feature_local _PARALLAXMAP
      #pragma shader_feature_local _RECEIVE_SHADOWS_OFF
      #pragma shader_feature_local _ _DETAIL_MULX2 _DETAIL_SCALED
      #pragma shader_feature_local_fragment _SURFACE_TYPE_TRANSPARENT
      #pragma shader_feature_local_fragment _ALPHATEST_ON
      #pragma shader_feature_local_fragment _ _ALPHAPREMULTIPLY_ON _ALPHAMODULATE_ON
      #pragma shader_feature_local_fragment _EMISSION
      #pragma shader_feature_local_fragment _METALLICSPECGLOSSMAP
      #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
      #pragma shader_feature_local_fragment _OCCLUSIONMAP
      #pragma shader_feature_local_fragment _SPECULARHIGHLIGHTS_OFF
      #pragma shader_feature_local_fragment _ENVIRONMENTREFLECTIONS_OFF
      #pragma shader_feature_local_fragment _SPECULAR_SETUP

      #pragma shader_feature _USEBRUSHTEX_ON

      // -------------------------------------
      // Universal Pipeline keywords
      #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
      #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
      #pragma multi_compile _ EVALUATE_SH_MIXED EVALUATE_SH_VERTEX
      #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
      #pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
      #pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
      #pragma multi_compile_fragment _ _SHADOWS_SOFT _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
      #pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
      #pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
      #pragma multi_compile_fragment _ _LIGHT_COOKIES
      #pragma multi_compile _ _LIGHT_LAYERS
      #pragma multi_compile _ _FORWARD_PLUS
      #include_with_pragmas "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRenderingKeywords.hlsl"
      #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"


      // -------------------------------------
      // Unity defined keywords
      #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
      #pragma multi_compile _ SHADOWS_SHADOWMASK
      #pragma multi_compile _ DIRLIGHTMAP_COMBINED
      #pragma multi_compile _ LIGHTMAP_ON
      #pragma multi_compile _ DYNAMICLIGHTMAP_ON
      #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE
      #pragma multi_compile_fog
      #pragma multi_compile_fragment _ DEBUG_DISPLAY

      //--------------------------------------
      // GPU Instancing
      #pragma multi_compile_instancing
      #pragma instancing_options renderinglayer
      #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

      #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
      #include "Packages/com.unity.render-pipelines.universal/Shaders/LitForwardPass.hlsl"

      // * _MedThreshold _MedSmooth _MedColor
      // * _ShadowThreshold _ShadowSmooth _ShadowColor
      // * _ReflectThreshold _ReflectSmooth _ReflectColor

      real _MedThreshold;
      real _MedSmooth;
      real3 _MedColor;
      real _ShadowThreshold;
      real _ShadowSmooth;
      real3 _ShadowColor;
      real _ReflectThreshold;
      real _ReflectSmooth;
      real3 _ReflectColor;

      real _ReceiveShadows;

      float _SpecularThreshold;
      float _SpecularSmooth;
      float _GGXSpecular;
      float _SpecularIntensity;

      

      float _FresnelThreshold;
      float _FresnelSmooth;
      float _FresnelIntensity;

      float _ReflProbeIntensity;
      float _MetalReflProbeIntensity;

      
      TEXTURE2D(_BrushTex);
      SAMPLER(sampler_BrushTex);
      real4 _BrushTex_ST;
      real _BrushStrangeR;
      real _BrushStrangeG;
      real _BrushStrangeB;


      float LinearStep(float min, float max, float value)
      {
        return saturate((value - min) / (max - min));
      }

      // * float _SpecularThreshold
      // * float _SpecularSmooth
      // * float _GGXSpecular
      // * float _SpecularIntensity

      // ! LightingPhysicallyBased_NPR
      half3 LightingPhysicallyBased_NPR(BRDFData brdfData, half3 radiance, BRDFData brdfDataClearCoat,
      half3 lightColor, half3 lightDirectionWS, half lightAttenuation,
      half3 normalWS, half3 viewDirectionWS,
      half clearCoatMask, bool specularHighlightsOff)
      {
        // half NdotL = saturate(dot(normalWS, lightDirectionWS));
        // half3 radiance = lightColor * (lightAttenuation * NdotL);

        half3 brdf = brdfData.diffuse;
        #ifndef _SPECULARHIGHLIGHTS_OFF
          [branch] if (!specularHighlightsOff)
          {
            half specularTerm = DirectBRDFSpecular(brdfData, normalWS, lightDirectionWS, viewDirectionWS);

            // ! -------------- 镜面反射 高光 ------------------
            brdf = lerp(
              LinearStep(_SpecularThreshold - _SpecularSmooth, _SpecularThreshold + _SpecularSmooth, specularTerm),
              specularTerm,
              _GGXSpecular
            ) * brdfData.specular * max(0, _SpecularIntensity) + brdf;
            // ! -------------- 镜面反射 高光 ------------------

            // brdf = specularTerm * brdfData.specular + brdf;

            #if defined(_CLEARCOAT) || defined(_CLEARCOATMAP)
              // Clear coat evaluates the specular a second timw and has some common terms with the base specular.
              // We rely on the compiler to merge these and compute them only once.
              half brdfCoat = kDielectricSpec.r * DirectBRDFSpecular(brdfDataClearCoat, normalWS, lightDirectionWS, viewDirectionWS);

              // Mix clear coat and base layer using khronos glTF recommended formula
              // https://github.com/KhronosGroup/glTF/blob/master/extensions/2.0/Khronos/KHR_materials_clearcoat/README.md
              // Use NoV for direct too instead of LoH as an optimization (NoV is light invariant).
              half NoV = saturate(dot(normalWS, viewDirectionWS));
              // Use slightly simpler fresnelTerm (Pow4 vs Pow5) as a small optimization.
              // It is matching fresnel used in the GI/Env, so should produce a consistent clear coat blend (env vs. direct)
              half coatFresnel = kDielectricSpec.x + kDielectricSpec.a * Pow4(1.0 - NoV);

              brdf = brdf * (1.0 - clearCoatMask * coatFresnel) + brdfCoat * clearCoatMask;
            #endif // _CLEARCOAT

          }
        #endif // _SPECULARHIGHLIGHTS_OFF

        return brdf * radiance;
      }

      // ! LightingPhysicallyBased_NPR
      half3 LightingPhysicallyBased_NPR(BRDFData brdfData, half3 radiance, BRDFData brdfDataClearCoat, Light light, half3 normalWS, half3 viewDirectionWS, half clearCoatMask, bool specularHighlightsOff)
      {
        return LightingPhysicallyBased_NPR(brdfData, radiance, brdfDataClearCoat, light.color, light.direction, light.distanceAttenuation * light.shadowAttenuation, normalWS, viewDirectionWS, clearCoatMask, specularHighlightsOff);
      }

      // ! CalculateRadiance 不推荐 RampTex更直观
      float3 CalculateRadiance(Light light, float3 normalWS, float3 brush, float3 brushStrengthRGB)
      {
        half NdotL = dot(normalize(normalWS), normalize(light.direction));

        #if _USEBRUSHTEX_ON
          half halfLambertMed = NdotL * lerp(0.5, brush.r, brushStrengthRGB.r) + 0.5;
          half halfLambertShadow = NdotL * lerp(0.5, brush.g, brushStrengthRGB.g) + 0.5;
          half halfLambertRefl = NdotL * lerp(0.5, brush.b, brushStrengthRGB.b) + 0.5;
        #else
          half halfLambertMed = NdotL * 0.5 + 0.5;
          half halfLambertShadow = halfLambertMed;
          half halfLambertRefl = halfLambertMed;
        #endif

        half smoothMedTone = LinearStep(_MedThreshold - _MedSmooth, _MedThreshold + _MedSmooth, halfLambertMed);
        half3 MedToneColor = lerp(_MedColor.rgb, 1, smoothMedTone);

        half smoothShadow = LinearStep(_ShadowThreshold - _ShadowSmooth, _ShadowThreshold + _ShadowSmooth,
        halfLambertShadow * (lerp(1, light.distanceAttenuation * light.shadowAttenuation, _ReceiveShadows)));
        half3 ShadowColor = lerp(_ShadowColor.rgb, MedToneColor, smoothShadow);

        half smoothReflect = LinearStep(_ReflectThreshold - _ReflectSmooth, _ReflectThreshold + _ReflectSmooth, halfLambertRefl);
        half3 ReflectColor = lerp(_ReflectColor.rgb, ShadowColor, smoothReflect);

        half3 radiance = light.color * ReflectColor;

        return radiance;
      }

      // ! EnvironmentBRDF_NPR
      half3 EnvironmentBRDF_NPR(BRDFData brdfData, half3 indirectDiffuse, half3 indirectSpecular, half fresnelTerm, half3 radiance)
      {
        half3 c = indirectDiffuse * brdfData.diffuse;

        // ! ----------------- 金属度 ---------------------

        half3 c2 = lerp(brdfData.specular * radiance, brdfData.grazingTerm, fresnelTerm);

        c += indirectSpecular * EnvironmentBRDFSpecular(brdfData, fresnelTerm) * c2;

        // ! ----------------- 金属度 ---------------------
        return c;
      }

      // ! GlobalIllumination_NPR
      half3 GlobalIllumination_NPR(BRDFData brdfData, BRDFData brdfDataClearCoat, float clearCoatMask,
      half3 bakedGI, half occlusion, float3 positionWS,
      half3 normalWS, half3 viewDirectionWS, float2 normalizedScreenSpaceUV, Light light, half metallic, half3 radiance)
      {
        half3 reflectVector = reflect(-viewDirectionWS, normalWS);
        half NoV = saturate(dot(normalWS, viewDirectionWS));

        
        // half fresnelTerm = Pow4(1.0 - NoV);
        // ! ----------------- 菲尼尔 ---------------------
        
        half NoL = dot(light.direction, normalWS);

        half stepNoL = LinearStep(_ShadowThreshold - _ShadowSmooth, _ShadowThreshold + _ShadowSmooth, NoL * 0.5 + 0.5);
        half fresnelTerm = 1 - NoV * max(0, _FresnelIntensity) * stepNoL;
        fresnelTerm = LinearStep(_FresnelThreshold - _FresnelSmooth, _FresnelThreshold + _FresnelSmooth, fresnelTerm);

        // ! ----------------- 菲尼尔 ---------------------

        

        half3 indirectDiffuse = bakedGI;

        

        // ! ------------- 间接光镜面反射 -------------------

        half reflProbeMask = lerp(max(0, _ReflProbeIntensity), max(0, _MetalReflProbeIntensity), metallic);// _Metallic?

        half3 indirectSpecular = GlossyEnvironmentReflection(reflectVector, positionWS, brdfData.perceptualRoughness, 1.0h, normalizedScreenSpaceUV) * reflProbeMask;
        
        // ! ------------- 间接光镜面反射 -------------------

        // ! EnvironmentBRDF_NPR
        half3 color = EnvironmentBRDF_NPR(brdfData, indirectDiffuse, indirectSpecular, fresnelTerm, radiance);

        if (IsOnlyAOLightingFeatureEnabled())
        {
          color = half3(1, 1, 1); // "Base white" for AO debug lighting mode

        }

        #if defined(_CLEARCOAT) || defined(_CLEARCOATMAP)
          half3 coatIndirectSpecular = GlossyEnvironmentReflection(reflectVector, positionWS, brdfDataClearCoat.perceptualRoughness, 1.0h, normalizedScreenSpaceUV);
          // TODO: "grazing term" causes problems on full roughness
          half3 coatColor = EnvironmentBRDFClearCoat(brdfDataClearCoat, clearCoatMask, coatIndirectSpecular, fresnelTerm);

          // Blend with base layer using khronos glTF recommended way using NoV
          // Smooth surface & "ambiguous" lighting
          // NOTE: fresnelTerm (above) is pow4 instead of pow5, but should be ok as blend weight.
          half coatFresnel = kDielectricSpec.x + kDielectricSpec.a * fresnelTerm;
          return (color * (1.0 - coatFresnel * clearCoatMask) + coatColor) * occlusion;
        #else
          return color * occlusion;
        #endif
      }

      // ! UniversalFragmentPBR_NPR
      half4 UniversalFragmentPBR_NPR(InputData inputData, SurfaceData surfaceData, real2 uv)
      {
        #if defined(_SPECULARHIGHLIGHTS_OFF)
          bool specularHighlightsOff = true;
        #else
          bool specularHighlightsOff = false;
        #endif
        BRDFData brdfData;

        // NOTE: can modify "surfaceData"...
        InitializeBRDFData(surfaceData, brdfData);

        #if defined(DEBUG_DISPLAY)
          half4 debugColor;

          if (CanDebugOverrideOutputColor(inputData, surfaceData, brdfData, debugColor))
          {
            return debugColor;
          }
        #endif

        // Clear-coat calculation...
        BRDFData brdfDataClearCoat = CreateClearCoatBRDFData(surfaceData, brdfData);
        half4 shadowMask = CalculateShadowMask(inputData);
        AmbientOcclusionFactor aoFactor = CreateAmbientOcclusionFactor(inputData, surfaceData);
        uint meshRenderingLayers = GetMeshRenderingLayer();
        Light mainLight = GetMainLight(inputData, shadowMask, aoFactor);

        // NOTE: We don't apply AO to the GI here because it's done in the lighting calculation below...
        MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI);

        LightingData lightingData = CreateLightingData(inputData, surfaceData);

        // ! CalculateRadiance
        #if _USEBRUSHTEX_ON
          // ! ------------- 笔刷效果 -------------------

          real2 uv_b = uv;
          real4 brush = SAMPLE_TEXTURE2D(_BrushTex, sampler_BrushTex, uv_b * _BrushTex_ST.xy + _BrushTex_ST.zw);
          real3 strange = real3(_BrushStrangeR, _BrushStrangeG, _BrushStrangeB);
          float3 radiance = CalculateRadiance(mainLight, inputData.normalWS, brush.rgb, strange);

          // ! ------------- 笔刷效果 -------------------
        #else
          float3 radiance = CalculateRadiance(mainLight, inputData.normalWS, 0.5, float3(0, 0, 0));
        #endif
        

        // ! GlobalIllumination_NPR
        lightingData.giColor = GlobalIllumination_NPR(brdfData, brdfDataClearCoat, surfaceData.clearCoatMask,
        inputData.bakedGI, aoFactor.indirectAmbientOcclusion, inputData.positionWS,
        inputData.normalWS, inputData.viewDirectionWS, inputData.normalizedScreenSpaceUV, mainLight, surfaceData.metallic, radiance);
        #ifdef _LIGHT_LAYERS
          if (IsMatchingLightLayer(mainLight.layerMask, meshRenderingLayers))
        #endif
        {

          // * SurfaceData -> brdfData -> LightingPhysicallyBased -> output color
          // ! LightingPhysicallyBased 光照模型
          lightingData.mainLightColor = LightingPhysicallyBased_NPR(brdfData, radiance, brdfDataClearCoat,
          mainLight,
          inputData.normalWS, inputData.viewDirectionWS,
          surfaceData.clearCoatMask, specularHighlightsOff);
          // ! 主灯

        }

        #if defined(_ADDITIONAL_LIGHTS)
          uint pixelLightCount = GetAdditionalLightsCount();

          #if USE_FORWARD_PLUS
            for (uint lightIndex = 0; lightIndex < min(URP_FP_DIRECTIONAL_LIGHTS_COUNT, MAX_VISIBLE_LIGHTS); lightIndex++)
            {
              FORWARD_PLUS_SUBTRACTIVE_LIGHT_CHECK

              Light light = GetAdditionalLight(lightIndex, inputData, shadowMask, aoFactor);

              #ifdef _LIGHT_LAYERS
                if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
              #endif
              {
                lightingData.additionalLightsColor += LightingPhysicallyBased_NPR(brdfData, brdfDataClearCoat, light,
                inputData.normalWS, inputData.viewDirectionWS,
                surfaceData.clearCoatMask, specularHighlightsOff);
                // ! 副灯

              }
            }
          #endif

          LIGHT_LOOP_BEGIN(pixelLightCount)
          Light light = GetAdditionalLight(lightIndex, inputData, shadowMask, aoFactor);

          #ifdef _LIGHT_LAYERS
            if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
          #endif
          {
            lightingData.additionalLightsColor += LightingPhysicallyBased(brdfData, brdfDataClearCoat, light,
            inputData.normalWS, inputData.viewDirectionWS,
            surfaceData.clearCoatMask, specularHighlightsOff);
          }
          LIGHT_LOOP_END
        #endif

        #if defined(_ADDITIONAL_LIGHTS_VERTEX)
          lightingData.vertexLightingColor += inputData.vertexLighting * brdfData.diffuse;
        #endif

        #if REAL_IS_HALF
          // Clamp any half.inf+ to HALF_MAX
          return min(CalculateFinalColor(lightingData, surfaceData.alpha), HALF_MAX);
        #else
          return CalculateFinalColor(lightingData, surfaceData.alpha);
        #endif
      }

      // ! LitPassFragment_NPR
      void LitPassFragment_NPR(
        Varyings input
        , out half4 outColor : SV_Target0
        #ifdef _WRITE_RENDERING_LAYERS
          , out float4 outRenderingLayers : SV_Target1
        #endif
      )
      {
        UNITY_SETUP_INSTANCE_ID(input);
        UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

        #if defined(_PARALLAXMAP)
          #if defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR)
            half3 viewDirTS = input.viewDirTS;
          #else
            half3 viewDirWS = GetWorldSpaceNormalizeViewDir(input.positionWS);
            half3 viewDirTS = GetViewDirectionTangentSpace(input.tangentWS, input.normalWS, viewDirWS);
          #endif
          ApplyPerPixelDisplacement(viewDirTS, input.uv);
        #endif

        SurfaceData surfaceData;
        InitializeStandardLitSurfaceData(input.uv, surfaceData);

        #ifdef LOD_FADE_CROSSFADE
          LODFadeCrossFade(input.positionCS);
        #endif

        InputData inputData;
        InitializeInputData(input, surfaceData.normalTS, inputData);
        // SETUP_DEBUG_TEXTURE_DATA(inputData, input.uv, _BaseMap);

        #ifdef _DBUFFER
          ApplyDecalToSurfaceData(input.positionCS, surfaceData, inputData);
        #endif

        // ! PBR color
        half4 color = UniversalFragmentPBR_NPR(inputData, surfaceData, input.uv);

        // ! fog and other
        color.rgb = MixFog(color.rgb, inputData.fogCoord);
        color.a = OutputAlpha(color.a, IsSurfaceTypeTransparent(_Surface));

        // ! output color
        outColor = color;

        #ifdef _WRITE_RENDERING_LAYERS
          uint renderingLayers = GetMeshRenderingLayer();
          outRenderingLayers = float4(EncodeMeshRenderingLayer(renderingLayers), 0, 0, 0);
        #endif
      }

      ENDHLSL
    }

    Pass
    {
      Name "ShadowCaster"
      Tags
      {
        "LightMode" = "ShadowCaster"
      }

      // -------------------------------------
      // Render State Commands
      ZWrite On
      ZTest LEqual
      ColorMask 0
      Cull[_Cull]

      HLSLPROGRAM
      #pragma target 2.0

      // -------------------------------------
      // Shader Stages
      #pragma vertex ShadowPassVertex
      #pragma fragment ShadowPassFragment

      // -------------------------------------
      // Material Keywords
      #pragma shader_feature_local _ALPHATEST_ON
      #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

      //--------------------------------------
      // GPU Instancing
      #pragma multi_compile_instancing
      #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

      // -------------------------------------
      // Universal Pipeline keywords

      // -------------------------------------
      // Unity defined keywords
      #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE

      // This is used during shadow map generation to differentiate between directional and punctual light shadows, as they use different formulas to apply Normal Bias
      #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW

      // -------------------------------------
      // Includes
      #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
      #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
      ENDHLSL
    }

    Pass
    {
      // Lightmode matches the ShaderPassName set in UniversalRenderPipeline.cs. SRPDefaultUnlit and passes with
      // no LightMode tag are also rendered by Universal Render Pipeline
      Name "GBuffer"
      Tags
      {
        "LightMode" = "UniversalGBuffer"
      }

      // -------------------------------------
      // Render State Commands
      ZWrite[_ZWrite]
      ZTest LEqual
      Cull[_Cull]

      HLSLPROGRAM
      #pragma target 4.5

      // Deferred Rendering Path does not support the OpenGL-based graphics API:
      // Desktop OpenGL, OpenGL ES 3.0, WebGL 2.0.
      #pragma exclude_renderers gles3 glcore

      // -------------------------------------
      // Shader Stages
      #pragma vertex LitGBufferPassVertex
      #pragma fragment LitGBufferPassFragment

      // -------------------------------------
      // Material Keywords
      #pragma shader_feature_local _NORMALMAP
      #pragma shader_feature_local_fragment _ALPHATEST_ON
      //#pragma shader_feature_local_fragment _ALPHAPREMULTIPLY_ON
      #pragma shader_feature_local_fragment _EMISSION
      #pragma shader_feature_local_fragment _METALLICSPECGLOSSMAP
      #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
      #pragma shader_feature_local_fragment _OCCLUSIONMAP
      #pragma shader_feature_local _PARALLAXMAP
      #pragma shader_feature_local _ _DETAIL_MULX2 _DETAIL_SCALED

      #pragma shader_feature_local_fragment _SPECULARHIGHLIGHTS_OFF
      #pragma shader_feature_local_fragment _ENVIRONMENTREFLECTIONS_OFF
      #pragma shader_feature_local_fragment _SPECULAR_SETUP
      #pragma shader_feature_local _RECEIVE_SHADOWS_OFF

      // -------------------------------------
      // Universal Pipeline keywords
      #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
      //#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
      //#pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
      #pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
      #pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
      #pragma multi_compile_fragment _ _SHADOWS_SOFT _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
      #pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
      #pragma multi_compile_fragment _ _RENDER_PASS_ENABLED
      #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"

      // -------------------------------------
      // Unity defined keywords
      #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
      #pragma multi_compile _ SHADOWS_SHADOWMASK
      #pragma multi_compile _ DIRLIGHTMAP_COMBINED
      #pragma multi_compile _ LIGHTMAP_ON
      #pragma multi_compile _ DYNAMICLIGHTMAP_ON
      #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE
      #pragma multi_compile_fragment _ _GBUFFER_NORMALS_OCT

      //--------------------------------------
      // GPU Instancing
      #pragma multi_compile_instancing
      #pragma instancing_options renderinglayer
      #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

      // -------------------------------------
      // Includes
      #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
      #include "Packages/com.unity.render-pipelines.universal/Shaders/LitGBufferPass.hlsl"
      ENDHLSL
    }

    Pass
    {
      Name "DepthOnly"
      Tags
      {
        "LightMode" = "DepthOnly"
      }

      // -------------------------------------
      // Render State Commands
      ZWrite On
      ColorMask R
      Cull[_Cull]

      HLSLPROGRAM
      #pragma target 2.0

      // -------------------------------------
      // Shader Stages
      #pragma vertex DepthOnlyVertex
      #pragma fragment DepthOnlyFragment

      // -------------------------------------
      // Material Keywords
      #pragma shader_feature_local _ALPHATEST_ON
      #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

      // -------------------------------------
      // Unity defined keywords
      #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE

      //--------------------------------------
      // GPU Instancing
      #pragma multi_compile_instancing
      #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

      // -------------------------------------
      // Includes
      #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
      #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
      ENDHLSL
    }

    // This pass is used when drawing to a _CameraNormalsTexture texture
    Pass
    {
      Name "DepthNormals"
      Tags
      {
        "LightMode" = "DepthNormals"
      }

      // -------------------------------------
      // Render State Commands
      ZWrite On
      Cull[_Cull]

      HLSLPROGRAM
      #pragma target 2.0

      // -------------------------------------
      // Shader Stages
      #pragma vertex DepthNormalsVertex
      #pragma fragment DepthNormalsFragment

      // -------------------------------------
      // Material Keywords
      #pragma shader_feature_local _NORMALMAP
      #pragma shader_feature_local _PARALLAXMAP
      #pragma shader_feature_local _ _DETAIL_MULX2 _DETAIL_SCALED
      #pragma shader_feature_local_fragment _ALPHATEST_ON
      #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

      // -------------------------------------
      // Unity defined keywords
      #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE

      // -------------------------------------
      // Universal Pipeline keywords
      #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"

      //--------------------------------------
      // GPU Instancing
      #pragma multi_compile_instancing
      #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

      // -------------------------------------
      // Includes
      #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
      #include "Packages/com.unity.render-pipelines.universal/Shaders/LitDepthNormalsPass.hlsl"
      ENDHLSL
    }

    // This pass it not used during regular rendering, only for lightmap baking.
    Pass
    {
      Name "Meta"
      Tags
      {
        "LightMode" = "Meta"
      }

      // -------------------------------------
      // Render State Commands
      Cull Off

      HLSLPROGRAM
      #pragma target 2.0

      // -------------------------------------
      // Shader Stages
      #pragma vertex UniversalVertexMeta
      #pragma fragment UniversalFragmentMetaLit

      // -------------------------------------
      // Material Keywords
      #pragma shader_feature_local_fragment _SPECULAR_SETUP
      #pragma shader_feature_local_fragment _EMISSION
      #pragma shader_feature_local_fragment _METALLICSPECGLOSSMAP
      #pragma shader_feature_local_fragment _ALPHATEST_ON
      #pragma shader_feature_local_fragment _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
      #pragma shader_feature_local _ _DETAIL_MULX2 _DETAIL_SCALED
      #pragma shader_feature_local_fragment _SPECGLOSSMAP
      #pragma shader_feature EDITOR_VISUALIZATION

      // -------------------------------------
      // Includes
      #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
      #include "Packages/com.unity.render-pipelines.universal/Shaders/LitMetaPass.hlsl"

      ENDHLSL
    }

    Pass
    {
      Name "Universal2D"
      Tags
      {
        "LightMode" = "Universal2D"
      }

      // -------------------------------------
      // Render State Commands
      Blend[_SrcBlend][_DstBlend]
      ZWrite[_ZWrite]
      Cull[_Cull]

      HLSLPROGRAM
      #pragma target 2.0

      // -------------------------------------
      // Shader Stages
      #pragma vertex vert
      #pragma fragment frag

      // -------------------------------------
      // Material Keywords
      #pragma shader_feature_local_fragment _ALPHATEST_ON
      #pragma shader_feature_local_fragment _ALPHAPREMULTIPLY_ON

      #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

      // -------------------------------------
      // Includes
      #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
      #include "Packages/com.unity.render-pipelines.universal/Shaders/Utils/Universal2D.hlsl"
      ENDHLSL
    }
  }

  FallBack "Hidden/Universal Render Pipeline/FallbackError"
  CustomEditor "UnityEditor.Rendering.Universal.ShaderGUI.LitShader"
}
