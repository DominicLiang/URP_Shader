Shader "Custom/StarRail/BodyMatcap"
{
  Properties
  {
    // ! -------------------------------------
    // ! 面板属性
    [NoScaleOffset]_ColorMap ("颜色贴图", 2D) = "white" { }
    [NoScaleOffset]_MaskMap ("MatcapMask", 2D) = "white" { }
    [NoScaleOffset]_MatcapMap1 ("Matcap贴图1", 2D) = "white" { }
    [NoScaleOffset]_MatcapMap2 ("Matcap贴图2", 2D) = "white" { }
    _OutlineWidth ("描边宽度", Float) = 1
    _OutlineColor ("描边颜色", Color) = (0, 0, 0, 1)
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
    #include "Assets/ShaderLibrary/Utility/Node.hlsl"
    #include "Assets/ShaderLibrary/Utility/NodeFromShaderGraph.hlsl"

    TEXTURE2D(_ColorMap); SAMPLER(sampler_ColorMap);
    TEXTURE2D(_MaskMap); SAMPLER(sampler_MaskMap);
    TEXTURE2D(_MatcapMap1); SAMPLER(sampler_MatcapMap1);
    TEXTURE2D(_MatcapMap2); SAMPLER(sampler_MatcapMap2);

    CBUFFER_START(UnityPerMaterial)

      // ! -------------------------------------
      // ! 变量声明
      real _OutlineWidth;
      real4 _OutlineColor;

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
      // #pragma multi_compile _MAIN_LIGHT_SHADOWS

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
        real2 matcapUV : TEXCOORD1;
      };

      // half2 MatCapUV(half3 positionVS, half3 normalOS)
      // {
      //   float3 posVS = normalize(positionVS);
      //   float3 normalVS = mul(UNITY_MATRIX_IT_MV, normalOS);
      //   float3 vcn = cross(posVS, normalVS);
      //   float2 uv = float2(-vcn.y, vcn.x);
      //   uv = uv * 0.5 + 0.5;
      //   return uv;
      // }

      // ! -------------------------------------
      // ! 顶点着色器
      v2f vert(appdata v)
      {
        v2f o = (v2f)0;

        VertexPositionInputs positionInputs = GetVertexPositionInputs(v.positionOS.xyz);
        
        o.uv = v.uv;
        o.positionCS = positionInputs.positionCS;
        o.matcapUV = MatCapUV(positionInputs.positionVS, v.normalOS);

        return o;
      }

      // ! -------------------------------------
      // ! 片元着色器
      real4 frag(v2f i) : SV_TARGET
      {
        real4 color = SAMPLE_TEXTURE2D(_ColorMap, sampler_ColorMap, i.uv);
        real4 mask = SAMPLE_TEXTURE2D(_MaskMap, sampler_MaskMap, i.uv);

        real4 matcap1 = SAMPLE_TEXTURE2D(_MatcapMap1, sampler_MatcapMap1, i.matcapUV);
        real4 matcap2 = SAMPLE_TEXTURE2D(_MatcapMap2, sampler_MatcapMap2, i.matcapUV);

        if (mask.r > 0.8)
        {
          // 手
          color = lerp(color, matcap1, mask.r);
        }
        else
        {
          // 鞋子
          color = lerp(color, matcap2, mask.r);
        }


        return color;
      }

      ENDHLSL
    }

    Pass
    {
      // ! -------------------------------------
      // ! Pass名
      Name "OutlinePass"

      // ! -------------------------------------
      // ! tags
      Tags
      {
        "LightMode" = "Outline"
      }

      // ! -------------------------------------
      // ! 渲染状态
      Cull Front
      ZTest LEqual
      ZWrite On

      HLSLPROGRAM

      // ! -------------------------------------
      // ! pass include
      #include "Outline.hlsl"

      // ! -------------------------------------
      // ! Shader阶段
      #pragma vertex vert
      #pragma fragment frag

      

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
      Cull [_Cull]
      ZWrite On
      ZTest LEqual

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

  // ! -------------------------------------
  // ! 紫色报错fallback
  Fallback "Hidden/Universal Render Pipeline/FallbackError"
}
