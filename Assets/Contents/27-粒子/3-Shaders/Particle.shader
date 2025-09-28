Shader "Custom/Normal/Particle"
{
  Properties
  {
    // ! -------------------------------------
    // ! 面板属性
    [HDR]_MainColor ("主颜色", Color) = (1, 1, 1, 1)
    _ParticleCount ("粒子数量", Float) = 50
    _ParticleCenter ("粒子中心", Vector) = (0, 0, 0, 0)
    _ParticleSize ("粒子大小", Range(0, 20)) = 0.01
    _ParticleLifetimeSize ("粒子生命周期大小", Float) = 1
    _ParticleSpeed ("粒子速度", Float) = 1

    _MainTex ("主贴图", 2D) = "white" { }
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

    TEXTURE2D(_MainTex);
    SAMPLER(sampler_MainTex);

    CBUFFER_START(UnityPerMaterial)

      // ! -------------------------------------
      // ! 变量声明
      real4 _MainColor;
      real _ParticleCount;
      real2 _ParticleCenter;
      real _ParticleSize;
      real _ParticleSpeed;
      real _ParticleLifetimeSize;

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
      };

      // ! -------------------------------------
      // ! 顶点着色器
      v2f vert(appdata v)
      {
        v2f o = (v2f)0;

        VertexPositionInputs positionInputs = GetVertexPositionInputs(v.positionOS.xyz);
        
        o.uv = v.uv;

        o.positionCS = positionInputs.positionCS;

        return o;
      }

      float circle(float2 uv, float radius)
      {
        return length(uv) - radius;
      }

      // ! -------------------------------------
      // ! 片元着色器
      real4 frag(v2f i) : SV_TARGET
      {
        // real4 color = _MainColor;
        // color.a = 0;

        real distance;
        real4 color;
        for (int index = 0; index < _ParticleCount; index++)
        {
          real2 dir = RandomVector2(index * 3.141592653);

          real timeOffset = Random(index);

          real time = frac(_Time.y + timeOffset);

          real speed = _ParticleSpeed * time;

          real2 offset = dir * speed;

          real2 uv = i.uv - 0.5;
          uv *= 20 - _ParticleSize;
          uv += i.uv;
          uv += offset;


          color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv);
        }

        real alpha = smoothstep(0, fwidth(distance), -distance);

        color = saturate(color);
        // color.a = saturate(alpha);
        
        return color;
      }

      ENDHLSL
    }
  }

  // ! -------------------------------------
  // ! 紫色报错fallback
  Fallback "Hidden/Universal Render Pipeline/FallbackError"
}
