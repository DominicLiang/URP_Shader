Shader "91make.top/Unlit" 
{
    Properties
    {
        _MainTex ("MainTex", 2d) = "" {}
    }
    Subshader 
    { 
        Tags // 标签用于确定子着色器的渲染顺序和其他参数。请注意，以下由 Unity 识别的标签必须位于 SubShader 部分中，不能在 Pass 中！
        { 
            "Queue" = "Geometry"//Background|AlphaTest|Transparent|Overlay" 
            //"DisableBatching" = "True|False|LODFading"
            //"ForceNoShadowCasting" = "True"
            //"IgnoreProjector" = "True"
            //"CanUseSpriteAtlas" = "False"
            //"PreviewType" = "Plane|Skybox"
            "RenderPipeline" = "UniversalPipeline"
        }
        
        //LOD 100 // 100=VertexLit，通过外部脚本传入Shader.maximumLOD来限制能使用的Shader的LOD级别
        //states // 对所有pass都适用的状态
        //oldstates // 固定功能管线的状态
        Pass 
        { 
            Name "Unlit"
            Tags 
            { 
                "LightMode" = "UniversalForward"//|ForwardBase|ForwardAdd|Deferred|ShadowCaster|MotionVectors|PrepassBase|PrepassFinal|Vertex|VertexLMRGBM|VertexLM" 
                //"PassFlags" = "OnlyDirectional" // 在 ForwardBase 通道类型中使用时，此标志的作用是仅允许主方向光和环境光/光照探针数据传递到着色器。这意味着非重要光源的数据将不会传递到顶点光源或球谐函数着色器变量。请参阅前向渲染以了解详细信息
                //"RequireOptions" = "SoftVegetation"
            }
            //states|oldstates
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };
            
            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
            };
            
            // TODO: 变量定义
            sampler2D _MainTex;
            float4 _MainTex_ST;
            
            v2f vert (appdata v) // appdata_base | appdata_tan | appdata_full
            {
                v2f o;
                o.pos = TransformObjectToHClip(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }
            
            half4 frag (v2f i) : SV_Target
            {
                // 对纹理进行采样
                half4 col = tex2D(_MainTex, i.uv);
                return col;
            }
            ENDHLSL
            
        }
        //usepass
        //grabpass
    }
    //Fallback "Another Shader"
    //CustomEditor "ExtendFromShaderGUI" // Unity 将查找具有此名称并能扩展 ShaderGUI 的类。如果找到，则使用此着色器的所有材质都将使用此 ShaderGUI。有关示例，请参阅《自定义着色器 GUI》
}