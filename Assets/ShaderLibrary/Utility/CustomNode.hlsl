#include "Node.hlsl"

void SoftParticle_float(float eyeDepth, float4 screenPosition, out float Out)
{
    Out = SoftParticle(eyeDepth, screenPosition);
}

void ReconstructWorldPositionFromDepth_float(float eyeDepth, float3 positionVS, out float3 Out)
{
    Out = ReconstructWorldPositionFromDepth(eyeDepth, positionVS);
}

void Billboard_float(float3 positionOS, out float3 Out)
{
    Out = Billboard(positionOS);
}

void MatCapUV_float(float3 positionVS, float3 normalOS, out float2 Out)
{
    Out = MatCapUV(positionVS, normalOS);
}

void QuickSSS_float(float3 L, float3 N, float3 V, float thickness, float normalDistort, float power, float strength, out float3 Out)
{
    Out = QuickSSS(L, N, V, thickness, normalDistort, power, strength);
}

void ParallaxOcclusionMapping_float(UnityTexture2D heightTex, UnitySamplerState heightTexSampler, float3 viewDirTS, float2 uv,
                                    int numLayers, float parallaxScale, out float2 Out)
{
    Out = ParallaxOcclusionMapping(heightTex.tex, heightTexSampler.samplerstate, viewDirTS, uv, numLayers, parallaxScale);
}


void SSRRayMarch_float(UnityTexture2D depthTexture, UnitySamplerState depthSampler, float3 posWS, float3 normalWS, float3 viewWS,
                       float sampleStep, float maxSampleCount, out float3 Out)
{
    Out = SSRRayMarch(depthTexture.tex, depthSampler.samplerstate, posWS, normalWS, viewWS, sampleStep, maxSampleCount);
}
