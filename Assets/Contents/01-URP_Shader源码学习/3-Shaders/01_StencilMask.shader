Shader "Custom/01-WriteShader/01_StencilMask"
{
  Properties
  {
    _WriteValue ("写入模版缓冲区的值", int) = 1
  }

  SubShader
  {
    LOD 200
    
    Tags
    {
      "Queue" = "Geometry-1"  // ! 重点 遮罩物体必须比显示物体的渲染队列更前 # 同队列先渲染也不行 必须是先渲染的队列
      "RenderPipeline" = "UniversalPipeline"
    }

    ZWrite Off // ! 遮罩透明所以ZWriteOff可以直接不显示 后面的顶点片元着色器可以直接不写 但是要有个pas

    pass
    {
      Tags
      {
        "LightMode" = "UniversalForward"
      }

      // ! 模版测试遮罩
      Stencil
      {
        // ! 模版测试默认值为0

        // ! Ref 1 <= = 直接写值不需要方括号 如果是引用值需要方括号
        Ref [_WriteValue]
        // ! Comp 模版测试对比方法
        // ​Always​ 始终通过测试，不比较（默认值） 示例：Comp Always
        // ​Never​ 始终拒绝测试，所有像素被丢弃 示例：Comp Never
        // ​Equal​ 仅当 (Ref & ReadMask) == (StencilBufferValue & ReadMask) 时通过 应用场景：实现遮罩镂空效果。
        // ​NotEqual​ 与 Equal 相反，值不相等时通过 示例：Comp NotEqual
        // ​Less​ 参考值小于缓冲区值时通过（Ref < StencilBufferValue）
        // ​LessEqual​ 参考值小于或等于时通过（Ref <= StencilBufferValue）
        // ​Greater​ 参考值大于缓冲区值时通过（Ref > StencilBufferValue）
        // ​GreaterEqual​ 参考值大于或等于时通过（Ref >= StencilBufferValue）
        Comp Always
        // ! Pass 模版测试通过时执行的操作
        // ​Keep​ 保留当前模板缓冲区的值（默认值） 示例：Pass Keep
        // ​Zero​ 将模板缓冲区的值设为0 示例：Pass Zero
        // ​Replace​ 用参考值（Ref）替换模板缓冲区的值 典型应用：标记特定区域（如遮罩写入） 示例：Pass Replace
        // ​IncrSat​ 递增模板缓冲区的值 但不超过最大值255 示例：Pass IncrSat
        // ​DecrSat​ 递减模板缓冲区的值 但不低于0 示例：Pass DecrSat
        // ​Invert​ 按位反转模板缓冲区的值（逐位取反） 示例：Pass Invert
        // ​IncrWrap​ 递增模板缓冲区的值 超过255时回绕到0 示例：Pass IncrWrap
        // ​DecrWrap​ 递减模板缓冲区的值 低于0时回绕到255 示例：Pass DecrWrap
        Pass Replace
        // ! Fail 模版测试失败时执行的操作
        // 可执行的操作同上
        Fail Keep
        // ! ZFail 用于定义当模板测试通过但深度测试失败时对模板缓冲区的操作方式
        // 可执行的操作同上
        ZFail Keep
      }
    }
  }
}