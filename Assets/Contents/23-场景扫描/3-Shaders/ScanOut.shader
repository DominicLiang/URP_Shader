Shader "Custom/Normal/ScanOut"
{
  Properties
  {
    // ! -------------------------------------
    // ! 面板属性
    [HDR]_MainColor ("主颜色", Color) = (1, 1, 1, 1)

    // _Center ("中心", Vector) = (0, 0, 0, 0)
    // _Threshold ("阈值", Range(0, 2000)) = 1
    
    [HDR]_EdgeColor ("边沿颜色", Color) = (1, 1, 1, 1)
    _EdgeThreshold ("边沿阈值", Float) = 1
  }
  
  SubShader
  {
    LOD 100

    // ! -------------------------------------
    // ! Tags
    Tags
    {
      "Queue" = "Transparent"
      "RenderPipeline" = "UniversalPipeline"
    }

    HLSLINCLUDE

    // ! -------------------------------------
    // ! 全shader include
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

    CBUFFER_START(UnityPerMaterial)

      // ! -------------------------------------
      // ! 变量声明
      SAMPLER(sampler_MainTex);
      real4 _MainColor;

      real3 _Center;
      real _Threshold;

      real4 _EdgeColor;
      real _EdgeThreshold;

    CBUFFER_END

    ENDHLSL



    Pass
    {
      // ! -------------------------------------
      // ! Pass名
      Name "GhostPass"

      // ! -------------------------------------
      // ! tags
      Tags
      {
        "LightMode" = "GhostPass"
      }

      // ! -------------------------------------
      // ! 渲染状态
      Cull Back
      ZWrite Off
      Blend SrcAlpha OneMinusSrcAlpha

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
        real2 uv : TEXCOORD0;
        real4 positionCS : SV_POSITION;
        real3 positionWS : TEXCOORD1;
        real3 normalWS : TEXCOORD2;
      };

      // ! -------------------------------------
      // ! 顶点着色器
      v2f vert(appdata v)
      {
        v2f o = (v2f)0;

        VertexPositionInputs positionInputs = GetVertexPositionInputs(v.positionOS.xyz);
        VertexNormalInputs normalInputs = GetVertexNormalInputs(v.normalOS);
        
        o.uv = v.uv;
        o.positionCS = positionInputs.positionCS;
        o.positionWS = positionInputs.positionWS;
        o.normalWS = normalInputs.normalWS;

        return o;
      }

      // ! -------------------------------------
      // ! 片元着色器
      real4 frag(v2f i) : SV_TARGET
      {
        // 材质二
        real3 n = normalize(i.normalWS);
        real3 v = normalize(GetCameraPositionWS() - i.positionWS);
        real fresnel = pow(1.0 - saturate(dot(n, v)), 5);
        // real4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
        // color *= _MainColor;
        real4 color = _MainColor;

        // 根据距离区分两个材质
        real dis = distance(i.positionWS, _Center);
        real stepDis = step(dis, _Threshold);
        color.a = lerp(1, 0, stepDis);
        clip(color.a - 0.5);

        // 边沿高光
        real edge = saturate(abs(dis - _Threshold));
        edge = step(edge, _EdgeThreshold);
        color = lerp(color, _EdgeColor, edge);

        color.a = fresnel;

        return color;
      }

      ENDHLSL
    }
  }

  // ! -------------------------------------
  // ! 紫色报错fallback
  Fallback "Hidden/Universal Render Pipeline/FallbackError"
}
