Shader "Custom/Normal/SSR"
{
  Properties
  {
    // ! -------------------------------------
    // ! 面板属性
    _SSRSampleStep ("SSR步进步数", Float) = 12
    _SSRMaxSampleCount ("SSR最大步进数", Float) = 64
    _SSRMaxSampleDistance ("SSR最大步进距离", Range(0, 1000)) = 1000

    _FresnelPower ("菲尼尔强度", Float) = 1
    _CenterFocus ("中心焦点强度", Float) = 1
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
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
    #include "Assets/ShaderLibrary/Utility/Node.hlsl"

    TEXTURE2D(_MainTex);
    SAMPLER(sampler_MainTex);
    TEXTURE2D(_CameraDepthTexture);
    SAMPLER(sampler_CameraDepthTexture);
    TEXTURE2D(_CameraOpaqueTexture);
    SAMPLER(sampler_CameraOpaqueTexture);

    CBUFFER_START(UnityPerMaterial)
      // ! -------------------------------------
      // ! 变量声明
      real _SSRSampleStep;
      real _SSRMaxSampleCount;
      real _SSRMaxSampleDistance;
      real _FresnelPower;
      real _CenterFocus;

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
      Blend SrcAlpha OneMinusSrcAlpha

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
        real4 color : COLOR;
      };

      // ! -------------------------------------
      // ! 顶点着色器输出 片元着色器输入
      struct v2f
      {
        real2 uv : TEXCOORD0;
        real4 positionCS : SV_POSITION;
        real3 positionWS : TEXCOORD1;
        real3 normalWS : TEXCOORD2;
        real3 tangentWS : TEXCOORD3;
        real3 bitangentWS : TEXCOORD4;
        real4 color : COLOR;
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
        o.tangentWS = normalInputs.tangentWS;
        o.bitangentWS = normalInputs.bitangentWS;
        o.color = v.color;

        return o;
      }

      void MySSRRayConvert(float3 posWS, out float4 posCS, out float3 screenPos)
      {
        posCS = TransformWorldToHClip(posWS);
        // screenPos.xy = ComputeScreenPos(posCS).xy / posCS.w;
        float4 screenPosOrg = posCS * 0.5f;
        screenPosOrg.xy = float2(screenPosOrg.x, screenPosOrg.y * _ProjectionParams.x) + screenPosOrg.w;
        screenPos.xy = screenPosOrg.xy / posCS.w;
        screenPos.z = posCS.w;
      }

      real3 MySSRRayMarch(Texture2D depthTexture, SamplerState samplerDepthTexture, real3 positionWS, real3 normalWS, real3 viewWS, real step, real maxCount)
      {
        real3 R = reflect(-viewWS, normalWS);

        real4 startPosCS;
        real3 startScreenPos;
        MySSRRayConvert(positionWS, startPosCS, startScreenPos);

        real4 endPosCS;
        real3 endScreenPos;
        MySSRRayConvert(positionWS + R, endPosCS, endScreenPos);

        real3 ray = endScreenPos - startScreenPos;
        real3 rayStep = _SSRMaxSampleDistance / _SSRMaxSampleCount;

        real3 lastScreenPos;

        real3 randomValue = RandomFromUV(startPosCS) * 0.1;

        UNITY_LOOP
        for (int ii = 0; ii < _SSRMaxSampleCount; ii++)
        {
          real3 curScreenPos = startScreenPos + (ii + randomValue) * rayStep * ray;

          if (curScreenPos.x < 0 || curScreenPos.x > 1 || curScreenPos.y < 0 || curScreenPos.y > 1) break;

          real depth = SAMPLE_DEPTH_TEXTURE(depthTexture, samplerDepthTexture, curScreenPos.xy);
          real eyeDepth = LinearEyeDepth(depth, _ZBufferParams);

          if (eyeDepth < curScreenPos.z)
          {
            real samplePercent = (curScreenPos.z - eyeDepth) / (curScreenPos.z - lastScreenPos.z);
            real3 samplePos = lerp(lastScreenPos, curScreenPos, samplePercent);
            return curScreenPos;
          }

          lastScreenPos = curScreenPos;
        }

        return real3(0, 0, 0);
      }

      // ! -------------------------------------
      // ! 片元着色器
      real4 frag(v2f i) : SV_TARGET
      {
        real3 N = normalize(i.normalWS);
        real3 V = normalize(GetCameraPositionWS() - i.positionWS);
        real3 NdotV = dot(N, V);
        
        real3 R = normalize(reflect(-V, N));
        real3 ssrUVZ = SSRRayMarch(_CameraDepthTexture, sampler_CameraDepthTexture, i.positionWS, N, V, _SSRSampleStep, _SSRMaxSampleCount);

        real4 ssrColor = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, ssrUVZ.xy);

        // real weight = 1;
        // weight *= saturate(1 - pow(max(0.01, NdotV), _FresnelPower));
        // real2 screenUV = i.positionCS.xy / GetScaledScreenParams().xy;
        // real center = 1 - saturate(length(screenUV - 0.5) + _CenterFocus);
        // center = smoothstep(0, 0.5, center);
        // weight *= center;

        // ssrColor = lerp(0, ssrColor, weight);
        // ssrColor.a = 1;
        

        return ssrColor;
      }
      ENDHLSL
    }
  }

  // ! -------------------------------------
  // ! 紫色报错fallback
  Fallback "Hidden/Universal Render Pipeline/FallbackError"
}