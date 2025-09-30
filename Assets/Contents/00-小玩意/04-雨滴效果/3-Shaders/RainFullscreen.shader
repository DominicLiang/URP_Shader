Shader "Custom/FullScreen/RainFullscreen"
{
    Properties
    {
        _DropSize("雨滴大小", Range(0, 0.1))= 0.06
        _DropSizeSmall("拖尾雨滴大小", Range(0, 0.1))= 0.04
        _TailXEdge1("拖尾X宽度1", Range(0, 1))= 0.05
        _TailXEdge2("拖尾X宽度2", Range(0, 1))= 0.05
        _DropIntensity("雨滴反射强度", Range(-0.5, 0))=-0.1

        _BlurOffset("模糊偏移量",Float)= 0.01
        _BlurIteration("模糊迭代次数",Float)=5
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
        #include "Assets/ShaderLibrary/PostProcessing/Blur.hlsl"
        #include "Assets/ShaderLibrary/Utility/Node.hlsl"

        // ! -------------------------------------
        // ! 变量声明
        real _DropSize;
        real _DropSizeSmall;
        real _DropIntensity;
        real _TailXEdge1;
        real _TailXEdge2;
        real _BlurOffset;
        real _BlurIteration;
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

            real EasingY(real x)
            {
                return sin(x + sin(x + 0.5 * sin(x)));
            }

            real EasingX(real x)
            {
                return pow(sin(x), 6) * sin(3 * x);
            }

            // ! -------------------------------------
            // ! 片元着色器
            real4 frag(Varyings input) : SV_TARGET
            {
                real2 uvScale = real2(2, 1);

                real aspect = _ScaledScreenParams.x / _ScaledScreenParams.y;
                real2 aspectXY = real2(1, aspect);

                real2 uv = input.texcoord.xy * uvScale;
                uv *= 4;
                uv.y += _Time.y * 0.5;
                real2 id = floor(uv);
                real randomValue = RandomFromUV(id) - 0.5;
                uv = frac(uv);

                real easingTimeX = EasingX((input.texcoord.xy.y + randomValue * 3.14 - 0.5) * 8) * 0.1 + randomValue * 0.5;
                real easingTimeY = EasingY(_Time.y + randomValue * 5465.556536) * 0.3;
                real2 easingTime = real2(easingTimeX, easingTimeY);

                real tailMaskY = smoothstep(0.45, 0.55, uv.y + easingTimeY);
                real tailMaskX = smoothstep(_TailXEdge1, _TailXEdge2, abs(uv.x + easingTimeX - 0.5));
                real tail = tailMaskX * tailMaskY * smoothstep(1, 0, uv.y);

                real2 uvSmallScale = real2(1, 6);
                real2 uvSmallDrop = uv * uvSmallScale;
                uvSmallDrop = frac(uvSmallDrop);
                uvSmallDrop -= 0.5;
                uvSmallDrop += easingTime;
                real2 smallCircleUV = uvSmallDrop / uvScale / uvSmallScale / aspectXY;
                real smallCircle = length(smallCircleUV);
                smallCircle = smoothstep(_DropSizeSmall, 0, smallCircle);
                smallCircle *= tail;

                real2 uvBigDrop = uv - 0.5;
                uvBigDrop += easingTime;
                real2 circleUV = uvBigDrop / uvScale / aspectXY;
                real circle = length(circleUV);
                circle = smoothstep(_DropSize, 0, circle);

                real drop = circle + smallCircle;
                real2 dropUV = (input.texcoord.xy - 0.5) * drop * _DropIntensity;
                dropUV += input.texcoord.xy;

                real4 color = SAMPLE_TEXTURE2D(_BlitTexture, sampler_LinearClamp, dropUV);
                real4 blurColor = GrainyBlur(_BlitTexture, sampler_LinearClamp, input.texcoord.xy, _BlurOffset, _BlurIteration) * 0.95;

                real blurMask = saturate(circle + smallCircle + tail * 5);
                color = lerp(blurColor, color, blurMask);

                return color;
            }
            ENDHLSL
        }
    }

    // ! -------------------------------------
    // ! 紫色报错fallback
    Fallback "Hidden/Universal Render Pipeline/FallbackError"
}