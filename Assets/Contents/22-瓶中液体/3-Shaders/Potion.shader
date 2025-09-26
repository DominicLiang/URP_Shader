Shader "Custom/11-Potion/Potion"
{
  Properties
  {
    [HDR]_MainColor ("主颜色", Color) = (1, 1, 1, 1)
    [HDR]_TopColor ("顶部颜色", Color) = (1, 1, 1, 1)

    _Cutoff ("AlphaClip阈值", Range(0, 1)) = 1
    _HeightStep ("高度阈值", Float) = 1

    _WobbleX ("WobbleX", Float) = 0
    _WobbleZ ("WobbleZ", Float) = 0
  }
  SubShader
  {
    LOD 200

    Tags
    {
      "Queue" = "Geometry"
      "RenderPipeline" = "UniversalPipeline"
    }

    Cull Off
    ZTest LEqual
    ZWrite On

    HLSLINCLUDE

    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

    CBUFFER_START(UnityPerMaterial)

      real4 _MainColor;
      real4 _TopColor;

      real _Cutoff;
      real _HeightStep;

      real _WobbleX;
      real _WobbleZ;

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
        real3 positionOS : TEXCOORD1;
        real3 positionWS : TEXCOORD2;
        real3 objectPos : TEXCOORD3;
      };

      v2f vert(appdata v)
      {
        v2f o = (v2f)0;

        VertexPositionInputs positionInputs = GetVertexPositionInputs(v.positionOS.xyz);
        
        o.uv = v.uv;

        o.positionCS = positionInputs.positionCS;
        o.positionWS = positionInputs.positionWS;

        o.objectPos = mul(UNITY_MATRIX_M, real4(0, 0, 0, 1)).xyz;

        return o;
      }

      void Unity_RotateAboutAxis_Degrees_float(float3 In, float3 Axis, float Rotation, out float3 Out)
      {
        Rotation = radians(Rotation);
        float s, c;
        sincos(Rotation, s, c);
        Axis = normalize(Axis);
        Out = In * c + cross(Axis, In) * s + Axis * dot(Axis, In) * (1 - c);
      }

      real4 frag(v2f i, FRONT_FACE_TYPE face : FRONT_FACE_SEMANTIC) : SV_TARGET
      {
        real3 height = (i.positionWS - i.objectPos);
        
        real3 rotateX;
        Unity_RotateAboutAxis_Degrees_float(height, real3(0, 0, 1), 90, rotateX);
        real3 rotateZ;
        Unity_RotateAboutAxis_Degrees_float(height, real3(1, 0, 0), 90, rotateZ);
        real3 rotateRes = rotateX * _WobbleX;
        rotateRes += rotateZ * _WobbleZ;
        
        height += rotateRes;
        
        clip(step(height.y, _HeightStep) - _Cutoff);

        real4 finalColor = lerp(_TopColor, _MainColor, IS_FRONT_VFACE(face, 1, 0));
        
        return finalColor;
      }

      ENDHLSL
    }
  }

  Fallback "Hidden/Universal Render Pipeline/FallbackError"
}
