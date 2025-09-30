// * 随机函数 -----------------------------

float RandomFromUV(float2 uv)
{
    return frac(sin(dot(uv, float2(12.9898, 78.233))) * 43758.5453);
}

float Random(float seed)
{
    return frac(sin(dot(seed.xx, float2(12.9898, 78.233))) * 43758.5453);
}

float RandomRange(float seed, float min, float max)
{
    return lerp(min, max, Random(seed));
}

float2 RandomVector2(float seed)
{
    float2 dir;
    dir.x = Random(seed) * 2.0 - 1.0;
    dir.y = Random(seed + 1.0) * 2.0 - 1.0;
    return normalize(dir);
}

float3 RandomVector3(float seed)
{
    float3 dir;
    dir.x = Random(seed) * 2.0 - 1.0;
    dir.y = Random(seed + 1.0) * 2.0 - 1.0;
    dir.z = Random(seed + 2.0) * 2.0 - 1.0;
    return normalize(dir);
}

// * 重要函数 -----------------------------

// 软粒子 物体交接
float SoftParticle(float eyeDepth, float4 screenPosition)
{
    return saturate(eyeDepth - screenPosition.w);
}

// 透明物体通过下面物体的深度重构下面物体的世界坐标
float3 ReconstructWorldPositionFromDepth(float eyeDepth, float3 positionVS)
{
    float4 objectPositionVS = 1;
    objectPositionVS.xy = (eyeDepth / -positionVS.z) * positionVS.xy;
    objectPositionVS.z = eyeDepth;
    float3 positionWS = mul(unity_CameraToWorld, objectPositionVS).xyz;
    return positionWS;
}

// 公告板 传入positionOS 传出公告板效果后的positionOS
float3 Billboard(float3 positionOS)
{
    float3 rightDir = UNITY_MATRIX_MV[0].xyz;
    float3 upDir = UNITY_MATRIX_MV[1].xyz;
    float3 forwardDir = UNITY_MATRIX_MV[2].xyz;

    //  缩放适应
    float3 vNorm;
    vNorm.x = positionOS.x / length(rightDir);
    vNorm.y = positionOS.y / length(upDir);
    vNorm.z = positionOS.z / length(forwardDir);

    return rightDir * vNorm.x + upDir * vNorm.y + forwardDir * vNorm.z;
}

// MatCapUV
float2 MatCapUV(float3 positionVS, float3 normalOS)
{
    float3 posVS = normalize(positionVS);
    float3 normalVS = mul(UNITY_MATRIX_IT_MV, normalOS);
    float3 vcn = cross(posVS, normalVS);
    float2 uv = float2(-vcn.y, vcn.x);
    return uv * 0.5 + 0.5;
}

// 快速SSS
float3 QuickSSS(float3 L, float3 N, float3 V, float thickness, float normalDistort, float power, float strength)
{
    float3 LN = normalize(L + N * normalDistort);
    // 效果核心 dot(V,-L) 背光
    // 加上N来扰动L 使背光更自然
    float sss = pow(saturate(dot(V, -LN)), power) * strength;
    sss *= thickness;
    return sss;
}

// 视差贴图
float2 ParallaxOcclusionMapping(Texture2D heightTex, SamplerState heightTexSampler, float3 viewDirTS, float2 uv, int numLayers,
                                float parallaxScale)
{
    // 切线空间视方向
    float3 viewDir = normalize(viewDirTS);

    // 层的高度值(初始数最大值)
    float currentLayerHeight = 1.0;
    // 单层歩进的高度
    float layerStep = currentLayerHeight / numLayers;

    // uv最大偏移值
    float2 maxOffset = viewDir.xy / viewDir.z * parallaxScale;
    // 单步uv偏移值
    float2 offsetStep = maxOffset / numLayers;

    // 初始化
    float2 currentUV = uv + maxOffset;
    float2 finalUV = uv;
    float mapHeight = saturate(SAMPLE_TEXTURE2D(heightTex, heightTexSampler, currentUV).r);

    // 开始一步步逼近 直到找到步进点比高度图低(看不到)
    UNITY_LOOP
    for (int i = 0; i < numLayers; i++)
    {
        if (currentLayerHeight <= mapHeight)
        {
            break;
        }
        currentUV -= offsetStep;
        mapHeight = saturate(SAMPLE_TEXTURE2D(heightTex, heightTexSampler, currentUV).r);
        currentLayerHeight -= layerStep;
    }

    // 计算 h1 和 h2
    float2 uvPrev = currentUV + offsetStep;
    float prevMapHeight = saturate(SAMPLE_TEXTURE2D(heightTex, heightTexSampler, uvPrev).r);
    float prevLayerHeight = currentLayerHeight + layerStep;
    float beforeHeight = prevLayerHeight - prevMapHeight; // h1
    float afterHeight = mapHeight - currentLayerHeight; // h2

    // 利用h1和h2得到权重,在两个红点间使用权重进行插值
    float weight = afterHeight / (afterHeight + beforeHeight);
    finalUV = lerp(uvPrev, currentUV, weight);

    return finalUV;
}

void SSRRayConvert(float3 posWS, out float4 posCS, out float3 screenPos)
{
    posCS = TransformWorldToHClip(posWS);
    // screenPos.xy = ComputeScreenPos(posCS).xy / posCS.w;
    float4 screenPosOrg = posCS * 0.5f;
    screenPosOrg.xy = float2(screenPosOrg.x, screenPosOrg.y * _ProjectionParams.x) + screenPosOrg.w;
    screenPos.xy = screenPosOrg.xy / posCS.w;
    screenPos.z = 1 / posCS.w;
}

// SSR
float3 SSRRayMarch(Texture2D depthTexture, SamplerState depthSampler, float3 posWS, float3 normalWS, float3 viewWS, float sampleStep,
                   float maxSampleCount)
{
    real3 R = normalize(reflect(-viewWS, normalWS));

    // 起点
    float4 startClipPos;
    float3 startScreenPos;
    SSRRayConvert(posWS, startClipPos, startScreenPos);

    // 终点
    float4 endClipPos;
    float3 endScreenPos;
    SSRRayConvert(posWS + R, endClipPos, endScreenPos);

    // 射线方向
    float3 screenDir = normalize(endScreenPos - startScreenPos);

    // 根据方向选择步长
    float screenDirX = abs(screenDir.x);
    float screenDirY = abs(screenDir.y);
    float dirXLength = 1 / (_ScreenParams.x * screenDirX);
    float dirYLength = 1 / (_ScreenParams.y * screenDirY);
    float isXLongerThenY = screenDirX > screenDirY;
    float dirMultiplier = lerp(dirYLength, dirXLength, isXLongerThenY) * sampleStep; // 10

    screenDir *= dirMultiplier; // 每一次步进视锥范围的1/_SSRSampleStep的距离

    // 采样次数（带有抖动）
    half sampleCount = 1 + RandomFromUV(startClipPos) * 0.1;

    // 起始射线深度
    half lastRayDepth = startClipPos.w;
    // 用前一次步进的终点作为下一次步进的起点
    float3 lastScreenMarchUVZ = startScreenPos;
    float lastDeltaDepth = 0;

    UNITY_LOOP
    for (int i = 0; i < maxSampleCount; i++)
    {
        // 计算本次采样的屏幕空间位置
        float3 screenMarchUVZ = startScreenPos + screenDir * sampleCount;

        // 如果超出屏幕范围，则退出循环
        if ((screenMarchUVZ.x <= 0) ||
            (screenMarchUVZ.x >= 1) ||
            (screenMarchUVZ.y <= 0) ||
            (screenMarchUVZ.y >= 1))
        {
            break;
        }
        float depth = SAMPLE_DEPTH_TEXTURE(depthTexture, depthSampler, screenMarchUVZ.xy).r;
        float sceneDepth = LinearEyeDepth(depth, _ZBufferParams);

        // 计算射线深度
        // rayDepth代表从当前像素位置到近裁剪面的距离（摄像机空间）
        half rayDepth = 1.0 / screenMarchUVZ.z; // screenMarchUVZ.z == 1/clipPos.w，因此rayDepth=clipPos.w

        // 计算场景物体和反射向量当前步进位置的深度差
        half deltaDepth = rayDepth - sceneDepth;

        // 如果深度差小于一定范围，说明反射向量“撞到”场景物体了，返回该点屏幕uv即可
        //（用于后续通过该屏幕uv采样场景颜色，作为该点反射颜色）
        bool isInsideObject = deltaDepth > 0;
        bool isStartInside = sceneDepth > startClipPos.w;
        bool isCloseToObject = deltaDepth < abs(rayDepth - lastRayDepth) * 2;
        if (isInsideObject && isStartInside && isCloseToObject)
        {
            float samplePercent = saturate(lastDeltaDepth / (lastDeltaDepth - deltaDepth));
            samplePercent = lerp(samplePercent, 1, rayDepth >= _ProjectionParams.z);
            float3 hitScreenUVZ = lerp(lastScreenMarchUVZ, screenMarchUVZ, samplePercent);
            return float3(hitScreenUVZ.xy, 1);
        }

        lastRayDepth = rayDepth;
        sampleCount += 1;

        lastScreenMarchUVZ = screenMarchUVZ;
        lastDeltaDepth = deltaDepth;
    }

    float4 farClipPos;
    float3 farScreenPos;

    SSRRayConvert(posWS + R * 100000, farClipPos, farScreenPos);

    if ((farScreenPos.x > 0) && (farScreenPos.x < 1) && (farScreenPos.y > 0) && (farScreenPos.y < 1))
    {
        float depth = SAMPLE_DEPTH_TEXTURE(depthTexture, depthSampler, farScreenPos.xy).r;
        float farDepth = LinearEyeDepth(depth, _ZBufferParams);

        if (farDepth > startClipPos.w)
        {
            return float3(farScreenPos.xy, 1);
        }
    }

    return float3(0, 0, 0);
}
