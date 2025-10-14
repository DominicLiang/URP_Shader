Shader "Custom/10-Shield/Shield"
{
  Properties
  {
    _LightTex ("扫光贴图", 2D) = "white" { }
    _MaskTex ("遮罩贴图", 2D) = "white" { }
    _NoiseTex ("噪声贴图", 2D) = "white" { }

    [HDR]_MainColor ("主颜色", Color) = (1, 1, 1, 1)
    [HDR]_EdgeColor ("边缘颜色", Color) = (1, 1, 1, 1)

    _LightSpeed ("扫光速度", Float) = 1

    _Threshold ("阈值", Float) = 1
    _Edge1 ("边缘1", Float) = 1
    _Edge2 ("边缘2", Float) = 1
    _EdgeAlpha2 ("边缘透明度", Float) = 1
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
    #include "Assets/ShaderLibrary/Utility/NodeFromShaderGraph.hlsl"

    TEXTURE2D(_CameraDepthTexture);
    SAMPLER(sampler_CameraDepthTexture);
    TEXTURE2D(_LightTex);
    SAMPLER(sampler_LightTex);
    TEXTURE2D(_MaskTex);
    SAMPLER(sampler_MaskTex);
    TEXTURE2D(_NoiseTex);
    SAMPLER(sampler_NoiseTex);

    CBUFFER_START(UnityPerMaterial)

      real4 _LightTex_ST;
      real4 _MaskTex_ST;
      real4 _NoiseTex_ST;

      real4 _MainColor;
      real4 _EdgeColor;

      real _LightSpeed;
      


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

      Cull Off
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

        _NoiseTex_ST.w += _Time.y * 0.3;
        real2 noiseUV = v.uv * _NoiseTex_ST.xy + _NoiseTex_ST.zw;
        real noise = SAMPLE_TEXTURE2D_LOD(_NoiseTex, sampler_NoiseTex, noiseUV, 0).r;
        v.positionOS.xyz += noise * v.normalOS * 0.01;

        VertexPositionInputs positionInputs = GetVertexPositionInputs(v.positionOS.xyz);
        VertexNormalInputs normalInputs = GetVertexNormalInputs(v.normalOS);
        
        o.uv = v.uv;

        o.positionCS = positionInputs.positionCS;
        o.positionWS = positionInputs.positionWS;
        o.normalWS = normalInputs.normalWS;

        return o;
      }

      real4 frag(v2f i, real facing : VFACE) : SV_TARGET
      {
        real3 N = normalize(lerp(-i.normalWS, i.normalWS, facing));
        real3 V = normalize(GetCameraPositionWS() - i.positionWS);
        real NoV = saturate(dot(N, V));
        real power = sin(_Time.y * 2);
        power = Unity_Remap_float(power, real2(-1, 1), real2(3.5, 7));
        real fresnel = pow(1 - saturate(NoV), power);
        fresnel += 0.05;

        _LightTex_ST.w += _Time.y * _LightSpeed;
        real2 lightTexUV = i.uv * _LightTex_ST.xy + _LightTex_ST.zw;
        real4 lightTex = SAMPLE_TEXTURE2D(_LightTex, sampler_LightTex, lightTexUV);

        real2 maskTexUV = i.uv * _MaskTex_ST.xy + _MaskTex_ST.zw;
        real4 maskTex = SAMPLE_TEXTURE2D(_MaskTex, sampler_MaskTex, maskTexUV);
        real light = lightTex.r * (1 - maskTex.r);
        
        real4 screenPosition = i.positionCS / GetScaledScreenParams();
        real depth = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, screenPosition.xy).r;
        real eyeDepth = LinearEyeDepth(depth, _ZBufferParams);
        
        real depthDiff = saturate(eyeDepth - screenPosition.w);
        real edge = 1 - smoothstep(0, 0.15, depthDiff);

        light += edge;

        real dist = distance(i.positionWS, _HitCenter);
        real edge3 = saturate(abs(dist - _Threshold));
        edge3 = smoothstep(_Edge1, _Edge2, edge3);
        edge3 = 1 - (saturate(edge3));
        edge3 *= _EdgeAlpha2;

        light += edge3;

        light = lerp(light * 0.7, light, facing);

        real3 finalColor = lerp(_MainColor.rgb, _EdgeColor.rgb, light);
        real finalAlpha = saturate(fresnel + light);

        return real4(finalColor, finalAlpha);
      }

      ENDHLSL
    }
  }

  Fallback "Hidden/Universal Render Pipeline/FallbackError"
}
