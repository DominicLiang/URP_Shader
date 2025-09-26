Shader "Custom/Normal/Anistropy"
{
  Properties
  {
    // ! -------------------------------------
    // ! 面板属性
    [NoScaleOffset]_FlowMap ("Flow贴图", 2D) = "white" { }
    [NoScaleOffset]_NoiseTex ("噪声贴图", 2D) = "white" { }

    _AnisoNoiseStrength ("Noise Shift", Range(0, 1)) = 0.3
    _AnisoShift ("Anisotropy Shift", Range(-2, 2)) = 0
    _AnisoSpecPower ("Anisotropy Specular Power", Range(0, 500)) = 10
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

    CBUFFER_START(UnityPerMaterial)

      // ! -------------------------------------
      // ! 变量声明
      TEXTURE2D(_FlowMap);
      SAMPLER(sampler_FlowMap);

      TEXTURE2D(_NoiseTex);
      SAMPLER(sampler_NoiseTex);

      float _AnisoNoiseStrength;
      // float _AnisoStrength;
      float _AnisoShift;
      float _AnisoSpecPower;

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
      // ! 材质关键字 shader_feature

      // ! -------------------------------------
      // ! URP关键字 multi_compile

      // ! -------------------------------------
      // ! Unity关键字 multi_compile

      // ! -------------------------------------
      // ! GPU实例 multi_compile

      // ! -------------------------------------
      // ! 顶点着色器输入
      struct appdata
      {
        real2 uv : TEXCOORD0;
        real4 positionOS : POSITION;
        real3 normalOS : NORMAL;
        real4 tangentOS : TANGENT;
      };

      // ! -------------------------------------
      // ! 顶点着色器输出 片元着色器输入
      struct v2f
      {
        real2 uv : TEXCOORD0;
        real4 positionCS : SV_POSITION;
        real3 positionWS : TEXCOORD1;
        real3 tangentWS : TEXCOORD2;
        real3 bitangentWS : TEXCOORD3;
        real3 normalWS : TEXCOORD4;
      };

      // ! -------------------------------------
      // ! 顶点着色器
      v2f vert(appdata v)
      {
        v2f o = (v2f)0;

        VertexPositionInputs positionInputs = GetVertexPositionInputs(v.positionOS.xyz);
        VertexNormalInputs normalInputs = GetVertexNormalInputs(v.normalOS, v.tangentOS);
        
        o.positionCS = positionInputs.positionCS;
        o.positionWS = positionInputs.positionWS;
        o.tangentWS = normalInputs.tangentWS;
        o.bitangentWS = normalInputs.bitangentWS;
        o.normalWS = normalInputs.normalWS;
        
        o.uv = v.uv;
        
        return o;
      }

      half AnisotropyKajiyaKay(half3 T, half3 V, half3 L, half specPower)
      {
        half3 H = normalize(V + L);
        half HdotT = dot(T, H);
        half sinTH = sqrt(1 - HdotT * HdotT);
        half dirAtten = smoothstep(-1, 0, HdotT);
        return dirAtten * saturate(pow(sinTH, specPower));
      }

      half3 ShiftTangent(half3 T, half3 N, half shift)
      {
        return normalize(T + shift * N);
      }

      // ! -------------------------------------
      // ! 片元着色器
      real4 frag(v2f i) : SV_TARGET
      {
        Light light = GetMainLight();
        real3 L = normalize(light.direction);
        real3 V = normalize(GetCameraPositionWS() - i.positionWS);
        real3 T = normalize(i.tangentWS);
        real3 B = normalize(i.bitangentWS);
        real3 N = normalize(i.normalWS);

        real2 anisoFlowmap = SAMPLE_TEXTURE2D(_FlowMap, sampler_FlowMap, i.uv).rg;
        anisoFlowmap = anisoFlowmap * 2 - 1;    // * -1 1

        real shiftNoise = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, i.uv).r;
        shiftNoise = (shiftNoise * 2 - 1) * _AnisoNoiseStrength;
        
        T = normalize(anisoFlowmap.x * T + anisoFlowmap.y * B);
        T = ShiftTangent(T, N, _AnisoShift + shiftNoise);
        real anisoSpec = AnisotropyKajiyaKay(T, V, L, _AnisoSpecPower);

        real diffuse_term = dot(N, L) * 0.5 + 0.5;

        real3 diffuse = diffuse_term * light.color;

        real3 color = anisoSpec + diffuse;
        
        return real4(color, 1);
      }

      ENDHLSL
    }
  }

  // ! -------------------------------------
  // ! 紫色报错fallback
  Fallback "Hidden/Universal Render Pipeline/FallbackError"
}
