Shader "Custom/Normal/UnlitColor"
{
  Properties
  {
    // ! -------------------------------------
    // ! 面板属性
    _MainColor ("主颜色", Color) = (0, 0, 0, 0)
  }
  
  SubShader
  {
    LOD 100

    // ! -------------------------------------
    // ! Tags
    Tags
    {
      "Queue" = "Geometry"
      "RenderPipeline" = "UniversalPipeline"
    }

    Fog
    {
      Mode Off
    }
    Color [_MainColor]

    Pass { }
  }

  // ! -------------------------------------
  // ! 紫色报错fallback
  Fallback "Hidden/Universal Render Pipeline/FallbackError"
}
