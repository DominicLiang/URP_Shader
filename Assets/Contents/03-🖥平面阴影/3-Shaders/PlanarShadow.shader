Shader "Custom/03-PlanarShadow/PlanarShadow"
{
  Properties
  {
    _MainTex ("贴图", 2D) = "white" { }

    _ShadowColor ("阴影颜色", Color) = (0, 0, 0, 0.5)
    _ShadowRadius ("阴影最大渐变半径", Float) = 1.0

    _ShadowOffset1 ("阴影偏移", Vector) = (1, 0.01, 1, 1)
    _ShadowOffset2 ("阴影偏移", Vector) = (1, 0.01, 1, 1)
    _ShadowOffset3 ("阴影偏移", Vector) = (1, 0.01, 1, 1)
    _ShadowOffset4 ("阴影偏移", Vector) = (1, 0.01, 1, 1)
  }

  SubShader
  {
    LOD 200

    Tags
    {
      "Queue" = "Geometry"
      "RenderPipeline" = "UniversalPipeline"
    }
    
    HLSLINCLUDE
    
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    
    CBUFFER_START(UnityPerMaterial)
      
      TEXTURE2D(_MainTex);
      real4 _MainTex_ST;
      SAMPLER(sampler_MainTex);
      real4 _ShadowColor;
      real _ShadowRadius;
      real4 _ShadowOffset1;
      real4 _ShadowOffset2;
      real4 _ShadowOffset3;
      real4 _ShadowOffset4;
      
    CBUFFER_END

    real4 _ShadowCenter;
    
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

      v2f vert(appdata v)
      {
        v2f o = (v2f)0;

        VertexPositionInputs positionInputs = GetVertexPositionInputs(v.posOS.xyz);

        o.posCS = positionInputs.positionCS;

        o.uv = TRANSFORM_TEX(v.uv, _MainTex);

        return o;
      }

      real4 frag(v2f i) : SV_TARGET
      {
        real4 texColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
        return texColor;
      }

      ENDHLSL
    }

    pass
    {
      Name "PlanarShadow"

      Tags
      {
        "LightMode" = "PlanarShadow1"
      }
      
      ZWrite Off
      Blend SrcAlpha OneMinusSrcAlpha

      // ! 解决y轴和地面相同时造成的错误显示问题
      // ! 深度偏移
      Offset -1, -1

      // ! 模版测试清除重叠问题
      Stencil
      {
        Ref 1
        Comp NotEqual
        Pass Replace
        Fail Keep
      }

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
        real2 shadowV : TEXCOORD1;
      };

      v2f vert(appdata v)
      {
        v2f o = (v2f)0;

        // ! 转换到世界空间
        real4 vertexWS = mul(UNITY_MATRIX_M, v.posOS);
        
        // ! 根据y轴高度来偏移xz
        vertexWS.xz += _ShadowOffset1.xz * (vertexWS.y - _ShadowOffset1.y);

        // ! 将操作后顶点的xz轴传到片元 用来计算渐变
        // * 注意
        // * 当你转换空间后做偏移压缩等操作后是无法通过逆矩阵转换回物体空间的
        // * 强制转换会得到奇怪的效果
        o.shadowV = vertexWS.xz;
        
        // ! y轴压扁
        vertexWS.y = _ShadowOffset1.y;
        
        // ! 转换到裁剪空间
        real4 vertexCS = mul(UNITY_MATRIX_VP, vertexWS);

        o.posCS = vertexCS;

        return o;
      }

      real4 frag(v2f i) : SV_TARGET
      {
        // ! 离中心距离
        real dist = length(i.shadowV - _ShadowCenter.xy);

        real4 color = _ShadowColor;

        // ! 计算渐变
        color.a *= saturate(1.0 - dist / _ShadowRadius);

        return color;
      }

      ENDHLSL
    }

    pass
    {
      Name "PlanarShadow"

      Tags
      {
        "LightMode" = "PlanarShadow2"
      }
      
      ZWrite Off
      Blend SrcAlpha OneMinusSrcAlpha

      // ! 解决y轴和地面相同时造成的错误显示问题
      // ! 深度偏移
      Offset -1, -1

      // ! 模版测试清除重叠问题
      Stencil
      {
        Ref 1
        Comp NotEqual
        Pass Replace
        Fail Keep
      }

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
        real2 shadowV : TEXCOORD1;
      };

      v2f vert(appdata v)
      {
        v2f o = (v2f)0;

        // ! 转换到世界空间
        real4 vertexWS = mul(UNITY_MATRIX_M, v.posOS);
        
        // ! 根据y轴高度来偏移xz
        vertexWS.xz += _ShadowOffset2.xz * (vertexWS.y - _ShadowOffset2.y);

        // ! 将操作后顶点的xz轴传到片元 用来计算渐变
        // * 注意
        // * 当你转换空间后做偏移压缩等操作后是无法通过逆矩阵转换回物体空间的
        // * 强制转换会得到奇怪的效果
        o.shadowV = vertexWS.xz;
        
        // ! y轴压扁
        vertexWS.y = _ShadowOffset2.y;
        
        // ! 转换到裁剪空间
        real4 vertexCS = mul(UNITY_MATRIX_VP, vertexWS);

        o.posCS = vertexCS;

        return o;
      }

      real4 frag(v2f i) : SV_TARGET
      {
        // ! 离中心距离
        real dist = length(i.shadowV - _ShadowCenter.xy);

        real4 color = _ShadowColor;

        // ! 计算渐变
        color.a *= saturate(1.0 - dist / _ShadowRadius);

        return color;
      }

      ENDHLSL
    }

    pass
    {
      Name "PlanarShadow"

      Tags
      {
        "LightMode" = "PlanarShadow3"
      }
      
      ZWrite Off
      Blend SrcAlpha OneMinusSrcAlpha

      // ! 解决y轴和地面相同时造成的错误显示问题
      // ! 深度偏移
      Offset -1, -1

      // ! 模版测试清除重叠问题
      Stencil
      {
        Ref 1
        Comp NotEqual
        Pass Replace
        Fail Keep
      }

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
        real2 shadowV : TEXCOORD1;
      };

      v2f vert(appdata v)
      {
        v2f o = (v2f)0;

        // ! 转换到世界空间
        real4 vertexWS = mul(UNITY_MATRIX_M, v.posOS);
        
        // ! 根据y轴高度来偏移xz
        vertexWS.xz += _ShadowOffset3.xz * (vertexWS.y - _ShadowOffset3.y);

        // ! 将操作后顶点的xz轴传到片元 用来计算渐变
        // * 注意
        // * 当你转换空间后做偏移压缩等操作后是无法通过逆矩阵转换回物体空间的
        // * 强制转换会得到奇怪的效果
        o.shadowV = vertexWS.xz;
        
        // ! y轴压扁
        vertexWS.y = _ShadowOffset3.y;
        
        // ! 转换到裁剪空间
        real4 vertexCS = mul(UNITY_MATRIX_VP, vertexWS);

        o.posCS = vertexCS;

        return o;
      }

      real4 frag(v2f i) : SV_TARGET
      {
        // ! 离中心距离
        real dist = length(i.shadowV - _ShadowCenter.xy);

        real4 color = _ShadowColor;

        // ! 计算渐变
        color.a *= saturate(1.0 - dist / _ShadowRadius);

        return color;
      }

      ENDHLSL
    }

    pass
    {
      Name "PlanarShadow"

      Tags
      {
        "LightMode" = "PlanarShadow4"
      }
      
      ZWrite Off
      Blend SrcAlpha OneMinusSrcAlpha

      // ! 解决y轴和地面相同时造成的错误显示问题
      // ! 深度偏移
      Offset -1, -1

      // ! 模版测试清除重叠问题
      Stencil
      {
        Ref 1
        Comp NotEqual
        Pass Replace
        Fail Keep
      }

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
        real2 shadowV : TEXCOORD1;
      };

      v2f vert(appdata v)
      {
        v2f o = (v2f)0;

        // ! 转换到世界空间
        real4 vertexWS = mul(UNITY_MATRIX_M, v.posOS);
        
        // ! 根据y轴高度来偏移xz
        vertexWS.xz += _ShadowOffset4.xz * (vertexWS.y - _ShadowOffset4.y);

        // ! 将操作后顶点的xz轴传到片元 用来计算渐变
        // * 注意
        // * 当你转换空间后做偏移压缩等操作后是无法通过逆矩阵转换回物体空间的
        // * 强制转换会得到奇怪的效果
        o.shadowV = vertexWS.xz;
        
        // ! y轴压扁
        vertexWS.y = _ShadowOffset4.y;
        
        // ! 转换到裁剪空间
        real4 vertexCS = mul(UNITY_MATRIX_VP, vertexWS);

        o.posCS = vertexCS;

        return o;
      }

      real4 frag(v2f i) : SV_TARGET
      {
        // ! 离中心距离
        real dist = length(i.shadowV - _ShadowCenter.xy);

        real4 color = _ShadowColor;

        // ! 计算渐变
        color.a *= saturate(1.0 - dist / _ShadowRadius);

        return color;
      }

      ENDHLSL
    }
  }

  FallBack "Hidden/Universal Render Pipeline/FallbackError"
}

