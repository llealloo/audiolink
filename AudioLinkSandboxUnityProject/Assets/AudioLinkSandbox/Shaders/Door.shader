// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Door"
{
	Properties
	{
		_MainTex("Main Tex", 2D) = "white" {}
		_AlbedoCubeScale("Albedo Cube Scale", Float) = 0
		_AlbedoCubeOffset("Albedo Cube Offset", Vector) = (0,0,0,0)
		[Normal]_BumpMap("BumpMap", 2D) = "bump" {}
		_Smoothness("Smoothness", Range( 0 , 1)) = 0.5
		_SmallCubes("Small Cubes", 2D) = "white" {}
		_EmissiveCubeScale("Emissive Cube Scale", Float) = 0
		_EmissiveCubeOffset("Emissive Cube Offset", Vector) = (0,0,0,0)
		_EmissionMinDistance("Emission Min Distance", Float) = 0
		_EmissionMaxDistance("Emission Max Distance", Float) = 0
		_CubifyEmissionGradient("Cubify Emission Gradient", Range( 0 , 1)) = 0
		_CubeSize("Cube Size", Vector) = (1,1,1,0)
		_CubeOffset("Cube Offset", Vector) = (0,0,0,0)
		_VertMinDistance("Vert Min Distance", Float) = 0
		_VertMaxDistance("Vert Max Distance", Float) = 0
		_PulseWidth("Pulse Width", Range( 0 , 1)) = 0.5
		_MixViewObjectPosition("Mix View / Object Position", Range( 0 , 1)) = 0
		_VertAudioLinkIntensity("Vert AudioLink Intensity", Range( 0 , 1)) = 0.8
		_EmissionAudioLinkIntensity("Emission AudioLink Intensity", Range( 0 , 1)) = 0.8
		_AutoCorrBassBand("AutoCorr / BassBand", Range( 0 , 1)) = 0.5
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] _texcoord2( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" "IsEmissive" = "true"  "LTCGI"="ALWAYS" }
		Cull Back
		CGINCLUDE
		#include "UnityShaderVariables.cginc"
		#include "UnityPBSLighting.cginc"
		#include "Lighting.cginc"
		#pragma target 3.0
		#include "Assets/_pi_/_LTCGI/Shaders/LTCGI.cginc"
		#include "Packages/com.llealloo.audiolink/Runtime/Shaders/AudioLink.cginc"
		#ifdef UNITY_PASS_SHADOWCASTER
			#undef INTERNAL_DATA
			#undef WorldReflectionVector
			#undef WorldNormalVector
			#define INTERNAL_DATA half3 internalSurfaceTtoW0; half3 internalSurfaceTtoW1; half3 internalSurfaceTtoW2;
			#define WorldReflectionVector(data,normal) reflect (data.worldRefl, half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal)))
			#define WorldNormalVector(data,normal) half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal))
		#endif
		struct Input
		{
			float3 worldPos;
			float3 worldNormal;
			INTERNAL_DATA
			float2 uv_texcoord;
			float2 uv2_texcoord2;
		};

		uniform float _VertMinDistance;
		uniform float _VertMaxDistance;
		uniform float4 PlayerPositions[100];
		uniform float4 HeadPositions[200];
		uniform float4 HandPositions[200];
		uniform float3 _CubeOffset;
		uniform float3 _CubeSize;
		uniform float _MixViewObjectPosition;
		uniform float _PulseWidth;
		uniform float _AutoCorrBassBand;
		uniform float _VertAudioLinkIntensity;
		uniform sampler2D _MainTex;
		uniform float _AlbedoCubeScale;
		uniform float3 _AlbedoCubeOffset;
		uniform sampler2D _SmallCubes;
		uniform float _EmissiveCubeScale;
		uniform float3 _EmissiveCubeOffset;
		uniform float _EmissionMinDistance;
		uniform float _EmissionMaxDistance;
		uniform float _CubifyEmissionGradient;
		uniform float _EmissionAudioLinkIntensity;
		uniform sampler2D _BumpMap;
		uniform float4 _BumpMap_ST;
		uniform float _Smoothness;


		float3 BetterWorldSpaceCameraPos1_g13(  )
		{
			#if defined(USING_STEREO_MATRICES)
			return 0.5 * (unity_StereoWorldSpaceCameraPos[0] + unity_StereoWorldSpaceCameraPos[1]);
			#else
			return _WorldSpaceCameraPos;
			#endif
		}


		float BubbleHandViewProximity262( float3 ClosestCubeCenter, float3 ViewPosition, float MinDistance, float MaxDistance )
		{
			float proximity = 0;
			// player positions
			for (uint i = 0; i < 100; i++)
			{
				// lighten blending mode
				proximity = max(saturate(AudioLinkRemap(length(PlayerPositions[i] - ClosestCubeCenter), MaxDistance, MinDistance, 0, 1)), proximity);
			}
			// head positions
			for (uint i = 0; i < 100; i++)
			{
				// lighten blending mode
				proximity = max(saturate(AudioLinkRemap(length(HeadPositions[i] - ClosestCubeCenter), MaxDistance, MinDistance, 0, 1)), proximity);
			}
			// hand positions
			for (uint i = 0; i < 200; i++)
			{
				// lighten blending mode
				proximity = max(saturate(AudioLinkRemap(length(HandPositions[i] - ClosestCubeCenter), MaxDistance, MinDistance, 0, 1)), proximity);
			}
			// view position lighten blend in
			proximity = max(saturate(AudioLinkRemap(length(ClosestCubeCenter - ViewPosition), MaxDistance, MinDistance, 0, 1)), proximity);
			return saturate(proximity);
		}


		inline float AudioLinkLerp2_g87( float Sample )
		{
			return AudioLinkLerp( ALPASS_AUTOCORRELATOR + float2( Sample * 128., 0 ) ).g;;
		}


		inline float AudioLinkLerp3_g84( int Band, float Delay )
		{
			return AudioLinkLerp( ALPASS_AUDIOLINK + float2( Delay, Band ) ).r;
		}


		float2 CubicWorldTextureUV315( float3 Normal, float3 Position, float Scale, float3 Offset )
		{
			float scaleInv = 1 / Scale;
			if (abs(Normal.x) > 0.5)
			{
				return Position.yz * scaleInv + Offset.yz;
			}
			else if (abs(Normal.z) > 0.5)
			{
				return Position.xy * scaleInv + Offset.xy;
			}
			else
			{
				return Position.xz * scaleInv + Offset.xz;
			}
		}


		float2 CubicWorldTextureUV5( float3 Normal, float3 Position, float Scale, float3 Offset )
		{
			float scaleInv = 1 / Scale;
			if (abs(Normal.x) > 0.5)
			{
				return Position.yz * scaleInv + Offset.yz;
			}
			else if (abs(Normal.z) > 0.5)
			{
				return Position.xy * scaleInv + Offset.xy;
			}
			else
			{
				return Position.xz * scaleInv + Offset.xz;
			}
		}


		struct Gradient
		{
			int type;
			int colorsLength;
			int alphasLength;
			float4 colors[8];
			float2 alphas[8];
		};


		Gradient NewGradient(int type, int colorsLength, int alphasLength, 
		float4 colors0, float4 colors1, float4 colors2, float4 colors3, float4 colors4, float4 colors5, float4 colors6, float4 colors7,
		float2 alphas0, float2 alphas1, float2 alphas2, float2 alphas3, float2 alphas4, float2 alphas5, float2 alphas6, float2 alphas7)
		{
			Gradient g;
			g.type = type;
			g.colorsLength = colorsLength;
			g.alphasLength = alphasLength;
			g.colors[ 0 ] = colors0;
			g.colors[ 1 ] = colors1;
			g.colors[ 2 ] = colors2;
			g.colors[ 3 ] = colors3;
			g.colors[ 4 ] = colors4;
			g.colors[ 5 ] = colors5;
			g.colors[ 6 ] = colors6;
			g.colors[ 7 ] = colors7;
			g.alphas[ 0 ] = alphas0;
			g.alphas[ 1 ] = alphas1;
			g.alphas[ 2 ] = alphas2;
			g.alphas[ 3 ] = alphas3;
			g.alphas[ 4 ] = alphas4;
			g.alphas[ 5 ] = alphas5;
			g.alphas[ 6 ] = alphas6;
			g.alphas[ 7 ] = alphas7;
			return g;
		}


		float BubbleHandViewProximity289( float3 ClosestCubeCenter, float3 ViewPosition, float MinDistance, float MaxDistance, float QuantizeLerp, float3 WorldPosition )
		{
			float proximity = 0;
			float3 testPosition = lerp(WorldPosition, ClosestCubeCenter, QuantizeLerp);
			// player positions
			for (uint i = 0; i < 100; i++)
			{
				// lighten blending mode
				proximity = max(saturate(AudioLinkRemap(length(PlayerPositions[i] - testPosition), MaxDistance, MinDistance, 0, 1)), proximity);
			}
			// head positions
			for (uint i = 0; i < 100; i++)
			{
				// lighten blending mode
				proximity = max(saturate(AudioLinkRemap(length(HeadPositions[i] - testPosition), MaxDistance, MinDistance, 0, 1)), proximity);
			}
			// hand positions
			for (uint i = 0; i < 200; i++)
			{
				// lighten blending mode
				proximity = max(saturate(AudioLinkRemap(length(HandPositions[i] - testPosition), MaxDistance, MinDistance, 0, 1)), proximity);
			}
			// view position lighten blend in
			proximity = max(saturate(AudioLinkRemap(length(testPosition - ViewPosition), MaxDistance, MinDistance, 0, 1)), proximity);
			return saturate(proximity);
		}


		inline float AudioLinkLerp2_g82( float Sample )
		{
			return AudioLinkLerp( ALPASS_AUTOCORRELATOR + float2( Sample * 128., 0 ) ).g;;
		}


		inline float AudioLinkLerp3_g79( int Band, float Delay )
		{
			return AudioLinkLerp( ALPASS_AUDIOLINK + float2( Delay, Band ) ).r;
		}


		float4 SampleGradient( Gradient gradient, float time )
		{
			float3 color = gradient.colors[0].rgb;
			UNITY_UNROLL
			for (int c = 1; c < 8; c++)
			{
			float colorPos = saturate((time - gradient.colors[c-1].w) / ( 0.00001 + (gradient.colors[c].w - gradient.colors[c-1].w)) * step(c, (float)gradient.colorsLength-1));
			color = lerp(color, gradient.colors[c].rgb, lerp(colorPos, step(0.01, colorPos), gradient.type));
			}
			#ifndef UNITY_COLORSPACE_GAMMA
			color = half3(GammaToLinearSpaceExact(color.r), GammaToLinearSpaceExact(color.g), GammaToLinearSpaceExact(color.b));
			#endif
			float alpha = gradient.alphas[0].x;
			UNITY_UNROLL
			for (int a = 1; a < 8; a++)
			{
			float alphaPos = saturate((time - gradient.alphas[a-1].y) / ( 0.00001 + (gradient.alphas[a].y - gradient.alphas[a-1].y)) * step(a, (float)gradient.alphasLength-1));
			alpha = lerp(alpha, gradient.alphas[a].x, lerp(alphaPos, step(0.01, alphaPos), gradient.type));
			}
			return float4(color, alpha);
		}


		void vertexDataFunc( inout appdata_full v, out Input o )
		{
			UNITY_INITIALIZE_OUTPUT( Input, o );
			float3 ase_vertex3Pos = v.vertex.xyz;
			float3 temp_output_15_0_g77 = float3( 0.0625,0.0625,0.0625 );
			float3 temp_output_17_0_g77 = ( float3( 1,1,1 ) / float3( 0.125,0.125,0.125 ) );
			float3 ase_worldPos = mul( unity_ObjectToWorld, v.vertex );
			float3 temp_output_15_0_g21 = _CubeOffset;
			float3 temp_output_17_0_g21 = ( float3( 1,1,1 ) / _CubeSize );
			float3 quantizedCubeCenter180 = ( ( round( ( ( ase_worldPos + temp_output_15_0_g21 ) * temp_output_17_0_g21 ) ) / temp_output_17_0_g21 ) - temp_output_15_0_g21 );
			float3 ClosestCubeCenter262 = quantizedCubeCenter180;
			float3 localBetterWorldSpaceCameraPos1_g13 = BetterWorldSpaceCameraPos1_g13();
			float4 transform86 = mul(unity_ObjectToWorld,float4( 0,0,0,1 ));
			float4 lerpResult82 = lerp( float4( localBetterWorldSpaceCameraPos1_g13 , 0.0 ) , transform86 , _MixViewObjectPosition);
			float4 viewTestPoint84 = lerpResult82;
			float3 ViewPosition262 = viewTestPoint84.xyz;
			float MinDistance262 = _VertMinDistance;
			float MaxDistance262 = _VertMaxDistance;
			float localBubbleHandViewProximity262 = BubbleHandViewProximity262( ClosestCubeCenter262 , ViewPosition262 , MinDistance262 , MaxDistance262 );
			float smoothstepResult121 = smoothstep( 0.0 , 1.0 , localBubbleHandViewProximity262);
			float temp_output_18_0_g83 = smoothstepResult121;
			float4 temp_cast_2 = (temp_output_18_0_g83).xxxx;
			float4 temp_output_1_0_g85 = temp_cast_2;
			float4 break5_g85 = temp_output_1_0_g85;
			float Sample2_g87 = saturate( temp_output_18_0_g83 );
			float localAudioLinkLerp2_g87 = AudioLinkLerp2_g87( Sample2_g87 );
			int Band3_g84 = 0;
			float smoothstepResult6_g83 = smoothstep( 0.0 , 1.0 , ( abs( ( 0.5 - temp_output_18_0_g83 ) ) * 2.0 ));
			float Delay3_g84 = ( smoothstepResult6_g83 * 128.0 * _PulseWidth );
			float localAudioLinkLerp3_g84 = AudioLinkLerp3_g84( Band3_g84 , Delay3_g84 );
			float lerpResult11_g83 = lerp( localAudioLinkLerp2_g87 , localAudioLinkLerp3_g84 , _AutoCorrBassBand);
			float lerpResult14_g83 = lerp( 0.5 , saturate( lerpResult11_g83 ) , _VertAudioLinkIntensity);
			float4 temp_cast_3 = (lerpResult14_g83).xxxx;
			float4 temp_output_2_0_g85 = temp_cast_3;
			float3 lerpResult93 = lerp( ase_vertex3Pos , ( ( round( ( ( ase_vertex3Pos + temp_output_15_0_g77 ) * temp_output_17_0_g77 ) ) / temp_output_17_0_g77 ) - temp_output_15_0_g77 ) , ( ( ( break5_g85.r * 0.2 ) + ( break5_g85.g * 0.7 ) + ( break5_g85.b * 0.1 ) ) < 0.5 ? ( 2.0 * temp_output_1_0_g85 * temp_output_2_0_g85 ) : ( 1.0 - ( 2.0 * ( 1.0 - temp_output_1_0_g85 ) * ( 1.0 - temp_output_2_0_g85 ) ) ) ).r);
			float3 absVertPos255 = lerpResult93;
			v.vertex.xyz = absVertPos255;
			v.vertex.w = 1;
		}

		void surf( Input i , inout SurfaceOutputStandard o )
		{
			o.Normal = float3(0,0,1);
			float3 ase_worldNormal = WorldNormalVector( i, float3( 0, 0, 1 ) );
			float3 Normal315 = ase_worldNormal;
			float3 ase_worldPos = i.worldPos;
			float3 Position315 = ase_worldPos;
			float Scale315 = _AlbedoCubeScale;
			float3 Offset315 = _AlbedoCubeOffset;
			float2 localCubicWorldTextureUV315 = CubicWorldTextureUV315( Normal315 , Position315 , Scale315 , Offset315 );
			float2 worldUVBig316 = localCubicWorldTextureUV315;
			o.Albedo = tex2D( _MainTex, worldUVBig316 ).rgb;
			float3 Normal5 = ase_worldNormal;
			float3 Position5 = ase_worldPos;
			float Scale5 = _EmissiveCubeScale;
			float3 Offset5 = _EmissiveCubeOffset;
			float2 localCubicWorldTextureUV5 = CubicWorldTextureUV5( Normal5 , Position5 , Scale5 , Offset5 );
			float2 worldUVSMall148 = localCubicWorldTextureUV5;
			float4 tex2DNode6 = tex2D( _SmallCubes, worldUVSMall148 );
			float4 lerpResult37 = lerp( ( 1.0 - tex2DNode6 ) , tex2DNode6 , float4( 1,1,1,0 ));
			Gradient gradient351 = NewGradient( 0, 8, 2, float4( 0, 0, 0, 0 ), float4( 0.1603774, 0, 0.1501947, 0.2235294 ), float4( 0.2132809, 0, 0.490566, 0.4260014 ), float4( 0, 0.2383077, 1, 0.7117723 ), float4( 0.365655, 0.8437017, 0.9339623, 0.9593805 ), float4( 0.810892, 0.7028302, 1, 0.9779507 ), float4( 1, 0.4117647, 0.7898859, 0.9895476 ), float4( 0, 0, 0, 1 ), float2( 1, 0 ), float2( 1, 1 ), 0, 0, 0, 0, 0, 0 );
			float3 temp_output_15_0_g21 = _CubeOffset;
			float3 temp_output_17_0_g21 = ( float3( 1,1,1 ) / _CubeSize );
			float3 quantizedCubeCenter180 = ( ( round( ( ( ase_worldPos + temp_output_15_0_g21 ) * temp_output_17_0_g21 ) ) / temp_output_17_0_g21 ) - temp_output_15_0_g21 );
			float3 ClosestCubeCenter289 = quantizedCubeCenter180;
			float3 localBetterWorldSpaceCameraPos1_g13 = BetterWorldSpaceCameraPos1_g13();
			float4 transform86 = mul(unity_ObjectToWorld,float4( 0,0,0,1 ));
			float4 lerpResult82 = lerp( float4( localBetterWorldSpaceCameraPos1_g13 , 0.0 ) , transform86 , _MixViewObjectPosition);
			float4 viewTestPoint84 = lerpResult82;
			float3 ViewPosition289 = viewTestPoint84.xyz;
			float MinDistance289 = _EmissionMinDistance;
			float MaxDistance289 = _EmissionMaxDistance;
			float QuantizeLerp289 = _CubifyEmissionGradient;
			float3 WorldPosition289 = ase_worldPos;
			float localBubbleHandViewProximity289 = BubbleHandViewProximity289( ClosestCubeCenter289 , ViewPosition289 , MinDistance289 , MaxDistance289 , QuantizeLerp289 , WorldPosition289 );
			float smoothstepResult27 = smoothstep( 0.0 , 1.0 , localBubbleHandViewProximity289);
			float temp_output_18_0_g78 = smoothstepResult27;
			float4 temp_cast_3 = (temp_output_18_0_g78).xxxx;
			float4 temp_output_1_0_g80 = temp_cast_3;
			float4 break5_g80 = temp_output_1_0_g80;
			float Sample2_g82 = saturate( temp_output_18_0_g78 );
			float localAudioLinkLerp2_g82 = AudioLinkLerp2_g82( Sample2_g82 );
			int Band3_g79 = 0;
			float smoothstepResult6_g78 = smoothstep( 0.0 , 1.0 , ( abs( ( 0.5 - temp_output_18_0_g78 ) ) * 2.0 ));
			float Delay3_g79 = ( smoothstepResult6_g78 * 128.0 * _PulseWidth );
			float localAudioLinkLerp3_g79 = AudioLinkLerp3_g79( Band3_g79 , Delay3_g79 );
			float lerpResult11_g78 = lerp( localAudioLinkLerp2_g82 , localAudioLinkLerp3_g79 , _AutoCorrBassBand);
			float lerpResult14_g78 = lerp( 0.5 , saturate( lerpResult11_g78 ) , _EmissionAudioLinkIntensity);
			float4 temp_cast_4 = (lerpResult14_g78).xxxx;
			float4 temp_output_2_0_g80 = temp_cast_4;
			float temp_output_303_0 = saturate( ( ( ( break5_g80.r * 0.2 ) + ( break5_g80.g * 0.7 ) + ( break5_g80.b * 0.1 ) ) < 0.5 ? ( 2.0 * temp_output_1_0_g80 * temp_output_2_0_g80 ) : ( 1.0 - ( 2.0 * ( 1.0 - temp_output_1_0_g80 ) * ( 1.0 - temp_output_2_0_g80 ) ) ) ).r );
			float4 emission247 = saturate( ( saturate( lerpResult37 ) * SampleGradient( gradient351, temp_output_303_0 ) ) );
			float localLTCGI15_g71 = ( 0.0 );
			float3 worldPos15_g71 = ase_worldPos;
			float2 uv_BumpMap = i.uv_texcoord * _BumpMap_ST.xy + _BumpMap_ST.zw;
			float3 normalizeResult9_g71 = normalize( (WorldNormalVector( i , UnpackNormal( tex2D( _BumpMap, uv_BumpMap ) ) )) );
			float3 worldNorm15_g71 = normalizeResult9_g71;
			float3 normalizeResult12_g71 = normalize( ( _WorldSpaceCameraPos - ase_worldPos ) );
			float3 cameraDir15_g71 = normalizeResult12_g71;
			float roughness15_g71 = ( 1.0 - _Smoothness );
			float2 lightmapUV15_g71 = i.uv2_texcoord2;
			float3 diffuse15_g71 = float3( 0,0,0 );
			float3 specular15_g71 = float3( 0,0,0 );
			float specularIntensity15_g71 = 0;
			{
			LTCGI_Contribution(worldPos15_g71, worldNorm15_g71, cameraDir15_g71, roughness15_g71, lightmapUV15_g71, diffuse15_g71, specular15_g71, specularIntensity15_g71);
			}
			float3 ltcgi168 = ( ( diffuse15_g71 * 0.05 ) + ( specular15_g71 * 1.0 ) );
			o.Emission = ( emission247 + float4( ltcgi168 , 0.0 ) ).rgb;
			o.Alpha = 1;
		}

		ENDCG
		CGPROGRAM
		#pragma surface surf Standard keepalpha fullforwardshadows vertex:vertexDataFunc 

		ENDCG
		Pass
		{
			Name "ShadowCaster"
			Tags{ "LightMode" = "ShadowCaster" }
			ZWrite On
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			#pragma multi_compile_shadowcaster
			#pragma multi_compile UNITY_PASS_SHADOWCASTER
			#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
			#include "HLSLSupport.cginc"
			#if ( SHADER_API_D3D11 || SHADER_API_GLCORE || SHADER_API_GLES || SHADER_API_GLES3 || SHADER_API_METAL || SHADER_API_VULKAN )
				#define CAN_SKIP_VPOS
			#endif
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"
			struct v2f
			{
				V2F_SHADOW_CASTER;
				float4 customPack1 : TEXCOORD1;
				float4 tSpace0 : TEXCOORD2;
				float4 tSpace1 : TEXCOORD3;
				float4 tSpace2 : TEXCOORD4;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};
			v2f vert( appdata_full v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID( v );
				UNITY_INITIALIZE_OUTPUT( v2f, o );
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );
				UNITY_TRANSFER_INSTANCE_ID( v, o );
				Input customInputData;
				vertexDataFunc( v, customInputData );
				float3 worldPos = mul( unity_ObjectToWorld, v.vertex ).xyz;
				half3 worldNormal = UnityObjectToWorldNormal( v.normal );
				half3 worldTangent = UnityObjectToWorldDir( v.tangent.xyz );
				half tangentSign = v.tangent.w * unity_WorldTransformParams.w;
				half3 worldBinormal = cross( worldNormal, worldTangent ) * tangentSign;
				o.tSpace0 = float4( worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x );
				o.tSpace1 = float4( worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y );
				o.tSpace2 = float4( worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z );
				o.customPack1.xy = customInputData.uv_texcoord;
				o.customPack1.xy = v.texcoord;
				o.customPack1.zw = customInputData.uv2_texcoord2;
				o.customPack1.zw = v.texcoord1;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET( o )
				return o;
			}
			half4 frag( v2f IN
			#if !defined( CAN_SKIP_VPOS )
			, UNITY_VPOS_TYPE vpos : VPOS
			#endif
			) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				Input surfIN;
				UNITY_INITIALIZE_OUTPUT( Input, surfIN );
				surfIN.uv_texcoord = IN.customPack1.xy;
				surfIN.uv2_texcoord2 = IN.customPack1.zw;
				float3 worldPos = float3( IN.tSpace0.w, IN.tSpace1.w, IN.tSpace2.w );
				half3 worldViewDir = normalize( UnityWorldSpaceViewDir( worldPos ) );
				surfIN.worldPos = worldPos;
				surfIN.worldNormal = float3( IN.tSpace0.z, IN.tSpace1.z, IN.tSpace2.z );
				surfIN.internalSurfaceTtoW0 = IN.tSpace0.xyz;
				surfIN.internalSurfaceTtoW1 = IN.tSpace1.xyz;
				surfIN.internalSurfaceTtoW2 = IN.tSpace2.xyz;
				SurfaceOutputStandard o;
				UNITY_INITIALIZE_OUTPUT( SurfaceOutputStandard, o )
				surf( surfIN, o );
				#if defined( CAN_SKIP_VPOS )
				float2 vpos = IN.pos;
				#endif
				SHADOW_CASTER_FRAGMENT( IN )
			}
			ENDCG
		}
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=18935
3856.8;22.4;1940;1560;-443.9541;931.1885;1;True;False
Node;AmplifyShaderEditor.CommentaryNode;198;-1522.222,-288.9193;Inherit;False;873.4077;536.9681;Quantize To World Cube Center;5;244;180;280;281;278;;0.8313726,0.46207,0,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;111;-1515.939,273.3344;Inherit;False;1012.272;523.147;View Test Point;5;84;82;86;175;83;;0.5576458,0,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;83;-1450.098,671.1414;Inherit;False;Property;_MixViewObjectPosition;Mix View / Object Position;16;0;Create;True;0;0;0;True;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.WorldPosInputsNode;278;-1485.68,-237.3869;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.FunctionNode;175;-1447.323,382.2635;Inherit;False;WorldSpaceMiddleCameraPos;-1;;13;2a245f7d1bf87f24abdaf57f89897db7;0;0;1;FLOAT3;0
Node;AmplifyShaderEditor.CommentaryNode;199;-3243.272,-702.5749;Inherit;False;813.0142;621.063;World UV Small Cubes;6;10;8;5;4;7;148;;0.7314231,1,0.3349057,1;0;0
Node;AmplifyShaderEditor.ObjectToWorldTransfNode;86;-1361.025,473.0961;Inherit;False;1;0;FLOAT4;0,0,0,1;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector3Node;281;-1477.88,-82.68622;Inherit;False;Property;_CubeOffset;Cube Offset;12;0;Create;True;0;0;0;True;0;False;0,0,0;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.Vector3Node;280;-1468.781,86.31424;Inherit;False;Property;_CubeSize;Cube Size;11;0;Create;True;0;0;0;True;0;False;1,1,1;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.WorldPosInputsNode;7;-3187.668,-503.0874;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.WorldNormalVector;4;-3199.853,-651.5751;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.Vector3Node;10;-3192.668,-260.0287;Inherit;False;Property;_EmissiveCubeOffset;Emissive Cube Offset;7;0;Create;True;0;0;0;True;0;False;0,0,0;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.LerpOp;82;-990.246,505.1903;Inherit;False;3;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0,0,0,0;False;2;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.FunctionNode;244;-1200.408,-91.10492;Inherit;False;QuantizeVector;-1;;21;69cf507c3daae8e4681450ea1a0e61bb;0;3;13;FLOAT3;0,0,0;False;15;FLOAT3;0.0625,0.0625,0.0625;False;16;FLOAT3;0.125,0.125,0.125;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;8;-3189.697,-349.9994;Inherit;False;Property;_EmissiveCubeScale;Emissive Cube Scale;6;0;Create;True;0;0;0;True;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.CustomExpressionNode;5;-2907.583,-464.9553;Inherit;False;float scaleInv = 1 / Scale@$if (abs(Normal.x) > 0.5)${$	return Position.yz * scaleInv + Offset.yz@$}$else if (abs(Normal.z) > 0.5)${$	return Position.xy * scaleInv + Offset.xy@$}$else${$	return Position.xz * scaleInv + Offset.xz@$};2;Create;4;True;Normal;FLOAT3;0,0,0;In;;Inherit;False;True;Position;FLOAT3;0,0,0;In;;Inherit;False;True;Scale;FLOAT;0;In;;Inherit;False;True;Offset;FLOAT3;0,0,0;In;;Inherit;False;Cubic World Texture UV;True;False;0;;False;4;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;3;FLOAT3;0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.CommentaryNode;246;-447.5663,-1164.013;Inherit;False;3055.732;691.0247;Emission;16;247;29;33;338;303;306;251;27;289;288;291;286;192;284;287;249;;0,0.6262352,1,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;84;-733.9241,546.2423;Inherit;False;viewTestPoint;-1;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;180;-908.4849,-53.93867;Inherit;False;quantizedCubeCenter;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CommentaryNode;249;558.3055,-1104.66;Inherit;False;1194.273;290.921;Lerp between inverted maintex based on prox;5;37;39;40;6;149;;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;284;-349.7929,-820.5033;Inherit;False;Property;_EmissionMaxDistance;Emission Max Distance;9;0;Create;True;0;0;0;True;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;192;-391.2611,-725.3784;Inherit;False;Property;_CubifyEmissionGradient;Cubify Emission Gradient;10;0;Create;True;0;0;0;True;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;287;-344.2088,-910.1994;Inherit;False;Property;_EmissionMinDistance;Emission Min Distance;8;0;Create;True;0;0;0;True;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;288;-363.0639,-1090.368;Inherit;False;180;quantizedCubeCenter;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;286;-316.3415,-996.9904;Inherit;False;84;viewTestPoint;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;148;-2655.057,-548.5904;Inherit;False;worldUVSMall;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.WorldPosInputsNode;291;-290.4955,-639.6894;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.GetLocalVarNode;149;600.2416,-1036.466;Inherit;False;148;worldUVSMall;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.CommentaryNode;299;48.65179,-388.291;Inherit;False;355.0259;456.1271;AudioLink Settings;4;304;52;51;53;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CustomExpressionNode;289;-11.89377,-888.1484;Inherit;False;float proximity = 0@$float3 testPosition = lerp(WorldPosition, ClosestCubeCenter, QuantizeLerp)@$$// player positions$for (uint i = 0@ i < 100@ i++)${$	// lighten blending mode$	proximity = max(saturate(AudioLinkRemap(length(PlayerPositions[i] - testPosition), MaxDistance, MinDistance, 0, 1)), proximity)@$}$$// head positions$for (uint i = 0@ i < 100@ i++)${$	// lighten blending mode$	proximity = max(saturate(AudioLinkRemap(length(HeadPositions[i] - testPosition), MaxDistance, MinDistance, 0, 1)), proximity)@$}$$// hand positions$for (uint i = 0@ i < 200@ i++)${$	// lighten blending mode$	proximity = max(saturate(AudioLinkRemap(length(HandPositions[i] - testPosition), MaxDistance, MinDistance, 0, 1)), proximity)@$}$$// view position lighten blend in$proximity = max(saturate(AudioLinkRemap(length(testPosition - ViewPosition), MaxDistance, MinDistance, 0, 1)), proximity)@$$return saturate(proximity)@;1;Create;6;True;ClosestCubeCenter;FLOAT3;0,0,0;In;;Inherit;False;True;ViewPosition;FLOAT3;0,0,0;In;;Inherit;False;True;MinDistance;FLOAT;0;In;;Inherit;False;True;MaxDistance;FLOAT;0;In;;Inherit;False;True;QuantizeLerp;FLOAT;0;In;;Inherit;False;True;WorldPosition;FLOAT3;0,0,0;In;;Inherit;False;Bubble + Hand + View Proximity;True;False;0;;False;6;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;53;102.5201,-27.9189;Inherit;False;Property;_AutoCorrBassBand;AutoCorr / BassBand;19;0;Create;True;0;0;0;True;0;False;0.5;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;51;99.96145,-123.8223;Inherit;False;Property;_PulseWidth;Pulse Width;15;0;Create;True;0;0;0;True;0;False;0.5;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;52;102.368,-338.291;Inherit;False;Property;_EmissionAudioLinkIntensity;Emission AudioLink Intensity;18;0;Create;True;0;0;0;True;0;False;0.8;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;6;821.1118,-1044.217;Inherit;True;Property;_SmallCubes;Small Cubes;5;0;Create;True;0;0;0;True;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.CommentaryNode;197;-373.6837,109.0049;Inherit;False;1869.159;533.3472;Vertex Shader: lerp between original vertex locations and quantized cubic centers based on proximity to player bubble positions, hands, and view positions added. Absolute positioning;12;255;93;252;301;89;121;262;273;265;117;277;319;;0.4745098,1,0.9483536,1;0;0
Node;AmplifyShaderEditor.SmoothstepOpNode;27;332.078,-899.2231;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;204;-2395.367,-1237.373;Inherit;False;1480.388;515.966;LTCGI;11;158;159;166;167;161;160;165;162;163;164;168;;0.3066038,1,0.4675546,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;251;1074.072,-768.2969;Inherit;False;655.0183;268.6903;Gradient based on emission prox;2;141;351;;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;158;-2231.617,-1089.484;Inherit;False;Constant;_Float1;Float 1;3;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;39;1221.876,-1055.295;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.FunctionNode;306;557.295,-771.351;Inherit;False;AudioLinkOverlay;-1;;78;38b4baa83024e894991549b38fce9d54;0;6;18;FLOAT;0;False;21;INT;0;False;17;FLOAT;0.8;False;19;FLOAT;0.5;False;22;FLOAT;0.5;False;20;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;117;-299.6818,499.2082;Inherit;False;Property;_VertMaxDistance;Vert Max Distance;14;0;Create;True;0;0;0;True;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;159;-2345.367,-1187.373;Inherit;False;Property;_Smoothness;Smoothness;4;0;Create;True;0;0;0;True;0;False;0.5;0.925;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;277;-294.0978,409.5116;Inherit;False;Property;_VertMinDistance;Vert Min Distance;13;0;Create;True;0;0;0;True;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;273;-337.6528,218.9431;Inherit;False;180;quantizedCubeCenter;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;265;-293.5302,318.8213;Inherit;False;84;viewTestPoint;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;167;-2046.295,-1099.421;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;37;1478.49,-1015.538;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;1,1,1,0;False;1;COLOR;0
Node;AmplifyShaderEditor.CustomExpressionNode;262;10.76573,401.4299;Inherit;False;float proximity = 0@$$// player positions$for (uint i = 0@ i < 100@ i++)${$	// lighten blending mode$	proximity = max(saturate(AudioLinkRemap(length(PlayerPositions[i] - ClosestCubeCenter), MaxDistance, MinDistance, 0, 1)), proximity)@$}$$// head positions$for (uint i = 0@ i < 100@ i++)${$	// lighten blending mode$	proximity = max(saturate(AudioLinkRemap(length(HeadPositions[i] - ClosestCubeCenter), MaxDistance, MinDistance, 0, 1)), proximity)@$}$$// hand positions$for (uint i = 0@ i < 200@ i++)${$	// lighten blending mode$	proximity = max(saturate(AudioLinkRemap(length(HandPositions[i] - ClosestCubeCenter), MaxDistance, MinDistance, 0, 1)), proximity)@$}$$// view position lighten blend in$proximity = max(saturate(AudioLinkRemap(length(ClosestCubeCenter - ViewPosition), MaxDistance, MinDistance, 0, 1)), proximity)@$$return saturate(proximity)@;1;Create;4;True;ClosestCubeCenter;FLOAT3;0,0,0;In;;Inherit;False;True;ViewPosition;FLOAT3;0,0,0;In;;Inherit;False;True;MinDistance;FLOAT;0;In;;Inherit;False;True;MaxDistance;FLOAT;0;In;;Inherit;False;Bubble + Hand + View Proximity;True;False;0;;False;4;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GradientNode;351;1115.954,-606.1885;Inherit;False;0;8;2;0,0,0,0;0.1603774,0,0.1501947,0.2235294;0.2132809,0,0.490566,0.4260014;0,0.2383077,1,0.7117723;0.365655,0.8437017,0.9339623,0.9593805;0.810892,0.7028302,1,0.9779507;1,0.4117647,0.7898859,0.9895476;0,0,0,1;1,0;1,1;0;1;OBJECT;0
Node;AmplifyShaderEditor.SaturateNode;303;909.7644,-754.23;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TexturePropertyNode;166;-2185.966,-954.1962;Inherit;True;Property;_BumpMap;BumpMap;3;1;[Normal];Create;True;0;0;0;False;0;False;None;None;True;bump;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.FunctionNode;161;-1888.232,-976.7701;Inherit;False;LTCGI_Contribution;-1;;71;d3ea6060590627141a6e856295f0e87c;0;2;18;SAMPLER2D;0;False;21;FLOAT;0;False;3;FLOAT3;16;FLOAT;17;FLOAT3;0
Node;AmplifyShaderEditor.SmoothstepOpNode;121;319.0092,376.5454;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;160;-1665.576,-836.806;Inherit;False;Constant;_Float3;Float 3;3;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;304;106.9399,-232.9833;Inherit;False;Property;_VertAudioLinkIntensity;Vert AudioLink Intensity;17;0;Create;True;0;0;0;True;0;False;0.8;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;165;-1665.576,-1061.937;Inherit;False;Constant;_Float2;Float 2;3;0;Create;True;0;0;0;False;0;False;0.05;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;310;-2395.91,-703.2172;Inherit;False;846.5942;624.088;World UV Big Cubes;6;316;315;314;313;312;311;;0.7314231,1,0.3349057,1;0;0
Node;AmplifyShaderEditor.SaturateNode;338;1798.159,-943.9639;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GradientSampleNode;141;1398.144,-705.2969;Inherit;True;2;0;OBJECT;;False;1;FLOAT;0;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;162;-1507.81,-1028.754;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;33;2008.868,-840.2326;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;163;-1505.255,-903.2233;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.PosVertexDataNode;89;549.66,177.2814;Inherit;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.WorldPosInputsNode;311;-2333.725,-504.7299;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.FunctionNode;307;543.0581,428.3989;Inherit;False;AudioLinkOverlay;-1;;83;38b4baa83024e894991549b38fce9d54;0;6;18;FLOAT;0;False;21;INT;0;False;17;FLOAT;0.8;False;19;FLOAT;0.5;False;22;FLOAT;0.5;False;20;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldNormalVector;314;-2345.91,-653.2173;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.Vector3Node;312;-2337.725,-268.6712;Inherit;False;Property;_AlbedoCubeOffset;Albedo Cube Offset;2;0;Create;True;0;0;0;True;0;False;0,0,0;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;313;-2328.754,-358.6419;Inherit;False;Property;_AlbedoCubeScale;Albedo Cube Scale;1;0;Create;True;0;0;0;True;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;164;-1346.1,-966.963;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.FunctionNode;252;798.0707,280.933;Inherit;False;QuantizeVector;-1;;77;69cf507c3daae8e4681450ea1a0e61bb;0;3;13;FLOAT3;0,0,0;False;15;FLOAT3;0.0625,0.0625,0.0625;False;16;FLOAT3;0.125,0.125,0.125;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SaturateNode;29;2204.054,-812.4483;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.WireNode;301;972.3445,413.7084;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CustomExpressionNode;315;-2053.64,-466.5979;Inherit;False;float scaleInv = 1 / Scale@$if (abs(Normal.x) > 0.5)${$	return Position.yz * scaleInv + Offset.yz@$}$else if (abs(Normal.z) > 0.5)${$	return Position.xy * scaleInv + Offset.xy@$}$else${$	return Position.xz * scaleInv + Offset.xz@$};2;Create;4;True;Normal;FLOAT3;0,0,0;In;;Inherit;False;True;Position;FLOAT3;0,0,0;In;;Inherit;False;True;Scale;FLOAT;0;In;;Inherit;False;True;Offset;FLOAT3;0,0,0;In;;Inherit;False;Cubic World Texture UV;True;False;0;;False;4;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;3;FLOAT3;0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;316;-1775.414,-550.5327;Inherit;False;worldUVBig;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.LerpOp;93;1071.07,224.391;Inherit;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;168;-1139.779,-884.4927;Inherit;False;ltcgi;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;247;2389.174,-789.3455;Inherit;False;emission;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;156;1553.286,-305.2704;Inherit;False;316;worldUVBig;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;255;1255.181,235.2426;Inherit;False;absVertPos;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;248;1865.926,-40.6795;Inherit;False;247;emission;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.CommentaryNode;75;-1523.628,-701.9573;Inherit;False;847.2349;396.8512;Is Back Face?;5;58;59;56;62;63;;0,1,0.5054021,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;290;-1854.169,-53.21796;Inherit;False;308.3387;429.3571;Vector4 Array Declarations;3;264;263;305;;1,0,0.342041,1;0;0
Node;AmplifyShaderEditor.GetLocalVarNode;169;1863.393,64.35925;Inherit;False;168;ltcgi;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;63;-901.1932,-518.4063;Inherit;False;backFace;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;58;-1445.248,-490.7063;Inherit;False;World;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SamplerNode;155;1813.988,-295.1212;Inherit;True;Property;_MainTex;Main Tex;0;0;Create;True;0;0;0;True;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RegisterLocalVarNode;319;303.8052,540.7806;Inherit;False;vertCubeProx;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;324;17.55051,-1707.055;Inherit;False;Property;_SmallCubeScaleCenter;Small Cube Scale Center;20;0;Create;True;0;0;0;False;0;False;0.5;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;256;1938.605,246.6856;Inherit;False;255;absVertPos;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GlobalArrayNode;305;-1801.839,222.8825;Inherit;False;HeadPositions;0;200;2;False;False;0;1;True;Object;-1;4;0;INT;0;False;2;INT;0;False;1;INT;0;False;3;INT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleAddOpNode;317;2074.824,6.183259;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT3;0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GradientNode;352;1060.954,-343.1885;Inherit;False;0;8;2;0,0,0,0;0.1603774,0,0.1501947,0.2235294;0.2132809,0,0.490566,0.4260014;0,0.2383077,1,0.7117723;0.365655,0.8437017,0.9339623,0.9593805;0.810892,0.7028302,1,0.9779507;1,0.4117647,0.7898859,0.9895476;0,0,0,1;1,0;1,1;0;1;OBJECT;0
Node;AmplifyShaderEditor.GlobalArrayNode;263;-1801.07,-3.218027;Inherit;False;PlayerPositions;0;100;2;False;False;0;1;True;Object;-1;4;0;INT;0;False;2;INT;0;False;1;INT;0;False;3;INT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.WorldNormalVector;59;-1473.628,-651.957;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.DotProductOpNode;56;-1246.588,-584.8771;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GlobalArrayNode;264;-1804.17,107.6824;Inherit;False;HandPositions;0;200;2;False;False;0;1;True;Object;-1;4;0;INT;0;False;2;INT;0;False;1;INT;0;False;3;INT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.OneMinusNode;40;1209.174,-935.5413;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Compare;62;-1096.947,-560.3661;Inherit;False;2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;146;2259.831,-129.3808;Float;False;True;-1;2;ASEMaterialInspector;0;0;Standard;Door;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;Back;0;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Opaque;0;True;True;0;False;Opaque;;Geometry;All;18;all;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;True;0;1;False;-1;1;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;True;Absolute;0;;-1;-1;-1;-1;1;LTCGI=ALWAYS;False;0;0;False;-1;-1;0;False;-1;1;Include;Assets/_pi_/_LTCGI/Shaders/LTCGI.cginc;False;;Custom;0;0;False;0.1;False;-1;0;False;-1;False;16;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;82;0;175;0
WireConnection;82;1;86;0
WireConnection;82;2;83;0
WireConnection;244;13;278;0
WireConnection;244;15;281;0
WireConnection;244;16;280;0
WireConnection;5;0;4;0
WireConnection;5;1;7;0
WireConnection;5;2;8;0
WireConnection;5;3;10;0
WireConnection;84;0;82;0
WireConnection;180;0;244;0
WireConnection;148;0;5;0
WireConnection;289;0;288;0
WireConnection;289;1;286;0
WireConnection;289;2;287;0
WireConnection;289;3;284;0
WireConnection;289;4;192;0
WireConnection;289;5;291;0
WireConnection;6;1;149;0
WireConnection;27;0;289;0
WireConnection;39;0;6;0
WireConnection;306;18;27;0
WireConnection;306;17;52;0
WireConnection;306;19;51;0
WireConnection;306;20;53;0
WireConnection;167;0;158;0
WireConnection;167;1;159;0
WireConnection;37;0;39;0
WireConnection;37;1;6;0
WireConnection;262;0;273;0
WireConnection;262;1;265;0
WireConnection;262;2;277;0
WireConnection;262;3;117;0
WireConnection;303;0;306;0
WireConnection;161;18;166;0
WireConnection;161;21;167;0
WireConnection;121;0;262;0
WireConnection;338;0;37;0
WireConnection;141;0;351;0
WireConnection;141;1;303;0
WireConnection;162;0;161;0
WireConnection;162;1;165;0
WireConnection;33;0;338;0
WireConnection;33;1;141;0
WireConnection;163;0;161;16
WireConnection;163;1;160;0
WireConnection;307;18;121;0
WireConnection;307;17;304;0
WireConnection;307;19;51;0
WireConnection;307;20;53;0
WireConnection;164;0;162;0
WireConnection;164;1;163;0
WireConnection;252;13;89;0
WireConnection;29;0;33;0
WireConnection;301;0;307;0
WireConnection;315;0;314;0
WireConnection;315;1;311;0
WireConnection;315;2;313;0
WireConnection;315;3;312;0
WireConnection;316;0;315;0
WireConnection;93;0;89;0
WireConnection;93;1;252;0
WireConnection;93;2;301;0
WireConnection;168;0;164;0
WireConnection;247;0;29;0
WireConnection;255;0;93;0
WireConnection;63;0;62;0
WireConnection;155;1;156;0
WireConnection;319;0;262;0
WireConnection;317;0;248;0
WireConnection;317;1;169;0
WireConnection;56;0;59;0
WireConnection;56;1;58;0
WireConnection;40;0;303;0
WireConnection;62;0;56;0
WireConnection;146;0;155;0
WireConnection;146;2;317;0
WireConnection;146;11;256;0
ASEEND*/
//CHKSM=E6D40EEA558CFC4C3DDA7D022CBDCAB677B5823B