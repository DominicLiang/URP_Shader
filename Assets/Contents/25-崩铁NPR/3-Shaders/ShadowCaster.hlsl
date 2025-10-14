#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

struct a2v
{
  float4 vertex : POSITION;
  float3 normal : NORMAL;
  float2 texcoord : TEXCOORD0;
};

struct v2f
{
  float2 uv : TEXCOORD0;
  float4 pos : SV_POSITION;
};



// 获取裁剪空间下的阴影坐标
float4 GetShadowPositionHClips(a2v v)
{
  float4 vertex_OS = v.vertex;

  //阴影
  float3 positionWS = TransformObjectToWorld(vertex_OS.xyz);
  float3 normalWS = TransformObjectToWorldNormal(v.normal);

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

v2f vert(a2v v)
{
  v2f o;
  o.uv = v.texcoord;
  o.pos = GetShadowPositionHClips(v);
  return o;
}

half4 frag(v2f i, FRONT_FACE_TYPE isFrontFace : FRONT_FACE_SEMANTIC) : SV_TARGET
{
  // real4 color = SAMPLE_TEXTURE2D(_ColorMap, sampler_ColorMap, i.uv);
  // color = IS_FRONT_VFACE(isFrontFace, color, real4(1, 1, 1, 1));
  // clip(color.a - 0.5);

  return 0;
}