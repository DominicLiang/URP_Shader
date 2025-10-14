Shader "Custom/ZZZNPR/ZZZFace"
{
  Properties
  {
    // ! -------------------------------------
    // ! 面板属性
    [NoScaleOffset]_MainTex ("主贴图", 2D) = "white" { }

    [NoScaleOffset]_SdfMap ("SDF贴图", 2D) = "white" { }
    _ShadowColor ("阴影颜色", Color) = (0, 0, 0, 1)

    _OutlineWidth ("描边宽度", Float) = 1
    _OutlineColor ("描边颜色", Color) = (0, 0, 0, 1)

    _FaceSmooth ("阴影平滑", Range(0, 1)) = 0.5
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
    #include "Assets/ShaderLibrary/Utility/Node.hlsl"

    TEXTURE2D(_MainTex);
    SAMPLER(sampler_MainTex);
    TEXTURE2D(_SdfMap);
    SAMPLER(sampler_SdfMap);

    CBUFFER_START(UnityPerMaterial)

      // ! -------------------------------------
      // ! 变量声明
      real4 _OutlineColor;
      real _OutlineWidth;

      real4 _ShadowColor;

      real _FaceSmooth;


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

        real4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);

        

        Light mainLight = GetMainLight();
        real3 frontWS = mul(UNITY_MATRIX_M, real4(1, 0, 0, 0)).xyz;
        real3 rightWS = mul(UNITY_MATRIX_M, real4(0, 0, -1, 0)).xyz;
        real FdotL = dot(normalize(frontWS.xz), normalize(mainLight.direction.xz));
        real RdotL = dot(normalize(rightWS.xz), normalize(mainLight.direction.xz));

        bool isRight = RdotL > 0;
        real2 uv = lerp(i.uv, real2(-i.uv.x, i.uv.y), isRight);

        real4 sdfColor = SAMPLE_TEXTURE2D(_SdfMap, sampler_SdfMap, uv);
        real sdf = sdfColor.r;
        real alwayHighLight = sdfColor.b;
        real alwayShadow = sdfColor.a;

        // return sdf;
        sdf = 1 - sdf;

        // return sdf;
        real FdotL01 = FdotL * 0.5 + 0.5;

        real shadow = smoothstep(saturate(sdf - _FaceSmooth), sdf, FdotL01);
        shadow += alwayHighLight;
        shadow *= alwayShadow;

        real4 shadowColor = lerp(_ShadowColor, 1, shadow);



        color *= shadowColor;

        
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
        float3 positionOS : POSITION;

        float3 normalOS : NORMAL;
        float4 tangentOS : TANGENT;
        float4 color : COLOR;
        float2 uv1 : TEXCOORD0;
        float2 uv2 : TEXCOORD1;
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

        real3 dist = distance(mul(UNITY_MATRIX_M, real4(v.positionOS, 1)), _WorldSpaceCameraPos);
        dist = lerp(1, dist, 0.5);

        real3 offset = _OutlineWidth * 0.0001 * v.normalOS.xyz * dist * v.color.r;

        v.positionOS.xyz += offset;

        VertexPositionInputs vertexInputs = GetVertexPositionInputs(v.positionOS);

        o.positionCS = vertexInputs.positionCS;

        return o;
      }

      // ! -------------------------------------
      // ! 片元着色器
      real4 frag(v2f i) : SV_TARGET
      {
        return _OutlineColor;
      }

      ENDHLSL
    }
  }

  // ! -------------------------------------
  // ! 紫色报错fallback
  Fallback "Hidden/Universal Render Pipeline/FallbackError"
}
