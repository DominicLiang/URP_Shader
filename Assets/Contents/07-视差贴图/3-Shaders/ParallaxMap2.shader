Shader "Custom/Normal/ParallaxMap2"
{
  Properties
  {
    // ! -------------------------------------
    // ! 面板属性
    [NoScaleOffset]_MainTex ("主贴图", 2D) = "white" { }
    [NoScaleOffset]_HeightTex ("高度贴图", 2D) = "white" { }

    _NumLayers ("_NumLayers", Range(1, 50)) = 10
    _ParallaxScale ("_ParallaxScale", Range(0, 5)) = 1
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

    CBUFFER_START(UnityPerMaterial)

      // ! -------------------------------------
      // ! 变量声明
      TEXTURE2D(_MainTex);
      SAMPLER(sampler_MainTex);
      TEXTURE2D(_HeightTex);
      SAMPLER(sampler_HeightTex);
      int _NumLayers;
      float _ParallaxScale;

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
        real3 normalWS : TEXCOORD2;
        real3 viewDirTS : TEXCOORD3;
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

        real3x3 TBN = real3x3(
          normalize(normalInputs.tangentWS),
          normalize(normalInputs.bitangentWS),
          normalize(normalInputs.normalWS)
        );

        real3 cameraPositionTS = mul(TBN, float4(GetCameraPositionWS(), 1)).xyz;
        real3 positionTS = mul(TBN, float4(positionInputs.positionWS, 1)).xyz;
        real3 viewDirTS = normalize(cameraPositionTS - positionTS);
        o.viewDirTS = viewDirTS;

        return o;
      }

      // half GetParallaxHeight(float2 uv)
      // {
      //   float4 color = SAMPLE_TEXTURE2D(_HeightTex, sampler_HeightTex, uv);
      //   return saturate(color.r);
      // }

      // half2 ParallaxOcclusionMapping(real3 viewDirTS, real2 uv, int numLayers, real parallaxScale)
      // {
      //   // 切线空间视方向
      //   real3 viewDir = normalize(viewDirTS);

      //   // 层的高度值(初始数最大值)
      //   half currentLayerHeight = 1.0;
      //   // 单层歩进的高度
      //   half layerStep = currentLayerHeight / numLayers;
      
      //   // uv最大偏移值
      //   half2 maxOffset = viewDir.xy / viewDir.z * parallaxScale;
      //   // 单步uv偏移值
      //   half2 offsetStep = maxOffset / numLayers;

      //   // 初始化
      //   half2 currentUV = uv + maxOffset;
      //   half2 finalOffset = uv;
      //   half mapHeight = GetParallaxHeight(currentUV); // ? GetParallaxHeight 采样高度贴图?
      
      //   // 开始一步步逼近 直到找到步进点比高度图低(看不到)
      //   UNITY_LOOP
      //   for (int i = 0; i < numLayers; i++)
      //   {
      //     if (currentLayerHeight <= mapHeight)
      //     {
      //       break;
      //     }
      //     currentUV -= offsetStep;
      //     mapHeight = GetParallaxHeight(currentUV);
      //     currentLayerHeight -= layerStep;
      //   }

      //   // 计算 h1 和 h2
      //   half2 uvPrev = currentUV + offsetStep;
      //   half prevMapHeight = GetParallaxHeight(uvPrev);
      //   half prevLayerHeight = currentLayerHeight + layerStep;
      //   half beforeHeight = prevLayerHeight - prevMapHeight; // h1
      //   half afterHeight = mapHeight - currentLayerHeight; // h2

      //   // 利用h1和h2得到权重,在两个红点间使用权重进行插值
      //   half weight = afterHeight / (afterHeight + beforeHeight);
      //   finalOffset = lerp(uvPrev, currentUV, weight);
      //   finalOffset -= uv;

      //   return finalOffset;
      // }

      // ! -------------------------------------
      // ! 片元着色器
      real4 frag(v2f i) : SV_TARGET
      {
        real2 offset = ParallaxOcclusionMapping(_HeightTex, sampler_HeightTex, i.viewDirTS, i.uv, _NumLayers, _ParallaxScale);
        real2 parallaxUV = i.uv + offset;

        real3 N = normalize(i.normalWS);
        real3 V = normalize(GetCameraPositionWS() - i.positionWS);
        real NdotV = dot(N, V);
        real fresnel = pow(1 - saturate(NdotV), 1);
        fresnel = smoothstep(0.7, 1, fresnel);

        parallaxUV = lerp(parallaxUV, i.uv, fresnel);

        real4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, parallaxUV);

        return color;
      }

      ENDHLSL
    }
  }

  // ! -------------------------------------
  // ! 紫色报错fallback
  Fallback "Hidden/Universal Render Pipeline/FallbackError"
}


// float3 ParallaxOcclusionMapping_ViewDir = IN.TangentSpaceViewDirection * GetDisplacementObjectScale().xzy;
// float ParallaxOcclusionMapping_NdotV = ParallaxOcclusionMapping_ViewDir.z;
// float ParallaxOcclusionMapping_MaxHeight = Amplitude * 0.01;
// ParallaxOcclusionMapping_MaxHeight *= 2.0 / (abs(Tiling.x) + abs(Tiling.y));

// float2 ParallaxOcclusionMapping_UVSpaceScale = ParallaxOcclusionMapping_MaxHeight * Tiling / PrimitiveSize;

// // Transform the view vector into the UV space.
// float3 ParallaxOcclusionMapping_ViewDirUV = normalize(float3(ParallaxOcclusionMapping_ViewDir.xy * ParallaxOcclusionMapping_UVSpaceScale, ParallaxOcclusionMapping_ViewDir.z)); // TODO: skip normalize

// PerPixelHeightDisplacementParam ParallaxOcclusionMapping_POM;
// ParallaxOcclusionMapping_POM.uv = UVs.xy;

// float ParallaxOcclusionMapping_OutHeight;
// float2 _ParallaxOcclusionMapping_ParallaxUVs = UVs.xy + ParallaxOcclusionMapping(Lod, Lod_Threshold, Steps, ParallaxOcclusionMapping_ViewDirUV, ParallaxOcclusionMapping_POM, ParallaxOcclusionMapping_OutHeight);

// float _ParallaxOcclusionMapping_PixelDepthOffset = (ParallaxOcclusionMapping_MaxHeight - ParallaxOcclusionMapping_OutHeight * ParallaxOcclusionMapping_MaxHeight) / max(ParallaxOcclusionMapping_NdotV, 0.0001);