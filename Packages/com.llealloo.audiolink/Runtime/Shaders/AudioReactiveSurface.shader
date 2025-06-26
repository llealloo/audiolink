// Upgrade NOTE: upgraded instancing buffer 'AudioLinkSurfaceAudioReactiveSurface' to new syntax.

// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X
Shader "AudioLink/Surface/AudioReactiveSurface"
{
    Properties
    {
        _MainTex("Albedo", 2D) = "white" {}
        _Color("Color", Color) = (0.4980392,0.4980392,0.4980392,1)
        _Metallic("Metallic", Range( 0 , 1)) = 0
        _Smoothness("Smoothness", Range( 0 , 1)) = 0.5
        _BumpMap("Normal Map", 2D) = "bump" {}
        _BumpScale("Normal Scale", Float) = 1
        _EmissionMap("Emission Map", 2D) = "gray" {}
        [HDR]_EmissionColor("Emission Color", Color) = (0,0,0,1)
        _Emission("Emission Scale", Float) = 1
        [Header(Audio Section)][IntRange]_Band("Band", Range( 0 , 3)) = 0
        _Delay("Delay", Range( 0 , 1)) = 0
        [Header(Pulse Across UVs)]_Pulse("Pulse", Range( 0 , 1)) = 0
        _AudioHueShift("Audio Hue Shift", Float) = 0
        _PulseRotation("Pulse Rotation", Range( 0 , 360)) = 0
        [HideInInspector] _texcoord( "", 2D ) = "white" {}

        //_TransmissionShadow( "Transmission Shadow", Range( 0, 1 ) ) = 0.5
        //_TransStrength( "Trans Strength", Range( 0, 50 ) ) = 1
        //_TransNormal( "Trans Normal Distortion", Range( 0, 1 ) ) = 0.5
        //_TransScattering( "Trans Scattering", Range( 1, 50 ) ) = 2
        //_TransDirect( "Trans Direct", Range( 0, 1 ) ) = 0.9
        //_TransAmbient( "Trans Ambient", Range( 0, 1 ) ) = 0.1
        //_TransShadow( "Trans Shadow", Range( 0, 1 ) ) = 0.5
        //_TessPhongStrength( "Tess Phong Strength", Range( 0, 1 ) ) = 0.5
        //_TessValue( "Tess Max Tessellation", Range( 1, 32 ) ) = 16
        //_TessMin( "Tess Min Distance", Float ) = 10
        //_TessMax( "Tess Max Distance", Float ) = 25
        //_TessEdgeLength ( "Tess Edge length", Range( 2, 50 ) ) = 16
        //_TessMaxDisp( "Tess Max Displacement", Float ) = 25
        //[ToggleOff] _SpecularHighlights("Specular Highlights", Float) = 1.0
        //[ToggleOff] _GlossyReflections("Reflections", Float) = 1.0
    }

    SubShader
    {

        Tags
        {
            "RenderType"="Opaque" "Queue"="Geometry" "DisableBatching"="False"
        }
        LOD 0

        Cull Back
        AlphaToMask Off
        ZWrite On
        ZTest LEqual
        ColorMask RGBA

        Blend Off


        CGINCLUDE
        #pragma target 3.0

        float4 FixedTess(float tessValue)
        {
            return tessValue;
        }

        float CalcDistanceTessFactor(float4 vertex, float minDist, float maxDist, float tess, float4x4 o2w,
                                                                          float3 cameraPos)
        {
            float3 wpos = mul(o2w, vertex).xyz;
            float dist = distance(wpos, cameraPos);
            float f = clamp(1.0 - (dist - minDist) / (maxDist - minDist), 0.01, 1.0) * tess;
            return f;
        }

        float4 CalcTriEdgeTessFactors(float3 triVertexFactors)
        {
            float4 tess;
            tess.x = 0.5 * (triVertexFactors.y + triVertexFactors.z);
            tess.y = 0.5 * (triVertexFactors.x + triVertexFactors.z);
            tess.z = 0.5 * (triVertexFactors.x + triVertexFactors.y);
            tess.w = (triVertexFactors.x + triVertexFactors.y + triVertexFactors.z) / 3.0f;
            return tess;
        }

        float CalcEdgeTessFactor(float3 wpos0, float3 wpos1, float edgeLen, float3 cameraPos, float4 scParams)
        {
            float dist = distance(0.5 * (wpos0 + wpos1), cameraPos);
            float len = distance(wpos0, wpos1);
            float f = max(len * scParams.y / (edgeLen * dist), 1.0);
            return f;
        }

        float DistanceFromPlane(float3 pos, float4 plane)
        {
            float d = dot(float4(pos, 1.0f), plane);
            return d;
        }

        bool WorldViewFrustumCull(float3 wpos0, float3 wpos1, float3 wpos2, float cullEps, float4 planes[6])
        {
            float4 planeTest;
            planeTest.x = ((DistanceFromPlane(wpos0, planes[0]) > -cullEps) ? 1.0f : 0.0f) +
                ((DistanceFromPlane(wpos1, planes[0]) > -cullEps) ? 1.0f : 0.0f) +
                ((DistanceFromPlane(wpos2, planes[0]) > -cullEps) ? 1.0f : 0.0f);
            planeTest.y = ((DistanceFromPlane(wpos0, planes[1]) > -cullEps) ? 1.0f : 0.0f) +
                ((DistanceFromPlane(wpos1, planes[1]) > -cullEps) ? 1.0f : 0.0f) +
                ((DistanceFromPlane(wpos2, planes[1]) > -cullEps) ? 1.0f : 0.0f);
            planeTest.z = ((DistanceFromPlane(wpos0, planes[2]) > -cullEps) ? 1.0f : 0.0f) +
                ((DistanceFromPlane(wpos1, planes[2]) > -cullEps) ? 1.0f : 0.0f) +
                ((DistanceFromPlane(wpos2, planes[2]) > -cullEps) ? 1.0f : 0.0f);
            planeTest.w = ((DistanceFromPlane(wpos0, planes[3]) > -cullEps) ? 1.0f : 0.0f) +
                ((DistanceFromPlane(wpos1, planes[3]) > -cullEps) ? 1.0f : 0.0f) +
                ((DistanceFromPlane(wpos2, planes[3]) > -cullEps) ? 1.0f : 0.0f);
            return !all(planeTest);
        }

        float4 DistanceBasedTess(float4 v0, float4 v1, float4 v2, float tess, float minDist, float maxDist,
                                                float4x4 o2w, float3 cameraPos)
        {
            float3 f;
            f.x = CalcDistanceTessFactor(v0, minDist, maxDist, tess, o2w, cameraPos);
            f.y = CalcDistanceTessFactor(v1, minDist, maxDist, tess, o2w, cameraPos);
            f.z = CalcDistanceTessFactor(v2, minDist, maxDist, tess, o2w, cameraPos);

            return CalcTriEdgeTessFactors(f);
        }

        float4 EdgeLengthBasedTess(float4 v0, float4 v1, float4 v2, float edgeLength, float4x4 o2w, float3 cameraPos,
                               float4 scParams)
        {
            float3 pos0 = mul(o2w, v0).xyz;
            float3 pos1 = mul(o2w, v1).xyz;
            float3 pos2 = mul(o2w, v2).xyz;
            float4 tess;
            tess.x = CalcEdgeTessFactor(pos1, pos2, edgeLength, cameraPos, scParams);
            tess.y = CalcEdgeTessFactor(pos2, pos0, edgeLength, cameraPos, scParams);
            tess.z = CalcEdgeTessFactor(pos0, pos1, edgeLength, cameraPos, scParams);
            tess.w = (tess.x + tess.y + tess.z) / 3.0f;
            return tess;
        }

        float4 EdgeLengthBasedTessCull(float4 v0, float4 v1, float4 v2, float edgeLength, float maxDisplacement,
                    float4x4 o2w, float3 cameraPos, float4 scParams, float4 planes[6])
        {
            float3 pos0 = mul(o2w, v0).xyz;
            float3 pos1 = mul(o2w, v1).xyz;
            float3 pos2 = mul(o2w, v2).xyz;
            float4 tess;

            if (WorldViewFrustumCull(pos0, pos1, pos2, maxDisplacement, planes))
            {
                tess = 0.0f;
            }
            else
            {
                tess.x = CalcEdgeTessFactor(pos1, pos2, edgeLength, cameraPos, scParams);
                tess.y = CalcEdgeTessFactor(pos2, pos0, edgeLength, cameraPos, scParams);
                tess.z = CalcEdgeTessFactor(pos0, pos1, edgeLength, cameraPos, scParams);
                tess.w = (tess.x + tess.y + tess.z) / 3.0f;
            }
            return tess;
        }
        ENDCG


        Pass
        {
            Blend One Zero

            CGPROGRAM
            #define ASE_NEEDS_FRAG_SHADOWCOORDS
            #pragma multi_compile_instancing
            #pragma multi_compile __ LOD_FADE_CROSSFADE
            #pragma multi_compile_fog
            #define ASE_FOG 1

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            #ifndef UNITY_PASS_FORWARDBASE
            #define UNITY_PASS_FORWARDBASE
            #endif
            #include "HLSLSupport.cginc"
            #ifndef UNITY_INSTANCED_LOD_FADE
            #define UNITY_INSTANCED_LOD_FADE
            #endif
            #ifndef UNITY_INSTANCED_SH
            #define UNITY_INSTANCED_SH
            #endif
            #ifndef UNITY_INSTANCED_LIGHTMAPSTS
            #define UNITY_INSTANCED_LIGHTMAPSTS
            #endif
            #include "UnityShaderVariables.cginc"
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "UnityPBSLighting.cginc"
            #include "AutoLight.cginc"
            #include "Packages/com.llealloo.audiolink/Runtime/Shaders/AudioLink.cginc"

            #pragma multi_compile_instancing

            struct appdata
            {
                float4 vertex : POSITION;
                float4 tangent : TANGENT;
                float3 normal : NORMAL;
                float4 texcoord1 : TEXCOORD1;
                float4 texcoord2 : TEXCOORD2;
                float4 ase_texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                #if UNITY_VERSION >= 201810
					UNITY_POSITION(pos);
                #else
                float4 pos : SV_POSITION;
                #endif
                #if defined(LIGHTMAP_ON) || (!defined(LIGHTMAP_ON) && SHADER_TARGET >= 30)
					float4 lmap : TEXCOORD0;
                #endif
                #if !defined(LIGHTMAP_ON) && UNITY_SHOULD_SAMPLE_SH
					half3 sh : TEXCOORD1;
                #endif
                #if defined(UNITY_HALF_PRECISION_FRAGMENT_SHADER_REGISTERS) && UNITY_VERSION >= 201810 && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					UNITY_LIGHTING_COORDS(2,3)
                #elif defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
                #if UNITY_VERSION >= 201710
						UNITY_SHADOW_COORDS(2)
                #else
                SHADOW_COORDS(2)
                #endif
                #endif
                #ifdef ASE_FOG
                UNITY_FOG_COORDS(4)
                #endif
                float4 tSpace0 : TEXCOORD5;
                float4 tSpace1 : TEXCOORD6;
                float4 tSpace2 : TEXCOORD7;
                #if defined(ASE_NEEDS_FRAG_SCREEN_POSITION)
				float4 screenPos : TEXCOORD8;
                #endif
                float4 ase_texcoord9 : TEXCOORD9;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            #ifdef _TRANSMISSION_ASE
				float _TransmissionShadow;
            #endif
            #ifdef _TRANSLUCENCY_ASE
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
            #endif
            #ifdef TESSELLATION_ON
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
            #endif
            uniform sampler2D _MainTex;
            uniform float4 _Color;
            uniform sampler2D _BumpMap;
            uniform float _BumpScale;
            uniform sampler2D _EmissionMap;
            uniform float _Metallic;
            uniform float _Smoothness;
            UNITY_INSTANCING_BUFFER_START(AudioLinkSurfaceAudioReactiveSurface)
                UNITY_DEFINE_INSTANCED_PROP(float4, _BumpMap_ST)
                #define _BumpMap_ST_arr AudioLinkSurfaceAudioReactiveSurface
                UNITY_DEFINE_INSTANCED_PROP(float4, _EmissionMap_ST)
                #define _EmissionMap_ST_arr AudioLinkSurfaceAudioReactiveSurface
                UNITY_DEFINE_INSTANCED_PROP(float4, _EmissionColor)
                #define _EmissionColor_arr AudioLinkSurfaceAudioReactiveSurface
                UNITY_DEFINE_INSTANCED_PROP(float, _AudioHueShift)
                #define _AudioHueShift_arr AudioLinkSurfaceAudioReactiveSurface
                UNITY_DEFINE_INSTANCED_PROP(float, _Band)
                #define _Band_arr AudioLinkSurfaceAudioReactiveSurface
                UNITY_DEFINE_INSTANCED_PROP(float, _PulseRotation)
                #define _PulseRotation_arr AudioLinkSurfaceAudioReactiveSurface
                UNITY_DEFINE_INSTANCED_PROP(float, _Pulse)
                #define _Pulse_arr AudioLinkSurfaceAudioReactiveSurface
                UNITY_DEFINE_INSTANCED_PROP(float, _Delay)
                #define _Delay_arr AudioLinkSurfaceAudioReactiveSurface
                UNITY_DEFINE_INSTANCED_PROP(float, _Emission)
                #define _Emission_arr AudioLinkSurfaceAudioReactiveSurface
            UNITY_INSTANCING_BUFFER_END(AudioLinkSurfaceAudioReactiveSurface)


            float3 HSVToRGB(float3 c)
            {
                float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
                float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
                return c.z * lerp(K.xxx, saturate(p - K.xxx), c.y);
            }

            float3 RGBToHSV(float3 c)
            {
                float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
                float4 p = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
                float4 q = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));
                float d = q.x - min(q.w, q.y);
                float e = 1.0e-10;
                return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
            }

            inline float AudioLinkLerp3_g6(int Band, float Delay)
            {
                return AudioLinkLerp(ALPASS_AUDIOLINK + float2(Delay, Band)).r;
            }


            v2f VertexFunction(appdata v)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                v2f o;
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.ase_texcoord9.xy = v.ase_texcoord.xy;

                //setting value to unused interpolator channels and avoid initialization warnings
                o.ase_texcoord9.zw = 0;
                #ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
                #else
                float3 defaultVertexValue = float3(0, 0, 0);
                #endif
                float3 vertexValue = defaultVertexValue;
                #ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
                #else
                v.vertex.xyz += vertexValue;
                #endif
                v.vertex.w = 1;
                v.normal = v.normal;
                v.tangent = v.tangent;

                o.pos = UnityObjectToClipPos(v.vertex);
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
                fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
                fixed tangentSign = v.tangent.w * unity_WorldTransformParams.w;
                fixed3 worldBinormal = cross(worldNormal, worldTangent) * tangentSign;
                o.tSpace0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
                o.tSpace1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
                o.tSpace2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

                #ifdef DYNAMICLIGHTMAP_ON
				o.lmap.zw = v.texcoord2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
                #endif
                #ifdef LIGHTMAP_ON
				o.lmap.xy = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
                #endif

                #ifndef LIGHTMAP_ON
                #if UNITY_SHOULD_SAMPLE_SH && !UNITY_SAMPLE_FULL_SH_PER_PIXEL
						o.sh = 0;
                #ifdef VERTEXLIGHT_ON
						o.sh += Shade4PointLights (
							unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
							unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
							unity_4LightAtten0, worldPos, worldNormal);
                #endif
						o.sh = ShadeSHPerVertex (worldNormal, o.sh);
                #endif
                #endif

                #if UNITY_VERSION >= 201810 && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					UNITY_TRANSFER_LIGHTING(o, v.texcoord1.xy);
                #elif defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
                #if UNITY_VERSION >= 201710
						UNITY_TRANSFER_SHADOW(o, v.texcoord1.xy);
                #else
                TRANSFER_SHADOW(o);
                #endif
                #endif

                #ifdef ASE_FOG
                UNITY_TRANSFER_FOG(o, o.pos);
                #endif
                #if defined(ASE_NEEDS_FRAG_SCREEN_POSITION)
					o.screenPos = ComputeScreenPos(o.pos);
                #endif
                return o;
            }

            #if defined(TESSELLATION_ON)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float4 tangent : TANGENT;
				float3 normal : NORMAL;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				float4 ase_texcoord : TEXCOORD0;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( appdata v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.tangent = v.tangent;
				o.normal = v.normal;
				o.texcoord1 = v.texcoord1;
				o.texcoord2 = v.texcoord2;
				o.ase_texcoord = v.ase_texcoord;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
            #if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
            #elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, UNITY_MATRIX_M, _WorldSpaceCameraPos );
            #elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, UNITY_MATRIX_M, _WorldSpaceCameraPos, _ScreenParams );
            #elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, UNITY_MATRIX_M, _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
            #endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			v2f DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				appdata o = (appdata) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.tangent = patch[0].tangent * bary.x + patch[1].tangent * bary.y + patch[2].tangent * bary.z;
				o.normal = patch[0].normal * bary.x + patch[1].normal * bary.y + patch[2].normal * bary.z;
				o.texcoord1 = patch[0].texcoord1 * bary.x + patch[1].texcoord1 * bary.y + patch[2].texcoord1 * bary.z;
				o.texcoord2 = patch[0].texcoord2 * bary.x + patch[1].texcoord2 * bary.y + patch[2].texcoord2 * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
            #if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].normal * (dot(o.vertex.xyz, patch[i].normal) - dot(patch[i].vertex.xyz, patch[i].normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
            #endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
            #else
            v2f vert(appdata v)
            {
                return VertexFunction(v);
            }
            #endif

            fixed4 frag(v2f IN
                #ifdef _DEPTHOFFSET_ON
				, out float outputDepth : SV_Depth
                #endif
            ) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(IN);

                #ifdef LOD_FADE_CROSSFADE
					UNITY_APPLY_DITHER_CROSSFADE(IN.pos.xy);
                #endif

                #if defined(_SPECULAR_SETUP)
					SurfaceOutputStandardSpecular o = (SurfaceOutputStandardSpecular)0;
                #else
                SurfaceOutputStandard o = (SurfaceOutputStandard)0;
                #endif
                float3 WorldTangent = float3(IN.tSpace0.x, IN.tSpace1.x, IN.tSpace2.x);
                float3 WorldBiTangent = float3(IN.tSpace0.y, IN.tSpace1.y, IN.tSpace2.y);
                float3 WorldNormal = float3(IN.tSpace0.z, IN.tSpace1.z, IN.tSpace2.z);
                float3 worldPos = float3(IN.tSpace0.w, IN.tSpace1.w, IN.tSpace2.w);
                float3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
                #if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
                UNITY_LIGHT_ATTENUATION(atten, IN, worldPos)
                #else
					half atten = 1;
                #endif
                #if defined(ASE_NEEDS_FRAG_SCREEN_POSITION)
				float4 ScreenPos = IN.screenPos;
                #endif

                float2 texCoord6 = IN.ase_texcoord9.xy * float2(1, 1) + float2(0, 0);
                float3 hsvTorgb32 = RGBToHSV((tex2D(_MainTex, texCoord6) * _Color).rgb);
                float _AudioHueShift_Instance = UNITY_ACCESS_INSTANCED_PROP(_AudioHueShift_arr, _AudioHueShift);
                float hueShift33 = _AudioHueShift_Instance;
                float _Band_Instance = UNITY_ACCESS_INSTANCED_PROP(_Band_arr, _Band);
                int Band3_g6 = (int)_Band_Instance;
                float2 texCoord50 = IN.ase_texcoord9.xy * float2(1, 1) + float2(0, 0);
                float2 break6_g4 = texCoord50;
                float temp_output_5_0_g4 = (break6_g4.x - 0.5);
                float _PulseRotation_Instance = UNITY_ACCESS_INSTANCED_PROP(_PulseRotation_arr, _PulseRotation);
                float temp_output_2_0_g4 = radians(_PulseRotation_Instance);
                float temp_output_3_0_g4 = cos(temp_output_2_0_g4);
                float temp_output_8_0_g4 = sin(temp_output_2_0_g4);
                float temp_output_20_0_g4 = (1.0 / (abs(temp_output_3_0_g4) + abs(temp_output_8_0_g4)));
                float temp_output_7_0_g4 = (break6_g4.y - 0.5);
                float2 appendResult16_g4 = (float2(
                    (((temp_output_5_0_g4 * temp_output_3_0_g4 * temp_output_20_0_g4) + (temp_output_7_0_g4 *
                        temp_output_8_0_g4 * temp_output_20_0_g4)) + 0.5),
                    (((temp_output_7_0_g4 * temp_output_3_0_g4 * temp_output_20_0_g4) - (temp_output_5_0_g4 *
                        temp_output_8_0_g4 * temp_output_20_0_g4)) + 0.5)));
                float _Pulse_Instance = UNITY_ACCESS_INSTANCED_PROP(_Pulse_arr, _Pulse);
                float _Delay_Instance = UNITY_ACCESS_INSTANCED_PROP(_Delay_arr, _Delay);
                float Delay3_g6 = (((_Delay_Instance + ((appendResult16_g4.x * _Pulse_Instance) - 0.0) * (1.0 -
                    _Delay_Instance) / (1.0 - 0.0)) % 1.0) * 128.0);
                float localAudioLinkLerp3_g6 = AudioLinkLerp3_g6(Band3_g6, Delay3_g6);
                float temp_output_96_0 = localAudioLinkLerp3_g6;
                float amplitude36 = temp_output_96_0;
                float3 hsvTorgb39 = HSVToRGB(float3((hsvTorgb32.x + (hueShift33 * amplitude36)), hsvTorgb32.y,
                            hsvTorgb32.z));

                float4 _BumpMap_ST_Instance = UNITY_ACCESS_INSTANCED_PROP(_BumpMap_ST_arr, _BumpMap_ST);
                float2 uv_BumpMap = IN.ase_texcoord9.xy * _BumpMap_ST_Instance.xy + _BumpMap_ST_Instance.zw;

                float4 _EmissionMap_ST_Instance = UNITY_ACCESS_INSTANCED_PROP(_EmissionMap_ST_arr, _EmissionMap_ST);
                float2 uv_EmissionMap = IN.ase_texcoord9.xy * _EmissionMap_ST_Instance.xy + _EmissionMap_ST_Instance.zw;
                float4 _EmissionColor_Instance = UNITY_ACCESS_INSTANCED_PROP(_EmissionColor_arr, _EmissionColor);
                float3 hsvTorgb40 = RGBToHSV(
                    (tex2D(_EmissionMap, uv_EmissionMap) * _EmissionColor_Instance * temp_output_96_0).rgb);
                float3 hsvTorgb45 = HSVToRGB(float3((hsvTorgb40.x + (hueShift33 * amplitude36)), hsvTorgb40.y,
                         hsvTorgb40.z));
                float _Emission_Instance = UNITY_ACCESS_INSTANCED_PROP(_Emission_arr, _Emission);

                o.Albedo = hsvTorgb39;
                o.Normal = (UnpackNormal(tex2D(_BumpMap, uv_BumpMap)) * _BumpScale);
                o.Emission = (hsvTorgb45 * _Emission_Instance);
                #if defined(_SPECULAR_SETUP)
					o.Specular = fixed3( 0, 0, 0 );
                #else
                o.Metallic = _Metallic;
                #endif
                o.Smoothness = _Smoothness;
                o.Occlusion = 1;
                o.Alpha = 1;
                float AlphaClipThreshold = 0.5;
                float AlphaClipThresholdShadow = 0.5;
                float3 BakedGI = 0;
                float3 RefractionColor = 1;
                float RefractionIndex = 1;
                float3 Transmission = 1;
                float3 Translucency = 1;

                #ifdef _ALPHATEST_ON
					clip( o.Alpha - AlphaClipThreshold );
                #endif

                #ifdef _DEPTHOFFSET_ON
					outputDepth = IN.pos.z;
                #endif

                #ifndef USING_DIRECTIONAL_LIGHT
                fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
                #else
					fixed3 lightDir = _WorldSpaceLightPos0.xyz;
                #endif

                fixed4 c = 0;
                float3 worldN;
                worldN.x = dot(IN.tSpace0.xyz, o.Normal);
                worldN.y = dot(IN.tSpace1.xyz, o.Normal);
                worldN.z = dot(IN.tSpace2.xyz, o.Normal);
                worldN = normalize(worldN);
                o.Normal = worldN;

                UnityGI gi;
                UNITY_INITIALIZE_OUTPUT(UnityGI, gi);
                gi.indirect.diffuse = 0;
                gi.indirect.specular = 0;
                gi.light.color = _LightColor0.rgb;
                gi.light.dir = lightDir;

                UnityGIInput giInput;
                    UNITY_INITIALIZE_OUTPUT(UnityGIInput, giInput);
                giInput.light = gi.light;
                giInput.worldPos = worldPos;
                giInput.worldViewDir = worldViewDir;
                giInput.atten = atten;
                #if defined(LIGHTMAP_ON) || defined(DYNAMICLIGHTMAP_ON)
					giInput.lightmapUV = IN.lmap;
                #else
                giInput.lightmapUV = 0.0;
                #endif
                #if UNITY_SHOULD_SAMPLE_SH && !UNITY_SAMPLE_FULL_SH_PER_PIXEL
					giInput.ambient = IN.sh;
                #else
                giInput.ambient.rgb = 0.0;
                #endif
                giInput.probeHDR[0] = unity_SpecCube0_HDR;
                giInput.probeHDR[1] = unity_SpecCube1_HDR;
                #if defined(UNITY_SPECCUBE_BLENDING) || defined(UNITY_SPECCUBE_BOX_PROJECTION)
					giInput.boxMin[0] = unity_SpecCube0_BoxMin;
                #endif
                #ifdef UNITY_SPECCUBE_BOX_PROJECTION
					giInput.boxMax[0] = unity_SpecCube0_BoxMax;
					giInput.probePosition[0] = unity_SpecCube0_ProbePosition;
					giInput.boxMax[1] = unity_SpecCube1_BoxMax;
					giInput.boxMin[1] = unity_SpecCube1_BoxMin;
					giInput.probePosition[1] = unity_SpecCube1_ProbePosition;
                #endif

                #if defined(_SPECULAR_SETUP)
					LightingStandardSpecular_GI(o, giInput, gi);
                #else
                LightingStandard_GI(o, giInput, gi);
                #endif

                #ifdef ASE_BAKEDGI
					gi.indirect.diffuse = BakedGI;
                #endif

                #if UNITY_SHOULD_SAMPLE_SH && !defined(LIGHTMAP_ON) && defined(ASE_NO_AMBIENT)
					gi.indirect.diffuse = 0;
                #endif

                #if defined(_SPECULAR_SETUP)
					c += LightingStandardSpecular (o, worldViewDir, gi);
                #else
                c += LightingStandard(o, worldViewDir, gi);
                #endif

                #ifdef _TRANSMISSION_ASE
				{
					float shadow = _TransmissionShadow;
                #ifdef DIRECTIONAL
						float3 lightAtten = lerp( _LightColor0.rgb, gi.light.color, shadow );
                #else
						float3 lightAtten = gi.light.color;
                #endif
					half3 transmission = max(0 , -dot(o.Normal, gi.light.dir)) * lightAtten * Transmission;
					c.rgb += o.Albedo * transmission;
				}
                #endif

                #ifdef _TRANSLUCENCY_ASE
				{
					float shadow = _TransShadow;
					float normal = _TransNormal;
					float scattering = _TransScattering;
					float direct = _TransDirect;
					float ambient = _TransAmbient;
					float strength = _TransStrength;

                #ifdef DIRECTIONAL
						float3 lightAtten = lerp( _LightColor0.rgb, gi.light.color, shadow );
                #else
						float3 lightAtten = gi.light.color;
                #endif
					half3 lightDir = gi.light.dir + o.Normal * normal;
					half transVdotL = pow( saturate( dot( worldViewDir, -lightDir ) ), scattering );
					half3 translucency = lightAtten * (transVdotL * direct + gi.indirect.diffuse * ambient) * Translucency;
					c.rgb += o.Albedo * translucency * strength;
				}
                #endif

                //#ifdef _REFRACTION_ASE
                //	float4 projScreenPos = ScreenPos / ScreenPos.w;
                //	float3 refractionOffset = ( RefractionIndex - 1.0 ) * mul( UNITY_MATRIX_V, WorldNormal ).xyz * ( 1.0 - dot( WorldNormal, WorldViewDirection ) );
                //	projScreenPos.xy += refractionOffset.xy;
                //	float3 refraction = UNITY_SAMPLE_SCREENSPACE_TEXTURE( _GrabTexture, projScreenPos ) * RefractionColor;
                //	color.rgb = lerp( refraction, color.rgb, color.a );
                //	color.a = 1;
                //#endif

                c.rgb += o.Emission;

                #ifdef ASE_FOG
                UNITY_APPLY_FOG(IN.fogCoord, c);
                #endif
                return c;
            }
            ENDCG
        }


        Pass
        {

            Name "ForwardAdd"
            Tags
            {
                "LightMode"="ForwardAdd"
            }
            ZWrite Off
            Blend One One

            CGPROGRAM
            #define ASE_NEEDS_FRAG_SHADOWCOORDS
            #pragma multi_compile_instancing
            #pragma multi_compile __ LOD_FADE_CROSSFADE
            #pragma multi_compile_fog
            #define ASE_FOG 1

            #pragma vertex vert
            #pragma fragment frag
            #pragma skip_variants INSTANCING_ON
            #pragma multi_compile_fwdadd_fullshadows
            #ifndef UNITY_PASS_FORWARDADD
            #define UNITY_PASS_FORWARDADD
            #endif
            #include "HLSLSupport.cginc"
            #if !defined( UNITY_INSTANCED_LOD_FADE )
            #define UNITY_INSTANCED_LOD_FADE
            #endif
            #if !defined( UNITY_INSTANCED_SH )
            #define UNITY_INSTANCED_SH
            #endif
            #if !defined( UNITY_INSTANCED_LIGHTMAPSTS )
            #define UNITY_INSTANCED_LIGHTMAPSTS
            #endif
            #include "UnityShaderVariables.cginc"
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "UnityPBSLighting.cginc"
            #include "AutoLight.cginc"
            #include "Packages/com.llealloo.audiolink/Runtime/Shaders/AudioLink.cginc"

            #pragma multi_compile_instancing

            struct appdata
            {
                float4 vertex : POSITION;
                float4 tangent : TANGENT;
                float3 normal : NORMAL;
                float4 texcoord1 : TEXCOORD1;
                float4 texcoord2 : TEXCOORD2;
                float4 ase_texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                #if UNITY_VERSION >= 201810
					UNITY_POSITION(pos);
                #else
                float4 pos : SV_POSITION;
                #endif
                #if UNITY_VERSION >= 201810 && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					UNITY_LIGHTING_COORDS(1,2)
                #elif defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
                #if UNITY_VERSION >= 201710
						UNITY_SHADOW_COORDS(1)
                #else
                SHADOW_COORDS(1)
                #endif
                #endif
                #ifdef ASE_FOG
                UNITY_FOG_COORDS(3)
                #endif
                float4 tSpace0 : TEXCOORD5;
                float4 tSpace1 : TEXCOORD6;
                float4 tSpace2 : TEXCOORD7;
                #if defined(ASE_NEEDS_FRAG_SCREEN_POSITION)
				float4 screenPos : TEXCOORD8;
                #endif
                float4 ase_texcoord9 : TEXCOORD9;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            #ifdef _TRANSMISSION_ASE
				float _TransmissionShadow;
            #endif
            #ifdef _TRANSLUCENCY_ASE
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
            #endif
            #ifdef TESSELLATION_ON
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
            #endif
            uniform sampler2D _MainTex;
            uniform float4 _Color;
            uniform sampler2D _BumpMap;
            uniform float _BumpScale;
            uniform sampler2D _EmissionMap;
            uniform float _Metallic;
            uniform float _Smoothness;
            UNITY_INSTANCING_BUFFER_START(AudioLinkSurfaceAudioReactiveSurface)
                UNITY_DEFINE_INSTANCED_PROP(float4, _BumpMap_ST)
                #define _BumpMap_ST_arr AudioLinkSurfaceAudioReactiveSurface
                UNITY_DEFINE_INSTANCED_PROP(float4, _EmissionMap_ST)
                #define _EmissionMap_ST_arr AudioLinkSurfaceAudioReactiveSurface
                UNITY_DEFINE_INSTANCED_PROP(float4, _EmissionColor)
                #define _EmissionColor_arr AudioLinkSurfaceAudioReactiveSurface
                UNITY_DEFINE_INSTANCED_PROP(float, _AudioHueShift)
                #define _AudioHueShift_arr AudioLinkSurfaceAudioReactiveSurface
                UNITY_DEFINE_INSTANCED_PROP(float, _Band)
                #define _Band_arr AudioLinkSurfaceAudioReactiveSurface
                UNITY_DEFINE_INSTANCED_PROP(float, _PulseRotation)
                #define _PulseRotation_arr AudioLinkSurfaceAudioReactiveSurface
                UNITY_DEFINE_INSTANCED_PROP(float, _Pulse)
                #define _Pulse_arr AudioLinkSurfaceAudioReactiveSurface
                UNITY_DEFINE_INSTANCED_PROP(float, _Delay)
                #define _Delay_arr AudioLinkSurfaceAudioReactiveSurface
                UNITY_DEFINE_INSTANCED_PROP(float, _Emission)
                #define _Emission_arr AudioLinkSurfaceAudioReactiveSurface
            UNITY_INSTANCING_BUFFER_END(AudioLinkSurfaceAudioReactiveSurface)


            float3 HSVToRGB(float3 c)
            {
                float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
                float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
                return c.z * lerp(K.xxx, saturate(p - K.xxx), c.y);
            }

            float3 RGBToHSV(float3 c)
            {
                float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
                float4 p = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
                float4 q = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));
                float d = q.x - min(q.w, q.y);
                float e = 1.0e-10;
                return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
            }

            inline float AudioLinkLerp3_g6(int Band, float Delay)
            {
                return AudioLinkLerp(ALPASS_AUDIOLINK + float2(Delay, Band)).r;
            }


            v2f VertexFunction(appdata v)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                v2f o;
                    UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.ase_texcoord9.xy = v.ase_texcoord.xy;

                //setting value to unused interpolator channels and avoid initialization warnings
                o.ase_texcoord9.zw = 0;
                #ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
                #else
                float3 defaultVertexValue = float3(0, 0, 0);
                #endif
                float3 vertexValue = defaultVertexValue;
                #ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
                #else
                v.vertex.xyz += vertexValue;
                #endif
                v.vertex.w = 1;
                v.normal = v.normal;
                v.tangent = v.tangent;

                o.pos = UnityObjectToClipPos(v.vertex);
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
                fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
                fixed tangentSign = v.tangent.w * unity_WorldTransformParams.w;
                fixed3 worldBinormal = cross(worldNormal, worldTangent) * tangentSign;
                o.tSpace0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
                o.tSpace1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
                o.tSpace2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

                #if UNITY_VERSION >= 201810 && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					UNITY_TRANSFER_LIGHTING(o, v.texcoord1.xy);
                #elif defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
                #if UNITY_VERSION >= 201710
						UNITY_TRANSFER_SHADOW(o, v.texcoord1.xy);
                #else
                TRANSFER_SHADOW(o);
                #endif
                #endif

                #ifdef ASE_FOG
                UNITY_TRANSFER_FOG(o, o.pos);
                #endif
                #if defined(ASE_NEEDS_FRAG_SCREEN_POSITION)
					o.screenPos = ComputeScreenPos(o.pos);
                #endif
                return o;
            }

            #if defined(TESSELLATION_ON)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float4 tangent : TANGENT;
				float3 normal : NORMAL;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				float4 ase_texcoord : TEXCOORD0;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( appdata v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.tangent = v.tangent;
				o.normal = v.normal;
				o.texcoord1 = v.texcoord1;
				o.texcoord2 = v.texcoord2;
				o.ase_texcoord = v.ase_texcoord;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
            #if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
            #elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, UNITY_MATRIX_M, _WorldSpaceCameraPos );
            #elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, UNITY_MATRIX_M, _WorldSpaceCameraPos, _ScreenParams );
            #elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, UNITY_MATRIX_M, _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
            #endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			v2f DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				appdata o = (appdata) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.tangent = patch[0].tangent * bary.x + patch[1].tangent * bary.y + patch[2].tangent * bary.z;
				o.normal = patch[0].normal * bary.x + patch[1].normal * bary.y + patch[2].normal * bary.z;
				o.texcoord1 = patch[0].texcoord1 * bary.x + patch[1].texcoord1 * bary.y + patch[2].texcoord1 * bary.z;
				o.texcoord2 = patch[0].texcoord2 * bary.x + patch[1].texcoord2 * bary.y + patch[2].texcoord2 * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
            #if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].normal * (dot(o.vertex.xyz, patch[i].normal) - dot(patch[i].vertex.xyz, patch[i].normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
            #endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
            #else
            v2f vert(appdata v)
            {
                return VertexFunction(v);
            }
            #endif

            fixed4 frag(v2f IN
                #ifdef _DEPTHOFFSET_ON
				, out float outputDepth : SV_Depth
                #endif
            ) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(IN);

                #ifdef LOD_FADE_CROSSFADE
					UNITY_APPLY_DITHER_CROSSFADE(IN.pos.xy);
                #endif

                #if defined(_SPECULAR_SETUP)
					SurfaceOutputStandardSpecular o = (SurfaceOutputStandardSpecular)0;
                #else
                SurfaceOutputStandard o = (SurfaceOutputStandard)0;
                #endif
                float3 WorldTangent = float3(IN.tSpace0.x, IN.tSpace1.x, IN.tSpace2.x);
                float3 WorldBiTangent = float3(IN.tSpace0.y, IN.tSpace1.y, IN.tSpace2.y);
                float3 WorldNormal = float3(IN.tSpace0.z, IN.tSpace1.z, IN.tSpace2.z);
                float3 worldPos = float3(IN.tSpace0.w, IN.tSpace1.w, IN.tSpace2.w);
                float3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
                #if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
                UNITY_LIGHT_ATTENUATION(atten, IN, worldPos)
                #else
					half atten = 1;
                #endif
                #if defined(ASE_NEEDS_FRAG_SCREEN_POSITION)
				float4 ScreenPos = IN.screenPos;
                #endif


                float2 texCoord6 = IN.ase_texcoord9.xy * float2(1, 1) + float2(0, 0);
                float3 hsvTorgb32 = RGBToHSV((tex2D(_MainTex, texCoord6) * _Color).rgb);
                float _AudioHueShift_Instance = UNITY_ACCESS_INSTANCED_PROP(_AudioHueShift_arr, _AudioHueShift);
                float hueShift33 = _AudioHueShift_Instance;
                float _Band_Instance = UNITY_ACCESS_INSTANCED_PROP(_Band_arr, _Band);
                int Band3_g6 = (int)_Band_Instance;
                float2 texCoord50 = IN.ase_texcoord9.xy * float2(1, 1) + float2(0, 0);
                float2 break6_g4 = texCoord50;
                float temp_output_5_0_g4 = (break6_g4.x - 0.5);
                float _PulseRotation_Instance = UNITY_ACCESS_INSTANCED_PROP(_PulseRotation_arr, _PulseRotation);
                float temp_output_2_0_g4 = radians(_PulseRotation_Instance);
                float temp_output_3_0_g4 = cos(temp_output_2_0_g4);
                float temp_output_8_0_g4 = sin(temp_output_2_0_g4);
                float temp_output_20_0_g4 = (1.0 / (abs(temp_output_3_0_g4) + abs(temp_output_8_0_g4)));
                float temp_output_7_0_g4 = (break6_g4.y - 0.5);
                float2 appendResult16_g4 = (float2(
                    (((temp_output_5_0_g4 * temp_output_3_0_g4 * temp_output_20_0_g4) + (temp_output_7_0_g4 *
                        temp_output_8_0_g4 * temp_output_20_0_g4)) + 0.5),
                    (((temp_output_7_0_g4 * temp_output_3_0_g4 * temp_output_20_0_g4) - (temp_output_5_0_g4 *
                        temp_output_8_0_g4 * temp_output_20_0_g4)) + 0.5)));
                float _Pulse_Instance = UNITY_ACCESS_INSTANCED_PROP(_Pulse_arr, _Pulse);
                float _Delay_Instance = UNITY_ACCESS_INSTANCED_PROP(_Delay_arr, _Delay);
                float Delay3_g6 = (((_Delay_Instance + ((appendResult16_g4.x * _Pulse_Instance) - 0.0) * (1.0 -
                    _Delay_Instance) / (1.0 - 0.0)) % 1.0) * 128.0);
                float localAudioLinkLerp3_g6 = AudioLinkLerp3_g6(Band3_g6, Delay3_g6);
                float temp_output_96_0 = localAudioLinkLerp3_g6;
                float amplitude36 = temp_output_96_0;
                float3 hsvTorgb39 = HSVToRGB(float3((hsvTorgb32.x + (hueShift33 * amplitude36)), hsvTorgb32.y,
                                                                            hsvTorgb32.z));

                float4 _BumpMap_ST_Instance = UNITY_ACCESS_INSTANCED_PROP(_BumpMap_ST_arr, _BumpMap_ST);
                float2 uv_BumpMap = IN.ase_texcoord9.xy * _BumpMap_ST_Instance.xy + _BumpMap_ST_Instance.zw;

                float4 _EmissionMap_ST_Instance = UNITY_ACCESS_INSTANCED_PROP(_EmissionMap_ST_arr, _EmissionMap_ST);
                float2 uv_EmissionMap = IN.ase_texcoord9.xy * _EmissionMap_ST_Instance.xy + _EmissionMap_ST_Instance.zw;
                float4 _EmissionColor_Instance = UNITY_ACCESS_INSTANCED_PROP(_EmissionColor_arr, _EmissionColor);
                float3 hsvTorgb40 = RGBToHSV(
                    (tex2D(_EmissionMap, uv_EmissionMap) * _EmissionColor_Instance * temp_output_96_0).rgb);
                float3 hsvTorgb45 = HSVToRGB(float3((hsvTorgb40.x + (hueShift33 * amplitude36)), hsvTorgb40.y,
                                      hsvTorgb40.z));
                float _Emission_Instance = UNITY_ACCESS_INSTANCED_PROP(_Emission_arr, _Emission);

                o.Albedo = hsvTorgb39;
                o.Normal = (UnpackNormal(tex2D(_BumpMap, uv_BumpMap)) * _BumpScale);
                o.Emission = (hsvTorgb45 * _Emission_Instance);
                #if defined(_SPECULAR_SETUP)
					o.Specular = fixed3( 0, 0, 0 );
                #else
                o.Metallic = _Metallic;
                #endif
                o.Smoothness = _Smoothness;
                o.Occlusion = 1;
                o.Alpha = 1;
                float AlphaClipThreshold = 0.5;
                float3 Transmission = 1;
                float3 Translucency = 1;

                #ifdef _ALPHATEST_ON
					clip( o.Alpha - AlphaClipThreshold );
                #endif

                #ifdef _DEPTHOFFSET_ON
					outputDepth = IN.pos.z;
                #endif

                #ifndef USING_DIRECTIONAL_LIGHT
                fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
                #else
					fixed3 lightDir = _WorldSpaceLightPos0.xyz;
                #endif

                fixed4 c = 0;
                float3 worldN;
                worldN.x = dot(IN.tSpace0.xyz, o.Normal);
                worldN.y = dot(IN.tSpace1.xyz, o.Normal);
                worldN.z = dot(IN.tSpace2.xyz, o.Normal);
                worldN = normalize(worldN);
                o.Normal = worldN;

                UnityGI gi;
                UNITY_INITIALIZE_OUTPUT(UnityGI, gi);
                gi.indirect.diffuse = 0;
                gi.indirect.specular = 0;
                gi.light.color = _LightColor0.rgb;
                gi.light.dir = lightDir;
                gi.light.color *= atten;

                #if defined(_SPECULAR_SETUP)
					c += LightingStandardSpecular( o, worldViewDir, gi );
                #else
                c += LightingStandard(o, worldViewDir, gi);
                #endif

                #ifdef _TRANSMISSION_ASE
				{
					float shadow = _TransmissionShadow;
                #ifdef DIRECTIONAL
						float3 lightAtten = lerp( _LightColor0.rgb, gi.light.color, shadow );
                #else
						float3 lightAtten = gi.light.color;
                #endif
					half3 transmission = max(0 , -dot(o.Normal, gi.light.dir)) * lightAtten * Transmission;
					c.rgb += o.Albedo * transmission;
				}
                #endif

                #ifdef _TRANSLUCENCY_ASE
				{
					float shadow = _TransShadow;
					float normal = _TransNormal;
					float scattering = _TransScattering;
					float direct = _TransDirect;
					float ambient = _TransAmbient;
					float strength = _TransStrength;

                #ifdef DIRECTIONAL
						float3 lightAtten = lerp( _LightColor0.rgb, gi.light.color, shadow );
                #else
						float3 lightAtten = gi.light.color;
                #endif
					half3 lightDir = gi.light.dir + o.Normal * normal;
					half transVdotL = pow( saturate( dot( worldViewDir, -lightDir ) ), scattering );
					half3 translucency = lightAtten * (transVdotL * direct + gi.indirect.diffuse * ambient) * Translucency;
					c.rgb += o.Albedo * translucency * strength;
				}
                #endif

                //#ifdef _REFRACTION_ASE
                //	float4 projScreenPos = ScreenPos / ScreenPos.w;
                //	float3 refractionOffset = ( RefractionIndex - 1.0 ) * mul( UNITY_MATRIX_V, WorldNormal ).xyz * ( 1.0 - dot( WorldNormal, WorldViewDirection ) );
                //	projScreenPos.xy += refractionOffset.xy;
                //	float3 refraction = UNITY_SAMPLE_SCREENSPACE_TEXTURE( _GrabTexture, projScreenPos ) * RefractionColor;
                //	color.rgb = lerp( refraction, color.rgb, color.a );
                //	color.a = 1;
                //#endif

                #ifdef ASE_FOG
                UNITY_APPLY_FOG(IN.fogCoord, c);
                #endif
                return c;
            }
            ENDCG
        }


        Pass
        {

            Name "Deferred"
            Tags
            {
                "LightMode"="Deferred"
            }

            AlphaToMask Off

            CGPROGRAM
            #define ASE_NEEDS_FRAG_SHADOWCOORDS
            #pragma multi_compile_instancing
            #pragma multi_compile __ LOD_FADE_CROSSFADE
            #pragma multi_compile_fog
            #define ASE_FOG 1

            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            #pragma exclude_renderers nomrt
            #pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
            #pragma multi_compile_prepassfinal
            #ifndef UNITY_PASS_DEFERRED
            #define UNITY_PASS_DEFERRED
            #endif
            #include "HLSLSupport.cginc"
            #if !defined( UNITY_INSTANCED_LOD_FADE )
            #define UNITY_INSTANCED_LOD_FADE
            #endif
            #if !defined( UNITY_INSTANCED_SH )
            #define UNITY_INSTANCED_SH
            #endif
            #if !defined( UNITY_INSTANCED_LIGHTMAPSTS )
            #define UNITY_INSTANCED_LIGHTMAPSTS
            #endif
            #include "UnityShaderVariables.cginc"
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "UnityPBSLighting.cginc"
            #include "Packages/com.llealloo.audiolink/Runtime/Shaders/AudioLink.cginc"

            #pragma multi_compile_instancing

            struct appdata
            {
                float4 vertex : POSITION;
                float4 tangent : TANGENT;
                float3 normal : NORMAL;
                float4 texcoord1 : TEXCOORD1;
                float4 texcoord2 : TEXCOORD2;
                float4 ase_texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                #if UNITY_VERSION >= 201810
					UNITY_POSITION(pos);
                #else
                float4 pos : SV_POSITION;
                #endif
                float4 lmap : TEXCOORD2;
                #ifndef LIGHTMAP_ON
                #if UNITY_SHOULD_SAMPLE_SH && !UNITY_SAMPLE_FULL_SH_PER_PIXEL
						half3 sh : TEXCOORD3;
                #endif
                #else
                #ifdef DIRLIGHTMAP_OFF
						float4 lmapFadePos : TEXCOORD4;
                #endif
                #endif
                float4 tSpace0 : TEXCOORD5;
                float4 tSpace1 : TEXCOORD6;
                float4 tSpace2 : TEXCOORD7;
                float4 ase_texcoord8 : TEXCOORD8;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            #ifdef LIGHTMAP_ON
			float4 unity_LightmapFade;
            #endif
            fixed4 unity_Ambient;
            #ifdef TESSELLATION_ON
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
            #endif
            uniform sampler2D _MainTex;
            uniform float4 _Color;
            uniform sampler2D _BumpMap;
            uniform float _BumpScale;
            uniform sampler2D _EmissionMap;
            uniform float _Metallic;
            uniform float _Smoothness;
            UNITY_INSTANCING_BUFFER_START(AudioLinkSurfaceAudioReactiveSurface)
                UNITY_DEFINE_INSTANCED_PROP(float4, _BumpMap_ST)
                #define _BumpMap_ST_arr AudioLinkSurfaceAudioReactiveSurface
                UNITY_DEFINE_INSTANCED_PROP(float4, _EmissionMap_ST)
                #define _EmissionMap_ST_arr AudioLinkSurfaceAudioReactiveSurface
                UNITY_DEFINE_INSTANCED_PROP(float4, _EmissionColor)
                #define _EmissionColor_arr AudioLinkSurfaceAudioReactiveSurface
                UNITY_DEFINE_INSTANCED_PROP(float, _AudioHueShift)
                #define _AudioHueShift_arr AudioLinkSurfaceAudioReactiveSurface
                UNITY_DEFINE_INSTANCED_PROP(float, _Band)
                #define _Band_arr AudioLinkSurfaceAudioReactiveSurface
                UNITY_DEFINE_INSTANCED_PROP(float, _PulseRotation)
                #define _PulseRotation_arr AudioLinkSurfaceAudioReactiveSurface
                UNITY_DEFINE_INSTANCED_PROP(float, _Pulse)
                #define _Pulse_arr AudioLinkSurfaceAudioReactiveSurface
                UNITY_DEFINE_INSTANCED_PROP(float, _Delay)
                #define _Delay_arr AudioLinkSurfaceAudioReactiveSurface
                UNITY_DEFINE_INSTANCED_PROP(float, _Emission)
                #define _Emission_arr AudioLinkSurfaceAudioReactiveSurface
            UNITY_INSTANCING_BUFFER_END(AudioLinkSurfaceAudioReactiveSurface)


            float3 HSVToRGB(float3 c)
            {
                float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
                float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
                return c.z * lerp(K.xxx, saturate(p - K.xxx), c.y);
            }

            float3 RGBToHSV(float3 c)
            {
                float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
                float4 p = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
                float4 q = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));
                float d = q.x - min(q.w, q.y);
                float e = 1.0e-10;
                return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
            }

            inline float AudioLinkLerp3_g6(int Band, float Delay)
            {
                return AudioLinkLerp(ALPASS_AUDIOLINK + float2(Delay, Band)).r;
            }


            v2f VertexFunction(appdata v)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                v2f o;
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.ase_texcoord8.xy = v.ase_texcoord.xy;

                //setting value to unused interpolator channels and avoid initialization warnings
                o.ase_texcoord8.zw = 0;
                #ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
                #else
                float3 defaultVertexValue = float3(0, 0, 0);
                #endif
                float3 vertexValue = defaultVertexValue;
                #ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
                #else
                v.vertex.xyz += vertexValue;
                #endif
                v.vertex.w = 1;
                v.normal = v.normal;
                v.tangent = v.tangent;

                o.pos = UnityObjectToClipPos(v.vertex);
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
                fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
                fixed tangentSign = v.tangent.w * unity_WorldTransformParams.w;
                fixed3 worldBinormal = cross(worldNormal, worldTangent) * tangentSign;
                o.tSpace0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
                o.tSpace1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
                o.tSpace2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

                #ifdef DYNAMICLIGHTMAP_ON
					o.lmap.zw = v.texcoord2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
                #else
                o.lmap.zw = 0;
                #endif
                #ifdef LIGHTMAP_ON
					o.lmap.xy = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
                #ifdef DIRLIGHTMAP_OFF
						o.lmapFadePos.xyz = (mul(unity_ObjectToWorld, v.vertex).xyz - unity_ShadowFadeCenterAndType.xyz) * unity_ShadowFadeCenterAndType.w;
						o.lmapFadePos.w = (-UnityObjectToViewPos(v.vertex).z) * (1.0 - unity_ShadowFadeCenterAndType.w);
                #endif
                #else
                o.lmap.xy = 0;
                #if UNITY_SHOULD_SAMPLE_SH && !UNITY_SAMPLE_FULL_SH_PER_PIXEL
						o.sh = 0;
						o.sh = ShadeSHPerVertex (worldNormal, o.sh);
                #endif
                #endif
                return o;
            }

            #if defined(TESSELLATION_ON)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float4 tangent : TANGENT;
				float3 normal : NORMAL;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				float4 ase_texcoord : TEXCOORD0;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( appdata v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.tangent = v.tangent;
				o.normal = v.normal;
				o.texcoord1 = v.texcoord1;
				o.texcoord2 = v.texcoord2;
				o.ase_texcoord = v.ase_texcoord;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
            #if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
            #elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, UNITY_MATRIX_M, _WorldSpaceCameraPos );
            #elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, UNITY_MATRIX_M, _WorldSpaceCameraPos, _ScreenParams );
            #elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, UNITY_MATRIX_M, _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
            #endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			v2f DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				appdata o = (appdata) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.tangent = patch[0].tangent * bary.x + patch[1].tangent * bary.y + patch[2].tangent * bary.z;
				o.normal = patch[0].normal * bary.x + patch[1].normal * bary.y + patch[2].normal * bary.z;
				o.texcoord1 = patch[0].texcoord1 * bary.x + patch[1].texcoord1 * bary.y + patch[2].texcoord1 * bary.z;
				o.texcoord2 = patch[0].texcoord2 * bary.x + patch[1].texcoord2 * bary.y + patch[2].texcoord2 * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
            #if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].normal * (dot(o.vertex.xyz, patch[i].normal) - dot(patch[i].vertex.xyz, patch[i].normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
            #endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
            #else
            v2f vert(appdata v)
            {
                return VertexFunction(v);
            }
            #endif

            void frag(v2f IN
                                                                 , out half4 outGBuffer0 : SV_Target0
                                                                 , out half4 outGBuffer1 : SV_Target1
                                                                 , out half4 outGBuffer2 : SV_Target2
                                                                 , out half4 outEmission : SV_Target3
                                                                 #if defined(SHADOWS_SHADOWMASK) && (UNITY_ALLOWED_MRT_COUNT > 4)
				, out half4 outShadowMask : SV_Target4
                                                                 #endif
                                                                 #ifdef _DEPTHOFFSET_ON
				, out float outputDepth : SV_Depth
                                                                 #endif
            )
            {
                UNITY_SETUP_INSTANCE_ID(IN);

                #ifdef LOD_FADE_CROSSFADE
					UNITY_APPLY_DITHER_CROSSFADE(IN.pos.xy);
                #endif

                #if defined(_SPECULAR_SETUP)
					SurfaceOutputStandardSpecular o = (SurfaceOutputStandardSpecular)0;
                #else
                SurfaceOutputStandard o = (SurfaceOutputStandard)0;
                #endif
                float3 WorldTangent = float3(IN.tSpace0.x, IN.tSpace1.x, IN.tSpace2.x);
                float3 WorldBiTangent = float3(IN.tSpace0.y, IN.tSpace1.y, IN.tSpace2.y);
                float3 WorldNormal = float3(IN.tSpace0.z, IN.tSpace1.z, IN.tSpace2.z);
                float3 worldPos = float3(IN.tSpace0.w, IN.tSpace1.w, IN.tSpace2.w);
                float3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
                half atten = 1;

                float2 texCoord6 = IN.ase_texcoord8.xy * float2(1, 1) + float2(0, 0);
                float3 hsvTorgb32 = RGBToHSV((tex2D(_MainTex, texCoord6) * _Color).rgb);
                float _AudioHueShift_Instance = UNITY_ACCESS_INSTANCED_PROP(_AudioHueShift_arr, _AudioHueShift);
                float hueShift33 = _AudioHueShift_Instance;
                float _Band_Instance = UNITY_ACCESS_INSTANCED_PROP(_Band_arr, _Band);
                int Band3_g6 = (int)_Band_Instance;
                float2 texCoord50 = IN.ase_texcoord8.xy * float2(1, 1) + float2(0, 0);
                float2 break6_g4 = texCoord50;
                float temp_output_5_0_g4 = (break6_g4.x - 0.5);
                float _PulseRotation_Instance = UNITY_ACCESS_INSTANCED_PROP(_PulseRotation_arr, _PulseRotation);
                float temp_output_2_0_g4 = radians(_PulseRotation_Instance);
                float temp_output_3_0_g4 = cos(temp_output_2_0_g4);
                float temp_output_8_0_g4 = sin(temp_output_2_0_g4);
                float temp_output_20_0_g4 = (1.0 / (abs(temp_output_3_0_g4) + abs(temp_output_8_0_g4)));
                float temp_output_7_0_g4 = (break6_g4.y - 0.5);
                float2 appendResult16_g4 = (float2(
                    (((temp_output_5_0_g4 * temp_output_3_0_g4 * temp_output_20_0_g4) + (temp_output_7_0_g4 *
                        temp_output_8_0_g4 * temp_output_20_0_g4)) + 0.5),
                    (((temp_output_7_0_g4 * temp_output_3_0_g4 * temp_output_20_0_g4) - (temp_output_5_0_g4 *
                        temp_output_8_0_g4 * temp_output_20_0_g4)) + 0.5)));
                float _Pulse_Instance = UNITY_ACCESS_INSTANCED_PROP(_Pulse_arr, _Pulse);
                float _Delay_Instance = UNITY_ACCESS_INSTANCED_PROP(_Delay_arr, _Delay);
                float Delay3_g6 = (((_Delay_Instance + ((appendResult16_g4.x * _Pulse_Instance) - 0.0) * (1.0 -
                    _Delay_Instance) / (1.0 - 0.0)) % 1.0) * 128.0);
                float localAudioLinkLerp3_g6 = AudioLinkLerp3_g6(Band3_g6, Delay3_g6);
                float temp_output_96_0 = localAudioLinkLerp3_g6;
                float amplitude36 = temp_output_96_0;
                float3 hsvTorgb39 = HSVToRGB(float3((hsvTorgb32.x + (hueShift33 * amplitude36)), hsvTorgb32.y,
                                        hsvTorgb32.z));

                float4 _BumpMap_ST_Instance = UNITY_ACCESS_INSTANCED_PROP(_BumpMap_ST_arr, _BumpMap_ST);
                float2 uv_BumpMap = IN.ase_texcoord8.xy * _BumpMap_ST_Instance.xy + _BumpMap_ST_Instance.zw;

                float4 _EmissionMap_ST_Instance = UNITY_ACCESS_INSTANCED_PROP(_EmissionMap_ST_arr, _EmissionMap_ST);
                float2 uv_EmissionMap = IN.ase_texcoord8.xy * _EmissionMap_ST_Instance.xy + _EmissionMap_ST_Instance.zw;
                float4 _EmissionColor_Instance = UNITY_ACCESS_INSTANCED_PROP(_EmissionColor_arr, _EmissionColor);
                float3 hsvTorgb40 = RGBToHSV(
                    (tex2D(_EmissionMap, uv_EmissionMap) * _EmissionColor_Instance * temp_output_96_0).rgb);
                float3 hsvTorgb45 = HSVToRGB(float3((hsvTorgb40.x + (hueShift33 * amplitude36)), hsvTorgb40.y,
                    hsvTorgb40.z));
                float _Emission_Instance = UNITY_ACCESS_INSTANCED_PROP(_Emission_arr, _Emission);

                o.Albedo = hsvTorgb39;
                o.Normal = (UnpackNormal(tex2D(_BumpMap, uv_BumpMap)) * _BumpScale);
                o.Emission = (hsvTorgb45 * _Emission_Instance);
                #if defined(_SPECULAR_SETUP)
					o.Specular = fixed3( 0, 0, 0 );
                #else
                o.Metallic = _Metallic;
                #endif
                o.Smoothness = _Smoothness;
                o.Occlusion = 1;
                o.Alpha = 1;
                float AlphaClipThreshold = 0.5;
                float3 BakedGI = 0;

                #ifdef _ALPHATEST_ON
					clip( o.Alpha - AlphaClipThreshold );
                #endif

                #ifdef _DEPTHOFFSET_ON
					outputDepth = IN.pos.z;
                #endif

                #ifndef USING_DIRECTIONAL_LIGHT
                fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
                #else
					fixed3 lightDir = _WorldSpaceLightPos0.xyz;
                #endif

                float3 worldN;
                worldN.x = dot(IN.tSpace0.xyz, o.Normal);
                worldN.y = dot(IN.tSpace1.xyz, o.Normal);
                worldN.z = dot(IN.tSpace2.xyz, o.Normal);
                worldN = normalize(worldN);
                o.Normal = worldN;

                UnityGI gi;
                UNITY_INITIALIZE_OUTPUT(UnityGI, gi);
                gi.indirect.diffuse = 0;
                gi.indirect.specular = 0;
                gi.light.color = 0;
                gi.light.dir = half3(0, 1, 0);

                UnityGIInput giInput;
                UNITY_INITIALIZE_OUTPUT(UnityGIInput, giInput);
                giInput.light = gi.light;
                giInput.worldPos = worldPos;
                giInput.worldViewDir = worldViewDir;
                giInput.atten = atten;
                #if defined(LIGHTMAP_ON) || defined(DYNAMICLIGHTMAP_ON)
					giInput.lightmapUV = IN.lmap;
                #else
                giInput.lightmapUV = 0.0;
                #endif
                #if UNITY_SHOULD_SAMPLE_SH && !UNITY_SAMPLE_FULL_SH_PER_PIXEL
					giInput.ambient = IN.sh;
                #else
                giInput.ambient.rgb = 0.0;
                #endif
                giInput.probeHDR[0] = unity_SpecCube0_HDR;
                giInput.probeHDR[1] = unity_SpecCube1_HDR;
                #if defined(UNITY_SPECCUBE_BLENDING) || defined(UNITY_SPECCUBE_BOX_PROJECTION)
					giInput.boxMin[0] = unity_SpecCube0_BoxMin;
                #endif
                #ifdef UNITY_SPECCUBE_BOX_PROJECTION
					giInput.boxMax[0] = unity_SpecCube0_BoxMax;
					giInput.probePosition[0] = unity_SpecCube0_ProbePosition;
					giInput.boxMax[1] = unity_SpecCube1_BoxMax;
					giInput.boxMin[1] = unity_SpecCube1_BoxMin;
					giInput.probePosition[1] = unity_SpecCube1_ProbePosition;
                #endif

                #if defined(_SPECULAR_SETUP)
					LightingStandardSpecular_GI( o, giInput, gi );
                #else
                LightingStandard_GI(o, giInput, gi);
                #endif

                #ifdef ASE_BAKEDGI
					gi.indirect.diffuse = BakedGI;
                #endif

                #if UNITY_SHOULD_SAMPLE_SH && !defined(LIGHTMAP_ON) && defined(ASE_NO_AMBIENT)
					gi.indirect.diffuse = 0;
                #endif

                #if defined(_SPECULAR_SETUP)
					outEmission = LightingStandardSpecular_Deferred( o, worldViewDir, gi, outGBuffer0, outGBuffer1, outGBuffer2 );
                #else
                outEmission = LightingStandard_Deferred(o, worldViewDir, gi, outGBuffer0, outGBuffer1, outGBuffer2);
                #endif

                #if defined(SHADOWS_SHADOWMASK) && (UNITY_ALLOWED_MRT_COUNT > 4)
					outShadowMask = UnityGetRawBakedOcclusions (IN.lmap.xy, float3(0, 0, 0));
                #endif
                #ifndef UNITY_HDR_ON
                outEmission.rgb = exp2(-outEmission.rgb);
                #endif
            }
            ENDCG
        }


        Pass
        {

            Name "Meta"
            Tags
            {
                "LightMode"="Meta"
            }
            Cull Off

            CGPROGRAM
            #define ASE_NEEDS_FRAG_SHADOWCOORDS
            #pragma multi_compile_instancing
            #pragma multi_compile __ LOD_FADE_CROSSFADE
            #pragma multi_compile_fog
            #define ASE_FOG 1

            #pragma vertex vert
            #pragma fragment frag
            #pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
            #pragma shader_feature EDITOR_VISUALIZATION
            #ifndef UNITY_PASS_META
            #define UNITY_PASS_META
            #endif
            #include "HLSLSupport.cginc"
            #if !defined( UNITY_INSTANCED_LOD_FADE )
            #define UNITY_INSTANCED_LOD_FADE
            #endif
            #if !defined( UNITY_INSTANCED_SH )
            #define UNITY_INSTANCED_SH
            #endif
            #if !defined( UNITY_INSTANCED_LIGHTMAPSTS )
            #define UNITY_INSTANCED_LIGHTMAPSTS
            #endif
            #include "UnityShaderVariables.cginc"
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "UnityPBSLighting.cginc"
            #include "UnityMetaPass.cginc"
            #include "Packages/com.llealloo.audiolink/Runtime/Shaders/AudioLink.cginc"

            #pragma multi_compile_instancing

            struct appdata
            {
                float4 vertex : POSITION;
                float4 tangent : TANGENT;
                float3 normal : NORMAL;
                float4 texcoord1 : TEXCOORD1;
                float4 texcoord2 : TEXCOORD2;
                float4 ase_texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                #if UNITY_VERSION >= 201810
					UNITY_POSITION(pos);
                #else
                float4 pos : SV_POSITION;
                #endif
                #ifdef EDITOR_VISUALIZATION
					float2 vizUV : TEXCOORD1;
					float4 lightCoord : TEXCOORD2;
                #endif
                float4 ase_texcoord3 : TEXCOORD3;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            #ifdef TESSELLATION_ON
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
            #endif
            uniform sampler2D _MainTex;
            uniform float4 _Color;
            uniform sampler2D _EmissionMap;
            UNITY_INSTANCING_BUFFER_START(AudioLinkSurfaceAudioReactiveSurface)
                UNITY_DEFINE_INSTANCED_PROP(float4, _EmissionMap_ST)
                #define _EmissionMap_ST_arr AudioLinkSurfaceAudioReactiveSurface
                UNITY_DEFINE_INSTANCED_PROP(float4, _EmissionColor)
                #define _EmissionColor_arr AudioLinkSurfaceAudioReactiveSurface
                UNITY_DEFINE_INSTANCED_PROP(float, _AudioHueShift)
                #define _AudioHueShift_arr AudioLinkSurfaceAudioReactiveSurface
                UNITY_DEFINE_INSTANCED_PROP(float, _Band)
                #define _Band_arr AudioLinkSurfaceAudioReactiveSurface
                UNITY_DEFINE_INSTANCED_PROP(float, _PulseRotation)
                #define _PulseRotation_arr AudioLinkSurfaceAudioReactiveSurface
                UNITY_DEFINE_INSTANCED_PROP(float, _Pulse)
                #define _Pulse_arr AudioLinkSurfaceAudioReactiveSurface
                UNITY_DEFINE_INSTANCED_PROP(float, _Delay)
                #define _Delay_arr AudioLinkSurfaceAudioReactiveSurface
                UNITY_DEFINE_INSTANCED_PROP(float, _Emission)
                #define _Emission_arr AudioLinkSurfaceAudioReactiveSurface
            UNITY_INSTANCING_BUFFER_END(AudioLinkSurfaceAudioReactiveSurface)


            float3 HSVToRGB(float3 c)
            {
                float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
                float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
                return c.z * lerp(K.xxx, saturate(p - K.xxx), c.y);
            }

            float3 RGBToHSV(float3 c)
            {
                float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
                float4 p = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
                float4 q = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));
                float d = q.x - min(q.w, q.y);
                float e = 1.0e-10;
                return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
            }

            inline float AudioLinkLerp3_g6(int Band, float Delay)
            {
                return AudioLinkLerp(ALPASS_AUDIOLINK + float2(Delay, Band)).r;
            }


            v2f VertexFunction(appdata v)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                v2f o;
                    UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.ase_texcoord3.xy = v.ase_texcoord.xy;

                //setting value to unused interpolator channels and avoid initialization warnings
                o.ase_texcoord3.zw = 0;
                #ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
                #else
                float3 defaultVertexValue = float3(0, 0, 0);
                #endif
                float3 vertexValue = defaultVertexValue;
                #ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
                #else
                v.vertex.xyz += vertexValue;
                #endif
                v.vertex.w = 1;
                v.normal = v.normal;
                v.tangent = v.tangent;

                #ifdef EDITOR_VISUALIZATION
					o.vizUV = 0;
					o.lightCoord = 0;
					if (unity_VisualizationMode == EDITORVIZ_TEXTURE)
						o.vizUV = UnityMetaVizUV(unity_EditorViz_UVIndex, v.texcoord.xy, v.texcoord1.xy, v.texcoord2.xy, unity_EditorViz_Texture_ST);
					else if (unity_VisualizationMode == EDITORVIZ_SHOWLIGHTMASK)
					{
						o.vizUV = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
						o.lightCoord = mul(unity_EditorViz_WorldToLight, mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1)));
					}
                #endif

                o.pos = UnityMetaVertexPosition(v.vertex, v.texcoord1.xy, v.texcoord2.xy, unity_LightmapST,
                                                       unity_DynamicLightmapST);

                return o;
            }

            #if defined(TESSELLATION_ON)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float4 tangent : TANGENT;
				float3 normal : NORMAL;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				float4 ase_texcoord : TEXCOORD0;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( appdata v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.tangent = v.tangent;
				o.normal = v.normal;
				o.texcoord1 = v.texcoord1;
				o.texcoord2 = v.texcoord2;
				o.ase_texcoord = v.ase_texcoord;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
            #if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
            #elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, UNITY_MATRIX_M, _WorldSpaceCameraPos );
            #elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, UNITY_MATRIX_M, _WorldSpaceCameraPos, _ScreenParams );
            #elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, UNITY_MATRIX_M, _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
            #endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			v2f DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				appdata o = (appdata) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.tangent = patch[0].tangent * bary.x + patch[1].tangent * bary.y + patch[2].tangent * bary.z;
				o.normal = patch[0].normal * bary.x + patch[1].normal * bary.y + patch[2].normal * bary.z;
				o.texcoord1 = patch[0].texcoord1 * bary.x + patch[1].texcoord1 * bary.y + patch[2].texcoord1 * bary.z;
				o.texcoord2 = patch[0].texcoord2 * bary.x + patch[1].texcoord2 * bary.y + patch[2].texcoord2 * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
            #if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].normal * (dot(o.vertex.xyz, patch[i].normal) - dot(patch[i].vertex.xyz, patch[i].normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
            #endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
            #else
            v2f vert(appdata v)
            {
                return VertexFunction(v);
            }
            #endif

            fixed4 frag(v2f IN
                #ifdef _DEPTHOFFSET_ON
				, out float outputDepth : SV_Depth
                #endif
            ) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(IN);

                #ifdef LOD_FADE_CROSSFADE
					UNITY_APPLY_DITHER_CROSSFADE(IN.pos.xy);
                #endif

                #if defined(_SPECULAR_SETUP)
					SurfaceOutputStandardSpecular o = (SurfaceOutputStandardSpecular)0;
                #else
                SurfaceOutputStandard o = (SurfaceOutputStandard)0;
                #endif

                float2 texCoord6 = IN.ase_texcoord3.xy * float2(1, 1) + float2(0, 0);
                float3 hsvTorgb32 = RGBToHSV((tex2D(_MainTex, texCoord6) * _Color).rgb);
                float _AudioHueShift_Instance = UNITY_ACCESS_INSTANCED_PROP(_AudioHueShift_arr, _AudioHueShift);
                float hueShift33 = _AudioHueShift_Instance;
                float _Band_Instance = UNITY_ACCESS_INSTANCED_PROP(_Band_arr, _Band);
                int Band3_g6 = (int)_Band_Instance;
                float2 texCoord50 = IN.ase_texcoord3.xy * float2(1, 1) + float2(0, 0);
                float2 break6_g4 = texCoord50;
                float temp_output_5_0_g4 = (break6_g4.x - 0.5);
                float _PulseRotation_Instance = UNITY_ACCESS_INSTANCED_PROP(_PulseRotation_arr, _PulseRotation);
                float temp_output_2_0_g4 = radians(_PulseRotation_Instance);
                float temp_output_3_0_g4 = cos(temp_output_2_0_g4);
                float temp_output_8_0_g4 = sin(temp_output_2_0_g4);
                float temp_output_20_0_g4 = (1.0 / (abs(temp_output_3_0_g4) + abs(temp_output_8_0_g4)));
                float temp_output_7_0_g4 = (break6_g4.y - 0.5);
                float2 appendResult16_g4 = (float2(
                    (((temp_output_5_0_g4 * temp_output_3_0_g4 * temp_output_20_0_g4) + (temp_output_7_0_g4 *
                        temp_output_8_0_g4 * temp_output_20_0_g4)) + 0.5),
                    (((temp_output_7_0_g4 * temp_output_3_0_g4 * temp_output_20_0_g4) - (temp_output_5_0_g4 *
                        temp_output_8_0_g4 * temp_output_20_0_g4)) + 0.5)));
                float _Pulse_Instance = UNITY_ACCESS_INSTANCED_PROP(_Pulse_arr, _Pulse);
                float _Delay_Instance = UNITY_ACCESS_INSTANCED_PROP(_Delay_arr, _Delay);
                float Delay3_g6 = (((_Delay_Instance + ((appendResult16_g4.x * _Pulse_Instance) - 0.0) * (1.0 -
                    _Delay_Instance) / (1.0 - 0.0)) % 1.0) * 128.0);
                float localAudioLinkLerp3_g6 = AudioLinkLerp3_g6(Band3_g6, Delay3_g6);
                float temp_output_96_0 = localAudioLinkLerp3_g6;
                float amplitude36 = temp_output_96_0;
                float3 hsvTorgb39 = HSVToRGB(float3((hsvTorgb32.x + (hueShift33 * amplitude36)), hsvTorgb32.y,
                                                    hsvTorgb32.z));

                float4 _EmissionMap_ST_Instance = UNITY_ACCESS_INSTANCED_PROP(_EmissionMap_ST_arr, _EmissionMap_ST);
                float2 uv_EmissionMap = IN.ase_texcoord3.xy * _EmissionMap_ST_Instance.xy + _EmissionMap_ST_Instance.zw;
                float4 _EmissionColor_Instance = UNITY_ACCESS_INSTANCED_PROP(_EmissionColor_arr, _EmissionColor);
                float3 hsvTorgb40 = RGBToHSV(
                    (tex2D(_EmissionMap, uv_EmissionMap) * _EmissionColor_Instance * temp_output_96_0).rgb);
                float3 hsvTorgb45 = HSVToRGB(float3((hsvTorgb40.x + (hueShift33 * amplitude36)), hsvTorgb40.y,
                                                    hsvTorgb40.z));
                float _Emission_Instance = UNITY_ACCESS_INSTANCED_PROP(_Emission_arr, _Emission);

                o.Albedo = hsvTorgb39;
                o.Normal = fixed3(0, 0, 1);
                o.Emission = (hsvTorgb45 * _Emission_Instance);
                o.Alpha = 1;
                float AlphaClipThreshold = 0.5;

                #ifdef _ALPHATEST_ON
					clip( o.Alpha - AlphaClipThreshold );
                #endif

                #ifdef _DEPTHOFFSET_ON
					outputDepth = IN.pos.z;
                #endif

                UnityMetaInput metaIN;
                UNITY_INITIALIZE_OUTPUT(UnityMetaInput, metaIN);
                metaIN.Albedo = o.Albedo;
                metaIN.Emission = o.Emission;
                #ifdef EDITOR_VISUALIZATION
					metaIN.VizUV = IN.vizUV;
					metaIN.LightCoord = IN.lightCoord;
                #endif
                return UnityMetaFragment(metaIN);
            }
            ENDCG
        }


        Pass
        {

            Name "ShadowCaster"
            Tags
            {
                "LightMode"="ShadowCaster"
            }
            ZWrite On
            ZTest LEqual
            AlphaToMask Off

            CGPROGRAM
            #define ASE_NEEDS_FRAG_SHADOWCOORDS
            #pragma multi_compile_instancing
            #pragma multi_compile __ LOD_FADE_CROSSFADE
            #pragma multi_compile_fog
            #define ASE_FOG 1

            #pragma vertex vert
            #pragma fragment frag
            #pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
            #pragma multi_compile_shadowcaster
            #ifndef UNITY_PASS_SHADOWCASTER
            #define UNITY_PASS_SHADOWCASTER
            #endif
            #include "HLSLSupport.cginc"
            #ifndef UNITY_INSTANCED_LOD_FADE
            #define UNITY_INSTANCED_LOD_FADE
            #endif
            #ifndef UNITY_INSTANCED_SH
            #define UNITY_INSTANCED_SH
            #endif
            #ifndef UNITY_INSTANCED_LIGHTMAPSTS
            #define UNITY_INSTANCED_LIGHTMAPSTS
            #endif
            #if ( SHADER_API_D3D11 || SHADER_API_GLCORE || SHADER_API_GLES || SHADER_API_GLES3 || SHADER_API_METAL || SHADER_API_VULKAN )
            #define CAN_SKIP_VPOS
            #endif
            #include "UnityShaderVariables.cginc"
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "UnityPBSLighting.cginc"
            #include "Packages/com.llealloo.audiolink/Runtime/Shaders/AudioLink.cginc"


            struct appdata
            {
                float4 vertex : POSITION;
                float4 tangent : TANGENT;
                float3 normal : NORMAL;
                float4 texcoord1 : TEXCOORD1;
                float4 texcoord2 : TEXCOORD2;

                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                V2F_SHADOW_CASTER;

                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            #ifdef UNITY_STANDARD_USE_DITHER_MASK
				sampler3D _DitherMaskLOD;
            #endif
            #ifdef TESSELLATION_ON
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
            #endif
            UNITY_INSTANCING_BUFFER_START(AudioLinkSurfaceAudioReactiveSurface)
            UNITY_INSTANCING_BUFFER_END(AudioLinkSurfaceAudioReactiveSurface)


            v2f VertexFunction(appdata v)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                v2f o;
                    UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);


                #ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
                #else
                float3 defaultVertexValue = float3(0, 0, 0);
                #endif
                float3 vertexValue = defaultVertexValue;
                #ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
                #else
                v.vertex.xyz += vertexValue;
                #endif
                v.vertex.w = 1;
                v.normal = v.normal;
                v.tangent = v.tangent;

                    TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
                return o;
            }

            #if defined(TESSELLATION_ON)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float4 tangent : TANGENT;
				float3 normal : NORMAL;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( appdata v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.tangent = v.tangent;
				o.normal = v.normal;
				o.texcoord1 = v.texcoord1;
				o.texcoord2 = v.texcoord2;

				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
            #if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
            #elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, UNITY_MATRIX_M, _WorldSpaceCameraPos );
            #elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, UNITY_MATRIX_M, _WorldSpaceCameraPos, _ScreenParams );
            #elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, UNITY_MATRIX_M, _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
            #endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			v2f DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				appdata o = (appdata) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.tangent = patch[0].tangent * bary.x + patch[1].tangent * bary.y + patch[2].tangent * bary.z;
				o.normal = patch[0].normal * bary.x + patch[1].normal * bary.y + patch[2].normal * bary.z;
				o.texcoord1 = patch[0].texcoord1 * bary.x + patch[1].texcoord1 * bary.y + patch[2].texcoord1 * bary.z;
				o.texcoord2 = patch[0].texcoord2 * bary.x + patch[1].texcoord2 * bary.y + patch[2].texcoord2 * bary.z;

            #if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].normal * (dot(o.vertex.xyz, patch[i].normal) - dot(patch[i].vertex.xyz, patch[i].normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
            #endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
            #else
            v2f vert(appdata v)
            {
                return VertexFunction(v);
            }
            #endif

            fixed4 frag(v2f IN
                #ifdef _DEPTHOFFSET_ON
				, out float outputDepth : SV_Depth
                #endif
                #if !defined( CAN_SKIP_VPOS )
				, UNITY_VPOS_TYPE vpos : VPOS
                #endif
            ) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(IN);

                #ifdef LOD_FADE_CROSSFADE
					UNITY_APPLY_DITHER_CROSSFADE(IN.pos.xy);
                #endif

                #if defined(_SPECULAR_SETUP)
					SurfaceOutputStandardSpecular o = (SurfaceOutputStandardSpecular)0;
                #else
                SurfaceOutputStandard o = (SurfaceOutputStandard)0;
                #endif


                o.Normal = fixed3(0, 0, 1);
                o.Occlusion = 1;
                o.Alpha = 1;
                float AlphaClipThreshold = 0.5;
                float AlphaClipThresholdShadow = 0.5;

                #ifdef _ALPHATEST_SHADOW_ON
					if (unity_LightShadowBias.z != 0.0)
						clip(o.Alpha - AlphaClipThresholdShadow);
                #ifdef _ALPHATEST_ON
					else
						clip(o.Alpha - AlphaClipThreshold);
                #endif
                #else
                #ifdef _ALPHATEST_ON
						clip(o.Alpha - AlphaClipThreshold);
                #endif
                #endif

                #if defined( CAN_SKIP_VPOS )
                float2 vpos = IN.pos;
                #endif

                #ifdef UNITY_STANDARD_USE_DITHER_MASK
					half alphaRef = tex3D(_DitherMaskLOD, float3(vpos.xy*0.25,o.Alpha*0.9375)).a;
					clip(alphaRef - 0.01);
                #endif

                #ifdef _DEPTHOFFSET_ON
					outputDepth = IN.pos.z;
                #endif

                SHADOW_CASTER_FRAGMENT(IN)
            }
            ENDCG
        }

        // DepthOnly pass
        Pass
        {
            Name "DepthOnly"
            Tags
            {
                "LightMode"="DepthOnly"
            }

            ZWrite On
            ColorMask 0
            Cull Back

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_instancing
            #pragma target 3.0
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma multi_compile _ LOD_FADE_CROSSFADE

            #define _ALPHATEST_ON 1

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            uniform sampler2D _MainTex;
            uniform float _Cutoff;

            v2f vert(appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.pos = UnityObjectToClipPos(v.vertex);
                o.texcoord = v.texcoord;
                return o;
            }

            half4 frag(v2f i) : SV_TARGET
            {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

                #ifdef LOD_FADE_CROSSFADE
            UNITY_APPLY_DITHER_CROSSFADE(i.pos.xy);
                #endif

                float4 tex = tex2D(_MainTex, i.texcoord);

                #ifdef _ALPHATEST_ON
                clip(tex.a - _Cutoff);
                #endif

                return 0;
            }
            ENDHLSL
        }

        // DepthNormals pass
        Pass
        {
            Name "DepthNormals"
            Tags
            {
                "LightMode"="DepthNormals"
            }

            ZWrite On
            Cull Back

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_instancing
            #pragma target 3.0
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma multi_compile _ LOD_FADE_CROSSFADE

            #define _ALPHATEST_ON 1

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 texcoord : TEXCOORD0;
                float3 normal : TEXCOORD1;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            uniform sampler2D _MainTex;
            uniform sampler2D _BumpMap;
            uniform float _BumpScale;
            uniform float _Cutoff;

            UNITY_INSTANCING_BUFFER_START(AudioLinkSurfaceAudioReactiveSurface_Cutout)
                UNITY_DEFINE_INSTANCED_PROP(float4, _BumpMap_ST)
            UNITY_INSTANCING_BUFFER_END(AudioLinkSurfaceAudioReactiveSurface_Cutout)

            v2f vert(appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.pos = UnityObjectToClipPos(v.vertex);
                o.texcoord = v.texcoord;
                o.normal = UnityObjectToWorldNormal(v.normal);
                return o;
            }

            half4 frag(v2f i) : SV_TARGET
            {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

                #ifdef LOD_FADE_CROSSFADE
                UNITY_APPLY_DITHER_CROSSFADE(i.pos.xy);
                #endif

                float4 tex = tex2D(_MainTex, i.texcoord);

                #ifdef _ALPHATEST_ON
                clip(tex.a - _Cutoff);
                #endif

                float4 _BumpMap_ST_Instance = UNITY_ACCESS_INSTANCED_PROP(
                    AudioLinkSurfaceAudioReactiveSurface_Cutout, _BumpMap_ST);
                float2 uv_BumpMap = i.texcoord * _BumpMap_ST_Instance.xy + _BumpMap_ST_Instance.zw;

                float3 normalTS = UnpackNormal(tex2D(_BumpMap, uv_BumpMap));
                normalTS.xy *= _BumpScale;
                normalTS.z = sqrt(1.0 - saturate(dot(normalTS.xy, normalTS.xy)));

                float3 normalWS = normalize(normalTS);

                // Encode normal and depth
                return float4(normalWS * 0.5 + 0.5, 0);
            }
            ENDHLSL
        }
    }
}
