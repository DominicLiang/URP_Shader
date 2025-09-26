Shader "Custom/04-Distortion/Distortion"
{
  Properties
  {
    _Noise ("噪声贴图", 2D) = "white" { }
    _Intensity ("扭曲强度", Range(0, 1)) = 0
  }

  SubShader
  {
    LOD 200

    Tags
    {
      "Queue" = "Transparent+1"
      "RenderPipeline" = "UniversalPipeline"
    }
    
    HLSLINCLUDE
    
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    
    CBUFFER_START(UnityPerMaterial)
      
      TEXTURE2D(_Noise);
      real4 _Noise_ST;
      SAMPLER(sampler_Noise);

      real _Intensity;

      TEXTURE2D(_CameraOpaqueTexture);
      SAMPLER(sampler_CameraOpaqueTexture);
      
    CBUFFER_END
    
    ENDHLSL

    pass
    {
      Name "BasePass"

      ZWrite On

      HLSLPROGRAM

      #pragma vertex vert
      #pragma fragment frag

      struct appdata
      {
        real4 posOS : POSITION;
        real2 uv : TEXCOORD0;
      };

      struct v2f
      {
        real4 posCS : SV_POSITION;
        real2 uv : TEXCOORD0;
      };

      // ! 公告板实现
      real3 billboard(real3 v)
      {
        real3 rightDir = UNITY_MATRIX_MV[0].xyz;
        real3 upDir = UNITY_MATRIX_MV[1].xyz;
        real3 forwardDir = UNITY_MATRIX_MV[2].xyz;

        // ! 缩放适应
        real3 vNorm;
        vNorm.x = v.x / length(rightDir);
        vNorm.y = v.y / length(upDir);
        vNorm.z = v.z / length(forwardDir);

        return rightDir * vNorm.x + upDir * vNorm.y + forwardDir * vNorm.z;
      }

      v2f vert(appdata v)
      {
        v2f o = (v2f)0;

        o.posCS = GetVertexPositionInputs(billboard(v.posOS.xyz)).positionCS;

        o.uv = TRANSFORM_TEX(v.uv, _Noise);

        return o;
      }

      real4 frag(v2f i) : SV_TARGET
      {
        // ! 噪声贴图制作技巧
        // ! 需要扭曲部分设置成黑色或白色 不需要扭曲部分设置成0.5灰或透明
        real4 noiseColor = SAMPLE_TEXTURE2D(_Noise, sampler_Noise, i.uv);
        // ! 这里将透明部分设成0.5灰 如果图片不需要扭曲部分已经是0.5灰 可以省略
        // ! 但是暂时还不知道制图软件怎么保存0.5灰 在csp中使用50%灰 采样出来的不是0.5灰
        // ! 所以先用alpha代替
        noiseColor.r = lerp(0.5, noiseColor.r, noiseColor.a);
        // ! 这里总体减0.5 之前黑色的部分会变成-0.5 白色部分变成0.5
        // ! 这样就可以右上左下两方向扭曲 如果只有单方向扭曲效果不是很好
        noiseColor -= 0.5;

        // ! 获取screenUV 这行代码等于ShaderGraph的ScreenPosition
        // * _ScreenParams是unity内置的变量 记录屏幕的横宽等数据 直接使用 不用声明
        // * 推荐用GetScaledScreenParams()方法
        real2 screenUV = (i.posCS / GetScaledScreenParams()).xy;

        // ! 裁剪空间 PositionCS
        // * x [-w 0 w]   屏幕 左负 中零 右正
        // * y [-w 0 w]   屏幕 下负 中零 上正
        // * z [0 w]      unity中的dx风格深度
        // * w 通常正(-z)  齐次坐标透视分量

        // ! NDC ->  PositionCS.xyz / PositionCS.w
        // * x [-1 0 1]   如上
        // * y [-1 0 1]
        // * z [0 1]

        // ! 这个扭曲公式可以排除黑色部分 使噪声贴图值为0黑色部分不被扭曲
        screenUV += noiseColor.rr * (_Intensity * 0.1);

        real4 screenColor = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, screenUV);

        return screenColor;
      }

      ENDHLSL
    }
  }

  FallBack "Hidden/Universal Render Pipeline/FallbackError"
}

