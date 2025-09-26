Shader "Custom/23-Fur/Fur"
{
  Properties
  {
    [NoScaleOffset]_MainTex ("主贴图", 2D) = "white" { }

    _FurFactor ("毛发外扩系数", Range(0.0001, 1)) = 0.25
    _FurAlpha ("毛发透明度系数", Range(0, 1)) = 0.5
    _FurAlphaFactor ("毛发边缘系数", Range(0, 1)) = 0.5

    _Gravity ("重力方向", Vector) = (0, -1, 0)
    _GravityStrength ("重力强度", Range(0, 1)) = 0.5
  }

  SubShader
  {
    LOD 200

    Tags
    {
      "Queue" = "Transparent"
      "RenderPipeline" = "UniversalPipeline"
    }

    Cull Back
    ZTest LEqual
    ZWrite On
    Blend SrcAlpha OneMinusSrcAlpha

    HLSLINCLUDE

    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

    CBUFFER_START(UnityPerMaterial)

      TEXTURE2D(_MainTex);
      SAMPLER(sampler_MainTex);

      real _FurFactor;
      real _FurAlpha;
      real _FurAlphaFactor;
      real3 _Gravity;
      real _GravityStrength;

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
      };

      v2f vert(appdata v)
      {
        v2f o = (v2f)0;

        VertexPositionInputs positionInputs = GetVertexPositionInputs(v.positionOS.xyz);
        
        o.uv = v.uv;

        o.positionCS = positionInputs.positionCS;

        return o;
      }

      real4 frag(v2f i) : SV_TARGET
      {
        real4 baseColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
        
        return baseColor;
      }

      ENDHLSL
    }

    Pass
    {
      Name "BasePass"

      Tags
      {
        "LightMode" = "Fur0"
      }

      HLSLPROGRAM
      
      #define Fur_Factor 0.0625

      #include "Assets/Contents/08-毛发渲染(Shell)/3-Shaders/Fur.hlsl"

      #pragma vertex vert
      #pragma fragment frag

      ENDHLSL
    }

    Pass
    {
      Name "BasePass"

      Tags
      {
        "LightMode" = "Fur1"
      }

      HLSLPROGRAM
      
      #define Fur_Factor 0.125

      #include "Assets/Contents/08-毛发渲染(Shell)/3-Shaders/Fur.hlsl"

      #pragma vertex vert
      #pragma fragment frag

      ENDHLSL
    }

    Pass
    {
      Name "BasePass"

      Tags
      {
        "LightMode" = "Fur2"
      }

      HLSLPROGRAM
      
      #define Fur_Factor 0.1875

      #include "Assets/Contents/08-毛发渲染(Shell)/3-Shaders/Fur.hlsl"

      #pragma vertex vert
      #pragma fragment frag

      ENDHLSL
    }

    Pass
    {
      Name "BasePass"

      Tags
      {
        "LightMode" = "Fur3"
      }

      HLSLPROGRAM
      
      #define Fur_Factor 0.25

      #include "Assets/Contents/08-毛发渲染(Shell)/3-Shaders/Fur.hlsl"

      #pragma vertex vert
      #pragma fragment frag

      ENDHLSL
    }

    Pass
    {
      Name "BasePass"

      Tags
      {
        "LightMode" = "Fur4"
      }

      HLSLPROGRAM
      
      #define Fur_Factor 0.3125

      #include "Assets/Contents/08-毛发渲染(Shell)/3-Shaders/Fur.hlsl"

      #pragma vertex vert
      #pragma fragment frag

      ENDHLSL
    }

    Pass
    {
      Name "BasePass"

      Tags
      {
        "LightMode" = "Fur5"
      }

      HLSLPROGRAM
      
      #define Fur_Factor 0.375

      #include "Assets/Contents/08-毛发渲染(Shell)/3-Shaders/Fur.hlsl"

      #pragma vertex vert
      #pragma fragment frag

      ENDHLSL
    }

    Pass
    {
      Name "BasePass"

      Tags
      {
        "LightMode" = "Fur6"
      }

      HLSLPROGRAM
      
      #define Fur_Factor 0.4375

      #include "Assets/Contents/08-毛发渲染(Shell)/3-Shaders/Fur.hlsl"

      #pragma vertex vert
      #pragma fragment frag

      ENDHLSL
    }

    Pass
    {
      Name "BasePass"

      Tags
      {
        "LightMode" = "Fur7"
      }

      HLSLPROGRAM
      
      #define Fur_Factor 0.5

      #include "Assets/Contents/08-毛发渲染(Shell)/3-Shaders/Fur.hlsl"

      #pragma vertex vert
      #pragma fragment frag

      ENDHLSL
    }

    Pass
    {
      Name "BasePass"

      Tags
      {
        "LightMode" = "Fur8"
      }

      HLSLPROGRAM
      
      #define Fur_Factor 0.5625

      #include "Assets/Contents/08-毛发渲染(Shell)/3-Shaders/Fur.hlsl"

      #pragma vertex vert
      #pragma fragment frag

      ENDHLSL
    }

    Pass
    {
      Name "BasePass"

      Tags
      {
        "LightMode" = "Fur9"
      }

      HLSLPROGRAM
      
      #define Fur_Factor 0.625

      #include "Assets/Contents/08-毛发渲染(Shell)/3-Shaders/Fur.hlsl"

      #pragma vertex vert
      #pragma fragment frag

      ENDHLSL
    }

    Pass
    {
      Name "BasePass"

      Tags
      {
        "LightMode" = "Fur10"
      }

      HLSLPROGRAM
      
      #define Fur_Factor 0.6875

      #include "Assets/Contents/08-毛发渲染(Shell)/3-Shaders/Fur.hlsl"

      #pragma vertex vert
      #pragma fragment frag

      ENDHLSL
    }

    Pass
    {
      Name "BasePass"

      Tags
      {
        "LightMode" = "Fur11"
      }

      HLSLPROGRAM
      
      #define Fur_Factor 0.7503

      #include "Assets/Contents/08-毛发渲染(Shell)/3-Shaders/Fur.hlsl"

      #pragma vertex vert
      #pragma fragment frag

      ENDHLSL
    }

    Pass
    {
      Name "BasePass"

      Tags
      {
        "LightMode" = "Fur12"
      }

      HLSLPROGRAM
      
      #define Fur_Factor 0.8128

      #include "Assets/Contents/08-毛发渲染(Shell)/3-Shaders/Fur.hlsl"

      #pragma vertex vert
      #pragma fragment frag

      ENDHLSL
    }

    Pass
    {
      Name "BasePass"

      Tags
      {
        "LightMode" = "Fur13"
      }

      HLSLPROGRAM
      
      #define Fur_Factor 0.8753

      #include "Assets/Contents/08-毛发渲染(Shell)/3-Shaders/Fur.hlsl"

      #pragma vertex vert
      #pragma fragment frag

      ENDHLSL
    }

    Pass
    {
      Name "BasePass"

      Tags
      {
        "LightMode" = "Fur14"
      }

      HLSLPROGRAM
      
      #define Fur_Factor 0.9375

      #include "Assets/Contents/08-毛发渲染(Shell)/3-Shaders/Fur.hlsl"

      #pragma vertex vert
      #pragma fragment frag

      ENDHLSL
    }

    Pass
    {
      Name "BasePass"

      Tags
      {
        "LightMode" = "Fur15"
      }

      HLSLPROGRAM
      
      #define Fur_Factor 1

      #include "Assets/Contents/08-毛发渲染(Shell)/3-Shaders/Fur.hlsl"

      #pragma vertex vert
      #pragma fragment frag

      ENDHLSL
    }
  }

  Fallback "Hidden/Universal Render Pipeline/FallbackError"
}
