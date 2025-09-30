Shader "Custom/FullScreen/Template"
{
    Properties
    {
        [HDR] _Color1("颜色1",Color)= (1,1,1,1)
        [HDR] _Color2("颜色2",Color)= (1,1,1,1)
        _StarSize("星星大小",Float)=0.05
        _StarStep("星星阈值",Float)=0.5
    }

    SubShader
    {
        LOD 100

        // ! -------------------------------------
        // ! Tags
        Tags
        {
            "Queue" = "Overlay"
            "RenderPipeline" = "UniversalPipeline"
        }

        HLSLINCLUDE
        // ! -------------------------------------
        // ! 全shader include
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"
        #include "Assets/ShaderLibrary/Utility/Node.hlsl"

        // ! -------------------------------------
        // ! 变量声明
        real4 _Color1;
        real4 _Color2;
        real _StarSize;
        real _StarStep;
        real _CircleSize;
        real _CircleSmooth;
        ENDHLSL

        Pass
        {
            // ! -------------------------------------
            // ! Pass名
            Name "BasePass"

            // ! -------------------------------------
            // ! tags
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            // ! -------------------------------------
            // ! 渲染状态
            Cull Off
            ZWrite Off

            HLSLPROGRAM
            // ! -------------------------------------
            // ! pass include

            // ! -------------------------------------
            // ! Shader阶段
            #pragma vertex Vert
            #pragma fragment frag

            // ! -------------------------------------
            // ! 材质关键字

            real Star(real2 uv, float w, float r)
            {
                uv = abs(uv);
                return length(uv - min(uv.x + uv.y, w) * 0.5) - r;
            }


            float2 Unity_Rotate_Degrees_float(float2 UV, float2 Center, float Rotation)
            {
                Rotation = Rotation * (3.1415926f / 180.0f);
                UV -= Center;
                float s = sin(Rotation);
                float c = cos(Rotation);
                float2x2 rMatrix = float2x2(c, -s, s, c);
                rMatrix *= 0.5;
                rMatrix += 0.5;
                rMatrix = rMatrix * 2 - 1;
                UV.xy = mul(UV.xy, rMatrix);
                UV += Center;
                return UV;
            }

            // ! -------------------------------------
            // ! 片元着色器
            real4 frag(Varyings input) : SV_TARGET
            {
                real2 uv = input.texcoord.xy;

                real aspect = _ScaledScreenParams.x / _ScaledScreenParams.y;
                real2 aspectXY = real2(1, aspect);

                real2 Size = real2(2, 1);
                uv *= Size;
                uv *= 8;
                real2 id = floor(uv);
                real randomValueX = RandomFromUV(id * 3.1415926) - 0.5;
                real randomValueY = RandomFromUV(id * 656.45644) - 0.5;
                real2 randomValue = real2(randomValueX, randomValueY);

                uv = frac(uv);

                real2 starUV = uv - 0.5;
                starUV += randomValue * 0.7;
                starUV = starUV / Size / aspectXY;
                starUV = Unity_Rotate_Degrees_float(starUV, real2(0, 0), 45);

                _StarSize *= randomValueX + 0.2;
                _StarSize *= sin(_Time.y * 2 + randomValueY * 565416.65465) * 0.5 + 0.5;
                real star = Star(starUV, _StarSize, 0.1);
                star = 1 - step(_StarStep, star);
                real circle = length(starUV);
                circle = smoothstep(_StarSize - 0.03, _StarStep, circle);

                real starShape = saturate(circle + star);

                real4 starColor = lerp(_Color1, _Color2, saturate(randomValueY)) * starShape;
                starColor = lerp(0, starColor, sin(_Time.y * 2 + randomValueY * 565416.65465) * 0.5 + 0.5);

                real4 color = SAMPLE_TEXTURE2D(_BlitTexture, sampler_LinearClamp, input.texcoord.xy);
                color += starColor;

                return color;
            }
            ENDHLSL
        }
    }

    // ! -------------------------------------
    // ! 紫色报错fallback
    Fallback "Hidden/Universal Render Pipeline/FallbackError"
}