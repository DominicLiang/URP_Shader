Shader "Custom/StarRail/Face"
{
  Properties
  {
    // ! -------------------------------------
    // ! 面板属性
    _AlphaTestThreshold ("透明裁剪阈值", Range(0, 1)) = 0.005
    [NoScaleOffset]_ColorMap ("颜色贴图", 2D) = "white" { }
    [NoScaleOffset]_SDFMap ("SDF贴图", 2D) = "white" { }
    _ShadowColor ("阴影颜色", Color) = (0, 0, 0, 1)
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
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"


    TEXTURE2D(_ColorMap); SAMPLER(sampler_ColorMap);
    TEXTURE2D(_SDFMap); SAMPLER(sampler_SDFMap);

    CBUFFER_START(UnityPerMaterial)

      // ! -------------------------------------
      // ! 变量声明
      real4 _ShadowColor;
      real _OutlineWidth;
      real4 _OutlineColor;
      real _AlphaTestThreshold;

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

      Stencil
      {
        Ref 2
        Comp Always
        Pass Replace
        Fail Keep
      }

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
        real4 color : COLOR;
      };

      // ! -------------------------------------
      // ! 顶点着色器输出 片元着色器输入
      struct v2f
      {
        real2 uv : TEXCOORD0;
        real4 positionCS : SV_POSITION;
        real4 color : COLOR;
      };

      // ! -------------------------------------
      // ! 顶点着色器
      v2f vert(appdata v)
      {
        v2f o = (v2f)0;

        VertexPositionInputs positionInputs = GetVertexPositionInputs(v.positionOS.xyz);
        
        o.uv = v.uv;
        o.positionCS = positionInputs.positionCS;
        o.color = v.color;

        return o;
      }

      // ! -------------------------------------
      // ! 片元着色器
      real4 frag(v2f i) : SV_TARGET
      {
        // return i.color.a;


        Light mainLight = GetMainLight();
        real3 frontWS = mul(UNITY_MATRIX_M, real4(1, 0, 0, 0)).xyz;
        real3 rightWS = mul(UNITY_MATRIX_M, real4(0, 0, -1, 0)).xyz;
        real FdotL = dot(normalize(frontWS.xz), mainLight.direction.xz);
        real RdotL = dot(normalize(rightWS.xz), mainLight.direction.xz);

        bool isFaceLight = RdotL > 0;
        real2 sdfUV = lerp(i.uv, real2(1 - i.uv.x, i.uv.y), isFaceLight);
        
        real sdf = SAMPLE_TEXTURE2D(_SDFMap, sampler_SDFMap, sdfUV).a;

        real shadow = step(1 - sdf, FdotL * 0.5 + 0.5);
        real3 shadowColor = lerp(_ShadowColor.rgb, 1, shadow);

        real3 color = SAMPLE_TEXTURE2D(_ColorMap, sampler_ColorMap, i.uv).rgb;

        return real4(color * shadowColor, 1);
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
