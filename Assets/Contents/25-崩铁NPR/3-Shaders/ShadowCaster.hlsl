#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

struct appdata
{
  float4 positionOS : POSITION;
  float3 normalOS : NORMAL;
  float2 texcoord : TEXCOORD0;
};

struct v2f
{
  float2 uv : TEXCOORD0;
  float4 pos : SV_POSITION;
};

// 获取裁剪空间下的阴影坐标
float4 GetShadowPositionHClips(appdata v)
{
  //阴影
  float3 positionWS = TransformObjectToWorld(v.positionOS.xyz);
  float3 normalWS = TransformObjectToWorldNormal(v.normalOS);

  Light mainLight = GetMainLight();
  // 获取阴影专用裁剪空间下的坐标
  float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, mainLight.direction));

  // 判断是否是在DirectX平台翻转过坐标
  #if UNITY_REVERSED_Z
    positionCS.z = min(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
  #else
    positionCS.z = max(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
  #endif

  return positionCS;
}

v2f vert(appdata v)
{
  v2f o;
  o.uv = v.texcoord;
  o.pos = GetShadowPositionHClips(v);
  return o;
}

half4 frag(v2f i, FRONT_FACE_TYPE isFrontFace : FRONT_FACE_SEMANTIC) : SV_TARGET
{
  return 0;
}