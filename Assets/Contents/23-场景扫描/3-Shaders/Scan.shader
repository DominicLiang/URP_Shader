Shader "Custom/Normal/Scan"
{
  Properties
  {
    // ! -------------------------------------
    // ! 面板属性
    [NoScaleOffset]_MainTex ("主贴图", 2D) = "white" { }
    [HDR]_MainColor ("主颜色", Color) = (1, 1, 1, 1)

    [NoScaleOffset]_MainTex2 ("主贴图", 2D) = "white" { }
    [HDR]_MainColor2 ("主颜色", Color) = (1, 1, 1, 1)

    _Center ("中心", Vector) = (0, 0, 0, 0)
    _Threshold ("阈值", Range(0, 200)) = 1
    
    _EdgeColor ("边沿颜色", Color) = (1, 1, 1, 1)
    _EdgeThreshold ("边沿阈值", Float) = 1
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
      TEXTURE2D(_MainTex);
      SAMPLER(sampler_MainTex);
      real4 _MainColor;

      TEXTURE2D(_MainTex2);
      SAMPLER(sampler_MainTex2);
      real4 _MainColor2;

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
      // ! 顶点着色器输入
      struct appdata
      {
        real2 uv : TEXCOORD0;
        real4 positionOS : POSITION;
      };

      // ! -------------------------------------
      // ! 顶点着色器输出 片元着色器输入
      struct v2f
      {
        real2 uv : TEXCOORD0;
        real4 positionCS : SV_POSITION;
        real3 positionWS : TEXCOORD1;
      };

      // ! -------------------------------------
      // ! 顶点着色器
      v2f vert(appdata v)
      {
        v2f o = (v2f)0;

        VertexPositionInputs positionInputs = GetVertexPositionInputs(v.positionOS.xyz);
        
        o.uv = v.uv;

        o.positionCS = positionInputs.positionCS;
        o.positionWS = positionInputs.positionWS;

        return o;
      }

      // ! -------------------------------------
      // ! 片元着色器
      real4 frag(v2f i) : SV_TARGET
      {
        // 材质一
        real4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
        color *= _MainColor;

        // 根据距离区分两个材质
        real dis = distance(i.positionWS, _Center);
        real stepDis = step(dis, _Threshold);
        color.a = lerp(0, 1, stepDis);
        clip(color.a - 0.5);

        // // 边沿高光
        // real edge = saturate(abs(dis - _Threshold));
        // edge = step(edge, _EdgeThreshold);
        // color = lerp(color, _EdgeColor, edge);

        return color;
      }

      ENDHLSL
    }
  }

  // ! -------------------------------------
  // ! 紫色报错fallback
  Fallback "Hidden/Universal Render Pipeline/FallbackError"
}
