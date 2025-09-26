Shader "Custom/05-QuickSSS/01-QuickSSSNotPBR"
{
  Properties
  {
    [NoScaleOffset]_MainTex ("主贴图", 2D) = "white" { }
    [HDR]_MainColor ("主颜色", Color) = (1, 1, 1, 1)
    _SpecPower ("高光系数", Range(1, 128)) = 64
    [HDR]_SpecColor ("高光颜色", Color) = (1, 1, 1, 1)

    [Toggle(_SSS_ON)]_SSS_Switch ("次表面漫反射开关", Float) = 1
    [NoScaleOffset]_ThicknessMap ("厚度贴图", 2D) = "white" { }
    _ThicknessFactor ("厚度贴图系数", Range(0, 1)) = 1
    [HDR]_SSColor ("次表面颜色", Color) = (1, 1, 1, 1)
    _DistortionFactor ("背光法线扰动系数", Range(0, 1)) = 1
    _BackPower ("背光集中度", Range(1, 4)) = 1
    _BackStrength ("背光强度", Range(1, 4)) = 1
    _BackAmbient ("背光环境光强度", Range(0, 4)) = 0
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
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
    #include "Assets/ShaderLibrary/Utility/Node.hlsl"

    CBUFFER_START(UnityPerMaterial)

      TEXTURE2D(_MainTex);
      SAMPLER(sampler_MainTex);
      real4 _MainColor;
      real _SpecPower;
      real4 _SpecColor;

      TEXTURE2D(_ThicknessMap);
      SAMPLER(sampler_ThicknessMap);
      real _ThicknessFactor;
      real3 _SSColor;
      real _DistortionFactor;
      real _BackPower;
      real _BackStrength;
      real _BackAmbient;

    CBUFFER_END

    ENDHLSL

    Pass
    {
      Name "PassName"

      Tags
      {
        "LightMode" = "UniversalForward"
      }

      HLSLPROGRAM

      #pragma shader_feature _SSS_ON

      #pragma vertex vert
      #pragma fragment frag

      struct appdata
      {
        real2 uv : TEXCOORD0;
        real4 color : COLOR;
        real4 positionOS : POSITION;
        real4 normalOS : NORMAL;
      };

      struct v2f
      {
        real2 uv : TEXCOORD0;
        real4 color : COLOR;
        real4 positionCS : SV_POSITION;
        real3 positionWS : TEXCOORD1;
        real3 normalWS : TEXCOORD2;
      };

      v2f vert(appdata v)
      {
        v2f o = (v2f)0;

        VertexPositionInputs positionInputs = GetVertexPositionInputs(v.positionOS.xyz);
        VertexNormalInputs normalInputs = GetVertexNormalInputs(v.normalOS.xyz);
        
        o.uv = v.uv;

        o.positionCS = positionInputs.positionCS;
        o.positionWS = positionInputs.positionWS;
        o.normalWS = normalInputs.normalWS;

        return o;
      }

      real3 SSS(Light light, real3 N, real3 V, real thickness)
      {
        real3 L = light.direction;
        real3 LN = normalize(L + N * _DistortionFactor);

        // ! V dot -L 背光
        // ! L + N 使用法线对灯光向量做扰动
        // ! V dot -L+N  实际效果
        
        real sss = pow(saturate(dot(V, -LN)), _BackPower) * _BackStrength + _BackAmbient;
        
        sss *= thickness;

        return sss * _SSColor * light.color * light.distanceAttenuation * light.shadowAttenuation;
      }

      real4 frag(v2f i) : SV_TARGET
      {
        Light mainLight = GetMainLight();

        // ! 正面光照

        real3 N = i.normalWS;
        real3 L = mainLight.direction;
        real3 V = normalize(_WorldSpaceCameraPos - i.positionWS);
        real3 LV = normalize(L + V);
        
        real halfLambert = dot(N, L) * 0.5 + 0.5;
        real blinnPhong = saturate(dot(N, LV));

        real3 diffuse = halfLambert * _MainColor.rgb * mainLight.color;
        real3 specular = pow(blinnPhong, _SpecPower) * _SpecColor.rgb * mainLight.color;

        real3 baseColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv).rgb;
        real3 finalColor = baseColor * diffuse + specular;

        // ! 背面光照
        
        #ifdef _SSS_ON

          real thickness = SAMPLE_TEXTURE2D(_ThicknessMap, sampler_ThicknessMap, i.uv).r;
          thickness *= _ThicknessFactor;

          // ! 直接光

          // finalColor += SSS(mainLight, N, V, thickness);

          // ! 间接光(灯光颜色 衰减 方向 与直接光不同)
          for (int j = 0; j < GetAdditionalLightsCount(); j++)
          {
            Light light = GetAdditionalLight(j, i.positionWS);
            
            finalColor += SSS(light, N, V, thickness);
          }

        #endif

        return real4(finalColor, 1);
      }

      ENDHLSL
    }
  }
}
