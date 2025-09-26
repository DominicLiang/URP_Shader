// URP的shader的结构
// 关键字不分大小写
Shader "Custom/01-WriteShader/01_Base" // shader最外层块 后面跟菜单层级

{
  Properties
  {
    // 通过材质面板传入的属性

    // 属性格式 变量名 ("显示名可以用中文", 变量类型) = 默认值 注意最后不需要跟分号
    _MainTex ("Main Texture", 2D) = "white" { }
    _MainColor ("Main Color", Color) = (1, 0, 0, 1)
    _ColorIntensity ("Color Intensity", float) = 1
  }

  SubShader
  {
    // 子着色器 可以有多个 但是只会执行一个 用来适配不同的画质配置

    // ! 如果LOD相同 优先执行上面的subshader
    LOD 200 // 渲染精度 用于在外部配置使用哪一个subshader 会执行LOD能支持的最高级别的subshader

    Tags
    {
      // ! 队列 优先级比RenderType高 有Queue的话RenderType不写也没问题
      // 渲染顺序 如果天空盒是纯色 那么最先渲染天空盒 如果天空盒不是纯色 最后渲染
      // <= 2500 不透明 先渲染靠近相机的物体 有深度测试
      // > 2500 透明 先渲染远离相机的物体 无深度测试
      // 默认队列 Background 1000 Geometry 2000 AlphaTest 2450 Transparent 3000 Overlay 4000
      "Queue" = "Geometry" // ! 后面可以接 + N 如 "Geometry+3"

      // ! 着色器分类 尽量用Queue 这个优先级低
      // 用于后处理或Shader替换 内置值包括 "Opaque" "Transparent" "Background" "Overlay"等
      "RenderType" = "Opaque"

      // ! "True" / "False" 禁止物体投射阴影
      "ForceNoShadowCasting" = "False"

      // ! "True" / "False" / "LODFading" 禁用动态批处理（保留模型空间信息）
      "DisableBatching" = "False"

      // ! "True" / "False" 忽略投影器效果（常用于半透明物体）
      "IgnoreProjector" = "False"

      // ! "True" / "False" 指定Sprite是否参与图集合并
      "CanUseSpriteAtlas" = "False"

      // ! 材质预览形状 可选 "Plane" "Sphere" "Skybox"
      "PreviewType" = "Sphere"

      // ! 在项目设置 图形和质量两个选项卡都可以设置渲染管线 质量里面的设置会覆盖图形的设置 如果质量没有设置渲染管线就不会覆盖
      "RenderPipeline" = "UniversalPipeline" // ! 指定渲染管线为URP 如果不指定 内置渲染管线也能用
    }

    pass
    {

      Tags
      {
        // ! URP的LightMode类型 URP会在有需要时才执行
        // ShadowCaster
        // DepthOnly => 输出 _CameraDepthTexture
        // DepthNormals => 输出 _CameraDepthTexture + CameraNormalsTexture
        // Meta 光照贴图
        // Universal2D
        // SRPDefaultUnlit 兼容老代码 如果没指定lightmode 会默认为是这个 可以作为多pass使用 只能使用一次
        "LightMode" = "UniversalForward" // ! pass标志 前向渲染
      }

      // ! 以下的项目和模版测试写在subshader和pass里都可以 写在subshader里应用于所有pass 写在pass里只有那个pass有效

      // ! 渲染剔除 可选 Front Back Off
      Cull Back

      // ! 深度测试 可选 LEqual Less Greater GEqual Equal NotEqual Always Never
      ZTest LEqual

      // ! 深度写入 可选 On Off
      ZWrite On

      // ! 半透明
      // 1 ZWrite关闭
      // 2 需要确保半透明物体是从后往前渲染 且在所有不透明物体渲染完毕后渲染

      // ! 颜色混合 只有支持透明度的着色器才有效 默认使用加法混合 使用BlendOp可以修改计算方法
      // ! Blend 源颜色(当前片元的颜色) 目标颜色(缓冲区已存在的颜色)
      // 透明物体渲染的渲染是先渲染远离摄像机的物体
      // 所以可以理解为源颜色(当前物体颜色) 目标颜色(距离摄像机比当前物体远的物体的颜色)
      // ! 可选 :
      // One 权重为1 完全保留颜色（源或目标）
      // Zero 权重为0 完全丢弃颜色（源或目标）
      // SrcColor 使用源颜色的RGB值作为权重（逐通道相乘）
      // SrcAlpha 使用源颜色的Alpha值作为权重（所有通道乘以同一个Alpha）
      // DstColor 使用目标颜色的RGB值作为权重（逐通道相乘）
      // DstAlpha 使用目标颜色的Alpha值作为权重（所有通道乘以同一个Alpha）
      // OneMinusSrcColor 使用1减去源颜色的RGB值作为权重（逐通道计算）
      // OneMinusSrcAlpha 使用1减去源Alpha值作为权重（标准透明混合的DstFactor）
      // OneMinusDstColor 使用1减去目标颜色的RGB值作为权重（逐通道计算）
      // OneMinusDstAlpha 使用1减去目标Alpha值作为权重
      //
      // ! 常用 :
      // Blend SrcAlpha OneMinusSrcAlpha 传统透明度
      // Blend One OneMinusSrcAlpha 预乘透明度
      // Blend One One 叠加
      // Blend OneMinusDstColor One 柔和叠加
      // Blend DstColor Zero 正片叠底
      // Blend DstColor SrcColor 两倍正片叠底
      Blend SrcAlpha OneMinusSrcAlpha

      // ! 颜色混合的计算符 不写默认加法
      // ! 可选 :
      // ​Add​ 默认模式，源颜色与目标颜色按因子加权相加（标准透明 / 加法混合）
      // ​Subtract​ 源颜色减去目标颜色（负值会被截断为0）
      // ​RevSubtract​ 目标颜色减去源颜色（反向减法）
      // ​Min​ 取源颜色和目标颜色的较小值（逐通道比较）
      // ​Max​ 取源颜色和目标颜色的较大值（逐通道比较）
      // ​LogicalClear​ 逻辑操作：清除结果为0（仅DX11.1支持）
      // ​LogicalSet​ 逻辑操作：强制设置为1（仅DX11.1支持）
      // ​LogicalCopy​ 逻辑操作：直接复制源颜色（仅DX11.1支持）
      // ​LogicalNoop​ 逻辑操作：保留目标颜色不变（仅DX11.1支持）
      // ​LogicalAnd​ 逻辑操作：源颜色与目标颜色按位与（仅DX11.1支持）
      // ​LogicalOr​ 逻辑操作：源颜色与目标颜色按位或（仅DX11.1支持）
      // ​LogicalXor​ 逻辑操作：源颜色与目标颜色按位异或（仅DX11.1支持）
      BlendOp Add

      HLSLPROGRAM // URP使用的是hlsl 要用宏包住

      #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" // 引用文件 可以理解为c#的using
      // Packages / com.unity.render - pipelines.universal / ShaderLibrary / Core.hlsl URP自带的shader可用API

      #pragma vertex vert // 定义顶点着色器 格式 #pragma 关键字 方法名(自定义, 大多用vert)
      #pragma fragment frag // 定义片元着色器 格式 #pragma 关键字 方法名(自定义, 大多用frag)

      // ! Properties中的属性要先声明才能使用
      TEXTURE2D(_MainTex); // ! 声明贴图 必须全大写
      SAMPLER(sampler_MainTex); // ! 声明采样器 必须全大写
      float4 _MainColor;
      float _ColorIntensity;

      // ! 这是URP自带的输入结构体 不需要写 直接用就行了
      // struct InputData
      // {
      //   float3 positionWS;// 世界空间顶点坐标
      //   float4 positionCS;// 裁切空间顶点坐标
      //   float3 normalWS;// 世界空间法线（经逐像素归一化）
      //   half3 viewDirectionWS;// 世界空间视角方向（已归一化）
      //   float4 shadowCoord; // 阴影坐标（根据是否启用阴影插值器动态生成）
      //   half fogCoord;// 雾效系数 控制顶点到相机的距离对雾浓度的影响
      //   half3 vertexLighting;  // 逐顶点光照贡献（非PBR光照补充）
      //   half3 bakedGI; // 烘焙全局光照数据（通过SAMPLE_GI采样）
      //   float2 normalizedScreenSpaceUV;
      //   half4 shadowMask; // 阴影遮罩（用于混合实时与烘焙阴影）
      //   half3x3 tangentToWorld; // 切线空间到世界空间的旋转矩阵 用于法线贴图计算
      //   #if defined(DEBUG_DISPLAY)
      //     half2 dynamicLightmapUV;
      //     half2 staticLightmapUV;
      //     float3 vertexSH;
      //     half3 brdfDiffuse;
      //     half3 brdfSpecular;
      //     float2 uv;
      //     uint mipCount;
      //     // texelSize :
      //     // x = 1 / width
      //     // y = 1 / height
      //     // z = width
      //     // w = height
      //     float4 texelSize;
      //     // mipInfo :
      //     // x = quality settings minStreamingMipLevel
      //     // y = original mip count for texture
      //     // z = desired on screen mip level
      //     // w = loaded mip level
      //     float4 mipInfo;
      //   #endif
      // };


      struct appdata
      {
        // 顶点着色器输入结构体

        float3 pos : POSITION; // 格式 字段类型 字段名(自定义) : 字段语义(系统固定)
        float2 uv : TEXCOORD0; // ! 申请uv

        // ! 所有可以申请的数据
        // float4 positionOS : POSITION;   // 物体空间顶点坐标（必需）
        // float3 normalOS : NORMAL;        // 物体空间法线向量
        // float4 tangentOS : TANGENT;      // 物体空间切线（w分量存储副切线方向

        // // 最多支持TEXCOORD7（URP 2025扩展至8通道）
        // float2 uv : TEXCOORD0;           // 主UV坐标（通道0）
        // float2 uv1 : TEXCOORD1;          // 第二组UV坐标
        // float2 uv2 : TEXCOORD2;          // 第三组UV坐标
        // float2 lightmapUV : TEXCOORD3;   // 光照贴图UV（需启用Lightmapping）
        // float4 shadowCoord : TEXCOORD4;  // 阴影坐标（需启用阴影接收）
        // float3 viewDirOS : TEXCOORD5;    // 物体空间视角方向（自定义用途）
        // float4 screenPos : TEXCOORD6;    // 屏幕空间位置（后处理常用）

        // float4 color : COLOR;

        // uint instanceID : SV_InstanceID; // GPU实例化ID（需启用#pragma multi_compile_instancing）
        // UNITY_VERTEX_INPUT_INSTANCE_ID   // 实例化宏（自动处理实例化数据）

      };

      struct v2f
      {
        // 顶点着色器的输出结构体 对应片元着色器输入

        float4 pos : SV_POSITION; // 格式 字段类型 字段名(自定义) : 字段语义(系统固定)
        float2 uv : TEXCOORD0; // ! 申请uv

      };

      v2f vert(appdata IN)
      {
        // 顶点着色器方法

        v2f OUT = (v2f)0; // 初始化输出结构体

        OUT.pos = mul(UNITY_MATRIX_MVP, float4(IN.pos, 1)); // ! 对象空间顶点转换到投影空间

        OUT.uv = IN.uv;

        return OUT;
      }

      float4 frag(v2f IN) : SV_TARGET // ! 返回值得用SV_TARGET

      {
        // 片元着色器方法

        // ! 采样贴图 调用的方法必须必须全大写
        float4 mainTexColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);

        return mainTexColor * _MainColor * _ColorIntensity;
      }

      ENDHLSL
    }
  }

  SubShader
  {
    // 低配subshader 测试用

    LOD 100

    pass
    {
      HLSLPROGRAM

      #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

      #pragma vertex vert
      #pragma fragment frag

      struct appdata
      {
        float3 pos : POSITION;
      };

      struct v2f
      {
        float4 pos : SV_POSITION;
      };

      v2f vert(appdata IN)
      {
        v2f OUT = (v2f)0;
        OUT.pos = mul(UNITY_MATRIX_MVP, float4(IN.pos, 1));
        return OUT;
      }

      float4 frag(v2f IN) : SV_TARGET
      {
        return float4(0, 1, 0, 1);
      }

      ENDHLSL
    }
  }

  Fallback "Hidden/Universal Render Pipeline/FallbackError" // 填写故障情况下的最保守shader的pass路径和名称
  // Hidden / Universal Render Pipeline / FallbackError URP默认的错误shader 显示紫色
  // Packages / com.unity.render - pipelines.universal / Shaders / Utils / FallbackError.shader

}