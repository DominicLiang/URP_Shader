Shader "Custom/Normal/Lighting"
{
  Properties
  {
    // ! -------------------------------------
    // ! 面板属性
    [Enum(Off, 0, Front, 1, Back, 2)]_Cull ("CullMode", Float) = 2

    _BaseMap ("主贴图", 2D) = "white" { }
    _BaseColor ("主颜色", Color) = (1, 1, 1, 1)

    [Toggle(_ALPHATEST_ON)]_AlphaTest_On ("AlphaClipping", Float) = 0
    _Cutoff ("AlphaCutoff", Float) = 0.5
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
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

    // ! -------------------------------------
    // ! 全shader材质关键字
    #pragma shader_feature _ALPHATEST_ON  // * 所有pass通用 如果要alphatest 必须关键字 _ALPHATEST_ON
    #pragma multi_compile_instancing  // * 所有pass通用 GPU实例化支持
    // #pragma shader_feature _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A  // * 所有pass通用 将颜色贴图的A通道作为PBR的平滑值来使用

    #pragma multi_compile _ LIGHTMAP_ON
    #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
    
    CBUFFER_START(UnityPerMaterial)

      // ! -------------------------------------
      // ! 变量声明
      real4 _BaseMap_ST;
      real4 _BaseColor;

      real _Cutoff;

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
      Cull [_Cull]
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
      struct appdata { };

      struct Attributes
      {
        real2 uv : TEXCOORD0;
        real4 positionOS : POSITION;
        real3 normalOS : NORMAL;
        real4 tangentOS : TANGENT;
        real2 lightmapUV : TEXCOORD1;
      };

      // ! -------------------------------------
      // ! 顶点着色器输出 片元着色器输入
      struct v2f { };

      struct Varyings
      {
        real2 uv : TEXCOORD0;
        real4 positionCS : SV_POSITION;
        DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 1);
        real3 positionWS : TEXCOORD2;
        real3 normalWS : TEXCOORD3;
      };

      // ! -------------------------------------
      // ! 顶点着色器
      void vert(Attributes input, appdata v, out Varyings output, out v2f o)
      {
        output = (Varyings)0;
        
        VertexPositionInputs positionInput = GetVertexPositionInputs(input.positionOS.xyz);
        VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);

        output.positionCS = positionInput.positionCS;
        output.positionWS = positionInput.positionWS;
        output.normalWS = normalInput.normalWS;

        OUTPUT_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV);
        OUTPUT_SH(output.normalWS, output.vertexSH);
        
        output.uv = TRANSFORM_TEX(input.uv, _BaseMap);

        o = (v2f)0;
      }

      // ! -------------------------------------
      // ! 片元着色器
      real4 frag(Varyings input, v2f i) : SV_TARGET
      {
        real4 color = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);
        color *= _BaseColor;

        #ifdef _ALPHATEST_ON
          clip(color.a - _Cutoff);
        #endif

        // ! 计算烘焙GI信息
        // ! SAMPLE_GI的gi来源 1.球谐光照 2.光照贴图 3.光照探针
        real3 bakedGI = SAMPLE_GI(input.lightmapUV, input.vertexSH, input.normalWS);

        real4 shadowCoord = TransformWorldToShadowCoord(input.positionWS);

        Light light = GetMainLight(shadowCoord);
        real3 attLightColor = light.color * light.distanceAttenuation * light.shadowAttenuation;
        real3 diffuse = LightingLambert(attLightColor, light.direction, input.normalWS);

        real4 shading = real4(diffuse + bakedGI, 1);
        
        return color * shading;
      }

      ENDHLSL
    }

    pass
    {
      // ! 关键变量
      // ! 这里面已经包含_BaseMap的贴图定义 你不能使用这个变量名 但是你得有_BaseMap_ST这个变量
      // ! 你需要有_BaseColor这个变量
      // ! 如果你不是用_BaseColor可以用宏将_BaseColor隐射到你自己定义的变量上 如下
      // ! #define _BaseColor _MyColor
      
      // ! 使用URP自带的阴影顶点片元着色器 ShadowPassVertex ShadowPassFragment
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

      // ! 必须的include
      #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"

      // ! 阴影pass限定 更好的支持局部光照
      #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW

      #pragma vertex ShadowPassVertex
      #pragma fragment ShadowPassFragment

      ENDHLSL
    }

    // ! 支持深度引动模式 如果在urp设置中开启了深度引动模式 不写这个pass无法显示哦
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

      // ! 注意这里引用DepthOnlyPass.hlsl
      #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"

      // ! 使用顶点片元着色器也要写对
      #pragma vertex DepthOnlyVertex
      #pragma fragment DepthOnlyFragment

      ENDHLSL
    }

    // ! 支持MSAA
    pass
    {
      Name "DepthNormals"

      Tags
      {
        // ! LightMode一定要写对
        "LightMode" = "DepthNormals"
      }

      ZWrite On
      ZTest LEqual

      HLSLPROGRAM

      // ! 注意这里引用DepthNormalsPass.hlsl
      #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthNormalsPass.hlsl"

      // ! 写入到normalmap中
      #pragma shader_feature_local _NORMAL_MAP

      // ! 使用顶点片元着色器也要写对
      #pragma vertex DepthNormalsVertex
      #pragma fragment DepthNormalsFragment

      ENDHLSL
    }
  }

  // ! -------------------------------------
  // ! 紫色报错fallback
  Fallback "Hidden/Universal Render Pipeline/FallbackError"
}
