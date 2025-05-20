Shader "AudioLink/Internal/AudioLinkController"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Metallic ("Metallic", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" }
        LOD 200

        // Main pass
        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma shader_feature UNIVERSAL_RENDER_PIPELINE
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile_fog
            #pragma target 3.0

            #if UNIVERSAL_RENDER_PIPELINE
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #endif

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 uv           : TEXCOORD0;
                float3 normalOS     : NORMAL;
                float4 tangentOS    : TANGENT;
                #if UNIVERSAL_RENDER_PIPELINE
                UNITY_VERTEX_INPUT_INSTANCE_ID
                #endif
            };

            struct Varyings
            {
                float2 uv           : TEXCOORD0;
                float4 positionCS   : SV_POSITION;
                float3 positionWS   : TEXCOORD1;
                float3 normalWS     : TEXCOORD2;
                float4 shadowCoord  : TEXCOORD3;
                #if UNIVERSAL_RENDER_PIPELINE
                UNITY_VERTEX_OUTPUT_STEREO
                #endif
            };

            #if UNIVERSAL_RENDER_PIPELINE
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            TEXTURE2D(_Metallic);
            SAMPLER(sampler_Metallic);

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _Color;
            CBUFFER_END
            #endif

            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;

                #if UNIVERSAL_RENDER_PIPELINE
                UNITY_SETUP_INSTANCE_ID(v); //Insert
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o); //Insert
                // Transform position and normals
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);

                output.positionCS = vertexInput.positionCS;
                output.positionWS = vertexInput.positionWS;
                output.normalWS = normalInput.normalWS;
                output.uv = TRANSFORM_TEX(input.uv, _MainTex);

                // Get shadow coordinates
                output.shadowCoord = GetShadowCoord(vertexInput);
                #endif

                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                #if UNIVERSAL_RENDER_PIPELINE
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                // Sample textures
                half4 c = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv) * _Color;
                half4 b = SAMPLE_TEXTURE2D(_Metallic, sampler_Metallic, input.uv);

                // Setup standard PBR inputs
                float3 normalWS = normalize(input.normalWS);
                float3 viewDirWS = normalize(GetWorldSpaceViewDir(input.positionWS));

                // Create InputData for URP's fragment lighting function
                InputData inputData;
                inputData.positionWS = input.positionWS;
                inputData.normalWS = normalWS;
                inputData.viewDirectionWS = viewDirWS;
                inputData.shadowCoord = TransformWorldToShadowCoord(input.positionWS);
                inputData.fogCoord = ComputeFogFactor(input.positionCS.z);
                inputData.vertexLighting = half3(0, 0, 0);
                inputData.bakedGI = SampleSH(normalWS);
                inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
                inputData.shadowMask = half4(1, 1, 1, 1);

                // Setup SurfaceData for URP PBR lighting
                SurfaceData surfaceData;
                surfaceData.albedo = c.rgb;
                surfaceData.metallic = b.r;
                surfaceData.specular = half3(0, 0, 0);
                surfaceData.smoothness = b.a;
                surfaceData.occlusion = b.g;
                surfaceData.emission = half3(0, 0, 0);
                surfaceData.alpha = c.a;
                surfaceData.clearCoatMask = 0;
                surfaceData.clearCoatSmoothness = 0;
                surfaceData.normalTS = half3(0, 0, 1);

                // Use URP's standard lighting function
                half4 color = UniversalFragmentPBR(inputData, surfaceData);

                // Apply fog
                color.rgb = MixFog(color.rgb, inputData.fogCoord);

                return color;
                #else
                return (0).xxxx;
                #endif
            }
            ENDHLSL
        }

        // Shadow casting pass
        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }

            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull Back

            HLSLPROGRAM
            #pragma shader_feature UNIVERSAL_RENDER_PIPELINE
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0

            #if UNIVERSAL_RENDER_PIPELINE
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _Color;
            CBUFFER_END

            #else
            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 texcoord : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
            };

            #endif

            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;
                #if UNIVERSAL_RENDER_PIPELINE
                return ShadowPassVertex(input);
                #else
                return output;
                #endif
            }

            half4 frag(Varyings input) : SV_TARGET
            {
                #if UNIVERSAL_RENDER_PIPELINE
                return ShadowPassFragment(input);
                #else
                return 0;
                #endif
            }

            ENDHLSL
        }

        // Depth-only pass
        Pass
        {
            Name "DepthOnly"
            Tags { "LightMode" = "DepthOnly" }

            ZWrite On
            ColorMask 0
            Cull Back

            HLSLPROGRAM
            #pragma shader_feature UNIVERSAL_RENDER_PIPELINE
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0

            #if UNIVERSAL_RENDER_PIPELINE
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _Color;
            CBUFFER_END

            #else
            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 texcoord : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
            };

            #endif

            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;
                #if UNIVERSAL_RENDER_PIPELINE
                return DepthOnlyVertex(input);
                #else
                return output;
                #endif
            }

            half4 frag(Varyings input) : SV_TARGET
            {
                #if UNIVERSAL_RENDER_PIPELINE
                return DepthOnlyFragment(input);
                #else
                return 0;
                #endif
            }
            ENDHLSL
        }

        // DepthNormals pass
        Pass
        {
            Name "DepthNormals"
            Tags { "LightMode" = "DepthNormals" }

            ZWrite On
            Cull Back

            HLSLPROGRAM
            #pragma shader_feature UNIVERSAL_RENDER_PIPELINE
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0

            // This is a custom depth normals pass
            #if UNIVERSAL_RENDER_PIPELINE
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthNormalsPass.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _Color;
            CBUFFER_END

            #else
            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 texcoord : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
            };

            #endif

            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;
                #if UNIVERSAL_RENDER_PIPELINE
                return DepthNormalsVertex(input);
                #else
                return output;
                #endif
            }

            void frag(Varyings input, out half4 outNormalWS : SV_Target0
            #ifdef _WRITE_RENDERING_LAYERS
                , out float4 outRenderingLayers : SV_Target1
            #endif
            )
            {
                #if UNIVERSAL_RENDER_PIPELINE
                DepthNormalsFragment(input, outNormalWS
                    #ifdef _WRITE_RENDERING_LAYERS
                    , outRenderingLayers : SV_Target1
                    #endif
                );
                #else
                outNormalWS = (0).xxxx;
                #endif
            }
            ENDHLSL
        }
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows
        #pragma target 3.0

        sampler2D _MainTex;
        sampler2D _Metallic;
        float4 _Color;

        struct Input
        {
            float2 uv_MainTex;
        };

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            float4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
            float4 b = tex2D(_Metallic, IN.uv_MainTex);
            o.Metallic = b.r;
            o.Smoothness = b.a;
            o.Occlusion = b.g;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
