﻿Shader "cnlohr/hexitone"
{
	Properties
	{
		_Tiling( "Tiling", Range( 0, 200 ) ) = 1.0
		_AspectRatio( "Aspect Ratio", Range( -2, 2 ) ) = 0.707
		_EffectRotateX( "Effect RotateX", float ) = 0

		_FlipAdvance( "Flip Advance", range(-6,6) ) = 1
		_Brightness( "Brightness", range(-10,10) ) = 1
		_HeighStep( "Heigh Step", range(-6,6) ) = 0.5
		_RayNoise( "Ray Noise (mm)", range(0,20) ) = 1
		
		_BiasColor( "Bias Color", Color ) = ( 0, 0, 0, 1 )
		_RayBias ("Ray Bias (mm)", range( -20, 20 ) ) = 0.0
		
		_SpeedX( "Speed X", range(-.1,.1) ) = 0.02
		_SpeedY( "Speed Y", range(-.1,.1) ) = 0.03
		
		_NonCCColor( "Non-CC Color", Color ) = ( .4,.4,1.,1 )
		
		[Toggle(_is_torso_local)] _is_torso_local ( "Torso (check)/Wall (uncheck)", int ) = 0
		[Toggle(_is_floormode_local)] _is_floormode_local ( "FloorMode", int ) = 0
		[Toggle(_use_hq_noise_local)]_use_hq_noise_local ("High Quality Noise", int) = 0

		_TANoiseTex ("TANoise", 2D) = "white" {}
		_TANoiseTexNearest ("TANoiseNearest", 2D) = "white" {}
	}
	SubShader
	{
		
		Tags { "RenderType"="Opaque" }
		LOD 100

		// shadow caster rendering pass, implemented manually
		// using macros from UnityCG.cginc
		Pass
		{
			Tags {"LightMode"="ShadowCaster"}
			Cull Off
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_shadowcaster
			#pragma multi_compile_instancing
			#include "UnityCG.cginc"

			struct v2f { 
				V2F_SHADOW_CASTER;
				float4 uv : TEXCOORD0;
			};

			v2f vert(appdata_base v)
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
				o.uv = v.texcoord;
				return o;
			}

			float4 frag(v2f i) : SV_Target
			{
				SHADOW_CASTER_FRAGMENT(i)
			}
			ENDCG
		}


		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			// Uncomment for fog.
			//#pragma multi_compile_fog
			
			// Torso/Wall
			#pragma shader_feature_local _is_torso_local
			#pragma shader_feature_local _is_floormode_local
			#pragma shader_feature_local _use_hq_noise_local

			#include "Packages/com.llealloo.audiolink/Runtime/Shaders/AudioLink.cginc"
			#include "Assets/AudioLinkSandbox/Prefabs/cnlohr/Shaders/hashwithoutsine/hashwithoutsine.cginc"
			#include "Assets/AudioLinkSandbox/Prefabs/cnlohr/Shaders/tanoise/tanoise.cginc"
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
				
				float3 roLocal : TEXCOORD2;
				float3 hitLocal : TEXCOORD3;
				float3 hitWorld : TEXCOORD4;
				float3 zeroLocal : TEXCOORD5;
				float3 surfWorld : TEXCOORD6;
			};

			float _Tiling, _AspectRatio, _EffectRotateX;
			float _Brightness, _FlipAdvance, _HeighStep;
			float _RayNoise, _RayBias;
			float _SpeedX, _SpeedY;
			float4 _BiasColor;
			float4 _NonCCColor;

			v2f vert (appdata v)
			{
#if _is_torso_local
				float gtime = (AudioLinkDecodeDataAsSeconds( ALPASS_GENERALVU_NETWORK_TIME )%20000)*.2;
#else
				float gtime = (AudioLinkDecodeDataAsSeconds( ALPASS_GENERALVU_NETWORK_TIME )%20000);
#endif				
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;

#if _is_floormode_local
				float rx = 90./180*3.14159;
#else
				float rx = _EffectRotateX/180*3.14159;
#endif

				float3x3 XRotation = {
					{ 1.0, 0.0, 0.0 },
					{ 0.0, cos(rx), -sin(rx) },
					{ 0.0, sin(rx), cos(rx) }
				};
				o.roLocal = mul( XRotation, mul( unity_WorldToObject, float4( _WorldSpaceCameraPos , 1.0 )) );

				//Local-space (do not discard rotation)
				o.hitLocal = mul( XRotation, v.vertex );

#if _is_floormode_local
				float angle = frac(gtime/50/6.283)*6.283;
				float c = cos(angle);
				float s = sin(angle);
				o.roLocal.xy = mul( o.roLocal.xy, float2x2(c,s,-s,c) );
				o.hitLocal.xy = mul( o.hitLocal.xy, float2x2(c,s,-s,c) );
#endif


				//World Space
				o.hitWorld = mul( unity_ObjectToWorld, v.vertex );
				o.zeroLocal = mul( unity_ObjectToWorld, float4(0.,0.,0.,1.) );

				//Not sure why, sometimes o.UseY gets messed up and can crash my GPU					
				o.surfWorld = mul( unity_ObjectToWorld, float4(v.vertex.xyz,1.) );

				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			// Let's split everything into triangular segments.
			//
			//   *---*
			//  / \ / \
			// *---*---*
			
			float maxv( float3 v ) { return max( max( v.x, v.y ), v.z ); }
			float minv( float3 v ) { return min( min( v.x, v.y ), v.z ); }
			
			float Trace( float3 coorde, float trisep, float hexsep, float heighsep, out uint2 coordei, out uint2 coordeihex, float AspectRatio )
			{
				coorde.y *= AspectRatio;
				coorde.x -= coorde.y/2;
				coordei = floor( coorde.xy ) + 10000; // So we can use uints instead of ints.
				float2 coordef = frac( coorde.xy );
				float3 triuv = float3( coordef, 0. );

				coordei.x *= 2;
				coordei.x += coordei.y*2;
				if( coordef.x + coordef.y > 1 )
				{
					coordei.x--;
					triuv.xy = 1.-triuv.xy;
				}
				triuv.z = 1.-(triuv.x+triuv.y);
				coordei.y += coordei.x/2;
				int tri_in_hex = (coordei.x%4) + (coordei.y%3) * 4;
				
				uint hexdec[12] = {
					0|(0<<5)|(0<<8), 2|(3<<5)|(3<<8), 1|(0<<5)|(0<<8), 3|(3<<5)|(3<<8),
					5|(2<<5)|(2<<8), 4|(3<<5)|(2<<8), 4|(2<<5)|(2<<8), 5|(3<<5)|(2<<8),
					3|(2<<5)|(1<<8), 1|(5<<5)|(4<<8), 2|(2<<5)|(1<<8), 0|(5<<5)|(4<<8),
				};
				uint code = hexdec[tri_in_hex];
				switch( (code>>1)&15 )
				{
				case 0: triuv = triuv.xyz; break;
				case 1: triuv = triuv.yzx; break;
				case 2: triuv = triuv.zxy; break;
				}

				// Triuv's .z now inversely eminates from the center of each hex group.
				if( AspectRatio<0) 
				{
					coordeihex = coordei;
				}
				else
				{
					coordeihex = coordei + uint2( (code>>5)&7, (code>>8)&7 );
					coordeihex = uint2( (coordeihex.x-coordeihex.y)/2, (coordeihex.y+1)/3 );
					coordeihex.x += (coordeihex.y+1)/2;
				}
				//OKAY!  Now,
				// coordeihex = HEX position
				// coordei = TRI position
				// triuv = z at max in center of hex.

				float w = 
					min(
						min( 
							(triuv.z - hexsep), 
							//(min( triuv.x+triuv.z, triuv.y+triuv.z ) - 0.3 )*.4 ), // Weird corners
							1),
						min(
							minv( triuv ) - trisep,
							(coorde.z)*heighsep
							)
						);

				return w;
			}

			float4 frag (v2f i) : SV_Target
			{
#if _is_torso_local
				float gtime = (AudioLinkDecodeDataAsSeconds( ALPASS_GENERALVU_NETWORK_TIME )%20000)*.2;
#else
				float gtime = (AudioLinkDecodeDataAsSeconds( ALPASS_GENERALVU_NETWORK_TIME )%20000);
#endif
				float FlipAdvance = _FlipAdvance;
				float FlipAdvanceB = _FlipAdvance;
				float Brightness = _Brightness;
				float heighsep = _HeighStep;
				float AspectRatio = _AspectRatio;
				float Tiling = _Tiling;
				float3 BiasColor = _BiasColor;
				float3 NonCCColor = _NonCCColor;
				
#if _is_floormode_local
				const uint modes = 8;
				float mixtime = gtime/15.;
				uint mode = ((uint)floor( mixtime ))%modes;
				float modemix = 1/(exp((-frac(mixtime)+0.5)*60)+1);

				float3 mode_data[4*8] = {
					float3( 1.0, 1.8, -1.5 ), float3( 10.0, 1.13, 90.0 ), float3( 0.3207547, 0.2436, 0 ), float3( 1, 0.7686275, 0 ),
					float3( -0.8, 0.5, 3.0 ), float3( 3.5, -1.13, 90.0 ), float3( 0.2436, 0.3207547, 0 ), float3( 0.7686275, 1, 0 ),
					float3( -.389, .323, -.51 ), float3( 17, 1.13, 90.0 ), float3( 0.2539723, 0, 0.6980392 ), float3( 1, 0.3180476, 0 ),
					float3( .96, -.025, -4.76 ), float3( 3.84, -1.13, 90.0 ), float3( 0, 0.04089664, 0.15 ), float3( 0.745283, 0.745283, 0.745283 ),
					float3( .82, .74, -.45 ), float3( 15, 1.13, 90.0 ), float3( 0.3207547, 0, 0.2436 ), float3( 0.7686275, 0, 1 ),
					float3( 1.73, 1.4, 5 ), float3( 3.84, -1.13, 90.0 ), float3( 0.107547, 0.2436, .3 ), float3( .0, 0.7686275, .4 ),
					float3( -2, .5, -.4 ), float3( 7.25, 1.13, 90.0 ), float3( 0.15, 0, 0 ), float3( .8, .1, -.5 ),
					float3( .5, -3, -1.2 ), float3( 6, 1.13, 90.0 ), float3( .1, .1, .1 ), float3( .6, .6, .6 ),
				};
				float fab[8] = { 1, -.8, .96, .96, .80, 1.,.66, 1 };
				int nextmode = ( mode + 1 ) % modes;
				float3 fma = lerp( mode_data[mode*4+0], mode_data[nextmode*4+0], modemix );
				float3 fmb = lerp( mode_data[mode*4+1], mode_data[nextmode*4+1], modemix );
				FlipAdvance = fma.x;
				Brightness = fma.y;
				heighsep = fma.z;
				AspectRatio = fmb.y;
				Tiling = fmb.x;
				BiasColor = pow( lerp( mode_data[mode*4+2], mode_data[nextmode*4+2], modemix ), 2.2 );
				NonCCColor = pow( lerp( mode_data[mode*4+3], mode_data[nextmode*4+3], modemix ), 2.2 );
				FlipAdvanceB = lerp( fab[mode], fab[nextmode], modemix );
#endif
				float3 gothitlocal = i.hitLocal;
				float3 hitLocal = gothitlocal + float3( _SpeedX, _SpeedY, 0 ) * gtime;

				float3 ray = normalize( gothitlocal - i.roLocal );
				float4 col = 0;
				float raylen = chash31( frac(gothitlocal.xyz)*2937. + frac(gtime*13)*900 )*0.001*_RayNoise + _RayBias*.001;
				float3 localcoord = hitLocal + ray * raylen;


				float XBrightIn = 1;
				XBrightIn = XBrightIn * saturate( FlipAdvance + 1 );
				//Using FlipAdvance makes it _wild_ - if negative, set brightin to 0.

				uint2 coordei;
				uint2 coordeihex;
				//Do initial trace here.  The first outcome is actually pretty tainet.
				//We can also use it to compute the heavy work.
				Trace( float3(localcoord.xy, raylen) * Tiling, 0, 0, 0, coordei, coordeihex, AspectRatio );
				int hpl1 = length(int2(coordeihex%80)-40);
				int hpl2 = length(int2((coordeihex+40)%80)-40);

#if _is_torso_local
				float trisep = AudioLinkData( ALPASS_AUDIOLINK + uint2( hpl1*2, 0 ) )*.25-.15;
				float hexsep = AudioLinkData( ALPASS_AUDIOLINK + uint2( hpl2*2, 1 ) )*.25-.05;
#elif _is_floormode_local
				float trisep = -1.0;
				float hexsep = -.1;
#else
				float trisep = AudioLinkData( ALPASS_AUDIOLINK + uint2( hpl1*2, 0 ) )*.4-.3;
				float hexsep = AudioLinkData( ALPASS_AUDIOLINK + uint2( hpl2*2, 1 ) )*.4;
#endif				
				trisep = saturate( trisep );
				hexsep = saturate( hexsep );
				
				const int _ChronotensityMode = 0;
				/* chrono = float2(
						(AudioLinkDecodeDataAsUInt( ALPASS_CHRONOTENSITY  + uint2( 0, 0 ) ) % 10000000 ) / 400000.0+
						(AudioLinkDecodeDataAsUInt( ALPASS_CHRONOTENSITY  + uint2( 2, 0 ) ) % 10000000 ) / 500000.0,
						(AudioLinkDecodeDataAsUInt( ALPASS_CHRONOTENSITY  + uint2( 0, 1 ) ) % 10000000 ) / 400000.0+
						(AudioLinkDecodeDataAsUInt( ALPASS_CHRONOTENSITY  + uint2( 2, 1 ) ) % 10000000 ) / 500000.0
						);
					*/	
				float2 chrono = float2( 
					AudioLinkData( ALPASS_FILTEREDAUDIOLINK + uint2( 5, 0 ) ).x,
					AudioLinkData( ALPASS_FILTEREDAUDIOLINK + uint2( 5, 1 ) ).x );
				chrono += gtime/10.;

				float inten = csimplex3( glsl_mod( float3( coordeihex.xy*.34, chrono.x+chrono.y ), 1000 ) ) +.5;
				float audioVolume = AudioLinkData( ALPASS_GENERALVU + int2( 11, 0 ) );
				
				int steps;
				const int nrsteps = 12;
				for( steps = 0; steps < nrsteps; steps++ )
				{
					localcoord = hitLocal + ray * raylen;

					float tvw = Trace( float3(localcoord.xy, raylen) * Tiling, trisep, hexsep, heighsep, coordei, coordeihex, AspectRatio );

#if _use_hq_noise_local
					inten = tasimplex3( float3( coordeihex.xy*.34, chrono.x+chrono.y ) ) +.5;
#else
					inten = taquicksmooth3( float3( coordeihex.xy*.34, chrono.x+chrono.y ) ) + 0.5;
#endif

					tvw -= (inten*.25)*FlipAdvance; //This indirectly gives the effect of height.

					float hexhash = chash12(int2(coordeihex+chrono.x));
#if _is_torso_local
	#if _use_hq_noise_local
					float3 compcol = tasimplex3(float3(coordeihex,raylen)*10.+1000.)*.5+NonCCColor;
	#else
					float3 compcol = taquicksmooth3(float3(coordeihex,raylen)*10.+1000)*.5+NonCCColor;
	#endif
#elif _is_floormode_local
					float3 compcol = chash31( coordeihex.x + coordeihex.y*373 ).xxx* .5 + NonCCColor;
#else

//					float3 compcol = AudioLinkData( ALPASS_CCLIGHTS + uint2( hexhash*128, 0 ) );
					float3 compcol = 
						lerp( 
							chash31( coordeihex.x + coordeihex.y*373 ).xxx* .5 + _NonCCColor,
							AudioLinkData( ALPASS_CCLIGHTS + uint2( hexhash*128, 0 ) ),
							saturate( audioVolume * 10 ) ); //If silence, make board white.


#endif


					col.xyz += saturate(BiasColor/nrsteps+Brightness*compcol*((steps+1)*.05)*(tvw+.35)*(lerp( inten, 1.0-inten, XBrightIn)));
					raylen -= (tvw*.04)*FlipAdvanceB;
				}
//				if( length(col.xyz)> 3 )
//					col.xyz = normalize( col.xyz ) * 3;
				UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}
			ENDCG
		}
	}
}
