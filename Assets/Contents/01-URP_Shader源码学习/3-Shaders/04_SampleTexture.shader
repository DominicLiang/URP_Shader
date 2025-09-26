Shader "Custom/01-WriteShader/04_SampleTexture"
{
  Properties
  {
    [Toggle]_IsUseMainTex ("Is Use Main Texture", int) = 1
    _MainTex ("Main Texture", 2D) = "white" { }
    _MainColor ("Main Color", Color) = (1, 0, 0, 1)
    _ColorIntensity ("Color Intensity", float) = 1
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

      // ! DX11 同一个shader 最高支持 118张贴图  16个采样器

      // ! 贴图变量 变量名在括号内
      TEXTURE2D(_MainTex);

      // ! 采样器 采样器名在括号内 这种方法是关联贴图的采样器
      // ! 命名必须为 sampler_贴图名
      // ! 贴图的拼接和过滤模式通过面板修改 shader中不能修改
      SAMPLER(sampler_MainTex);
      
      // ! 更推荐这种方法
      // ! 这种方法的采样器是可复用的 不关联贴图
      // ! 而且可以直接覆盖修改拼接和过滤模式
      // ! 命名为 自定义前缀+拼接模式名+过滤模式名+Sampler
      // ! ​过滤模式​（必需）：
      // Point：最近邻采样（像素风格）
      // Linear：线性插值（模糊效果）
      // Trilinear：结合多级渐远纹理的线性插值
      // ! ​拼接模式​（必需）：
      // Repeat：重复纹理
      // Clamp：边缘拉伸
      // Mirror / MirrorOnce：镜像平铺
      SamplerState NewRepeatPointSampler;

      // ! 要使用面板中自带的TilingAndOffset 必须申请一个这样的变量
      // ! 命名 _变量名_ST
      // ! 然后还需要在顶点着色器中使用TRANSFORM_TEX方法 看顶点着色器
      float4 _MainTex_ST;

      // ! 其他贴图类型
      // TEXTURE2D_ARRAY(textureName)
      // TEXTURE3D(textureName)
      // TEXTURECUBE(textureName)
      // TEXTURECUBE_ARRAY(textureName)

    CBUFFER_END

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

        o.uv = TRANSFORM_TEX(v.uv, _MainTex); // ! TilingAndOffset 这里传uv和贴图名

        // ! 扩展 flipbook的uv计算
        // // 应该有的属性
        // float rows = 4;
        // float columns = 4;
        // float index = 2;
        // // 计算行列偏移
        // float row = floor(index / columns);
        // float column = fmod(index, columns);
        // float2 frameOffset = float2(column / columns, 1.0 - (row + 1.0) / rows);
        // // 修正UV采样区域
        // float2 flipbookUV = v.uv / float2(columns, rows) + frameOffset;

        return o;
      }

      float4 frag(v2f i) : SV_TARGET
      {
        float4 mainTexColor = float4(1, 1, 1, 1);

        if (_IsUseMainTex)
        {
          // ! 2D贴图采样
          mainTexColor = SAMPLE_TEXTURE2D(_MainTex, NewRepeatPointSampler, i.uv);

          // ! 其他类型贴图采样
          // SAMPLE_TEXTURE2D_LOD(textureName, sampler_textureName, uv, lod);
          // SAMPLE_TEXTURE2D_ARRAY(textureName, sampler_textureName, uv, index);
          // SAMPLE_TEXTURE3D(textureName, sampler_textureName, uvw);
          // SAMPLE_TEXTURE3D_LOD(textureName, sampler_textureName, uvw, lod);
          // SAMPLE_TEXTURECUBE(textureName, sampler_textureName, direction);
          // SAMPLE_TEXTURECUBE_LOD(textureName, sampler_textureName, direction, lod);
          // SAMPLE_TEXTURECUBE_ARRAY(textureName, sampler_textureName, direction, index);
          // SAMPLE_TEXTURECUBE_ARRAY_LOD(textureName, sampler_textureName, direction, index, lod);

        }

        return mainTexColor * _MainColor * _ColorIntensity;
      }

      ENDHLSL
    }
  }

  Fallback "Hidden/Universal Render Pipeline/FallbackError"
}