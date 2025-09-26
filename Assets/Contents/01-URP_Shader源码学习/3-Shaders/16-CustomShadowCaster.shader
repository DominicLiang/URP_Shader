Shader "Custom/Normal/CustomShadowCaster"
{
  Properties
  {
    // ! -------------------------------------
    // ! 面板属性
    [NoScaleOffset]_MainTex ("主贴图", 2D) = "white" { }
    [HDR]_MainColor ("主颜色", Color) = (1, 1, 1, 1)
    _ShadowAlpha ("阴影透明度", Range(0, 2)) = 2
    selfShadowDepthBias ("depthBias", Float) = 0
    selfShadowNormalBias ("NormalBias", Float) = 0
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

    TEXTURE2D(_MainTex);
    SAMPLER(sampler_MainTex);

    CBUFFER_START(UnityPerMaterial)

      // ! -------------------------------------
      // ! 变量声明
      real4 _MainColor;
      real _ShadowAlpha;
      real selfShadowDepthBias;
      real selfShadowNormalBias;
      float4 _BaseMap_ST;

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

        return o;
      }

      // ! -------------------------------------
      // ! 片元着色器
      real4 frag(v2f i) : SV_TARGET
      {
        real4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
        color *= _MainColor;
        
        return color;
      }

      ENDHLSL
    }

    Pass
    {
      Tags
      {
        "LightMode" = "ShadowCaster"
      }

      Cull Off
      ZWrite On
      ZTest LEqual
      ColorMask 0     // 不输出Color

      HLSLPROGRAM

      // 设置关键字
      #pragma shader_feature _ALPHATEST_ON

      #pragma vertex vert
      #pragma fragment frag

      #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
      #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
      #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
      #include "Assets/ShaderLibrary/Utility/Node.hlsl"


      float3 _LightDirection;



      TEXTURE2D(_BaseMap);
      SAMPLER(sampler_BaseMap);
      //TecrayC的变量
      //float _Grow;
      //float _GrowMin;
      //float _GrowMax;
      //float _EndMin;
      //float _EndMax;
      //float _ExpandScale;

      struct a2v
      {
        float4 vertex : POSITION;
        float3 normal : NORMAL;
        float2 texcoord : TEXCOORD0;
      };

      struct v2f
      {
        float2 uv : TEXCOORD0;
        float4 pos : SV_POSITION;
      };


      float3 ApplySelfShadowBias(float3 positionWS, float3 normalWS, float3 lightDirection, float2 selfShadowBias)
      {
        float invNdotL = 1.0 - saturate(dot(lightDirection, normalWS));
        float scale = invNdotL * selfShadowBias.y;

        // normal bias is negative since we want to apply an inset normal offset
        positionWS = lightDirection * selfShadowBias.xxx + positionWS;
        positionWS = normalWS * scale.xxx + positionWS;
        return positionWS;
      }
      

      // 获取裁剪空间下的阴影坐标
      float4 GetShadowPositionHClips(a2v v)
      {
        float4 vertex_OS = v.vertex;
        //-------TecrayC:顶点缩放部分----需要和主pass一样-----
        // 权重：前端缩放
        // float grow = 1.0 - (v.texcoord.y - _Grow);
        // float weight = 1.0 - Smootherstep(_GrowMin,_GrowMax, grow);
        // float endWeight = Smootherstep(_EndMin,_EndMax,v.texcoord.y);
        // weight = max(weight, endWeight);
        // // 顶点缩放
        // float3 finalOffset = v.normal * _ExpandScale * weight * 0.1;
        // vertex_OS.xyz = vertex_OS + finalOffset;
        //----TecrayC:顶点缩放完成-------------------------------------

        //阴影
        float3 positionWS = TransformObjectToWorld(vertex_OS.xyz);
        float3 normalWS = TransformObjectToWorldNormal(v.normal);
        // 获取阴影专用裁剪空间下的坐标
        // float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, _LightDirection));
        float2 selfShadowBias = float2(selfShadowDepthBias, selfShadowNormalBias);
        float4 positionCS = TransformWorldToHClip(ApplySelfShadowBias(positionWS, normalWS, _LightDirection, selfShadowBias));

        // 判断是否是在DirectX平台翻转过坐标
        #if UNITY_REVERSED_Z
          positionCS.z = min(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
        #else
          positionCS.z = max(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
        #endif

        return positionCS;
      }

      v2f vert(a2v v)
      {
        v2f o;
        o.uv = TRANSFORM_TEX(v.texcoord, _BaseMap);
        o.pos = GetShadowPositionHClips(v);
        return o;
      }


      half4 frag(v2f i) : SV_TARGET
      {
        // Alpha(SampleAlbedoAlpha(i.uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap)).a, _BaseColor, _Cutoff);
        // half4 texColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv);

        //--------TecrayC:clip()内容和上边Pass一致-----------
        // float grow = 1.0 - (i.uv.y - _Grow);
        // clip(grow);
        //--------TecrayC:clip完成-----------------------------

        real dither;
        Unity_Dither_float(_ShadowAlpha, i.pos / GetScaledScreenParams(), dither);
        clip(dither - 0.5);

        return 0;
      }
      ENDHLSL
    }
  }

  // ! -------------------------------------
  // ! 紫色报错fallback
  Fallback "Hidden/Universal Render Pipeline/FallbackError"
}
