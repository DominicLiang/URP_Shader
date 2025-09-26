Shader "Custom/GenShin/Body"
{
  Properties
  {
    // ! -------------------------------------
    // ! 面板属性
    [NoScaleOffset]_BaseMap ("主贴图", 2D) = "white" { }

    [Toggle(_NORMAL_MAP)]_NormalMap ("开启法线贴图", Float) = 0
    [NoScaleOffset]_BumpMap ("法线贴图", 2D) = "bump" { }
    _BumpScale ("法线强度", Float) = 1

    [NoScaleOffset]_LightMap ("光照贴图", 2D) = "black" { }

    [NoScaleOffset]_RampMap ("Ramp贴图", 2D) = "black" { }
    _RampEdge1 ("RampEdge1", Range(0, 1)) = 0.5
    _RampEdge2 ("RampEdge2", Range(0, 1)) = 0

    _Shininess ("高光", Range(0.1, 500)) = 10
    _Roughness ("粗糙度", Range(0, 1)) = 0.02
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

    TEXTURE2D(_BaseMap); SAMPLER(sampler_BaseMap);
    TEXTURE2D(_BumpMap); SAMPLER(sampler_BumpMap);
    TEXTURE2D(_LightMap); SAMPLER(sampler_LightMap);
    TEXTURE2D(_RampMap); SAMPLER(sampler_RampMap);

    CBUFFER_START(UnityPerMaterial)

      // ! -------------------------------------
      // ! 变量声明
      real _BumpScale;
      real _RampEdge1;
      real _RampEdge2;
      real _Shininess;
      real _Roughness;

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

      // ! -------------------------------------
      // ! 材质关键字
      #pragma shader_feature _ _NORMAL_MAP

      // ! -------------------------------------
      // ! 顶点着色器输入
      struct appdata
      {
        real2 uv : TEXCOORD0;
        real4 positionOS : POSITION;
        real3 normalOS : NORMAL;
        real4 tangentOS : TANGENT;
        real4 color : COLOR;
      };

      // ! -------------------------------------
      // ! 顶点着色器输出 片元着色器输入
      struct v2f
      {
        real2 uv : TEXCOORD0;
        real4 positionCS : SV_POSITION;
        real3 positionWS : TEXCOORD1;
        real3 normalWS : TEXCOORD2;
        real3 tangentWS : TEXCOORD3;
        real3 bitangentWS : TEXCOORD4;
        real4 color : COLOR;
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
        o.tangentWS = normalInputs.tangentWS;
        o.bitangentWS = normalInputs.bitangentWS;

        return o;
      }

      // ! -------------------------------------
      // ! 片元着色器
      real4 frag(v2f i) : SV_TARGET
      {
        #ifdef _NORMALMAP
          real4 packedNormal = SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, i.uv);
          real3 normalTS = UnpackNormalScale(packedNormal, _BumpScale);
          real3x3 TBN = real3x3(i.tangentWS, i.bitangentWS, i.normalWS);
          real3 normalWS = TransformTangentToWorld(normalTS, TBN);
        #else
          real3 normalWS = i.normalWS;
        #endif
        
        Light mainLight = GetMainLight();

        real3 N = normalize(normalWS);
        real3 V = normalize(_WorldSpaceCameraPos.xyz - i.positionWS.xyz);
        real3 L = normalize(mainLight.direction);
        real3 H = normalize(L + V);

        real NdotL = dot(N, L);
        real NdotV = dot(N, V);
        real NdotH = dot(N, H);

        real4 baseMapColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv);
        real4 lightMapColor = SAMPLE_TEXTURE2D(_LightMap, sampler_LightMap, i.uv);
        
        real highlightIntensity = lightMapColor.r;
        real ao = lightMapColor.g;
        real highlightMask = lightMapColor.b;
        real rampUVy = lightMapColor.a;

        real halfLambert = NdotL * 0.5 + 0.5;
        halfLambert = saturate(smoothstep(_RampEdge1, _RampEdge2, halfLambert));
        // float shadow = min(1.0f, dot(halfLambert.xx, 2 * ao.xx));
        real2 rampUV = real2(halfLambert, rampUVy + 0.05);
        real4 rampColor = SAMPLE_TEXTURE2D(_RampMap, sampler_RampMap, rampUV);

        float blinnPhong = pow(max(0.01, NdotH), _Shininess);
        float threshold = 1.03 - highlightMask;
        float specular = smoothstep(threshold - _Roughness, threshold + _Roughness, blinnPhong);
        specular *= highlightMask * highlightIntensity;
        real4 specularColor = baseMapColor * specular;

        
        return baseMapColor * rampColor + specularColor;
      }

      ENDHLSL
    }
  }

  // ! -------------------------------------
  // ! 紫色报错fallback
  Fallback "Hidden/Universal Render Pipeline/FallbackError"
}
