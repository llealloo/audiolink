Shader "Unlit/VoxeltasticDemo"
{
	Properties
	{
		_Tex ("Texture (3D)", 3D) = "white" {}
		_Tex2D ("Texture (2D)", 2D) = "white" {}
		_ColorRamp( "Color Ramp", 2D ) = "white" { }
		_MinVal ("Min Val", float ) = 0.6
		_MaxVal ("Min Val", float ) = 1.0
		_GenAlpha ("Gen Alpha", float ) = 1.0
		_SoftCubes ("Soft Cubes", float ) = 1.0
		
		[Toggle(ENABLE_CUTTING_EDGE)] ENABLE_CUTTING_EDGE ("Enable Cutting Edge", int ) = 1
		[Toggle(DO_CUSTOM_EFFECT)] DO_CUSTOM_EFFECT ("Do Custom Effect", int ) = 0
		[Toggle(ENABLE_Z_WRITE)] ENABLE_Z_WRITE ("Enable Z Write", int ) = 0
		[Toggle(DO_2D3D_TEXTURE)] DO_2D3D_TEXTURE ("Upconvert 2D to 3D Texture (like a CRT)", int ) = 0
		[Toggle(ALTMODE)] ALTMODE ("Alternate Mode for this Specific Mode", int ) = 0
	}
	SubShader
	{
		Tags {"RenderType"="Transparent"  "Queue"="Transparent+1" }
		
		Pass
		{
			Tags {"LightMode"="ForwardBase" }
			Blend One OneMinusSrcAlpha 
			Cull Front
			
			// Normally we would want to turn on ZWrite because it would cover name tags.
			// But if we are transparent pixels, it will many times render in front of 
			// user's clothing, and could make them appear naked.

			ZWrite [ENABLE_Z_WRITE]
			
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag alpha earlydepthstencil

			#pragma multi_compile_fog
			#pragma multi_compile _ VERTEXLIGHT_ON 
			#pragma multi_compile_local _ ENABLE_CUTTING_EDGE
			#pragma multi_compile_local _ DO_CUSTOM_EFFECT DO_2D3D_TEXTURE
			#pragma multi_compile_local _ ENABLE_Z_WRITE
			#pragma multi_compile_local _ ALTMODE
			#pragma target 5.0

			#include "UnityCG.cginc"
			#include "UnityInstancing.cginc"
			#include "UnityShadowLibrary.cginc"
			#include "AutoLight.cginc"
			
			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
				float3 worldPos : WORLDPOS;
				float2 screenPosition : SCREENPOS; // Trivially refactorable to a float2
				UNITY_VERTEX_OUTPUT_STEREO
			};

			sampler2D _ColorRamp;
			float _MinVal;
			float _MaxVal;
			float _GenAlpha;
			float _SoftCubes;

			UNITY_DECLARE_DEPTH_TEXTURE( _CameraDepthTexture );

			uint3 samplesize; 

			// Utility Function
			float AudioLinkRemap(float t, float a, float b, float u, float v) { return ((t-a) / (b-a)) * (v-u) + u; }
  
			// You have to tell voxeltastic what function to actually use for its
			// volume tracing.
			#ifdef DO_CUSTOM_EFFECT
				#define VT_FN custom_effect_function
				#define CUSTOM_SAMPLE_SIZE uint3( 32, 32, 32 )
				void custom_effect_function( int3 pos, float distance, float travel, inout float4 accum )
				{
					float a = 0.0;
					float usetime = _Time.y / 6.0;
					a += 1.0/length( pos - (float3(sin(usetime), -.4, cos(usetime) )*10+16 ) );
					a += 1.0/length( pos - (float3(sin(usetime+2.1), -.6, cos(usetime+2.1) )*10+16 ) );
					a += 1.0/length( pos - (float3(sin(usetime+4.2), -.8, cos(usetime+4.2) )*10+16 ) );

					a = AudioLinkRemap( a, _MinVal, _MaxVal, 0, 1 );
					a = saturate( a );
					float initiala = accum.a;
					float this_alpha = a*distance*accum.a*_GenAlpha;
					
					// OPTIONAL: Enable or disable this to either smoothly interact with Z
					// or to harshly interact with Z (this is very interesting).
					// Having this code makes it nice and smooth.
					this_alpha = min( travel/distance, 1.0 ) * this_alpha;
					
					float3 color = tex2Dlod( _ColorRamp, float4( a, 0, 0, 0 ) );
					accum.rgb += this_alpha * color;//lerp( accum.rgba, float4( normalize(AudioLinkHSVtoRGB(float3( a,1,1 ))), 0.0 ), this_alpha );
					accum.a = initiala - this_alpha;
				}			
			#elif DO_2D3D_TEXTURE
				#define VT_FN convert2d3d_function
				Texture2D<float4> _Tex2D;
				void convert2d3d_function( int3 pos, float distance, float travel, inout float4 accum )
				{
					/*float4 color = _Tex2D.Load( int4( pos.x, pos.y + pos.z * samplesize.x, 0, 0 ) );
					float this_alpha = color.a;
					// OPTIONAL: Enable or disable this to either smoothly interact with Z
					// or to harshly interact with Z (this is very interesting).
					// Having this code makes it nice and smooth.
					this_alpha = min( travel/distance, 1.0 ) * this_alpha;
					float initiala = accum.a;
					accum.rgb += this_alpha * color;
					accum.a = initiala - this_alpha;*/




					/*float4 color = _Tex2D.Load( int4( pos.x, pos.y + pos.z * samplesize.x, 0, 0 ) );
					float a = color.a;
					float initiala = accum.a;
					float this_alpha = a*distance*accum.a*_GenAlpha;
					// OPTIONAL: Enable or disable this to either smoothly interact with Z
					// or to harshly interact with Z (this is very interesting).
					// Having this code makes it nice and smooth.
					//this_alpha = min( travel/distance, 1.0 ) * this_alpha;
					//this_alpha = min( travel/distance, 1.0 ) * this_alpha + ((travel < 4) ? 0.02 : 0.0);
					//this_alpha = min( travel/distance, 1.0 ) * this_alpha + smoothstep(0, 1, (saturate(12 - travel/distance)) * 0.08);
					this_alpha = min( travel/distance, 1.0 ) * this_alpha ;
					accum.rgb += this_alpha * color;//lerp( accum.rgba, float4( normalize(AudioLinkHSVtoRGB(float3( a,1,1 ))), 0.0 ), this_alpha );
					accum.a = initiala - this_alpha;*/


					float4 color = _Tex2D.Load( int4( pos.x, pos.y + pos.z * samplesize.x, 0, 0 ) );

				#ifdef ALTMODE
                    // For flat squares
                    float this_alpha = color.a;
				#else
                    // For more interesting squares
                    float this_alpha = distance*accum.a*color.a*_GenAlpha;
				#endif
                    // OPTIONAL: Enable or disable this to either smoothly interact with Z
                    // or to harshly interact with Z (this is very interesting).
                    // Having this code makes it nice and smooth.
                    this_alpha = min( travel/distance, 1.0 ) * this_alpha;
                    
                    float initiala = accum.a;
                    accum.rgb += this_alpha * color;
                    accum.a = initiala - this_alpha;

				}
			#else
				#define VT_FN my_density_function
				Texture3D<float4> _Tex;
				void my_density_function( int3 pos, float distance, float travel, inout float4 accum )
				{
					float a = _Tex.Load( int4( pos.xyz, 0.0 ) ).a;
					a = AudioLinkRemap( a, _MinVal, _MaxVal, 0, 1 );
					a = saturate( a );
					float initiala = accum.a;
					float this_alpha = a*distance*accum.a*_GenAlpha;
					float3 color = tex2Dlod( _ColorRamp, float4( a, 0, 0, 0 ) );
					accum.rgb += this_alpha * color;//lerp( accum.rgba, float4( normalize(AudioLinkHSVtoRGB(float3( a,1,1 ))), 0.0 ), this_alpha );
					accum.a = initiala - this_alpha;
				}
			#endif
			#define VT_TRACE trace


			#include "Voxeltastic.cginc"

			// Inspired by Internal_ScreenSpaceeShadow implementation.
			// This code can be found on google if you search for "computeCameraSpacePosFromDepthAndInvProjMat"
			float GetLinearZFromZDepth_WorksWithMirrors(float zDepthFromMap, float2 screenUV) {
				#if defined(UNITY_REVERSED_Z)
					zDepthFromMap = 1 - zDepthFromMap;
				#endif
				if( zDepthFromMap >= 1.0 ) return _ProjectionParams.z;
				float4 clipPos = float4(screenUV.xy, zDepthFromMap, 1.0);
				clipPos.xyz = 2.0f * clipPos.xyz - 1.0f;
				float2 camPos = mul(unity_CameraInvProjection, clipPos).zw;
				return -camPos.x / camPos.y;
			}


			v2f vert (appdata v)
			{
				v2f o;
				
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_OUTPUT(v2f, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;

				// Save the clip space position so we can use it later.
				// This also handles situations where the Y is flipped.
				float2 suv = o.vertex * float2( 0.5, 0.5*_ProjectionParams.x);
							
				// Tricky, constants like the 0.5 and the second paramter
				// need to be premultiplied by o.vertex.w.
				o.screenPosition = TransformStereoScreenSpaceTex( suv+0.5*o.vertex.w, o.vertex.w );
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}

			// was SV_DepthLessEqual
			fixed4 frag (v2f i, uint is_front : SV_IsFrontFace, out float outDepth : SV_Depth ) : SV_Target
			{
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( i );
				float3 fullVectorFromEyeToGeometry = i.worldPos - _WorldSpaceCameraPos;
				float3 worldSpaceDirection = normalize( fullVectorFromEyeToGeometry );

				// Compute projective scaling factor.
				// perspectiveFactor is 1.0 for the center of the screen, and goes above 1.0 toward the edges,
				// as the frustum extent is further away than if the zfar in the center of the screen
				// went to the edges.
				float perspectiveDivide = 1.0f / i.vertex.w;
				float perspectiveFactor = length( fullVectorFromEyeToGeometry * perspectiveDivide );

				// Calculate our UV within the screen (for reading depth buffer)
				float2 screenUV = i.screenPosition.xy * perspectiveDivide;
				float eyeDepthWorld =
					GetLinearZFromZDepth_WorksWithMirrors( 
						SAMPLE_DEPTH_TEXTURE( _CameraDepthTexture, screenUV), 
						screenUV ) * perspectiveFactor;
				
				// eyeDepthWorld is in world space, it is where the "termination" of our ray should happen, or rather
				// how far away from the camera we should be.
				float3 worldPosModified = _WorldSpaceCameraPos;

				// This allows you to "slice" the volume if you so choose.
				#if VERTEXLIGHT_ON && ENABLE_CUTTING_EDGE
					// We use a cutting edge with lights.
					// This is not needed, but an interesting feature to add.
					// Use lights to control cutting plane
					int lid0 = -1;
					int lid1 = -1;
					float cls = 1e20;
					float4 lrads = 5 * rsqrt(unity_4LightAtten0);
					float3 lxyz[4] = {
						float3( unity_4LightPosX0[0], unity_4LightPosY0[0], unity_4LightPosZ0[0] ),
						float3( unity_4LightPosX0[1], unity_4LightPosY0[1], unity_4LightPosZ0[1] ),
						float3( unity_4LightPosX0[2], unity_4LightPosY0[2], unity_4LightPosZ0[2] ),
						float3( unity_4LightPosX0[3], unity_4LightPosY0[3], unity_4LightPosZ0[3] ) };
						
					// Find cutting 
					float3 wobj = mul(unity_ObjectToWorld, float4(0,0,0,1));

					int n;
					for( n = 0; n < 4; n++ )
					{
						if( (frac( lrads[n]*100 ) - .1)<0.05 )
						{
							float len = length( lxyz[n]- wobj );
							if( len < cls )
							{
								lid0 = n;
								cls = length( lxyz[n] - wobj );
							}
						}
					}
					for( n = 0; n < 4; n++ )
					{
						if( n != lid0 && (frac( lrads[n]*100 ) - .2)<0.05 && floor( lrads[n]*100 ) == floor( lrads[lid0]*100 ) )
						{
							lid1 = n;
						}
					}

					if( lid1 >= 0 && lid0 >= 0 )
					{
						float3 vecSlice = lxyz[lid0];
						float3 vecNorm = normalize( lxyz[lid1] - vecSlice );
						float3 vecDiff = vecSlice - worldPosModified;
						float vd = dot(worldSpaceDirection, vecNorm );

						float dist = dot(vecDiff, vecNorm)/vd;

						if( dot(vecDiff, vecNorm) > 0 )
						{
							if( vd < 0 ) discard;
							worldPosModified += worldSpaceDirection * dist;
						}
						else
						{
							if( vd < 0 )
							{
								// Tricky:  We also want to z out on the slicing plane.
								// XXX: I have no idea why you have to / perspectiveFactor.
								// Like literally, no idea.
								// 
								eyeDepthWorld = min( eyeDepthWorld, dist );
							}
						}
					}
				#endif

				// We transform into object space for operations.
				float3 objectSpaceCamera = mul(unity_WorldToObject, float4(worldPosModified,1.0));
				float3 objectSpaceEyeDepthHit = mul(unity_WorldToObject, float4( _WorldSpaceCameraPos + eyeDepthWorld * worldSpaceDirection, 1.0 ) );
				float3 objectSpaceDirection = mul(unity_WorldToObject, float4(worldSpaceDirection,0.0));
				
				// We want to transform into the local object space.
				
				#ifdef DO_CUSTOM_EFFECT
				samplesize = CUSTOM_SAMPLE_SIZE;
				#elif DO_2D3D_TEXTURE
				int dummy; _Tex2D.GetDimensions( 0, samplesize.x, samplesize.y, dummy );
				samplesize.x=samplesize.x;
				samplesize.z=samplesize.y/samplesize.x;
				samplesize.y=samplesize.x;
				#else
				int dummy; _Tex.GetDimensions( 0, samplesize.x, samplesize.y, samplesize.z, dummy );
				#endif
				
				objectSpaceDirection = normalize( objectSpaceDirection * samplesize );
				float3 surfhit = objectSpaceCamera*(samplesize);
				float TravelLength = length( (objectSpaceEyeDepthHit - objectSpaceCamera) * samplesize);
				float4 col = VT_TRACE( samplesize, surfhit, objectSpaceDirection, float4( 0, 0, 0, 1 ), TravelLength );

				// Compute what our Z value should be, so the front of our shape appears on top of
				// objects inside the volume of the traced area.
				// surfhit is the location in object space where the ray "started"
				float3 WorldSpace_StartOfTrace = mul(unity_ObjectToWorld, float4( (surfhit) / samplesize, 1.0 ));
				float zDistanceWorldSpace = length( WorldSpace_StartOfTrace - _WorldSpaceCameraPos );
				float3 WorldSpace_BasedOnComputedDepth = normalize( i.worldPos - _WorldSpaceCameraPos ) * zDistanceWorldSpace + _WorldSpaceCameraPos;
				float4 clipPosSurface = mul(UNITY_MATRIX_VP, float4(WorldSpace_BasedOnComputedDepth, 1.0));

#if defined(UNITY_REVERSED_Z)
				outDepth = clipPosSurface.z / clipPosSurface.w;
#else
				outDepth = clipPosSurface.z / clipPosSurface.w *0.5+0.5;
#endif
				#ifdef ENABLE_Z_WRITE
				if( col.a > 0.991 ) discard;
				#endif

				col.a = 1.0 - col.a;
				UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}
			ENDCG
			
		}
		
		
		// shadow caster rendering pass, implemented manually
		// using macros from UnityCG.cginc
		Pass
		{
			Tags {"LightMode"="ShadowCaster"}
			
			// We actually only want to draw backfaces on the shadowcast.
			Cull Front
			ZWrite On
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
	}
}
