Shader "Custom/10-Shield/Shield"
{
  Properties
  {
    [HDR]_MainColor ("主颜色", Color) = (1, 1, 1, 1)
    _FresnelPower ("菲尼尔系数", Range(0.001, 10)) = 1
    [HDR]_EdgeColor ("边缘颜色", Color) = (1, 1, 1, 1)
    _EdgeAlpha ("边缘透明度", Range(0, 1)) = 1
    _SoftRange ("边缘范围", Range(0.01, 1)) = 0.2
    _Noise ("扭曲贴图", 2D) = "white" { }
    _NoiseIntensity ("扭曲强度", Range(0, 2)) = 1
    _NoiseRange ("扭曲范围", Range(0.01, 1)) = 0.2

    _Threshold ("_Threshold", Float) = 0
    _Edge1 ("_Edge1", Float) = 0
    _Edge2 ("_Edge2", Float) = 1
  }
  SubShader
  {
    LOD 200

    Tags
    {
      "Queue" = "Transparent"
      "RenderPipeline" = "UniversalPipeline"
    }

    HLSLINCLUDE

    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

    CBUFFER_START(UnityPerMaterial)

      real4 _MainColor;
      real4 _EdgeColor;
      real _FresnelPower;

      TEXTURE2D(_CameraDepthTexture);
      SAMPLER(sampler_CameraDepthTexture);

      TEXTURE2D(_CameraOpaqueTexture);
      SAMPLER(sampler_CameraOpaqueTexture);

      TEXTURE2D(_Noise);
      SAMPLER(sampler_Noise);
      real4 _Noise_ST;
      real _NoiseIntensity;
      real _NoiseRange;

      real _SoftRange;
      real _EdgeAlpha;

      real3 _HitCenter;
      real _EdgeAlpha2;
      real _Threshold;
      real _Edge1;
      real _Edge2;

    CBUFFER_END

    ENDHLSL

    Pass
    {
      Name "BasePass"

      Tags
      {
        "LightMode" = "UniversalForward"
      }

      Cull Back
      ZTest LEqual
      ZWrite Off

      HLSLPROGRAM

      #pragma vertex vert
      #pragma fragment frag

      struct appdata
      {
        real2 uv : TEXCOORD0;
        real4 positionOS : POSITION;
        real3 normalOS : NORMAL;
      };

      struct v2f
      {
        real2 uv : TEXCOORD0;
        real4 positionCS : SV_POSITION;
        real3 positionWS : TEXCOORD1;
        real3 normalWS : TEXCOORD2;
      };

      v2f vert(appdata v)
      {
        v2f o = (v2f)0;

        VertexPositionInputs positionInputs = GetVertexPositionInputs(v.positionOS.xyz);
        VertexNormalInputs normalInputs = GetVertexNormalInputs(v.normalOS);
        
        o.uv = TRANSFORM_TEX(v.uv, _Noise);

        o.positionCS = positionInputs.positionCS;
        o.positionWS = positionInputs.positionWS;
        o.normalWS = normalInputs.normalWS;

        return o;
      }

      real4 frag(v2f i, real facing : VFACE) : SV_TARGET
      {
        real3 N = normalize(lerp(-i.normalWS, i.normalWS, saturate(facing)));
        real3 V = normalize(GetCameraPositionWS() - i.positionWS);
        real NoV = saturate(dot(N, V));
        real fresnel = 1 - saturate(pow(NoV, _FresnelPower));

        real4 screenPosition = i.positionCS / GetScaledScreenParams();
        // ! 深度图的深度 近大远小 非线性
        real depth = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, screenPosition.xy).r;
        // ! 视图空间线性深度 远大近小
        // * eyeDepth 本物体后面的物体的深度
        real eyeDepth = LinearEyeDepth(depth, _ZBufferParams);
        // ! 深度差 screenPosition.w 也是视图空间的线性深度 同样远大近小
        // ! 所以用减来计算深度差
        // * screenPosition.w 本物体的深度
        real depthDiff = saturate(eyeDepth - screenPosition.w);
        real edge = 1 - smoothstep(0, _SoftRange, depthDiff);
        edge *= _EdgeAlpha;
        real edge2 = 1 - smoothstep(0, _NoiseRange, depthDiff);
        edge2 *= _EdgeAlpha;

        real2 noiseUV = i.uv;
        noiseUV.x += _Time.y;
        real noise = SAMPLE_TEXTURE2D(_Noise, sampler_Noise, noiseUV).r;
        // noise -= 0.5;
        noise *= _NoiseIntensity;
        noise *= edge2;
        real2 opaqueUV = screenPosition.xy;
        opaqueUV += noise;

        real4 finalColor = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, opaqueUV);
        finalColor += _MainColor * fresnel;
        finalColor += _EdgeColor * edge;

        real dist = distance(i.positionWS, _HitCenter);
        real edge3 = saturate(abs(dist - _Threshold));
        edge3 = smoothstep(_Edge1, _Edge2, edge3);
        edge3 = 1 - (saturate(edge3));
        real4 eColor = edge3 * _EdgeColor * 0.5 * _EdgeAlpha2;

        finalColor += eColor;


        
        return finalColor;
      }

      ENDHLSL
    }

    Pass
    {
      Name "BasePass"

      Tags
      {
        "LightMode" = "BackEdge"
      }

      Cull Front
      ZTest LEqual
      ZWrite Off
      Blend SrcAlpha OneMinusSrcAlpha

      HLSLPROGRAM

      #pragma vertex vert
      #pragma fragment frag

      struct appdata
      {
        real2 uv : TEXCOORD0;
        real4 positionOS : POSITION;
        real3 normalOS : NORMAL;
      };

      struct v2f
      {
        real2 uv : TEXCOORD0;
        real4 positionCS : SV_POSITION;
        real3 positionWS : TEXCOORD1;
        real3 normalWS : TEXCOORD2;
      };

      v2f vert(appdata v)
      {
        v2f o = (v2f)0;

        VertexPositionInputs positionInputs = GetVertexPositionInputs(v.positionOS.xyz);
        VertexNormalInputs normalInputs = GetVertexNormalInputs(v.normalOS);
        
        o.uv = TRANSFORM_TEX(v.uv, _Noise);

        o.positionCS = positionInputs.positionCS;
        o.positionWS = positionInputs.positionWS;
        o.normalWS = normalInputs.normalWS;

        return o;
      }

      real4 frag(v2f i, real facing : VFACE) : SV_TARGET
      {
        real4 screenPosition = i.positionCS / GetScaledScreenParams();

        real depth = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, screenPosition.xy).r;
        real eyeDepth = LinearEyeDepth(depth, _ZBufferParams);
        real fragEyeDepth = screenPosition.w;
        real depthDiff = saturate(eyeDepth - fragEyeDepth);
        real edge = 1 - smoothstep(0, _SoftRange, depthDiff);
        edge *= _EdgeAlpha;

        real4 finalColor = _EdgeColor - 1 ;
        finalColor.a = edge;
        
        return finalColor;
      }

      ENDHLSL
    }
  }

  Fallback "Hidden/Universal Render Pipeline/FallbackError"
}
