Shader "Hidden/HairShadow"
{
  Properties
  {
    // ! -------------------------------------
    // ! 面板属性

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
      real _Offset;
      real4 _ShadowColor;

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
      ZWrite Off
      Blend DstColor Zero

      Stencil
      {
        Ref 10
        Comp Equal
        Pass Zero
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
      };

      // ! -------------------------------------
      // ! 顶点着色器
      v2f vert(appdata v)
      {
        v2f o = (v2f)0;

        VertexPositionInputs positionInputs = GetVertexPositionInputs(v.positionOS.xyz);
        o.uv = v.uv;
        o.positionCS = positionInputs.positionCS;

        Light light = GetMainLight();
        real3 viewDir = normalize(GetWorldSpaceViewDir(positionInputs.positionWS));
        real3 dir = normalize(lerp(viewDir, light.direction, 0.5));
        real2 lightOffset = normalize(dir).xz;
        lightOffset.x *= -1;
        lightOffset.y *= _ProjectionParams.x;
        o.positionCS.xy += lightOffset * _Offset;

        return o;
      }

      // ! -------------------------------------
      // ! 片元着色器
      real4 frag(v2f i) : SV_TARGET
      {
        return _ShadowColor;
      }

      ENDHLSL
    }
  }

  Fallback Off
}
