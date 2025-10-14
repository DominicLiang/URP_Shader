Shader "Custom/Normal/VolumetricClouds"
{
  Properties
  {
    // ! -------------------------------------
    // ! 面板属性
    [NoScaleOffset] _HeightCurveA ("高度曲线A", 2D) = "white" { }
    [NoScaleOffset] _HeightCurveB ("高度曲线B", 2D) = "white" { }

    _2DTexA ("主2D贴图", 2D) = "white" { }
    _2DTexB ("副2D贴图", 2D) = "white" { }

    [NoScaleOffset]_3DTexA ("主3D贴图", 3D) = "white" { }
    _3DTexATiling ("主3D贴图缩放", Range(0.01, 10.0)) = 1.0
    _3DTexAOffset ("主3D贴图偏移", Vector) = (0, 0, 0)
    [NoScaleOffset]_3DTexB ("副3D贴图", 3D) = "white" { }
    _3DTexBTiling ("副3D贴图缩放", Range(0.01, 10.0)) = 1.0
    _3DTexBOffset ("副3D贴图偏移", Vector) = (0, 0, 0)

    _NoiseCullThreshold ("裁切阈值", Range(0.0, 2.0)) = 0.5

    _StepLength ("步长", Float) = 1
    _MaxIter ("迭代次数", Float) = 100
    _LightStepLength ("灯光步长", Float) = 1
    _LightMaxIter ("灯光迭代次数", Float) = 100
    _LightScale ("灯光强度", Float) = 1
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
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

    TEXTURE2D(_HeightCurveA);
    SAMPLER(sampler_HeightCurveA);
    TEXTURE2D(_HeightCurveB);
    SAMPLER(sampler_HeightCurveB);
    TEXTURE2D(_2DTexA);
    SAMPLER(sampler_2DTexA);
    TEXTURE2D(_2DTexB);
    SAMPLER(sampler_2DTexB);
    TEXTURE3D(_3DTexA);
    SAMPLER(sampler_3DTexA);
    TEXTURE3D(_3DTexB);
    SAMPLER(sampler_3DTexB);

    CBUFFER_START(UnityPerMaterial)
      // ! -------------------------------------
      // ! 变量声明
      real3 _BoundsMin;
      real3 _BoundsMax;

      real4 _2DTexA_ST;
      real4 _2DTexB_ST;
      real _3DTexATiling;
      real _3DTexBTiling;
      real3 _3DTexAOffset;
      real3 _3DTexBOffset;

      real _NoiseCullThreshold;

      real _StepLength;
      real _MaxIter;
      real _LightStepLength;
      real _LightMaxIter;
      real _LightScale;

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
      ZWrite On
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
        real3 positionWS : TEXCOORD1;
        real3 positionVS : TEXCOORD2;
      };

      // ! -------------------------------------
      // ! 顶点着色器
      v2f vert(appdata v)
      {
        v2f o = (v2f)0;

        VertexPositionInputs positionInputs = GetVertexPositionInputs(v.positionOS.xyz);

        o.uv = v.uv;

        o.positionCS = positionInputs.positionCS;
        o.positionWS = positionInputs.positionWS;

        return o;
      }

      float2 RayBoxDistance(float3 boundsMin, float3 boundsMax, float3 rayOrigin, float3 invRay)
      {
        float3 t0 = (boundsMin - rayOrigin) * invRay;
        float3 t1 = (boundsMax - rayOrigin) * invRay;
        float3 tmin = min(t0, t1);
        float3 tmax = max(t0, t1);

        float dstA = max(max(tmin.x, tmin.y), tmin.z);
        float dstB = min(tmax.x, min(tmax.y, tmax.z));

        float dstToBox = max(0, dstA);
        float dstInsideBox = max(0, dstB - dstToBox);

        return float2(dstToBox, dstInsideBox);
      }

      float RayBoxDistance(float3 boundsMin, float3 boundsMax, float3 rayOrigin, float3 ray, out float3 inPos, out float3 outPos)
      {
        float3 invRay = 1.0 / ray;

        float2 rayBoxDst = RayBoxDistance(boundsMin, boundsMax, rayOrigin, invRay);

        inPos = rayOrigin + ray * rayBoxDst.x;
        outPos = inPos + ray * rayBoxDst.y;

        if (rayBoxDst.x > 1)
          return 0;

        if (rayBoxDst.x + rayBoxDst.y > 1)
          outPos = rayOrigin + ray;

        if (rayBoxDst.y == 0)
          return 0;

        return 1;
      }

      real SampleNoiseDensity(real3 pos)
      {
        real density = 0;

        real2 heightCurveUV = real2((pos.y - _BoundsMin.y) / (_BoundsMax.y - _BoundsMin.y), 0);
        real heightCurveAColor = SAMPLE_TEXTURE2D(_HeightCurveA, sampler_HeightCurveA, heightCurveUV);
        real heightCurveBColor = SAMPLE_TEXTURE2D(_HeightCurveB, sampler_HeightCurveB, heightCurveUV);

        real2 noise2DbUV = pos.xz * _2DTexB_ST.xy + _2DTexB_ST.zw;
        float noise2DbColor = SAMPLE_TEXTURE2D(_2DTexB, sampler_2DTexB, noise2DbUV);

        float heightCurve = lerp(heightCurveAColor, heightCurveBColor, noise2DbColor);

        if (heightCurve <= 0)return 0;

        real2 noise2DaUV = pos.xz * _2DTexA_ST.xy + _2DTexA_ST.zw * _Time.y;
        density += SAMPLE_TEXTURE2D(_2DTexA, sampler_2DTexA, noise2DaUV);

        density += SAMPLE_TEXTURE3D(_3DTexA, sampler_3DTexA, pos * _3DTexATiling + _3DTexAOffset * _Time.y);
        density += SAMPLE_TEXTURE3D(_3DTexB, sampler_3DTexB, pos * _3DTexBTiling + _3DTexBOffset * _Time.y);

        density *= heightCurve;

        if (density < _NoiseCullThreshold) return 0;

        return density;
      }

      bool IsOutOfBound(float3 worldPos)
      {
        if (worldPos.x > _BoundsMax.x || worldPos.x < _BoundsMin.x)
          return true;

        if (worldPos.y > _BoundsMax.y || worldPos.y < _BoundsMin.y)
          return true;

        if (worldPos.z > _BoundsMax.z || worldPos.z < _BoundsMin.z)
          return true;

        return false;
      }

      // ! -------------------------------------
      // ! 片元着色器
      real4 frag(v2f i) : SV_TARGET
      {
        Light mainLight = GetMainLight();
        real3 lightDir = normalize(mainLight.direction);

        real3 rayOrigin = i.positionWS;
        real3 ray = normalize(i.positionWS - GetCameraPositionWS());
        real3 inPos, outPos;
        RayBoxDistance(_BoundsMin, _BoundsMax, rayOrigin, ray * 1000, inPos, outPos);
        real maxDist = distance(inPos, outPos);

        real finalDensity = 0;
        real lightIntensity = 0;
        UNITY_LOOP
        for (int ii = 0; ii < _MaxIter; ii++)
        {
          real densityLength = ii * 0.01 * _StepLength;
          if (densityLength > maxDist) break;
          real3 pos = inPos + ray * densityLength;

          if (IsOutOfBound(pos)) break;

          real density = SampleNoiseDensity(pos);

          if (density <= 0) continue;
          finalDensity += density;

          real depth = 0;
          UNITY_LOOP
          for (int jj = 0; jj < _LightMaxIter; ++jj)
          {
            real lightLength = jj * 0.01 * _LightStepLength;
            real3 lightPos = pos + lightDir * lightLength;
            density += SampleNoiseDensity(lightPos);
            if (density > 0)depth++;
          }
          depth /= _LightMaxIter;

          lightIntensity += 1 - (depth / _LightMaxIter);
          lightIntensity = saturate(lightIntensity * _LightScale);
        }

        finalDensity /= _MaxIter;
        finalDensity = saturate(finalDensity);

        return real4(lightIntensity.xxx * mainLight.color * mainLight.distanceAttenuation, finalDensity);


        // return color;

      }
      ENDHLSL
    }
  }

  // ! -------------------------------------
  // ! 紫色报错fallback
  Fallback "Hidden/Universal Render Pipeline/FallbackError"
}