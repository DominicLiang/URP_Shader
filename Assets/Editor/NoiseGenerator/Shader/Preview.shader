Shader "CustomRTNoise/Preview"
{
  Properties
  {
    _MainTex ("噪声图", 2D) = "white" { }
    _Brightness ("亮度", Range(0, 1)) = 0.5
    _Contrast ("对比度", Range(0, 1)) = 0.5
    // 0=R, 1=G, 2=B, 3=A
    _OutputR ("R通道", Float) = 0
    _OutputG ("G通道", Float) = 0
    _OutputB ("B通道", Float) = 0
  }

  SubShader
  {
    Blend One Zero

    Pass
    {
      Name "Preview"

      CGPROGRAM
      #include "UnityCustomRenderTexture.cginc"
      #pragma vertex CustomRenderTextureVertexShader
      #pragma fragment frag
      #pragma target 3.0

      sampler2D _MainTex;
      float _Brightness;
      float _Contrast;
      float _OutputR;
      float _OutputG;
      float _OutputB;



      float4 frag(v2f_customrendertexture IN) : SV_Target
      {
        float2 uv = IN.localTexcoord.xy;
        float4 color = tex2D(_MainTex, uv);
        _Brightness = _Brightness * 2 - 1;
        _Contrast = _Contrast * 2;
        color = (color - 0.5) * _Contrast + 0.5 + _Brightness;
        float r = color[_OutputR];
        float g = color[_OutputG];
        float b = color[_OutputB];
        return float4(r, g, b, 1);
      }
      ENDCG
    }
  }
}
