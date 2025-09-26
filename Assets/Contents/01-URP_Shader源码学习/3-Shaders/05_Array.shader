Shader "Custom/01-WriteShader/05_Array"
{
  Properties
  {
    [Toggle]_IsUseMainTex ("Is Use Main Texture", int) = 1
    _MainTex ("Main Texture", 2D) = "white" { }
    _MainColor ("Main Color", Color) = (1, 0, 0, 1)
    _ColorIntensity ("Color Intensity", float) = 1

    // ! 贴图数组可以在Properties中传
    _MutTextures ("Multiple Textures", 2DArray) = "" { }
    // ! 如果贴图数组是在Properties中传的话 index同样用Properties传
    [IntRange]_TextureIndex ("Texture Index", Range(0, 3)) = 0
  }

  SubShader
  {
    LOD 200

    Tags
    {
      "Queue" = "Geometry"
      "RenderPipeline" = "UniversalPipeline"
    }

    Cull Back
    ZTest LEqual
    ZWrite On

    HLSLINCLUDE

    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

    CBUFFER_START(UnityPerMaterial)

      bool _IsUseMainTex;
      float4 _MainColor;
      float _ColorIntensity;

      TEXTURE2D(_MainTex);
      float4 _MainTex_ST;
      SamplerState NewRepeatPointSampler;

      float _TextureIndex;
      TEXTURE2D_ARRAY(_MutTextures);
      SamplerState ArrayClampLinearSampler;
      float4 _MutTextures_ST;

    CBUFFER_END

    // ! 数组
    // ! unity中数组数量必须小于1024 最大1023
    // ! 数组不能在CBUFFER块内 如果在CBUFFER内就不能使用SRPBatcher
    // ! Properties块无法输入数组 只能用c#代码输入
    float _FloatArray[4]; // ! c#中使用Shader.SetGlobalFloatArray来输入 看MatPropCtrl.cs
    // ! 向量数组
    // float4 _VectorArray[4]; // ! c#中使用Shader.SetGlobalVectorArray来输入

    // ! 贴图数组
    // ! 如果贴图数组是通过C#传递的话 不能写在CBUFFER块内 连用到的index也不能在CBUFFER块内
    // ! 但是如果贴图数组是通过属性面板传递的 数组和index都可以写在CBUFFER块内
    // TEXTURE2D_ARRAY(_MutTextures);
    // SamplerState ArrayClampLinearSampler;
    // float4 _MutTextures_ST;
    // ! _Index这个变量名不知道是unity内部使用了还是怎么的 反正是不能用 用其他变量名
    // float _TextureIndex;

    ENDHLSL

    pass
    {
      Tags
      {
        "LightMode" = "UniversalForward"
      }

      HLSLPROGRAM

      #pragma vertex vert
      #pragma fragment frag

      struct appdata
      {
        float3 pos : POSITION;
        float2 uv : TEXCOORD0;
      };

      struct v2f
      {
        float4 pos : SV_POSITION;
        float2 uv : TEXCOORD0;
      };

      v2f vert(appdata v)
      {
        v2f o = (v2f)0;

        o.pos = mul(UNITY_MATRIX_MVP, float4(v.pos, 1));

        o.uv = TRANSFORM_TEX(v.uv, _MainTex);

        return o;
      }

      float4 frag(v2f i) : SV_TARGET
      {
        float4 mainTexColor = float4(1, 1, 1, 1);

        if (_IsUseMainTex)
        {
          // mainTexColor = SAMPLE_TEXTURE2D(_MainTex, NewRepeatPointSampler, i.uv);

          mainTexColor = SAMPLE_TEXTURE2D_ARRAY(_MutTextures, ArrayClampLinearSampler, i.uv, _TextureIndex);
        }

        float4 array = float4(_FloatArray[0], _FloatArray[1], _FloatArray[2], _FloatArray[3]); // ! 数组使用
        
        // ! 数组遍历
        // for (int i = 0; i < 4; i++)
        // {
        //   float4 vect = _VectorArray[i];
        // }

        return mainTexColor * _MainColor * _ColorIntensity * array;
      }

      ENDHLSL
    }
  }

  Fallback "Hidden/Universal Render Pipeline/FallbackError"
}