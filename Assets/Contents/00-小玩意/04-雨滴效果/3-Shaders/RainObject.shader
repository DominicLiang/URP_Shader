Shader "Custom/Normal/Rain"
{
    Properties
    {
        // ! -------------------------------------
        // ! 面板属性
        [NoScaleOffset]_MainTex ("主贴图", 2D) = "white" { }

        _DropSize("雨滴大小", Range(0, 0.1))= 0.06
        _DropSizeSmall("拖尾雨滴大小", Range(0, 0.1))= 0.04
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
            "Queue" = "Geometry"
            "RenderPipeline" = "UniversalPipeline"
        }

        HLSLINCLUDE
        // ! -------------------------------------
        // ! 全shader include
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Assets/ShaderLibrary/Utility/Node.hlsl"
        #include "Assets/ShaderLibrary/PostProcessing/Blur.hlsl"

        TEXTURE2D(_CameraOpaqueTexture);
        SAMPLER(sampler_CameraOpaqueTexture);

        CBUFFER_START(UnityPerMaterial)
            // ! -------------------------------------
            // ! 变量声明
            real _DropSize;
            real _DropSizeSmall;
            real _DropIntensity;
            real _BlurOffset;
            real _BlurIteration;

        CBUFFER_END
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
            Cull Back
            ZTest LEqual
            ZWrite On

            HLSLPROGRAM
            // ! -------------------------------------
            // ! pass include

            // ! -------------------------------------
            // ! Shader阶段
            #pragma vertex vert
            #pragma fragment frag

            // ! -------------------------------------
            // ! 材质关键字

            // ! -------------------------------------
            // ! 顶点着色器输入
            struct appdata
            {
                real2 uv : TEXCOORD0;
                real4 positionOS : POSITION;
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

                VertexPositionInputs positionInputs = GetVertexPositionInputs(v.positionOS.xyz);

                o.uv = v.uv;

                o.positionCS = positionInputs.positionCS;

                return o;
            }

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
            real4 frag(v2f i) : SV_TARGET
            {
                real2 uvScale = real2(2, 1);

                real2 uv = i.uv * uvScale;
                uv *= 4;
                uv.y += _Time.y * 0.5;
                real2 id = floor(uv);
                real randomValue = RandomFromUV(id) - 0.5;
                uv = frac(uv);

                real easingTimeX = EasingX((i.uv.y + randomValue * 3.14 - 0.5) * 8) * 0.1 + randomValue * 0.5;
                real easingTimeY = EasingY(_Time.y + randomValue * 5465.556536) * 0.3;
                real2 easingTime = real2(easingTimeX, easingTimeY);

                real tailMaskY = smoothstep(0.45, 0.55, uv.y + easingTimeY);
                real tailMaskX = smoothstep(0.12, 0.06, abs(uv.x + easingTimeX - 0.5));
                real tail = tailMaskX * tailMaskY * smoothstep(1, 0, uv.y);

                real2 uvSmallScale = real2(1, 6);
                real2 uvSmallDrop = uv * uvSmallScale;
                uvSmallDrop = frac(uvSmallDrop);
                uvSmallDrop -= 0.5;
                uvSmallDrop += easingTime;
                real2 smallCircleUV = uvSmallDrop / uvScale / uvSmallScale;
                real smallCircle = length(smallCircleUV);
                smallCircle = smoothstep(_DropSizeSmall, 0, smallCircle);
                smallCircle *= tail;

                real2 uvBigDrop = uv - 0.5;
                uvBigDrop += easingTime;
                real2 circleUV = uvBigDrop / uvScale;
                real circle = length(circleUV);
                circle = smoothstep(_DropSize, 0, circle);

                real drop = circle + smallCircle;
                real2 dropUV = (i.uv - 0.5) * drop * _DropIntensity;
                dropUV += i.uv;

                real4 color = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, dropUV);
                real4 blurColor = GrainyBlur(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, i.uv, _BlurOffset, _BlurIteration);

                real blurMask = circle + smallCircle + tail;
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