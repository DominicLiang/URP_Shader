Shader "Custom/ZZZNPR/ZZZBody"
{
  Properties
  {
    // ! -------------------------------------
    // ! 面板属性
    [NoScaleOffset]_MainTex ("主贴图", 2D) = "white" { }
    [NoScaleOffset]_BumpMap ("法线贴图", 2D) = "bump" { }
    [NoScaleOffset]_LightMap ("光照贴图", 2D) = "white" { }

    _Mat1Threshold ("材质1阈值", Range(0, 1.05)) = 0.5
    _Mat2Threshold ("材质2阈值", Range(0, 1.05)) = 0.5
    _Mat3Threshold ("材质3阈值", Range(0, 1.05)) = 0.5
    _Mat4Threshold ("材质4阈值", Range(0, 1.05)) = 0.5

    _ShoeThreshold ("鞋子阈值", Range(0, 1)) = 0.5
    _ShoeSmooth ("鞋子过渡", Range(0, 1)) = 0
    _ShoeColor1 ("鞋子颜色1", Color) = (1, 1, 1, 1)
    _ShoeColor2 ("鞋子颜色2", Color) = (1, 1, 1, 1)

    _BlackThreshold ("衣服黑阈值", Range(0, 1)) = 0.5
    _BlackSmooth ("衣服黑过渡", Range(0, 1)) = 0
    _BlackColor1 ("衣服黑颜色1", Color) = (1, 1, 1, 1)
    _BlackColor2 ("衣服黑颜色2", Color) = (1, 1, 1, 1)

    _MetalThreshold ("金属阈值", Range(0, 1)) = 0.5
    _MetalSmooth ("金属过渡", Range(0, 1)) = 0
    _MetalColor1 ("金属颜色1", Color) = (1, 1, 1, 1)
    _MetalColor2 ("金属颜色2", Color) = (1, 1, 1, 1)

    _ClothThreshold ("衣服阈值", Range(0, 1)) = 0.5
    _ClothSmooth ("衣服过渡", Range(0, 1)) = 0
    _ClothColor1 ("衣服颜色1", Color) = (1, 1, 1, 1)
    _ClothColor2 ("衣服颜色2", Color) = (1, 1, 1, 1)

    _SkinThreshold ("皮肤阈值", Range(0, 1)) = 0.5
    _SkinSmooth ("皮肤过渡", Range(0, 1)) = 0
    _SkinColor1 ("皮肤颜色1", Color) = (1, 1, 1, 1)
    _SkinColor2 ("皮肤颜色2", Color) = (1, 1, 1, 1)

    _Metallic ("高光", Float) = 0.5
    _BThreshold ("高光阈值", Range(0, 1)) = 0.5
    _BSmooth ("高光过渡", Range(0, 1)) = 0
    _HightLightColor ("高光颜色", Color) = (1, 1, 1, 1)

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

    TEXTURE2D(_MainTex);
    SAMPLER(sampler_MainTex);
    TEXTURE2D(_BumpMap);
    SAMPLER(sampler_BumpMap);
    TEXTURE2D(_LightMap);
    SAMPLER(sampler_LightMap);

    CBUFFER_START(UnityPerMaterial)

      // ! -------------------------------------
      // ! 变量声明
      real _Mat1Threshold;
      real _Mat2Threshold;
      real _Mat3Threshold;
      real _Mat4Threshold;

      real _ShoeThreshold;
      real _ShoeSmooth;
      real4 _ShoeColor1;
      real4 _ShoeColor2;

      real _BlackThreshold;
      real _BlackSmooth;
      real4 _BlackColor1;
      real4 _BlackColor2;

      real _MetalThreshold;
      real _MetalSmooth;
      real4 _MetalColor1;
      real4 _MetalColor2;

      real _ClothThreshold;
      real _ClothSmooth;
      real4 _ClothColor1;
      real4 _ClothColor2;

      real _SkinThreshold;
      real _SkinSmooth;
      real4 _SkinColor1;
      real4 _SkinColor2;

      real _Metallic;
      real _Smoothness;

      real _BThreshold;
      real _BSmooth;
      real4 _HightLightColor;

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

      // ! -------------------------------------
      // ! 顶点着色器输入
      struct appdata
      {
        real2 uv : TEXCOORD0;
        real4 positionOS : POSITION;
        real3 normalOS : NORMAL;
        real4 tangentOS : TANGENT;
        real4 vertexColor : COLOR;
      };

      // ! -------------------------------------
      // ! 顶点着色器输出 片元着色器输入
      struct v2f
      {
        real2 uv : TEXCOORD0;
        real4 positionCS : SV_POSITION;
        real3 positionWS : TEXCOORD1;
        real3 normalWS : TEXCOORD2;
        real4 tangentWS : TEXCOORD3;
        real3 bitangentWS : TEXCOORD4;
        real4 vertexColor : TEXCOORD5;
      };

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
        o.normalWS = normalInputs.normalWS;
        o.tangentWS = real4(normalInputs.tangentWS, 1.0);
        o.bitangentWS = normalInputs.bitangentWS;
        o.vertexColor = v.vertexColor;

        return o;
      }

      real4 GetMatColor(real halfLambert, real threshold, real smooth, real4 color1, real4 color2, real mask)
      {
        real edge1 = threshold;
        real edge2 = saturate(threshold + smooth);
        real stepValue = smoothstep(edge1, edge2, halfLambert);
        return lerp(color2, color1, stepValue) * mask;
      }


      void InitializeInputData(v2f input, half3 normalTS, out InputData inputData)
      {
        inputData = (InputData)0;

        inputData.positionWS = input.positionWS;
        half3 viewDirWS = GetWorldSpaceNormalizeViewDir(input.positionWS);
        float sgn = input.tangentWS.w;      // should be either +1 or -1
        float3 bitangent = sgn * cross(input.normalWS.xyz, input.tangentWS.xyz);
        half3x3 tangentToWorld = half3x3(input.tangentWS.xyz, bitangent.xyz, input.normalWS.xyz);
        inputData.tangentToWorld = tangentToWorld;
        inputData.normalWS = TransformTangentToWorld(normalTS, tangentToWorld);

        inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
        inputData.viewDirectionWS = viewDirWS;

        inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);

        inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
      }

      // ! -------------------------------------
      // ! 片元着色器
      real4 frag(v2f i) : SV_TARGET
      {
        real4 mainTexColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
        real4 bumpMapColor = SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, i.uv);
        real4 lightMapColor = SAMPLE_TEXTURE2D(_LightMap, sampler_LightMap, i.uv);

        real3x3 TBN = real3x3(i.tangentWS.xyz, i.bitangentWS, i.normalWS);
        real3 normalTS = UnpackNormal(bumpMapColor);
        Light mainLight = GetMainLight();

        real3 N = normalize(TransformTangentToWorld(normalTS, TBN));
        real3 L = normalize(mainLight.direction);
        real3 V = normalize(GetWorldSpaceViewDir(i.positionWS));
        real3 H = normalize(L + V);

        real NdotL = dot(N, L); // 兰伯特
        real NdotV = dot(N, V); // 菲尼尔
        real NdotH = dot(N, H); // 布林冯

        real orgHalfLambert = dot(i.normalWS, L) * 0.5 + 0.5;
        real halfLambert = NdotL * 0.5 + 0.5;


        // 鞋子
        real m1 = 1 - step(_Mat1Threshold, lightMapColor.r);

        // 衣服黑
        real m2 = 1 - step(_Mat2Threshold, lightMapColor.r) - m1;

        // 金属
        real m3 = 1 - step(_Mat3Threshold, lightMapColor.r) - m1 - m2;

        // 衣服黄
        real m4 = 1 - step(_Mat4Threshold, lightMapColor.r) - m1 - m2 - m3;

        // 皮肤
        real m5 = saturate(1 - m1 - m2 - m3 - m4);

        real4 shoeShadow = GetMatColor(halfLambert, _ShoeThreshold, _ShoeSmooth, _ShoeColor1, _ShoeColor2, m1);
        real4 clothBlackShadow = GetMatColor(orgHalfLambert, _BlackThreshold, _BlackSmooth, _BlackColor1, _BlackColor2, m2);
        real4 metalShadow = GetMatColor(halfLambert, _MetalThreshold, _MetalSmooth, _MetalColor1, _MetalColor2, m3);
        real4 clothYellowShadow = GetMatColor(halfLambert, _ClothThreshold, _ClothSmooth, _ClothColor1, _ClothColor2, m4);
        real4 skinShadow = GetMatColor(orgHalfLambert, _SkinThreshold, _SkinSmooth, _SkinColor1, _SkinColor2, m5);

        real4 shadowColor = shoeShadow + clothBlackShadow + metalShadow + clothYellowShadow + skinShadow;

        real4 metalMask = lightMapColor.g;

        
        real4 finalColor = mainTexColor * shadowColor;
        
        real highLight = pow(max(NdotH, 0.01), _Metallic) * m2;
        highLight = smoothstep(_BThreshold, saturate(_BThreshold + _BSmooth), highLight);
        real4 highColor = highLight * _HightLightColor;


        InputData inputData = (InputData)0;
        InitializeInputData(i, normalTS, inputData);
        SurfaceData surfaceData = (SurfaceData)0;
        surfaceData.albedo = mainTexColor;
        surfaceData.specular = half3(0.0, 0.0, 0.0);
        surfaceData.metallic = 0.5;
        surfaceData.normalTS = normalTS;
        surfaceData.smoothness = 0.7;

        
        real4 pbrColor = UniversalFragmentPBR(inputData, surfaceData);


        finalColor = lerp(finalColor, pbrColor, metalMask * 2) + highColor;


        
        return finalColor;
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

        real3 offset = _OutlineWidth * 0.0001 * v.normalOS.xyz * dist;

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

    pass
    {
      Name "ShadowCaster"
      Tags
      {
        "LightMode" = "ShadowCaster"
      }

      ColorMask 0
      Cull Off
      ZWrite On
      ZTest LEqual

      HLSLPROGRAM

      // #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
      // #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
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
