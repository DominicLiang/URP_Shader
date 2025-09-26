Shader "Custom/01-WriteShader/11_Diffuse"
{
  Properties
  {
    _MainTex ("Main Texture", 2D) = "white" { }
    _MainColor ("Main Color", Color) = (1, 1, 1, 1)
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

    CBUFFER_START(UnityPerMaterial)

      TEXTURE2D(_MainTex);
      float4 _MainTex_ST;
      SamplerState NewRepeatPointSampler;

      float4 _MainColor;

    CBUFFER_END

    ENDHLSL

    pass
    {
      Name "ForwardLit"

      Tags
      {
        "LightMode" = "UniversalForward"
      }

      HLSLPROGRAM

      // ! 灯光选项
      #pragma multi_compile LIGHTMAP_ON
      // ! 接受阴影选项
      // #pragma multi_compile _MAIN_LIGHT_SHADOWS

      #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
      #pragma multi_compile_fragment _ _SHADOWS_SOFT

      #pragma vertex vert
      #pragma fragment frag

      struct appdata
      {
        float4 posOS : POSITION;
        float4 normalOS : NORMAL;
        float2 uv : TEXCOORD0;
        float2 lightmapUV : TEXCOORD1;
        float4 color : COLOR;
      };

      struct v2f
      {
        float4 posCS : SV_POSITION;
        float2 uv : TEXCOORD0;
        // ! 球谐光照
        DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 1);
        float3 normalWS : TEXCOORD2;
        float3 posWS : TEXCOORD3;
        float4 color : COLOR;
        real4 shadowCoord : TEXCOORD4;
      };

      v2f vert(appdata v)
      {
        v2f o = (v2f)0;

        VertexPositionInputs posInputs = GetVertexPositionInputs(v.posOS.xyz);

        o.posCS = posInputs.positionCS;
        o.posWS = posInputs.positionWS;

        VertexNormalInputs normalInputs = GetVertexNormalInputs(v.normalOS.xyz);

        o.normalWS = normalInputs.normalWS;
        
        // ! 计算lightmap的uv 第三个参数是输出
        OUTPUT_LIGHTMAP_UV(v.lightmapUV, unity_LightmapST, o.lightmapUV);
        // ! 输出球谐光照
        OUTPUT_SH(o.normalWS, o.vertexSH);

        o.uv = TRANSFORM_TEX(v.uv, _MainTex);
        o.color = v.color;

        // !  如果要用屏幕空间阴影必须要用这个方法来获取阴影uv
        o.shadowCoord = GetShadowCoord(posInputs);

        return o;
      }

      float4 frag(v2f i) : SV_TARGET
      {
        float4 mainTexColor = SAMPLE_TEXTURE2D(_MainTex, NewRepeatPointSampler, i.uv);

        // ! 从光照贴图中获得gi信息
        // ! 球谐光照(天空盒)  光照贴图  光照探针
        float3 bakedGI = SAMPLE_GI(i.lightmapUV, i.vertexSH, i.normalWS);

        // ! 计算光照和接受阴影
        // 计算当前像素在主光源阴影贴图中的坐标（用于采样阴影）
        // * 这个获得阴影uv的方法适用于透明物体
        // float4 shadowCoord = TransformWorldToShadowCoord(i.posWS);
        // 获取主光源信息（包含阴影衰减等），shadowCoord用于阴影采样
        Light mainLight = GetMainLight(i.shadowCoord);
        // 计算主光源的最终颜色（包含颜色、距离衰减、阴影衰减）

        float3 lightColor = mainLight.color * mainLight.distanceAttenuation * mainLight.shadowAttenuation;

        // 使用Lambert模型计算实时主光源下的漫反射光照
        float3 realtimeLight = LightingLambert(lightColor, mainLight.direction, i.normalWS);

        return mainTexColor * _MainColor * i.color * float4(bakedGI + realtimeLight, 1);
      }

      ENDHLSL
    }

    // 之前写的投射阴影pass
    pass
    {
      Name "ShadowCaster"
      Tags
      {
        "LightMode" = "ShadowCaster"
      }

      ColorMask 0
      Cull Off
      ZWrite On
      ZTest LEqual

      HLSLPROGRAM

      #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
      #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
      #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"

      #pragma shader_feature _ALPHATEST_ON
      #pragma shader_feature _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
      #pragma multi_compile_instancing

      #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW

      #pragma vertex ShadowPassVertex
      #pragma fragment ShadowPassFragment

      ENDHLSL
    }
  }

  Fallback "Hidden/Universal Render Pipeline/FallbackError"
}