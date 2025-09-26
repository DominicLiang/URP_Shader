Shader "Custom/07-Water/Water"
{
  Properties
  {
    [Main(Vert, _, off, off)]_Vert ("顶点偏移", float) = 0
    [Sub(Vert)]_Wave1 ("波浪1", Vector) = (0, 0, 0, 0)
    [Sub(Vert)]_Wave2 ("波浪2", Vector) = (0, 0, 0, 0)
    [Sub(Vert)]_Wave3 ("波浪3", Vector) = (0, 0, 0, 0)
    [Sub(Vert)]_WaveColor ("波浪顶峰颜色", Color) = (1, 1, 1, 1)
    
    [Main(Base, _, off, off)]_Base ("基础", float) = 0
    [Sub(Base)]_NormalMap ("法线纹理", 2D) = "bump" { }
    [Sub(Base)]_NormalIntensity ("法线强度", Range(0, 2)) = 0.3
    [Sub(Base)]_NormalSpeed ("法线速度", Float) = 0.1
    [Sub(Base)]_NormalSpeed2 ("法线速度2", Float) = 0.1
    [Sub(Base)]_DepthMin ("深度最小值", Range(0, 10)) = 0
    [Sub(Base)]_DepthMax ("深度最大值", Range(0, 10)) = 1
    [Sub(Base)]_WaterColorDeep ("深水颜色", Color) = (0, 0, 0, 1)
    [Sub(Base)]_WaterColorShallow ("浅水颜色", Color) = (1, 1, 1, 1)
    [Sub(Base)]_ShadowColor ("阴影颜色", Color) = (1, 1, 1, 1)
    [Sub(Base)]_Alpha ("Alpha", Range(0, 10)) = 1
    
    [Main(Fresnel, _, off, off)]_Fresnel ("菲尼尔", float) = 0
    [Sub(Fresnel)]_FresnelColor ("菲尼尔颜色", Color) = (0, 0, 0, 1)
    [Sub(Fresnel)]_FresnelPower ("菲尼尔乘方", Range(0, 10)) = 1
    
    [Main(Foam, _, off, off)]_Foam ("泡沫", float) = 0
    [Sub(Foam)]_FoamFrequency ("泡沫重复度", Float) = 100
    [Sub(Foam)]_FoamSpeed ("泡沫移动速度", Float) = 2
    [Sub(Foam)]_FoamNoiseTexture ("泡沫噪声纹理", 2D) = "white" { }
    [Sub(Foam)]_FoamMinEdge ("泡沫范围1", Float) = 1
    [Sub(Foam)]_FoamMaxEdge ("泡沫范围2", Float) = 1
    [Sub(Foam)]_FoamMin ("泡沫岸边系数", Float) = 0.75
    [Sub(Foam)]_FoamMax ("泡沫离岸系数", Float) = 1.2
    [Sub(Foam)]_FoamColor ("泡沫颜色", Color) = (1, 1, 1, 1)
    [Sub(Foam)]_FoamEdge1 ("泡沫边缘系数1", Range(0, 1)) = 0.5
    [Sub(Foam)]_FoamEdge2 ("泡沫边缘系数2", Range(0, 1)) = 0.5
    
    [Main(Refract, _, off, off)]_Refract ("折射", float) = 0
    [Sub(Refract)]_RefractDistortTexture ("折射扰动纹理", 2D) = "bump" { }
    [Sub(Refract)]_RefractDistortIntensity ("折射扰动强度", Range(0, 1)) = 1
    [Sub(Refract)]_RefractDistortSpeed ("折射扰动速度", Float) = 0.1
    [Sub(Refract)]_RefractIntensity ("折射强度", Range(0, 2)) = 1
    
    
    [Main(Reflect, _, off, off)]_Reflect ("反射", float) = 0
    [Sub(Reflect)]_CubeMap ("环境反射贴图", Cube) = "" { }
    [Sub(Reflect)]_ReflectIntensity ("反射强度", Range(0, 1)) = 0.5
    [Sub(Reflect)]_ReflectDistortIntensity ("反射扰动强度", Range(0, 1)) = 0.5
    [Sub(Reflect)]_ReflectBlurIntensity ("反射模糊强度", Range(0, 1)) = 0.5
    
    [Main(Caustics, _, off, off)]_Caustics ("焦散", float) = 0
    [Sub(Caustics)]_CausticsColor ("焦散颜色", Color) = (1, 1, 1, 1)
    [Sub(Caustics)]_CausticsIntensity ("焦散强度", Range(0, 1)) = 1
    [Sub(Caustics)]_CausticsSpeed ("焦散移动速度", Range(0, 5)) = 0.7
    [Sub(Caustics)]_CausticsScale ("焦散缩放", Float) = 0.4
    [Sub(Caustics)]_CausticsPower ("焦散粗细", Float) = 5
    
    [Main(Ripple, _, off, off)]_Ripple ("涟漪", float) = 0
    [Sub(Ripple)][NoScaleOffset]_RippleRT ("涟漪RT", 2D) = "white" { }
    [Sub(Ripple)]_RippleNormalIntensity ("涟漪法线强度", Range(0, 100)) = 10
    [Sub(Ripple)]_RippleFoamIntensity ("涟漪泡沫强度", Range(0, 1)) = 0.5
  }

  SubShader
  {
    LOD 200

    Tags
    {
      "Queue" = "Transparent"
      "RenderPipeline" = "UniversalPipeline"
    }

    HLSLINCLUDE

    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
    #include "Assets/ShaderLibrary/Utility/Node.hlsl"
    #include "Assets/ShaderLibrary/PostProcessing/Blur.hlsl"

    CBUFFER_START(UnityPerMaterial)

      // system
      TEXTURE2D(_CameraDepthTexture);
      SAMPLER(sampler_CameraDepthTexture);
      TEXTURE2D(_CameraOpaqueTexture);
      SAMPLER(sampler_CameraOpaqueTexture);
      TEXTURE2D(_ReflectRT);
      SAMPLER(sampler_ReflectRT);

      // vert
      real4 _Wave1;
      real4 _Wave2;
      real4 _Wave3;
      real4 _WaveColor;

      // base
      TEXTURE2D(_NormalMap);
      SAMPLER(sampler_NormalMap);
      real4 _NormalMap_ST;
      real _NormalIntensity;
      real _NormalSpeed;
      real _NormalSpeed2;
      real _DepthMin;
      real _DepthMax;
      real4 _WaterColorDeep;
      real4 _WaterColorShallow;
      real4 _ShadowColor;
      real _Alpha;

      // fresnel
      real4 _FresnelColor;
      real _FresnelPower;

      // foam
      real _FoamFrequency;
      real _FoamSpeed;
      TEXTURE2D(_FoamNoiseTexture);
      SAMPLER(sampler_FoamNoiseTexture);
      real4 _FoamNoiseTexture_ST;
      real _FoamMinEdge;
      real _FoamMaxEdge;
      real _FoamMin;
      real _FoamMax;
      real4 _FoamColor;
      real _FoamEdge1;
      real _FoamEdge2;
      

      // refract
      TEXTURE2D(_RefractDistortTexture);
      SAMPLER(sampler_RefractDistortTexture);
      real4 _RefractDistortTexture_ST;
      real _RefractDistortIntensity;
      real _RefractDistortSpeed;
      real _RefractIntensity;
      
      // reflect
      TEXTURECUBE(_CubeMap);
      SAMPLER(sampler_CubeMap);
      real _ReflectIntensity;
      real _ReflectDistortIntensity;
      real _ReflectBlurIntensity;

      // Caustics
      real4 _CausticsColor;
      real _CausticsIntensity;
      real _CausticsSpeed;
      real _CausticsScale;
      real _CausticsPower;

      // Ripple
      TEXTURE2D(_RippleRT);
      SAMPLER(sampler_RippleRT);
      real _RippleNormalIntensity;
      real _RippleFoamIntensity;

    CBUFFER_END

    #ifndef UNITY_PI
      #define UNITY_PI 3.14159265359
    #endif

    ENDHLSL

    Pass
    {
      Name "BasePass"

      Tags
      {
        "LightMode" = "UniversalForward"
      }

      Cull Back
      ZWrite Off
      Blend SrcAlpha OneMinusSrcAlpha

      HLSLPROGRAM

      #pragma vertex vert
      #pragma fragment frag


      #pragma multi_compile _MAIN_LIGHT_SHADOWS_CASCADE

      struct appdata
      {
        real2 uv : TEXCOORD0;
        real4 positionOS : POSITION;
        real3 normalOS : NORMAL;
        real4 tangentOS : TANGENT;
      };

      struct v2f
      {
        real2 uv : TEXCOORD0;
        real2 refractUV : TEXCOORD1;
        real2 normalUV : TEXCOORD2;
        real4 positionCS : SV_POSITION;
        real3 positionVS : TEXCOORD3;
        real3 positionWS : TEXCOORD4;
        real3 tangentWS : TEXCOORD5;
        real3 bitangentWS : TEXCOORD6;
        real3 normalWS : TEXCOORD7;
        real waveOffset : TEXCOORD8;
      };

      real Distortion(Texture2D distortTex, SamplerState texSampler, real2 uv, real intensity)
      {
        real distortOffset = SAMPLE_TEXTURE2D_LOD(distortTex, texSampler, uv, 0).r;
        
        distortOffset -= 0.5;
        distortOffset *= intensity;
        return distortOffset;
      }

      float3 GerstnerWave(float4 wave, float3 position, inout float3 tangent, inout float3 binormal)
      {
        float steepness = wave.z * 0.01;
        float wavelength = wave.w;
        float k = 2 * UNITY_PI / wavelength;
        float c = sqrt(9.8 / k);
        float2 d = normalize(wave.xy);
        float f = k * (dot(d, position.xz) - c * _Time.y * 0.1);
        float a = steepness / k;

        tangent += float3(
          - d.x * d.x * (steepness * sin(f)),
          d.x * (steepness * cos(f)),
          - d.x * d.y * (steepness * sin(f))
        );
        binormal += float3(
          - d.x * d.y * (steepness * sin(f)),
          d.y * (steepness * cos(f)),
          - d.y * d.y * (steepness * sin(f))
        );
        return float3(
          d.x * (a * cos(f)),
          a * sin(f),
          d.y * (a * cos(f))
        );
      }

      v2f vert(appdata v)
      {
        v2f o = (v2f)0;

        real3 tangentOS = real3(1, 0, 0);
        real3 binormalOS = real3(0, 0, 1);
        real3 offset = GerstnerWave(_Wave1, v.positionOS.xyz, tangentOS, binormalOS);
        offset += GerstnerWave(_Wave2, v.positionOS.xyz, tangentOS, binormalOS);
        offset += GerstnerWave(_Wave3, v.positionOS.xyz, tangentOS, binormalOS);
        v.positionOS.xyz += offset;
        o.waveOffset = offset.y;

        VertexPositionInputs positionInputs = GetVertexPositionInputs(v.positionOS.xyz);
        VertexNormalInputs normalInputs = GetVertexNormalInputs(v.normalOS, v.tangentOS);

        o.positionCS = positionInputs.positionCS;
        o.positionVS = positionInputs.positionVS;
        o.positionWS = positionInputs.positionWS;
        o.tangentWS = normalInputs.tangentWS;
        o.bitangentWS = normalInputs.bitangentWS;
        o.normalWS = normalInputs.normalWS;
        o.uv = v.uv;

        _RefractDistortTexture_ST.w += _RefractDistortSpeed * _Time.y;
        real2 refractUV = v.uv * _RefractDistortTexture_ST.xy + _RefractDistortTexture_ST.zw;

        _NormalMap_ST.w += _NormalSpeed * _Time.y;
        real2 normalUV = v.uv * _NormalMap_ST.xy + _NormalMap_ST.zw;

        o.refractUV = refractUV;
        o.normalUV = normalUV;

        return o;
      }

      real4 frag(v2f i) : SV_TARGET
      {
        real3x3 TBN = real3x3(
          normalize(i.tangentWS),
          normalize(i.bitangentWS),
          normalize(i.normalWS)
        );
        
        real4 normalST1 = _NormalMap_ST;
        normalST1.w += _NormalSpeed * _Time.y;
        real2 normalUV1 = i.uv * normalST1.xy + normalST1.zw;

        real4 normalST2 = _NormalMap_ST;
        normalST2.w += _NormalSpeed2 * _Time.y;
        real2 normalUV2 = i.uv * normalST2.xy + normalST2.zw;

        real3 normalTS1 = UnpackNormalScale(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, normalUV1), _NormalIntensity);
        real3 normalTS2 = UnpackNormalScale(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, normalUV2), _NormalIntensity);
        real3 normalTS = (normalTS1 + normalTS2) * 0.5;

        real3 normalWS = mul(normalTS, TBN);
        Light light = GetMainLight();
        real3 n = normalize(normalWS);
        real3 l = light.direction;
        real3 v = normalize(GetCameraPositionWS() - i.positionWS);

        // ! 深度
        real2 orgScreenUV = i.positionCS.xy / GetScaledScreenParams().xy;
        real eyeDepth = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, orgScreenUV).r;
        eyeDepth = LinearEyeDepth(eyeDepth, _ZBufferParams);

        // 根据相似三角形公式计算世界空间坐标
        real4 positionVS = 1;
        positionVS.xy = (eyeDepth / - i.positionVS.z) * i.positionVS.xy;
        positionVS.z = eyeDepth;
        real3 positionWS = mul(unity_CameraToWorld, positionVS).xyz;
        
        real baseHeight = i.positionWS.y - positionWS.y;
        real height = Unity_Remap_float4(baseHeight, real2(_DepthMin, _DepthMax), real2(0, 1));
        height = saturate(height);

        // real baseHeight = eyeDepth + i.positionVS.z; // ! 用posVS.z更适合大面积的水
        // real height = Unity_Remap_float4(baseHeight, real2(_DepthMin, _DepthMax), real2(0, 1));
        // height = saturate(height);

        // ! 菲尼尔
        real fresnel = saturate(pow(1 - dot(i.normalWS, v), _FresnelPower));

        // ! 泡沫
        real2 foamNoiseUV = i.uv * _FoamNoiseTexture_ST.xy + _FoamNoiseTexture_ST.zw;
        real sineWave = sin(height * _FoamFrequency + _Time.y * _FoamSpeed);
        real orgFoamNoise = SAMPLE_TEXTURE2D(_FoamNoiseTexture, sampler_FoamNoiseTexture, foamNoiseUV).r - 0.5;
        real foamNoise = orgFoamNoise - 0.5;
        sineWave += foamNoise;
        real foamShapeMask = smoothstep(_FoamMaxEdge, _FoamMinEdge, height);
        real foamStepEdge = lerp(_FoamMin, _FoamMax, foamShapeMask);
        real foamShape = step(sineWave, foamStepEdge);
        real foamEdge = smoothstep(_FoamEdge1, _FoamEdge2, height) * 0.8;
        foamShape *= 1 - foamShapeMask;
        foamShape += foamEdge;

        // ! 折射
        real refractOffset = Distortion(_RefractDistortTexture, sampler_RefractDistortTexture, i.refractUV, _RefractDistortIntensity);
        real4 refractColor = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, orgScreenUV + refractOffset);

        // ! 涟漪
        real2 rippleUV = real2(-i.uv.x, -i.uv.y);
        real4 rippleHeight = SAMPLE_TEXTURE2D(_RippleRT, sampler_RippleRT, i.uv);
        real3 rippleNormal;
        Unity_NormalFromHeight_World_float(rippleHeight, _RippleNormalIntensity, i.positionWS, TBN, rippleNormal);
        n += rippleNormal;

        // ! 反射
        // * 平面反射
        real4 screenUV = i.positionCS / GetScaledScreenParams();
        real2 reflectUV = screenUV.xy + n * _ReflectDistortIntensity;
        real4 reflectColor = KawaseBlur(_ReflectRT, sampler_ReflectRT, reflectUV, _ReflectBlurIntensity);

        // * CubeMap
        // real3 rn = lerp(i.normalWS, n, 0.1);
        // real3 r = reflect(-v, rn);
        // real4 reflectColor = SAMPLE_TEXTURECUBE(_CubeMap, sampler_CubeMap, r);
        // * 反射探针
        // real4 reflectColor = SAMPLE_TEXTURECUBE(unity_SpecCube0, samplerunity_SpecCube0, r);

        // ! 焦散
        // real4 objPosVS = 1;
        // objPosVS.xy = eyeDepth / - i.positionVS.z * i.positionVS.xy;
        // objPosVS.z = eyeDepth;
        // real3 objPosWS = mul(unity_CameraToWorld, objPosVS).xyz;
        real2 uvCaustics = positionWS.xz + positionWS.y;

        real value = 0;
        real cell = 0;
        Unity_Voronoi_Deterministic_float(uvCaustics, _Time.y * _CausticsSpeed, _CausticsScale, value, cell);
        value = saturate(pow(saturate(value), _CausticsPower));
        real4 causticsColor = _CausticsColor * value;
        causticsColor *= 1 - saturate(height);
        causticsColor *= _CausticsIntensity;

        // ! 最终
        real4  color = lerp(_WaterColorShallow, _WaterColorDeep, height);
        color = lerp(color, _WaveColor, saturate(i.waveOffset));
        color = lerp(color, _FresnelColor, fresnel);
        color = lerp(refractColor, color, saturate(height * _RefractIntensity));
        color = lerp(color, reflectColor, _ReflectIntensity);
        color = lerp(color, _FoamColor, foamShape);
        color += causticsColor;

        real4 shadowCoord = TransformWorldToShadowCoord(i.positionWS);
        Light mainLight = GetMainLight(shadowCoord);
        real3 shadowColor = lerp(_ShadowColor, real3(1, 1, 1), mainLight.shadowAttenuation);
        color.rgb *= shadowColor;
        color.a = saturate(height * _Alpha);
        color.a = lerp(color.a, 1, foamShape);

        return color;
      }

      ENDHLSL
    }
  }

  Fallback "Hidden/Universal Render Pipeline/FallbackError"
  CustomEditor "LWGUI.LWGUI"
}
