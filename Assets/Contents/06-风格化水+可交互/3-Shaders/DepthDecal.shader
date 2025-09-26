Shader "Custom/07-Water/DepthDecal"
{
  Properties
  {
    _DecalTex ("主贴图", 2D) = "white" { }
  }
  SubShader
  {
    LOD 200

    Tags
    {
      "Queue" = "Transparent+100"
      "RenderPipeline" = "UniversalPipeline"
    }

    Cull Back
    ZTest LEqual
    ZWrite On
    // Blend One One

    HLSLINCLUDE

    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

    CBUFFER_START(UnityPerMaterial)

      TEXTURE2D(_CameraDepthTexture);
      SAMPLER(sampler_CameraDepthTexture);

      TEXTURE2D(_DecalTex);
      SAMPLER(sampler_DecalTex);
      real4 _DecalTex_ST;

    CBUFFER_END

    ENDHLSL

    Pass
    {
      Name "BasePass"

      Tags
      {
        "LightMode" = "UniversalForward"
      }

      HLSLPROGRAM

      #pragma vertex vert
      #pragma fragment frag

      struct appdata
      {
        real2 uv : TEXCOORD0;
        real4 positionOS : POSITION;
      };

      struct v2f
      {
        real2 uv : TEXCOORD0;
        real4 positionCS : SV_POSITION;
        real3 positionVS : TEXCOORD1;
      };

      v2f vert(appdata v)
      {
        v2f o = (v2f)0;

        VertexPositionInputs positionInputs = GetVertexPositionInputs(v.positionOS.xyz);

        o.positionCS = positionInputs.positionCS;
        o.positionVS = positionInputs.positionVS;

        return o;
      }

      real4 frag(v2f i) : SV_TARGET
      {
        real2 orgScreenUV = i.positionCS.xy / GetScaledScreenParams().xy;
        real depth = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, orgScreenUV).r;
        depth = LinearEyeDepth(depth, _ZBufferParams);

        real4 objPosVS = 1;
        // ! 用近似三角形原理 通过屏幕空间的位置计算三维坐标
        objPosVS.xy = depth / - i.positionVS.z * i.positionVS.xy;
        objPosVS.z = depth;
        
        // ! 世界空间采样
        real3 objPosWS = mul(unity_CameraToWorld, objPosVS).xyz;
        real2 decalUV = objPosWS.xz;
        // real2 decalUV = objPosWS.xz + objPosWS.y;
        decalUV = decalUV * _DecalTex_ST.xy + _DecalTex_ST.zw;
        // ! 物体空间采样
        // real3 objPosOS = mul(UNITY_MATRIX_I_M, real4(objPosWS, 1));
        // real2 decalUV = objPosOS.xy + objPosOS.z;
        // decalUV = decalUV * _DecalTex_ST.xy + _DecalTex_ST.zw;

        // return real4(decalUV, 0, 1);
        
        real4 finalColor = SAMPLE_TEXTURE2D(_DecalTex, sampler_DecalTex, decalUV);

        return finalColor;
      }

      ENDHLSL
    }
  }

  Fallback "Hidden/Universal Render Pipeline/FallbackError"
}
