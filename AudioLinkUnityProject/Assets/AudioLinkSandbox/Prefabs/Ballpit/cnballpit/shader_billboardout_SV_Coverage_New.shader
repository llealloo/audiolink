// UNITY_SHADER_NO_UPGRADE

Shader "cnballpit/billboardoutSV_Coverage_New" 
{
	Properties 
	{
		_PositionsIn ("Positions", 2D) = "" {}
		_VelocitiesIn ("Velocities", 2D) = "" {}
		_ColorsIn ("Colors In", 2D) = "" {}
		_Mode ("Mode", float) = 0
		_Smoothness( "Smoothness", float ) = 0
		_Metallic("Metallic", float ) = 0
		_ScreenshotMode("Screenshot Mode", float) = 0
		[ToggleUI] _ExtraPretty( "Extra Pretty", float ) = 0
		_NightMode("Night Mode", float) = 0
		
		_VideoTexture ("Video Texture", 2D) = "black" {}
		_IsAVProInput ("IsAVProInput", float) = 0
		_BallpitRescale( "BallpitRescale", float ) = 1
		_MinimumDistance( "Minimum distance", float ) = 0
		_DistanceGradient( "Distance Gradient", float ) = 1
	}
	

	SubShader 
	{
	
		// shadow caster rendering pass, implemented manually
		// using macros from UnityCG.cginc
		Pass
		{
			Tags {"LightMode"="ShadowCaster"}

			CGINCLUDE
			
			#include "Assets/AudioLinkSandbox/Shaders/hashwithoutsine/hashwithoutsine.cginc"
			#include "Packages/com.llealloo.audiolink/Runtime/Shaders/AudioLink.cginc"
			#pragma vertex vert
			#pragma geometry geo

			#pragma target 5.0

			//#define SHADOWS_SCREEN
			
			#include "UnityCG.cginc"
			#include "cnballpit.cginc"
			#include "AutoLight.cginc"
			#include "Lighting.cginc"
			#include "UnityShadowLibrary.cginc"
			#include "UnityPBSLighting.cginc"


			#define SHADOW_SIZE 0.6
			
			//This is for the size of the bounding square that we are rendering the impostor into.
			#define OVERDRAW_FUDGE 0.6
			#define EXPAND_FUDGE  0.12
			#define RADIUS_FUDGE_ADD_BY_DISTANCE_BOUNDING .002
			
			#define RAIDUS_FUDGE_MUX 1.0 
			#define RADIUS_FUDGE_ADD 0
			//Expand the radius of the ball a tiny bit at distance to cover the edge fading.
			#define RADIUS_FUDGE_ADD_BY_DISTANCE 0.001
 
			struct v2g
			{
				float4	pos		: POSITION;
				float3	normal	: NORMAL;
				float2  uv	: TEXCOORD0;
				float4  opos	: TEXCOORD1;
			};
			struct g2f
			{
				float4	pos		: POSITION;
				float2  uv	: TEXCOORD0;
				float4  ballcenter : TEXCOORD1;
				float3  hitworld : TEXCOORD2;
				float4  props : TEXCOORD3;
				float4  colorDiffuse : TEXCOORD4;
				float4  colorAmbient : TEXCOORD5;
			};

			float4x4 _VP;
			
			float _Mode, _Smoothness, _Metallic;
			texture2D<float4> _RVData;
			sampler2D _VideoTexture;
			float4 _RVData_TexelSize;
			float _ExtraPretty;
			float _ScreenshotMode;
			float _NightMode;
			float _BallpitRescale;
			float _MinimumDistance;
			float _DistanceGradient;
			
			v2g vert(appdata_base v)
			{
				v2g output = (v2g)0;

				output.pos =  mul(unity_ObjectToWorld, v.vertex);
				output.normal = v.normal;
				output.uv = float2(0, 0);
				output.opos = v.vertex;

				return output;
			}

			[maxvertexcount(32)]
			void geo(point v2g p[1], inout TriangleStream<g2f> triStream, uint id : SV_PrimitiveID)
			{
				int transadd;

// No shadows at night, at least not from the directional light.
#ifdef UNITY_PASS_SHADOWCASTER
				if( _NightMode > 0.5 && UNITY_MATRIX_P._m33 > 0 )
				{
					return;
				}
#endif

				#define GEO_MUX 8
				for( transadd = 0; transadd < GEO_MUX; transadd++ )
				{
					//based on https://github.com/MarekKowalski/LiveScan3D-Hololens/blob/master/HololensReceiver/Assets/GS%20Billboard.shader

					float3 worldoffset = p[0].pos;	// World pos of center of system.
					//int3  oposid = p[0].opos * float3( -1, 1, 1 ) + float3( 0., 0., 0. );
					
					//oposid += transadd * 16;
					
					// Set based on data
					//int ballid = oposid.x + oposid.y * 32 + oposid.z * 1024;
					uint ballid = id * GEO_MUX + transadd;
					
					float4 DataPos = GetPosition(ballid)*_BallpitRescale;
					float3 PositionRelativeToCenterOfBallpit = DataPos;
					float4 DataVel = GetVelocity(ballid);
					DataPos.xyz += worldoffset ;
					
					float3 rvpos = DataPos;

					float3 up, look, right;

					up = float3(0, 1, 0);
 
					if ((UNITY_MATRIX_P[3].x == 0.0) && (UNITY_MATRIX_P[3].y == 0.0) && (UNITY_MATRIX_P[3].z == 0.0)){
						//look = UNITY_MATRIX_V[2].xyz;
						look = normalize(_WorldSpaceLightPos0.xyz - rvpos * _WorldSpaceLightPos0.w);
					}
					else
					{
						look = _WorldSpaceCameraPos - rvpos;
						//look.y = 0; //uncomment to force horizontal billboard.
					}
 

					float distance_to_ball = length( look );

					look = normalize(look);
					right = cross(up, look);
					
					//Make actually face directly.
					up = normalize(cross( look, right ));
					right = normalize(right);

					float size = DataPos.w*2+EXPAND_FUDGE*DataPos.w/.08+ RADIUS_FUDGE_ADD_BY_DISTANCE_BOUNDING * distance_to_ball; //DataPos.w is radius. (Add a little to not clip edges.)
					float halfS = 0.5f * size * OVERDRAW_FUDGE;
					
					//Pushthe view plane away a tiny bit, to prevent nastiness when doing the SV_DepthLessEqual for perf.
					rvpos += look*halfS;
							
					float4 v[4];
					v[0] = float4(rvpos + halfS * right - halfS * up, 1.0f);
					v[1] = float4(rvpos + halfS * right + halfS * up, 1.0f);
					v[2] = float4(rvpos - halfS * right - halfS * up, 1.0f);
					v[3] = float4(rvpos - halfS * right + halfS * up, 1.0f);

					float4x4 vp = mul( UNITY_MATRIX_MVP, unity_WorldToObject);

#ifdef UNITY_PASS_SHADOWCASTER
					float4 colorDiffuse = 0;
					float3 SmoothHue = 0;
					float4 colorAmbient = 0;
#else
					float4 colorDiffuse = float4( chash33((DataVel.www*10.+10.1)), 1. ) - .1;
					
					float3 SmoothHue = AudioLinkHSVtoRGB( float3(  frac(ballid/1024. + AudioLinkDecodeDataAsSeconds(ALPASS_GENERALVU_NETWORK_TIME)*.05), 1, .8 ) );
					float4 colorAmbient = 0.;

					//Christmas
					//static const float3 ballcolors[3] = { float3( 1., .0, 0 ), float3( 0.00, 1.0, 0.00 ), float3( 1., 1., 1. ) };
					//#define NR_BALL_COLORS 3

					// Valentine's
					//static const float3 ballcolors[3] = { float3( 1., .0, 0 ), float3( 1., 1., 1. ),float3( 1., .5, .5 ) };
					//#define NR_BALL_COLORS 3

					// St. Patrick's Day
					//static const float3 ballcolors[3] = { float3( 0., .6, 0 ), float3( .1, 1., .1 ), float3( .5,  1., .5 ) };
					//#define NR_BALL_COLORS 3

					// Ukraine
					static const float3 ballcolors[2] = { float3( .1, .1, 0.7 ), float3( .7, .7, .0 ) };
					#define NR_BALL_COLORS 2
					
					//NOTE: Light was 255, 152, 31 FOR ALL OTHER CASES (Except ukraine)

					//Default 
					static const float3 ballcolors_default[7] = { float3( .984, .784, 0 ), float3( 0.0, .635, .820 ), float3( .918, .271, .263 ), float3( .729, .739, .059 ), float3( .941, .490, .024 ), float3( .682, .859, .941 ), float3( .537, .451, .776 ) };
					#define NR_BALL_COLORS_DEFAULT 7

					if( _ScreenshotMode > 0.5 )
					{
						float dfc = length( PositionRelativeToCenterOfBallpit.xz ) / 15;
						float intensity = saturate(sin(dfc*15.+2.5)+0.3);//(glsl_mod( dfc * 5, 1.0 )>0.5)?1:0;

						colorDiffuse.xyz = ballcolors[ballid%NR_BALL_COLORS];

						//colorDiffuse *= intensity; 
						colorAmbient += colorDiffuse * intensity * .3;
						colorDiffuse = colorDiffuse * .5 + .04;
					} else if( _Mode == 0 )
					{
						float intensitymux = lerp( 1., sin(_Time.y+ballid)*1.1+1.1, _NightMode );
						colorDiffuse *= intensitymux;
						colorAmbient   += colorDiffuse * .06;
					}
					else if( _Mode == 1 )
					{
						colorDiffuse = abs(float4( 1.-abs(glsl_mod(PositionRelativeToCenterOfBallpit.xyz,2)), 1 )) * .8;
						float intensitymux = lerp( 1., 2.0, _NightMode );
						colorDiffuse *= intensitymux;
						colorAmbient   += colorDiffuse * .06;
					}
					else if( _Mode == 2 )
					{
						//float3 dvl = abs( DataVel.xyz ) - .03;
						float3 dvl = length( DataVel.xyz ) * .5 - .03;
						colorDiffuse.xyz = float3( dvl.x, dvl.y, dvl.z * 5. );
						colorDiffuse.xyz = max( colorDiffuse.xyz, float3( 0., 0., 0. ) );
						float intensitymux = lerp( 1., 2.0, _NightMode );
						colorDiffuse *= intensitymux;				
						colorAmbient   += colorDiffuse * lerp( .01, .04, _NightMode );

					}
					else if( _Mode == 3 )
					{
					/* Old - is bad.
						float intensity = saturate( AudioLinkData( ALPASS_AUDIOLINK + uint2( ballid % 16, (ballid / 128)%4 ) ) * 6 + .05 );
						colorDiffuse.xyz = SmoothHue;
						//colorDiffuse *= intensity; 
						colorAmbient += colorDiffuse * intensity * .35;
						colorDiffuse = colorDiffuse * .5 + .04;
					*/
						float dfc = length( PositionRelativeToCenterOfBallpit.xz ) / 15;
						float intensity = saturate( AudioLinkData( ALPASS_AUDIOLINK + uint2( dfc * 128, (ballid / 128)%4 ) ) * 6 + .05 );

						colorDiffuse.xyz = ballcolors[ballid%NR_BALL_COLORS];

						//colorDiffuse *= intensity; 
						colorAmbient += colorDiffuse * intensity * .35;
						colorDiffuse = colorDiffuse * .5 + .02;

					}
					else if( _Mode == 4 )
					{
						//float intensity = saturate( AudioLinkData( ALPASS_FILTEREDAUDIOLINK + uint2( 4, ( ballid / 128 ) % 4 ) ) * 6 + .1);

						uint selccnote = 0;
						uint balldiv = ballid % 7;
						if( balldiv < 3 ) selccnote = 0;
						else if( balldiv < 5 ) selccnote = 1;
						else if( balldiv < 6 ) selccnote = 2;
						else selccnote = 3;
						float4 rnote =  AudioLinkData( ALPASS_CCINTERNAL + uint2( (selccnote % 4)+1, 0 ) );
						float rgbcol;
						if( rnote.x >= 0 )
							colorDiffuse.xyz = AudioLinkCCtoRGB( rnote.x, rnote.z * 0.1 + 0.1, 0 );
						else
							colorDiffuse.xyz = SmoothHue * 0.1;

						colorAmbient   += colorDiffuse * lerp( .1, .5, _NightMode );
					}
					else if( _Mode == 5 )
					{
						float dfc = length( PositionRelativeToCenterOfBallpit.xz ) / 15;
						float intensity = saturate( AudioLinkData( ALPASS_AUDIOLINK + uint2( dfc * 128, (ballid / 128)%4 ) ) * 6 + .05 );

						colorDiffuse.xyz = ballcolors_default[ballid%NR_BALL_COLORS_DEFAULT];

						//colorDiffuse *= intensity; 
						colorAmbient += colorDiffuse * intensity * .35;
						colorDiffuse = colorDiffuse * .5 + .04;
					}
					else if( _Mode == 6 )
					{
						colorDiffuse = GetColorTex(ballid);
						//colorDiffuse = GetPosition(ballid);
						//colorDiffuse = (ballid/1024)%2;
						
						float dist_from_1 = abs( rvpos.y - 0.2 );
						//float4 alc = AudioLinkLerp( ALPASS_CCSTRIP + float2( length( PositionRelativeToCenterOfBallpit.xz )/10 * AUDIOLINK_WIDTH, 0 ) ).rgba * length( DataVel.xyz )*.5;
						
						float falloff = .5 / pow( (dist_from_1+.01), 2 );
						
						colorDiffuse = lerp( 0, colorDiffuse, saturate( falloff ) );
						
						colorAmbient += colorDiffuse * .7;
						colorDiffuse = colorDiffuse * .75 + 0.01;
					}
					// added by llealloo
					else if( _Mode == 7 )
					{

						float4 color1 = float4(0.38, 0.48, 0.84, 1);
						float4 color2 = float4(0.3, 0.16, 0.83, 1);
						

						//float3 dvl = abs( DataVel.xyz ) - .03;
						float3 dvl = length( DataVel.xyz ) * .5 - .03;
						colorDiffuse.xyz = float3( dvl.x, dvl.y, dvl.z * 5. );
						colorDiffuse.xyz = max( colorDiffuse.xyz, float3( 0., 0., 0. ) );
						float intensitymux = lerp( 1., 2.0, _NightMode );
						colorDiffuse *= intensitymux;				
						colorAmbient   += colorDiffuse * lerp( .01, .04, _NightMode );

						float dist = length(float3(DataPos.x, DataPos.y*0.5, DataPos.z));
						float distNorm = saturate(dist / 16);

						float amplitude = AudioLinkLerp( ALPASS_AUDIOLINK + float2( distNorm * 128, 0 ) );
						colorDiffuse += amplitude * lerp(color1, color2, distNorm);
						colorAmbient += amplitude * lerp(color1, color2, distNorm);
					}
#endif
					g2f pIn;

					pIn.pos = mul(vp, v[0]);
					pIn.uv = float2(1.0f, 0.0f);
					pIn.ballcenter = float4( DataPos.xyz, DataPos.w * RAIDUS_FUDGE_MUX + RADIUS_FUDGE_ADD + RADIUS_FUDGE_ADD_BY_DISTANCE * distance_to_ball );
					pIn.hitworld = v[0];
					pIn.props = float4( DataVel.w, 0, 0, 1 );
					pIn.colorDiffuse = colorDiffuse;
					pIn.colorAmbient = colorAmbient;
					triStream.Append(pIn);

					pIn.pos =  mul(vp, v[1]);
					pIn.uv = float2(1.0f, 1.0f);
					pIn.hitworld = v[1];					
					triStream.Append(pIn);

					pIn.pos =  mul(vp, v[2]);
					pIn.uv = float2(0.0f, 0.0f);
					pIn.hitworld = v[2];
					triStream.Append(pIn);

					pIn.pos =  mul(vp, v[3]);
					pIn.uv = float2(0.0f, 1.0f);
					pIn.hitworld = v[3];
					triStream.Append(pIn);
					triStream.RestartStrip();
				}
			}

			ENDCG

			CGPROGRAM

			#pragma fragment frag alpha earlydepthstencil
			#pragma multi_compile_shadowcaster


			struct shadowHelper
			{
				float4 vertex;
				float3 normal;
				V2F_SHADOW_CASTER;
			};

			float4 colOut(shadowHelper data)
			{
				SHADOW_CASTER_FRAGMENT(data);
			}


			float4 frag(g2f input, out float outDepth : SV_DepthLessEqual) : COLOR
			{
				float4 props = input.props;
				float3 s0 = input.ballcenter;
				float sr = input.ballcenter.w;
				float3 hitworld = input.hitworld;
				
				// Found by BenDotCom -
				// I saw these ortho shadow substitutions in a few places, but bgolus explains them
				// https://bgolus.medium.com/rendering-a-sphere-on-a-quad-13c92025570c

				float howOrtho = UNITY_MATRIX_P._m33; // instead of unity_OrthoParams.w
				float3 worldSpaceCameraPos = UNITY_MATRIX_I_V._m03_m13_m23; // instead of _WorldSpaceCameraPos
				float3 worldPos = input.hitworld; // mul(unity_ObjectToWorld, v.vertex); (If in vertex shader)
				float3 cameraToVertex = worldPos - worldSpaceCameraPos;
				float3 orthoFwd = -UNITY_MATRIX_I_V._m02_m12_m22; // often seen: -UNITY_MATRIX_V[2].xyz;
				float3 orthoRayDir = orthoFwd * dot(cameraToVertex, orthoFwd);
				// start from the camera plane (can also just start from o.vertex if your scene is contained within the geometry)
				float3 orthoCameraPos = worldPos - orthoRayDir;
				float3 ro = lerp(worldSpaceCameraPos, orthoCameraPos, howOrtho );
				float3 rd = lerp(cameraToVertex, orthoRayDir, howOrtho );

				float a = dot(rd, rd);
				float3 s0_r0 = ro - s0;
				float b = 2.0 * dot(rd, s0_r0);
				float c = dot(s0_r0, s0_r0) - (sr * sr);
				
				float disc = b * b - 4.0 * a* c;

				//clip( disc );
				if (disc < 0.0)
					discard;
				float2 answers = float2(-b - sqrt(disc), -b + sqrt(disc)) / (2.0 * a);
				float minr = min( answers.x, answers.y );
	
				float3 worldhit = ro + rd * minr;
				float3 dist = worldhit.xyz - _LightPositionRange.xyz;

				//Charles way.
				float4 clipPos = mul(UNITY_MATRIX_VP, float4(worldhit, 1.0));
				
				//D4rkPl4y3r's shadow technique		
				shadowHelper v;
				v.vertex = mul(unity_WorldToObject, float4(worldhit, 1));
				v.normal = normalize(mul((float3x3)unity_WorldToObject, worldhit - s0));
				TRANSFER_SHADOW_CASTER_NOPOS(v, clipPos);
				outDepth = clipPos.z / clipPos.w;

				//return colOut(v);
				return 0;
			}

			ENDCG
		}
		

		Pass
		{
			Tags { "RenderType"="Opaque" "LightMode"="ForwardBase"}
			//LOD 200
			//Tags {"Queue" = "Transparent" "RenderType"="Opaque" } 
			//AlphaToMask On

		
			CGPROGRAM


			#pragma fragment FS_Main alpha
			#pragma multi_compile_fwdadd_fullshadows



		#define FIXED_POSITION_RANGE 64
		#define SIGN_BIT 0x80000000
		#define GET_SIGN_BIT(f) ((asuint(f) & SIGN_BIT) >> 31)
		#define BITS_PER_POSITION 24
		#define MASK_BITS(bitCount) ((1 << (bitCount)) - 1)

		void decodeData(uint4 data, out float3 pos, out float3 vel, out uint colorId)
		{
			uint3 fixedPos;
			fixedPos.x = data.x >> 8;
			fixedPos.y = (data.x & MASK_BITS(8)) << 16 | data.y >> 16;
			fixedPos.z = (data.y & MASK_BITS(8)) << 16 | data.z >> 16;
			pos = (float3)(fixedPos & MASK_BITS(BITS_PER_POSITION - 1));
			pos *= ((float)FIXED_POSITION_RANGE) / (1 << (BITS_PER_POSITION - 1));
			pos = asfloat(asuint(pos) | ((fixedPos << (32 - BITS_PER_POSITION)) & SIGN_BIT));
			vel.x = f16tof32(data.z & MASK_BITS(16));
			vel.y = f16tof32(data.w >> 16);
			vel.z = f16tof32(data.w & MASK_BITS(16));
			colorId = (data.y >> 8) & MASK_BITS(8);
		}

		//L1 light probe sampling - from Bakery Standard
		float3 SHEvalL0L1Geomerics(float3 n)
		{
			// average energy
			//float R0 = L0;
			float3 R0 = { unity_SHAr.a, unity_SHAg.a, unity_SHAb.a };

			// avg direction of incoming light
			//float3 R1 = 0.5f * L1;
			float3 R1r = unity_SHAr.rgb;
			float3 R1g = unity_SHAg.rgb;
			float3 R1b = unity_SHAb.rgb;

			float3 rlenR1 = { dot(R1r,R1r), dot(R1g, R1g), dot(R1b, R1b) };
			rlenR1 = rsqrt(rlenR1);

			// directional brightness
			//float lenR1 = length(R1);
			float3 lenR1 = rcp(rlenR1) * .5;

			// linear angle between normal and direction 0-1
			//float q = 0.5f * (1.0f + dot(R1 / lenR1, n));
			//float q = dot(R1 / lenR1, n) * 0.5 + 0.5;
			//float q = dot(normalize(R1), n) * 0.5 + 0.5;
			float3 q = { dot(R1r, n), dot(R1g, n), dot(R1b, n) };
			q = q * rlenR1 * .5 + .5;
			q = isnan(q) ? 1 : q;

			// power for q
			// lerps from 1 (linear) to 3 (cubic) based on directionality
			float3 p = 1.0f + 2.0f * (lenR1 / R0);

			// dynamic range constant
			// should vary between 4 (highly directional) and 0 (ambient)
			float3 a = (1.0f - (lenR1 / R0)) / (1.0f + (lenR1 / R0));

			return max(0, R0 * (a + (1.0f - a) * (p + 1.0f) * pow(q, p)));
		}

		float3 BlendCubeMapOnDistance(float smoothness, float3 reflectedDir, float distanceBlend)
		{
			Unity_GlossyEnvironmentData envData;
			envData.roughness = 1 - smoothness;
			envData.reflUVW = reflectedDir;
			float3 result = Unity_GlossyEnvironment(UNITY_PASS_TEXCUBE(unity_SpecCube0),
				unity_SpecCube0_HDR, envData);
			float spec0interpolationStrength = unity_SpecCube0_BoxMin.w;
			UNITY_BRANCH
			if (spec0interpolationStrength < 0.999)
			{
				float spec0dist = length(unity_SpecCube0_ProbePosition - unity_ObjectToWorld._14_24_34);
				float spec1dist = length(unity_SpecCube1_ProbePosition - unity_ObjectToWorld._14_24_34);
				spec0interpolationStrength = smoothstep(-distanceBlend, distanceBlend, spec1dist - spec0dist);
				envData.reflUVW = reflectedDir;
				result = lerp(Unity_GlossyEnvironment(
					UNITY_PASS_TEXCUBE_SAMPLER(unity_SpecCube1, unity_SpecCube0),
					unity_SpecCube1_HDR, envData),
					result, spec0interpolationStrength);
			}
			return result;
		}

		float min3(float3 v)
		{
			return min(v.x, min(v.y, v.z));
		}

		half3 boxProjection(half3 worldRefl, float3 worldPos, float4 cubemapCenter, float4 boxMin, float4 boxMax)
		{
			// Do we have a valid reflection probe?
			UNITY_BRANCH
			if (cubemapCenter.w > 0.0)
			{
				half3 nrdir = worldRefl;
				half3 rbmax = (boxMax.xyz - worldPos) / nrdir;
				half3 rbmin = (boxMin.xyz - worldPos) / nrdir;
				half3 rbminmax = (nrdir > 0.0f) ? rbmax : rbmin;
				worldRefl = worldPos - cubemapCenter.xyz + nrdir * min3(rbminmax);
			}
			return worldRefl;
		}

		float3 cubemapReflection(float smoothness, float3 reflectedDir, float3 pos)
		{
			float3 worldPos = pos;
			float3 worldReflDir = reflectedDir;
			Unity_GlossyEnvironmentData envData;
			envData.roughness = 1 - smoothness;
			envData.reflUVW = boxProjection(worldReflDir, worldPos,
				unity_SpecCube0_ProbePosition,
				unity_SpecCube0_BoxMin, unity_SpecCube0_BoxMax);
			float3 result = Unity_GlossyEnvironment(UNITY_PASS_TEXCUBE(unity_SpecCube0),
				unity_SpecCube0_HDR, envData);
			float spec0interpolationStrength = unity_SpecCube0_BoxMin.w;
			UNITY_BRANCH
			if (spec0interpolationStrength < 0.999)
			{
				envData.reflUVW = boxProjection(worldReflDir, worldPos,
					unity_SpecCube1_ProbePosition,
					unity_SpecCube1_BoxMin, unity_SpecCube1_BoxMax);
				result = lerp(Unity_GlossyEnvironment(
					UNITY_PASS_TEXCUBE_SAMPLER(unity_SpecCube1, unity_SpecCube0),
					unity_SpecCube1_HDR, envData),
					result, spec0interpolationStrength);
			}
			return result;
		}
		
		
			float4 FS_Main(g2f input, out float outDepth : SV_DepthLessEqual, out uint Coverage[1] : SV_Coverage ) : COLOR
			{
				float4 props = input.props;
				float3 s0 = input.ballcenter;
				float sr = input.ballcenter.w;
				float3 hitworld_plane = input.hitworld;
				float3 ro = _WorldSpaceCameraPos;
				float3 rd = normalize(hitworld_plane-_WorldSpaceCameraPos);
				
				float a = dot(rd, rd);
				float3 s0_r0 = ro - s0;
				float b = 2.0 * dot(rd, s0_r0);
				float c = dot(s0_r0, s0_r0) - (sr * sr);
				
				float disc = b * b - 4.0 * a* c;

				if (disc < 0.0)
				{
					//disc = 0;
					//return 0.;
				}
				float2 answers = float2(-b - sqrt(disc), -b + sqrt(disc)) / (2.0 * a);
				float minr = min( answers.x, answers.y );
	
	
				float3 worldhit = ro + rd * minr;
				float3 hitnorm = normalize(worldhit-s0);
				float4 clipPos = mul(UNITY_MATRIX_VP, float4(worldhit, 1.0));
				float4 albcolor = 1.;
				
				// Potentially subtract from shadowmap
				
				//if( _ExtraPretty > 0.5 ) 
				{
					float4 col = input.colorDiffuse;
					float3 normal = hitnorm;
					float3 dir = rd;
					float3 wPos = worldhit;
					float attenuation = 1;
					
					float3 specularTint;
					float oneMinusReflectivity;
					float3 albedo = DiffuseAndSpecularFromMetallic(
						col.rgb, _Metallic, specularTint, oneMinusReflectivity
					);
					

					_Smoothness = saturate(_Smoothness + col.a * .1 - .1);
					UnityLight light;
					light.color = _LightColor0.rgb;
					light.dir = _WorldSpaceLightPos0.xyz;
					UnityIndirect indirectLight;
					indirectLight.diffuse = SHEvalL0L1Geomerics(normal);
					indirectLight.specular = cubemapReflection(_Smoothness, reflect(dir, normal), wPos);

					if( _NightMode <= 0.5 )
					{
						struct shadowonly
						{
							float4 pos;
							float4 _LightCoord;
							float4 _ShadowCoord;
						} so;
						so._LightCoord = 0.;
						so.pos = clipPos;
						so._ShadowCoord  = 0;
						UNITY_TRANSFER_SHADOW( so, 0. );
						attenuation = LIGHT_ATTENUATION( so );

						if( 1 )
						{
							//GROSS: We actually need to sample adjacent pixels. 
							//sometimes we are behind another object but our color.
							//shows through because of the mask.
							so.pos = clipPos + float4( 1/_ScreenParams.x, 0.0, 0.0, 0.0 );
							UNITY_TRANSFER_SHADOW( so, 0. );
							attenuation = min( attenuation, LIGHT_ATTENUATION( so ) );
							so.pos = clipPos + float4( -1/_ScreenParams.x, 0.0, 0.0, 0.0 );
							UNITY_TRANSFER_SHADOW( so, 0. );
							attenuation = min( attenuation, LIGHT_ATTENUATION( so ) );
							so.pos = clipPos + float4( 0, 1/_ScreenParams.y, 0.0, 0.0 );
							UNITY_TRANSFER_SHADOW( so, 0. );
							attenuation = min( attenuation, LIGHT_ATTENUATION( so ) );
							so.pos = clipPos + float4( 0, 1/_ScreenParams.y, 0.0, 0.0 );
							UNITY_TRANSFER_SHADOW( so, 0. );
							attenuation = min( attenuation, LIGHT_ATTENUATION( so ) );
						}
					}

					// No Light
					#if 0
					if (all(light.color == 0))
					{
						light.dir = normalize(unity_SHAr.xyz + unity_SHAg.xyz + unity_SHAb.xyz + 0.001);
						light.color = ShadeSH9(float4(light.dir, .25));
						indirectLight.diffuse = ShadeSH9(float4(0, 0, 0, 1));
					}
					else
					#endif
					{
						indirectLight.diffuse += light.color * .025;
						light.color *= .75 * attenuation;
					}
					
					float EmissiveShift = 1. - length( input.uv - 0.5 )*0.8; //setting this to .8 makes the balls look kinda glassy.
					
					albcolor.rgb = UNITY_BRDF_PBS(
						albedo, specularTint,
						oneMinusReflectivity, _Smoothness,
						normal, -dir,
						light, indirectLight
					).rgb + input.colorAmbient.xyz * EmissiveShift;

					if( _NightMode > 0.5 )
					{
						//Handle up to 4 additional lights if at night.
						
						float3 unityLightPositions[4] = { 
							float3( unity_4LightPosX0.x, unity_4LightPosY0.x, unity_4LightPosZ0.x ),
							float3( unity_4LightPosX0.y, unity_4LightPosY0.y, unity_4LightPosZ0.y ),
							float3( unity_4LightPosX0.z, unity_4LightPosY0.z, unity_4LightPosZ0.z ),
							float3( unity_4LightPosX0.w, unity_4LightPosY0.w, unity_4LightPosZ0.w )
							};
						float3 deltas[4] = {
							unityLightPositions[0].xyz - wPos,
							unityLightPositions[1].xyz - wPos,
							unityLightPositions[2].xyz - wPos,
							unityLightPositions[3].xyz - wPos };

						float4 comps = float4(
							length( deltas[0] ),
							length( deltas[1] ),
							length( deltas[2] ),
							length( deltas[3] ) );
							
						deltas[0] = normalize( deltas[0] );
						deltas[1] = normalize( deltas[1] );
						deltas[2] = normalize( deltas[2] );
						deltas[3] = normalize( deltas[3] );
							
						float4 ndotls = float4(
							dot( normal, normalize( deltas[0] ) ),
							dot( normal, normalize( deltas[1] ) ),
							dot( normal, normalize( deltas[2] ) ),
							dot( normal, normalize( deltas[3] ) ) );

						float4 squaredDistance = comps * comps;
						
						float4 attenuations_base = 1.0 / (1.0 + 
							unity_4LightAtten0 * squaredDistance);

						float4 attenuations = attenuations_base * (saturate( ndotls )+.03);
						attenuations = saturate( attenuations - .1 );

						//specularReflection = attenuations * _LightColor0.rgb * _SpecColor.rgb * pow(max(0.0, dot(reflect(-lightDirection, normalDirection), viewDirection)), _Shininess);
						float _Shininess = 5;
						
						float4 attenuationspec = saturate( attenuations_base/2 - 0.1 ) ;
						
						float3 basergb = saturate( input.colorAmbient.xyz * 20 );
						albcolor.rgb += unity_LightColor[0] * ( attenuations.x * basergb + attenuationspec.x * pow(max(0.0, dot(reflect(-deltas[0], normal), -dir)), _Shininess) ); 
						albcolor.rgb += unity_LightColor[1] * ( attenuations.y * basergb + attenuationspec.y * pow(max(0.0, dot(reflect(-deltas[1], normal), -dir)), _Shininess) );
						albcolor.rgb += unity_LightColor[2] * ( attenuations.z * basergb + attenuationspec.z * pow(max(0.0, dot(reflect(-deltas[2], normal), -dir)), _Shininess) );
						albcolor.rgb += unity_LightColor[3] * ( attenuations.w * basergb + attenuationspec.w * pow(max(0.0, dot(reflect(-deltas[3], normal), -dir)), _Shininess) );
						
					}
				}
				#if 0
				//Not pretty mode.
				else
				{
					const float shininessVal = 8;
					const float Kd = 1;
					const float Ks = 1;
					
					float3 N = normalize(hitnorm);
					float3 L = normalize(_WorldSpaceLightPos0);
					// Lambert's cosine law
					float lambertian = max(dot(N, L), 0.0);
					float specular = 0.0;
					if(lambertian > 0.0) {
						float3 R = reflect(-L, N);	  // Reflected light vector
						float3 V = normalize(-rd); // Vector to viewer
						// Compute the specular term
						float specAngle = max(dot(R, V), 0.0);
						specular = pow(specAngle, shininessVal);
					}
					
					albcolor = float4( input.colorAmbient.xyz +
						   Kd * lambertian * input.colorDiffuse +
						   Ks * specular * float3(.3, .3, .3), 1.0);
				   
				   
				   

					float attenuation = 1;

					//XXX TODO FIX SHADOWS
					#if 1
					struct shadowonly
					{
						float4 pos;
						float4 _LightCoord;
						SHADOW_COORDS(1)
					} so;
					so._LightCoord = 0.;
					so.pos = clipPos;
					UNITY_TRANSFER_SHADOW( so, 0. );
					attenuation = LIGHT_ATTENUATION( so );
					#else
					#endif
					
					albcolor *= attenuation;
				}
				#endif

				UNITY_APPLY_FOG(i.fogCoord, col);
				outDepth = clipPos.z / clipPos.w;
				
				// Tricky - compute the edge-y-ness.  If we're on an edge
				// then reduce the alpha.
				float dx = length( float2( ddx_fine(disc), ddy_fine(disc) ) );

				float fakealpha = saturate(disc/dx);
				float dist_to_surface = length( worldhit - ro );
				float distalpha = dist_to_surface*10. - _ProjectionParams.y - chash22(input.uv*1000.).y*.5*_DistanceGradient - _MinimumDistance;
				fakealpha = min( distalpha, fakealpha );
				//Thanks, D4rkPl4y3r.
				Coverage[0] = ( 1u << ((uint)(fakealpha*GetRenderTargetSampleCount() + 0.5)) ) - 1;
				return albcolor;
			}

			ENDCG
		}
	} 
}
