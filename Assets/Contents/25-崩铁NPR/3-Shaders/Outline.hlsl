// ! -------------------------------------
// ! 材质关键字

// ! -------------------------------------
// ! 顶点着色器输入
struct appdata
{
  float3 positionOS : POSITION;

  float3 normalOS : NORMAL;
  float4 tangentOS : TANGENT;
  float4 color : COLOR;
  float2 uv1 : TEXCOORD0;
  float2 uv2 : TEXCOORD1;
};


// ! -------------------------------------
// ! 顶点着色器输出 片元着色器输入
struct v2f
{
  real2 uv : TEXCOORD0;
  real4 positionCS : SV_POSITION;
};

// ! -------------------------------------
// ! 顶点着色器
v2f vert(appdata v)
{
  v2f o = (v2f)0;

  real3 dist = distance(mul(UNITY_MATRIX_M, real4(v.positionOS, 1)), _WorldSpaceCameraPos);
  dist = lerp(1, dist, 0.5);

  real3 offset = _OutlineWidth * 0.01 * v.normalOS.xyz * v.color.a * dist;

  v.positionOS.xyz += offset;

  VertexPositionInputs vertexInputs = GetVertexPositionInputs(v.positionOS);

  o.positionCS = vertexInputs.positionCS;

  return o;
}

// ! -------------------------------------
// ! 片元着色器
real4 frag(v2f i) : SV_TARGET
{
  real dither;
  real4 screenPosition = i.positionCS / GetScaledScreenParams();
  Unity_Dither_float(_DitherAlpha * 2, screenPosition, dither);
  clip(dither - _AlphaTestThreshold);
  return _OutlineColor;
}