#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

#define MAX_PER_OBJECT_SHADOW_COUNT 16

// -------------- 公共 -------------------

float4 TransformWorldToPerObjectShadowCoord(float4x4 shadowMatrix, float3 positionWS)
{
  return mul(shadowMatrix, float4(positionWS, 1));
}

float PerObjectShadow(
  TEXTURE2D_SHADOW_PARAM(shadowMap, sampler_shadowMap),
  float4 shadowMapRects,
  float4 shadowCoord,
  ShadowSamplingData shadowSamplingData)
{
  if (shadowCoord.x < shadowMapRects.x ||
  shadowCoord.x > shadowMapRects.y ||
  shadowCoord.y < shadowMapRects.z ||
  shadowCoord.y > shadowMapRects.w)
  {
    return 1;
  }

  return SampleShadowmapFilteredHighQuality(TEXTURE2D_SHADOW_ARGS(shadowMap, sampler_shadowMap), shadowCoord, shadowSamplingData);
}

float4 _PerObjectShadowOffset0;
float4 _PerObjectShadowOffset1;
float4 _PerObjectShadowMapSize;

ShadowSamplingData GetPerObjectShadowSamplingData()
{
  ShadowSamplingData shadowSamplingData;

  // shadowOffsets are used in SampleShadowmapFiltered for low quality soft shadows.
  shadowSamplingData.shadowOffset0 = _PerObjectShadowOffset0;
  shadowSamplingData.shadowOffset1 = _PerObjectShadowOffset1;

  // shadowmapSize is used in SampleShadowmapFiltered otherwise
  shadowSamplingData.shadowmapSize = _PerObjectShadowMapSize;
  shadowSamplingData.softShadowQuality = _MainLightShadowParams.y;

  return shadowSamplingData;
}

// -------------- 场景 -------------------

TEXTURE2D_SHADOW(_PerObjSceneShadowMap);
SAMPLER_CMP(sampler_PerObjSceneShadowMap);
float4x4 _PerObjSceneShadowMatrixArray[MAX_PER_OBJECT_SHADOW_COUNT];
float4 _PerObjSceneShadowRectArray[MAX_PER_OBJECT_SHADOW_COUNT];
int _PerObjShadowCount;

float MainLightPerObjectSceneShadow(float3 positionWS)
{
  ShadowSamplingData shadowSamplingData = GetPerObjectShadowSamplingData();

  float shadow = 1;

  for (int i = 0; i < _PerObjShadowCount; i++)
  {
    float4 shadowCoord = TransformWorldToPerObjectShadowCoord(_PerObjSceneShadowMatrixArray[i], positionWS);
    shadow = min(shadow, PerObjectShadow(TEXTURE2D_SHADOW_ARGS(_PerObjSceneShadowMap, sampler_PerObjSceneShadowMap),
    _PerObjSceneShadowRectArray[i], shadowCoord, shadowSamplingData));
  }

  return shadow;
}

// -------------- 自身 -------------------

TEXTURE2D_SHADOW(_PerObjSelfShadowMap);
SAMPLER_CMP(sampler_PerObjSelfShadowMap);
float4x4 _PerObjSelfShadowMatrixArray[MAX_PER_OBJECT_SHADOW_COUNT];
float4 _PerObjSelfShadowRectArray[MAX_PER_OBJECT_SHADOW_COUNT];

float MainLightPerObjectSelfShadow(float3 positionWS, float casterId)
{
  ShadowSamplingData shadowSamplingData = GetPerObjectShadowSamplingData();

  float4 shadowCoord = TransformWorldToPerObjectShadowCoord(_PerObjSelfShadowMatrixArray[casterId], positionWS);
  return PerObjectShadow(TEXTURE2D_SHADOW_ARGS(_PerObjSelfShadowMap, sampler_PerObjSelfShadowMap),
  _PerObjSelfShadowRectArray[casterId], shadowCoord, shadowSamplingData);

  return 1;
}