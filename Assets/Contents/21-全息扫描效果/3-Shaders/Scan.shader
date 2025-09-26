Shader "Custom/Normal/35-Scan"
{
  Properties
  {
    // ! -------------------------------------
    // ! 面板属性
    [HDR]_Color1 ("浅颜色", Color) = (1, 1, 1, 1)
    [HDR]_Color2 ("深颜色", Color) = (1, 1, 1, 1)
    _RimPower ("边缘乘方", Float) = 2
    _RimEdge1 ("边缘1", Float) = 0
    _RimEdge2 ("边缘2", Float) = 1
    _FlowTex ("流光贴图", 2D) = "white" { }
    _FlowIntensity ("流光强度", Float) = 1
    _InnerAlpha ("内部Alpha", Float) = 0.1
    _MTex ("金属贴图", 2D) = "white" { }
    _MTexPower ("金属贴图乘方", Float) = 6.5
  }
  
  SubShader
  {
    LOD 100

    // ! -------------------------------------
    // ! Tags
    Tags
    {
      "Queue" = "AlphaTest"
      "RenderPipeline" = "UniversalPipeline"
    }

    HLSLINCLUDE

    // ! -------------------------------------
    // ! 全shader include
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

    CBUFFER_START(UnityPerMaterial)

      // ! -------------------------------------
      // ! 变量声明
      TEXTURE2D(_CameraDepthTexture);
      SAMPLER(sampler_CameraDepthTexture);

      real4 _Color1;
      real4 _Color2;
      real _RimPower;
      real  _RimEdge1;
      real  _RimEdge2;

      TEXTURE2D(_FlowTex);
      SAMPLER(sampler_FlowTex);
      real4 _FlowTex_ST;
      real _FlowIntensity;
      real _InnerAlpha;

      TEXTURE2D(_MTex);
      SAMPLER(sampler_MTex);
      real4 _MTex_ST;
      real _MTexPower;

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
      ZWrite On
      ZTest LEqual
      Cull Back
      Blend SrcAlpha OneMinusSrcAlpha

      // Stencil
      // {
      //   Ref 1
      //   Comp NotEqual
      //   Pass Replace
      //   Fail Keep
      // }

      HLSLPROGRAM

      // ! -------------------------------------
      // ! pass include

      // ! -------------------------------------
      // ! Shader阶段
      #pragma vertex vert
      #pragma fragment frag

      // ! -------------------------------------
      // ! 顶点着色器输入
      struct appdata
      {
        real2 uv : TEXCOORD0;
        real4 positionOS : POSITION;
        real3 normalOS : NORMAL;
      };

      // ! -------------------------------------
      // ! 顶点着色器输出 片元着色器输入
      struct v2f
      {
        real2 uvFlow : TEXCOORD0;
        real2 uvM : TEXCOORD1;
        real4 positionCS : SV_POSITION;
        real3 positionWS : TEXCOORD2;
        real3 normalWS : TEXCOORD3;
      };

      // ! -------------------------------------
      // ! 顶点着色器
      v2f vert(appdata v)
      {
        v2f o = (v2f)0;

        VertexPositionInputs positionInputs = GetVertexPositionInputs(v.positionOS.xyz);
        VertexNormalInputs normalInputs = GetVertexNormalInputs(v.normalOS);
        
        o.positionCS = positionInputs.positionCS;
        o.positionWS = positionInputs.positionWS;
        o.normalWS = normalInputs.normalWS;

        real2 flowTexUV = v.positionOS.xz;
        _FlowTex_ST.w += _Time.y;
        flowTexUV = flowTexUV * _FlowTex_ST.xy + _FlowTex_ST.zw;
        o.uvFlow = flowTexUV;
        o.uvM = v.uv * _MTex_ST.xy + _MTex_ST.zw;

        return o;
      }

      // ! -------------------------------------
      // ! 片元着色器
      real4 frag(v2f i) : SV_TARGET
      {
        real3 viewDirWS = normalize(GetCameraPositionWS() - i.positionWS);
        real NdotV = saturate(dot(i.normalWS, viewDirWS));
        real fresnel = pow(1 - NdotV, _RimPower);
        fresnel = smoothstep(_RimEdge1, _RimEdge2, fresnel);

        real3 mColor = SAMPLE_TEXTURE2D(_MTex, sampler_MTex, i.uvM).rgb;
        mColor = pow(saturate(mColor), _MTexPower);

        real mask = saturate(fresnel + mColor.r);

        real3 finalColor = lerp(_Color2, _Color1, mask);
        
        real3 flowColor = SAMPLE_TEXTURE2D(_FlowTex, sampler_FlowTex, i.uvFlow).rgb;
        finalColor += flowColor * _FlowIntensity;

        real finalAlpha = mask + flowColor.b;
        finalAlpha = saturate(finalAlpha + _InnerAlpha);
        
        real2 screenUV = (i.positionCS / GetScaledScreenParams()).xy;
        float depth = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, screenUV).r;
        clip(i.positionCS.z - depth);
        
        return real4(finalColor, finalAlpha);
      }

      ENDHLSL
    }

    pass
    {
      Name "DepthOnly"

      Tags
      {
        // ! LightMode一定要写对
        "LightMode" = "DepthOnly"
      }

      ZWrite On
      ZTest LEqual

      ColorMask 0

      HLSLPROGRAM

      #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
      #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
      // ! 注意这里引用DepthOnlyPass.hlsl
      #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"

      #pragma shader_feature _ALPHATEST_ON
      #pragma shader_feature _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
      #pragma multi_compile_instancing

      // ! 使用顶点片元着色器也要写对
      #pragma vertex DepthOnlyVertex
      #pragma fragment DepthOnlyFragment

      ENDHLSL
    }
  }

  // ! -------------------------------------
  // ! 紫色报错fallback
  Fallback "Hidden/Universal Render Pipeline/FallbackError"
}
