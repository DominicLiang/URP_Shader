
Shader "Custom/Normal/ParticleZZZ"
{
  Properties
  {
    // ! -------------------------------------
    // ! 面板属性
    _ParticleCount ("Particle Count", Int) = 50
    _SpreadSpeed ("Spread Speed", Range(0.1, 10.0)) = 1.0
    _Thickness ("Thickness", Range(0, 1)) = 0.1

    [HDR] _OutlineColor ("OutlineColor", Color) = (1, 1, 1, 1)
    _OutlineMap ("OutlineMap", 2D) = "white" { }
    _OutlineMapIntensity ("OutlineMapIntensity", Range(0, 1)) = 0.5

    _Color1 ("Color1", Color) = (1, 1, 1, 1)
    _Color2 ("Color2", Color) = (1, 1, 1, 1)
    _BackMap ("BackMap", 2D) = "white" { }
    _MapIntensity ("MapIntensity", Range(0, 1)) = 0.5
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
    #include "Assets/ShaderLibrary/Utility/Node.hlsl"

    TEXTURE2D(_BackMap);
    SAMPLER(sampler_BackMap);
    TEXTURE2D(_OutlineMap);
    SAMPLER(sampler_OutlineMap);

    CBUFFER_START(UnityPerMaterial)

      // ! -------------------------------------
      // ! 变量声明
      int _ParticleCount;
      float _SpreadSpeed;
      float _Thickness;
      real4 _OutlineColor;
      real4 _Color1;
      real4 _Color2;
      real _MapIntensity;
      real _OutlineMapIntensity;

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
      ZWrite Off
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
      };

      // ! -------------------------------------
      // ! 顶点着色器输出 片元着色器输入
      struct v2f
      {
        real2 uv : TEXCOORD0;
        real4 positionCS : SV_POSITION;
        real2 seed : TEXCOORD1;
      };

      // ! -------------------------------------
      // ! 顶点着色器
      v2f vert(appdata v)
      {
        v2f o = (v2f)0;

        VertexPositionInputs positionInputs = GetVertexPositionInputs(v.positionOS.xyz);
        
        o.uv = v.uv;

        o.seed = v.positionOS.xy + v.positionOS.z;
        o.positionCS = positionInputs.positionCS;

        return o;
      }

      float circle(float2 uv, float radius)
      {
        return length(uv) - radius;
      }

      float Outline(float distance, float thickness)
      {
        return abs(distance) - thickness;
      }

      // ! -------------------------------------
      // ! 片元着色器
      real4 frag(v2f i) : SV_TARGET
      {
        real distance;
        real3 finalColor;
        for (int index = 0; index < _ParticleCount; index++)
        {
          // 获得随机方向
          real2 dir = RandomVector3(index * 3.141592653);

          // 随机时间 用来错开粒子发射的时间
          real timeOffset = Random(index);
          
          // 时间一直从0到1 进行循环
          real time = frac(_Time.y * _SpreadSpeed + timeOffset);
          
          // 粒子运动
          real2 uv = i.uv - 0.5;
          uv = dir * time - uv;

          // 粒子大小随时间减小
          real size = 1 - time * 2.2;

          // 距离场圆形
          real a = circle(uv, 0.1 * size);
          real b = circle(uv, 0.2 * size);

          // 混合距离场
          real minAB = min(a, b);
          distance = lerp(min(minAB, distance), minAB, index == 0);
        }

        real alpha = smoothstep(0, fwidth(distance), -distance);
        real outline = Outline(distance, _Thickness);
        outline = smoothstep(0, fwidth(outline), -outline);
        outline = saturate(outline);

        real3 color1 = lerp(_Color1, _Color2, -distance);
        real3 mapColor = SAMPLE_TEXTURE2D(_BackMap, sampler_BackMap, i.uv);
        color1 = lerp(color1, mapColor, _MapIntensity);

        real3 color2 = _OutlineColor;
        real3 outlineMapColor = SAMPLE_TEXTURE2D(_OutlineMap, sampler_OutlineMap, i.uv);
        color2 = lerp(color2, outlineMapColor, _OutlineMapIntensity);

        finalColor = lerp(color1, color2, outline);
        
        return real4(finalColor, alpha);
      }

      ENDHLSL
    }
  }

  // ! -------------------------------------
  // ! 紫色报错fallback
  Fallback "Hidden/Universal Render Pipeline/FallbackError"
}
