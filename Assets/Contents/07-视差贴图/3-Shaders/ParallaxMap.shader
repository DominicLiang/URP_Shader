Shader "Custom/08-ParallaxMap/ParallaxMap"
{
  Properties
  {
    [NoScaleOffset]_MainTex ("主贴图", 2D) = "white" { }
    [NoScaleOffset]_NormalMap ("法线贴图", 2D) = "bump" { }
    [NoScaleOffset]_ParallaxMap ("视差贴图", 2D) = "white" { }
    _ParallaxScale ("视差强度", Range(-1, 1)) = 0
  }
  SubShader
  {
    LOD 200

    Tags
    {
      "Queue" = "Geometry"
      "RenderPipeline" = "UniversalPipeline"
    }

    Cull Back
    ZTest LEqual
    ZWrite On

    HLSLINCLUDE

    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/ParallaxMapping.hlsl"

    CBUFFER_START(UnityPerMaterial)

      TEXTURE2D(_MainTex);
      SAMPLER(sampler_MainTex);
      TEXTURE2D(_NormalMap);
      SAMPLER(sampler_NormalMap);
      TEXTURE2D(_ParallaxMap);
      SAMPLER(sampler_ParallaxMap);
      real _ParallaxScale;

    CBUFFER_END

    ENDHLSL

    Pass
    {
      Name "BasePass"

      Tags
      {
        "LightMode" = "UniversalForward"
      }

      HLSLPROGRAM

      #pragma vertex vert
      #pragma fragment frag

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
        real4 positionCS : SV_POSITION;
        real3 positionWS : TEXCOORD1;
        real3 normalWS : TEXCOORD2;
        real4 tangentWS : TEXCOORD3;
        real3 bitangentWS : TEXCOORD4;
      };

      v2f vert(appdata v)
      {
        v2f o = (v2f)0;

        VertexPositionInputs positionInputs = GetVertexPositionInputs(v.positionOS.xyz);

        // ! 坑 GetVertexNormalInputs 有两个重载 必须传入tangentOS的那个重载才能获得tangentWS和bitangentWS
        VertexNormalInputs normalInputs = GetVertexNormalInputs(v.normalOS, v.tangentOS);
        
        o.uv = v.uv;

        o.positionCS = positionInputs.positionCS;
        o.positionWS = positionInputs.positionWS;
        o.normalWS = normalInputs.normalWS;
        o.tangentWS = mul(UNITY_MATRIX_M, v.tangentOS);
        o.bitangentWS = normalInputs.bitangentWS;
        
        return o;
      }

      float2 ParallaxUvDelta(Texture2D heightMap, SamplerState samplerState, real2 uv, real3 viewDirTS, real intensity)
      {
        real height = SAMPLE_TEXTURE2D(heightMap, samplerState, uv).r;

        real2 offset = viewDirTS.xy / max(viewDirTS.z, 0.0001) * height * intensity;

        return offset;
      }

      real4 frag(v2f i) : SV_TARGET
      {
        real3 viewDirWS = normalize(GetCameraPositionWS() - i.positionWS);
        real3x3 TBN = real3x3(normalize(i.tangentWS.xyz), normalize(i.bitangentWS), normalize(i.normalWS));
        // ! TBN乘向量 世界 -> 切线
        // real3 viewDirTS = normalize(mul(TBN, viewDirWS));

        // real height = SAMPLE_TEXTURE2D(_ParallaxMap, sampler_ParallaxMap, i.uv).r;
        // height -= 0.5;
        // real2 offset = -viewDirTS.xy / max(viewDirTS.z, 0.01) * height * _ParallaxScale;

        // real2 offset = ParallaxUvDelta(_ParallaxMap, sampler_ParallaxMap, i.uv, viewDirTS, _ParallaxScale);

        // ! SRP内置的实现 Packages/com.unity.render-pipelines.core/ShaderLibrary/ParallaxMapping.hlsl
        real3 viewDirTS = GetViewDirectionTangentSpace(i.tangentWS, i.normalWS, viewDirWS);
        real2 offset = ParallaxMapping(TEXTURE2D_ARGS(_ParallaxMap, sampler_ParallaxMap), viewDirTS, _ParallaxScale, i.uv);
        real2 parallaxUV = i.uv + offset;
        

        // real3 N = normalize(i.normalWS);
        // real3 V = viewDirWS;
        // real NdotV = dot(N, V);
        // real fresnel = pow(1 - saturate(NdotV), 1);
        // fresnel = smoothstep(0.5, 1, fresnel);

        // parallaxUV = lerp(parallaxUV, i.uv, fresnel);



        real4 packedNormal = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, parallaxUV);
        real3 tangentNormal = UnpackNormal(packedNormal);
        // ! 向量乘TBN 切线 -> 世界
        real3 normalWS = normalize(mul(tangentNormal, TBN));
        Light light = GetMainLight();
        real NoL = dot(normalWS, light.direction);
        real halfLambert = NoL * light.distanceAttenuation * light.shadowAttenuation * 0.5 + 0.5;

        real4 baseColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, parallaxUV);
        
        return baseColor * halfLambert;
      }

      ENDHLSL
    }
  }

  Fallback "Hidden/Universal Render Pipeline/FallbackError"
}
