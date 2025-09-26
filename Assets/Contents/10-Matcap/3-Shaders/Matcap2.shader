Shader "Custom/Normal/Template"
{
  Properties
  {
    // ! -------------------------------------
    // ! 面板属性
    [NoScaleOffset]_NormalMap ("法线贴图", 2D) = "bump" { }

    [NoScaleOffset]_Matcap1Tex ("Matcap1", 2D) = "white" { }
    _Matcap1Intensity ("Matcap1强度", Range(0, 10)) = 1
    
    [NoScaleOffset]_Matcap2Tex ("Matcap2", 2D) = "white" { }
    _Matcap2Intensity ("Matcap2强度", Range(0, 10)) = 1

    [NoScaleOffset]_RampTex ("Ramp贴图", 2D) = "white" { }
    _RampEdge1 ("Ramp边沿1", Float) = 0.55
    _RampEdge2 ("Ramp边沿2", Float) = 2.1
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

    CBUFFER_START(UnityPerMaterial)

      // ! -------------------------------------
      // ! 变量声明
      TEXTURE2D(_NormalMap);
      SAMPLER(sampler_NormalMap);

      TEXTURE2D(_Matcap1Tex);
      SAMPLER(sampler_Matcap1Tex);
      real _Matcap1Intensity;

      TEXTURE2D(_Matcap2Tex);
      SAMPLER(sampler_Matcap2Tex);
      real _Matcap2Intensity;

      TEXTURE2D(_RampTex);
      SAMPLER(sampler_RampTex);
      real _RampEdge1;
      real _RampEdge2;

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
        real3 positionVS : TEXCOORD2;
        real3 tangentWS : TEXCOORD3;
        real3 bitangentWS : TEXCOORD4;
        real3 normalWS : TEXCOORD5;
      };

      half2 MatCapUV(half3 positionVS, half3 normalVS)
      {
        float3 posVS = normalize(positionVS);
        float3 nVS = normalVS;
        float3 vcn = cross(posVS, nVS);
        float2 uv = float2(-vcn.y, vcn.x);
        uv = uv * 0.5 + 0.5;
        return uv;
      }

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
        o.positionVS = positionInputs.positionVS;
        o.tangentWS = normalInputs.tangentWS;
        o.bitangentWS = normalInputs.bitangentWS;
        o.normalWS = normalInputs.normalWS;

        return o;
      }

      // ! -------------------------------------
      // ! 片元着色器
      real4 frag(v2f i) : SV_TARGET
      {
        // * 从法线贴图获取法线并转到世界空间
        real4 packedNormal = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, i.uv);
        real3 tangentNormal = UnpackNormal(packedNormal);
        real3x3 TBN = real3x3(normalize(i.tangentWS.xyz), normalize(i.bitangentWS), normalize(i.normalWS));
        real3 normalWS = normalize(mul(tangentNormal, TBN));

        // * 计算matcap的uv
        real3x3 worldToViewNormal = transpose((real3x3)UNITY_MATRIX_I_V);
        real3 normalVS = mul(worldToViewNormal, normalWS);
        real2 matcapUV = MatCapUV(i.positionVS, normalVS);
        
        // * matcap颜色
        real4 mc1 = SAMPLE_TEXTURE2D(_Matcap1Tex, sampler_Matcap1Tex, matcapUV);
        real4 mc2 = SAMPLE_TEXTURE2D(_Matcap2Tex, sampler_Matcap2Tex, matcapUV);
        real3 matCapColor = mc1.rgb * _Matcap1Intensity + mc2.rgb * _Matcap2Intensity;

        // * ramp贴图uv
        real3 viewDirWS = normalize(GetCameraPositionWS() - i.positionWS);
        real NdotV = dot(normalWS, viewDirWS);
        real fresnel = 1 - saturate(smoothstep(_RampEdge1, _RampEdge2, NdotV));
        real2 rampUV = real2(fresnel, 0.5);

        real3 ramp = SAMPLE_TEXTURE2D(_RampTex, sampler_RampTex, rampUV);
        matCapColor *= ramp;

        return real4(matCapColor, 1);
      }

      ENDHLSL
    }
  }

  // ! -------------------------------------
  // ! 紫色报错fallback
  Fallback "Hidden/Universal Render Pipeline/FallbackError"
}
