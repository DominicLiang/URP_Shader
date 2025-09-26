struct appdata
{
  real2 uv : TEXCOORD0;
  real4 positionOS : POSITION;
  real3 normalOS : NORMAL;
  real4 vertexColor : COLOR;
};

struct v2f
{
  real2 uv : TEXCOORD0;
  real4 positionCS : SV_POSITION;
  real3 positionWS : TEXCOORD1;
  real3 normalWS : TEXCOORD2;
};

v2f vert(appdata v)
{
  v2f o = (v2f)0;
  
  real3 normal = lerp(v.normalOS, _Gravity * _GravityStrength + v.normalOS * (1 - _GravityStrength), Fur_Factor);
  v.positionOS.xyz += normal * _FurFactor * Fur_Factor;

  VertexPositionInputs positionInputs = GetVertexPositionInputs(v.positionOS.xyz);
  VertexNormalInputs normalInputs = GetVertexNormalInputs(v.normalOS);
  
  o.uv = v.uv;

  o.positionCS = positionInputs.positionCS;
  o.positionWS = positionInputs.positionWS;
  o.normalWS = normalInputs.normalWS;

  return o;
}

real4 frag(v2f i) : SV_TARGET
{
  real4 baseColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);

  real edgeFade = 1 - (pow(Fur_Factor, 2));

  real3 viewDir = normalize(GetCameraPositionWS() - i.positionWS);
  real NoV = saturate(dot(i.normalWS, viewDir));

  edgeFade += NoV - _FurAlphaFactor;
  edgeFade = saturate(pow(edgeFade, 6));

  real endFade = 1 - Fur_Factor;
  baseColor.a *= endFade;
  baseColor.a *= _FurAlpha;
  baseColor.a *= edgeFade;

  return baseColor;
}