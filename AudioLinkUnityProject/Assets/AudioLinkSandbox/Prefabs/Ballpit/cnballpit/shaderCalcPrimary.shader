//XXX TODO: Remember to credit d4kpl4y3r with the bucketing tech.
//XXX TODO: ACTUALLY_DO_COMPLEX_HASH_FUNCTION and try it.
//
// Camera Comparison
//   All on UI Layer: 7.1ms ish
//   Cameras on Default, looking at other layer: 7.6ms? ish
//   All cameras on and looking at PlayerLocal: 7.1ms-7.6ms
//   All cameras on and looking at PickupNoLocal: 6.4-6.9ms???


Shader "cnballpit/shaderCalcPrimary"
{
	Properties
	{
		_BallRadius( "Default Ball Radius", float ) = 0.08
		_PositionsIn ("Positions", 2D) = "white" {}
		_VelocitiesIn ("Velocities", 2D) = "white" {}
		_Adjacency0 ("Adjacencies0", 2D) = "white" {}
        _DepthMapComposite ("Composite Depth", 2D) = "white" {}
		_Friction( "Friction", float ) = .008
		_DebugFloat("Debug", float) = 0
		[ToggleUI] _ResetBalls("Reset", float) = 0
		_GravityValue( "Gravity", float ) = 9.8
		_TargetFPS ("Target FPS", float ) = 120
		[ToggleUI] _DontPerformStep( "Don't Perform Step", float ) = 0

		_BallpitBoundaryMode("Ballpit Boundary Mode", int ) = 1
		_TubCenter("Tub Center", Vector) = ( 0, -.5, 0, 0 )
		_TubSize( "Tub Size", Vector ) = ( 1, 1, 1, 0 )
		_TopCenter( "Top Center", Vector ) = ( 0, 2.5, 0, 0 )
		_TopSize( "Top Size", Vector ) = ( 3, 2, 3, 0 )


		_FanPosition0( "Fan Position 0", Vector ) = ( -1000, 0, 0, 0 )
		_FanRotation0( "Fan Rotation 0", Vector ) = ( -1000, 0, 0, 1 )
		_FanPosition1( "Fan Position 1", Vector ) = ( -1000, 0, 0, 0 )
		_FanRotation1( "Fan Rotation 1", Vector ) = ( -1000, 0, 0, 1 )
		_FanPosition2( "Fan Position 2", Vector ) = ( -1000, 0, 0, 0 )
		_FanRotation2( "Fan Rotation 2", Vector ) = ( -1000, 0, 0, 1 )
		_MagnetPos0( "Magnet Pos0", Vector ) = ( -1000, 0, 0, 0 )
		_MagnetPos1( "Magnet Pos1", Vector ) = ( -1000, 0, 0, 0 )
		_MagnetPos2( "Magnet Pos2", Vector ) = ( -1000, 0, 0, 0 )
		_ShroomPos0( "Shroom Pos0", Vector ) = ( -1000, 0, 0, 0 )
		_ShroomPos1( "Shroom Pos1", Vector ) = ( -1000, 0, 0, 0 )
		_ShroomPos2( "Shroom Pos2", Vector ) = ( -1000, 0, 0, 0 )
		_ShroomPos3( "Shroom Pos3", Vector ) = ( -1000, 0, 0, 0 )
		_ShroomPos4( "Shroom Pos4", Vector ) = ( -1000, 0, 0, 0 )
		_ShroomPos5( "Shroom Pos4", Vector ) = ( -1000, 0, 0, 0 )
		WorldSize("Camera Span Size", Vector) = (16, 16, 1, 0 )
		_BallForceRating( "Ball Force Rating", float ) = 1.0
		_HeightmapCFM( "Heightmap CFM", float ) = 1
	}
	SubShader
	{
		Tags { "RenderType"="Opaque"  "Compute" = "Compute" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"
			#include "Assets/AudioLinkSandbox/Shaders/hashwithoutsine/hashwithoutsine.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};
			
			struct f2a
			{
				float4 Pos : COLOR0;
				float4 Vel : COLOR1;
			};

			//https://community.khronos.org/t/quaternion-functions-for-glsl/50140/2
			float3 qtransform( in float4 q, in float3 v )
			{
				return v + 2.0*cross(cross(v, q.xyz ) + q.w*v, q.xyz);
			}
			
			// Next two https://gist.github.com/mattatz/40a91588d5fb38240403f198a938a593
			float4 q_conj(float4 q)
			{
				return float4(-q.x, -q.y, -q.z, q.w);
			}

			// https://jp.mathworks.com/help/aeroblks/quaternioninverse.html
			float4 q_inverse(float4 q)
			{
				float4 conj = q_conj(q);
				return conj / (q.x * q.x + q.y * q.y + q.z * q.z + q.w * q.w);
			}
			

			
			
			#include "cnballpit.cginc"
			float _BallRadius, _DebugFloat, _ResetBalls, _GravityValue, _Friction, _DontPerformStep;
			texture2D<float2> _DepthMapComposite;
			float4 _DepthMapComposite_TexelSize;
			float _TargetFPS;
			float4 _FanPosition0;
			float4 _FanRotation0;
			float4 _FanPosition1;
			float4 _FanRotation1;
			float4 _FanPosition2;
			float4 _FanRotation2;
			float4 _MagnetPos0;
			float4 _MagnetPos1;
			float4 _MagnetPos2;
			float4 _ShroomPos0;
			float4 _ShroomPos1;
			float4 _ShroomPos2;			
			float4 _ShroomPos3;			
			float4 _ShroomPos4;			
			float4 _ShroomPos5;
			float3 _TubCenter;
			float3 _TubSize;
			float3 _TopCenter;
			float3 _TopSize;
			float3 WorldSize;
			float _BallForceRating;
			float _HeightmapCFM;
			int _BallpitBoundaryMode;


			float SDFBoundary( float3 position )
			{
				//if( _BallpitBoundaryMode == 2 )
				if( _BallpitBoundaryMode >= 2 )   			// Changed by llealloo to work with her boundary mode 3
				{
					return min( 
						length( max( abs( position - _TubCenter ) - _TubSize, 0..xxx ) ),
						length( max( abs( position - _TopCenter ) - _TopSize, 0..xxx ) ) );
				}
				else
				{
					return 0;
				}
			}


			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}

			f2a frag ( v2f i )
			{
				f2a ret;
				int2 screenCoord = i.vertex.xy;
				uint ballid = screenCoord.y * 1024 + screenCoord.x;
				
				if( ballid >= MAX_BALLS )
				{
					ret.Pos = float4( 10000., 10000., 10000., 0. );
					ret.Vel = 0.;

					return ret;
				}

				float dt;
				float vcfmfpsP;
				float vcfmfpsV;
				if( 1 )
				{
					dt = 1./_TargetFPS;
					vcfmfpsP = 1;
					vcfmfpsV = 1;
				}
				else
				{
					dt = clamp( unity_DeltaTime.x/2., 0, .01 );
					vcfmfpsV = dt*180;
					vcfmfpsP = .5*sqrt(dt);
				}
				
				float4 Position = GetPosition( ballid );
				float4 Velocity = GetVelocity( ballid );
				if( _Time.y < 3 || Position.w == 0 || _ResetBalls > 0 )
				//if( 0 )
				{
					ret.Pos = float4( chash33( ballid.xxx ) * float3( 12, 2.5, 12 ) + float3( -6, 0, -6 ), _BallRadius );
					ret.Vel = float4( 0., 0., 0., ballid );
					return ret;
				}
				
				//Potentially skip step.
				if( _DontPerformStep > 0.5 )
				{
					ret.Pos = Position;
					ret.Vel = Velocity;
					return ret;
				}
				
				Position.w = _BallRadius;
				int did_find_self = 0;
				
				
				//Collide with other balls - this section of code is about 350us per pass.
				if( 1 )
				{
					const float cfmVelocity = 20.0 * vcfmfpsV;
					const float cfmPosition = .0008 * vcfmfpsP;
					
					// Step 1 find collisions.
					
					int3 ballneighbor;
					for( ballneighbor.x = -SearchExtents; ballneighbor.x <= SearchExtents; ballneighbor.x++ )
					for( ballneighbor.y = -SearchExtents; ballneighbor.y <= SearchExtents; ballneighbor.y++ )
					for( ballneighbor.z = -SearchExtents; ballneighbor.z <= SearchExtents; ballneighbor.z++ )
					{
						int j;
						
						//Determined experimentally - we do not need to check the cells at the far diagonals.
						if( length( ballneighbor ) > SeachExtentsRange ) continue;
						
						uint2 hashed = Hash3ForAdjacency(ballneighbor/HashCellRange+Position.xyz);
						float4 adjacencyvalue = 0.;
						{
							uint4 data = _Adjacency0[hashed];
							if( data.a >= 2 )
							{
								adjacencyvalue.x = data.a;
							}
							if( data.x >= 2 )
							{
								adjacencyvalue.y = data.x;
							}
						}
						
						int selfballidplus4 = ballid+4;

						for( j = 0; j < MAX_BINS_TO_CHECK; j++ )
						{
							uint obid;
							if( j == 0 )      obid = adjacencyvalue.x;
							else              obid = adjacencyvalue.y;

							//See if we hit ourselves.
							if( obid == ballid || obid < 4 )
							{
								continue;
							}
							
							obid -= 4;
						
							float4 otherball = GetPosition( obid );
							float len = length( Position.xyz - otherball.xyz );
							
							//Do we collide AND are we NOT the other ball?
							if( len > 0.02 )
							{
								float penetration = ( otherball.w + Position.w ) - len;
								penetration *= _BallForceRating;
								
								if( penetration > 0 )
								{
									// Collision! (Todo, smarter)
									// We only edit us, not the other ball.
									float3 vectortome = normalize(Position.xyz - otherball.xyz);
									Velocity.xyz += penetration * vectortome * cfmVelocity;
									Position.xyz += penetration * vectortome * cfmPosition;
									Velocity.xyz *= 1;
								}
							}
							else
							{
								if( obid > ballid )
								{
									Position.xyz += 0.04;
								}
							}
						}
					}
				}
				



				//Collide with edges.
				
				float edgecfm = 1.5 * vcfmfpsP;
				float edgecfmv = 1.5 * vcfmfpsV;
				
				// A bowl (not in use right now)
				if( _BallpitBoundaryMode == 0 )
				{
					//Bowl Collision.
					float3 bowlcenter = float3( 0., 31., 0. );
					float bowlradius = 30;				
					float exitlength = length( Position.xyz - bowlcenter ) - bowlradius;
					if( exitlength > 0 )
					{
						float3 enterdir = Position.xyz - bowlcenter;
						Velocity.xyz -= (normalize( enterdir ) * exitlength) * edgecfmv;
						Position.xyz -= (normalize( enterdir ) * exitlength)*edgecfm;
					}
				}
				else if( _BallpitBoundaryMode == 1 )
				{
					const float2 HighXZ = float2( 5, 5 );
					const float2 LowXZ = float2( -5, -5 );

					edgecfm = 0.5 * vcfmfpsP;
					edgecfmv = 100.5 * vcfmfpsV;
				
					//XXX XXX BIG XXX  THIS SHOULD ALL BE REWRITTEN AS A SDF!!!
					float protrudelen;

					// Floor
					protrudelen = -Position.y + Position.w -.04 - .5;
					if( protrudelen > 0 )
					{
						Velocity.xyz -= float3( 0, -1, 0 ) * protrudelen * edgecfmv;
						Position.xyz -= float3( 0, -1, 0 ) * protrudelen * edgecfm;
					}
					
					//Outer floor
					if( length( Position.xz ) + Position.w > 7.93 )
					{
						protrudelen = -Position.y + Position.w + .7 - .5;
						if( protrudelen > 0 )
						{
							Velocity.xyz -= float3( 0, -1, 0 ) * protrudelen * edgecfmv;
							Position.xyz -= float3( 0, -1, 0 ) * protrudelen * edgecfm;
						}
					} else if( length( Position.xz ) + Position.w > 5.0 && Position.y < 5-.5 ) //Between 6.5 and 8...
					{
						//Lip edge of floor.
						float3 delta = Position.xyz - float3( 0, 18-.5, 0 );
						protrudelen = length(delta)-18.93;
						if( protrudelen > 0 )
						{
							float3 norm = normalize(delta);
							Velocity.xyz -= norm * protrudelen * edgecfmv;
							Position.xyz -= norm * protrudelen * edgecfm;
						}
					}

					//Island (a sphere below the ground)
					if( 0 )
					{
						float3 diff = Position.xyz - float3( 0, -1.25, 0 );
						protrudelen = -length( diff ) + 2 + Position.w;
						if( protrudelen > 0 )
						{
							diff = normalize( diff  ) * protrudelen;
							Velocity.xyz += diff * edgecfmv;
							Position.xyz += diff * edgecfm;
						}
					}

					//This is just a slight nudge to push the balls back in.
					float adv = 0.00005;

					// Diameter of pit, cylindrically.
					protrudelen = length( Position.xz ) + Position.w - 5.95;
					if( protrudelen > 0 )
					{
						float3 norm = float3( normalize( Position.xz ).x, 0, normalize( Position.xz ).y );
						Velocity.xyz -= norm * protrudelen * edgecfmv * adv;
						Position.xyz -= norm * protrudelen * edgecfm * adv;
					}
				}
				else if( _BallpitBoundaryMode == 2 )
				{
					//Stepped environment.
					edgecfm = 0.5 * vcfmfpsP;
					edgecfmv = 100.5 * vcfmfpsV;

					float protrudelen = SDFBoundary( Position.xyz );
					if( protrudelen > 0 )
					{
						float3 protNorm = normalize( float3( 
							SDFBoundary( Position.xyz + float3( 0.01, 0, 0 ) ) - 
							SDFBoundary( Position.xyz + float3(-0.01, 0, 0 ) ),
							SDFBoundary( Position.xyz + float3( 0, 0.01, 0 ) ) - 
							SDFBoundary( Position.xyz + float3( 0,-0.01, 0 ) ),
							SDFBoundary( Position.xyz + float3( 0, 0, 0.01 ) ) - 
							SDFBoundary( Position.xyz + float3( 0, 0,-0.01 ) )
							) );
						Velocity.xyz -= protNorm * protrudelen * edgecfmv;
						Position.xyz -= protNorm * protrudelen * edgecfm;
					}
					
				}
				// boundary mode 3 is slightly different than 2, just with a soft return above "top" bound similar to that of mode 1
				// added by llealloo
				else if ( _BallpitBoundaryMode == 3 )
				{
					//Stepped environment.
					edgecfm = 0.5 * vcfmfpsP;
					edgecfmv = 100.5 * vcfmfpsV;

					// Floor
					float floorHeight = 0;

					float protrudelen = SDFBoundary( Position.xyz );
					// if ball is outside of boundary
					if( protrudelen > 0 )
					{

						// calculate normal to middle of 
						float adv = 0.000301;

						float3 norm = float3( normalize( Position.xz ).x, 0, normalize( Position.xz ).y );
						

						// if ball is outside of boundary and below floor 
						if( Position.y < floorHeight + Position.w ) 
						{
							// if ball is outside of boundary, below floor, and also within a distance of the SDF
							if(protrudelen < Position.w)
							{
								float3 protNorm = normalize( float3( 
									SDFBoundary( Position.xyz + float3( 0.01, 0, 0 ) ) - 
									SDFBoundary( Position.xyz + float3(-0.01, 0, 0 ) ),
									SDFBoundary( Position.xyz + float3( 0, 0.01, 0 ) ) - 
									SDFBoundary( Position.xyz + float3( 0,-0.01, 0 ) ),
									SDFBoundary( Position.xyz + float3( 0, 0, 0.01 ) ) - 
									SDFBoundary( Position.xyz + float3( 0, 0,-0.01 ) )
									) );
								if( Position.y < 0)
								{
									Velocity.xyz -= protNorm * protrudelen * edgecfmv;
									Position.xyz -= protNorm * protrudelen * edgecfm;
								}
								else
								{
									Velocity.xyz -= norm * protrudelen * edgecfmv * adv;
									Position.xyz -= norm * protrudelen * edgecfm * adv;
									Velocity.y = -Velocity.y;
									Position.y = floorHeight + Position.w;
								}
							}
							// if ball is outside of boundary, below floor, and outside of 2 radii from the SDF
							else
							{
								Velocity.xyz -= norm * protrudelen * edgecfmv * adv;
								Position.xyz -= norm * protrudelen * edgecfm * adv;
								Velocity.y = -Velocity.y;
								Position.y = floorHeight + Position.w;
							}
						}
						// if ball is outside of boundary and above floor
						else
						{
							Velocity.xyz -= norm * protrudelen * edgecfmv * adv;
							Position.xyz -= norm * protrudelen * edgecfm * adv;
						}
					}
				}

				//Use depth cameras (Totals around 150us per camera on a 2070 laptop)
				if( 1 ) 
				{
					//const float2 WorldSize = float2( 16, 16 );

					float heightcfm = _HeightmapCFM * 0.48 * vcfmfpsP;
					float heightcfmv = _HeightmapCFM * 200. * 1 * vcfmfpsV; //Should have been *4 because we /4'd our texture?
					
					float4 StorePos = Position;
					float4 StoreVel = Velocity;
					//Collision with depth map.
					int2 DepthMapCoord = ( (Position.xz) / WorldSize + 0.5 ) * _DepthMapComposite_TexelSize.zw ;
					float2 DepthMapDeltaMeters = WorldSize * _DepthMapComposite_TexelSize.xy;


					int2 neighborhood = 7;//ceil( Position.w / DepthMapDeltaMeters );
					int2 ln;
					for( ln.x = -neighborhood.x; ln.x < neighborhood.x; ln.x++ )
					[unroll]
					for( ln.y = -neighborhood.y; ln.y < neighborhood.y; ln.y++ )
					{
						int2 coord = ln + DepthMapCoord;

						// Note: Out-of-bounds checking seems unncessary. 
							
						float2 Y = _DepthMapComposite[coord];

						
						// No top pixels - early out!
						if( Y.x <= 0 ) continue;

	
						Y *= _BallpitCameraHeight;
						Y.x += CAMERA_Y_OFFSET;
						Y.y -= CAMERA_Y_OFFSET;

						if( Y.y == 0 ) Y.y = _BallpitCameraHeight;
						Y.y = _BallpitCameraHeight-((Y.y));

						//coord + 0.5 because we went from 2048 to 1024 here.
						float2 xzWorldPos = (((coord + 0.5)* _DepthMapComposite_TexelSize.xy) - 0.5 ) * WorldSize;

						Y *= WorldSize.z;
						
						//Figure out which side we're coming from.
						float CenterY = (Y.y + Y.x) / 2;
						float3 CollisionPosition = float3( xzWorldPos.x, (StorePos.y > CenterY )?Y.x:Y.y, xzWorldPos.y );
						
						//Tricky: If we are above the bottom part and below the top, we are "inside" so zero the Y.
						if( StorePos.y < Y.x && StorePos.y > Y.y )
						{
							CollisionPosition.y = StorePos.y;
						}


						float3 deltap = StorePos.xyz - CollisionPosition;

						float penetration = StorePos.w - length(deltap);
						if( penetration > 0 )
						{
							float neighborderate = neighborhood.x *neighborhood.y;
							deltap = normalize( deltap );
							Velocity.xyz += deltap * penetration * heightcfmv / neighborderate;
							Position.xyz += deltap * penetration * heightcfm / neighborderate;
						}
					}
				}
				
				//Fountain / Fan
				if( 1 )
				{
					float4 FanPos[3];
					float4 FanQuat[3];
					FanPos[0] = _FanPosition0*WorldSize.z;
					FanPos[1] = _FanPosition1*WorldSize.z;
					FanPos[2] = _FanPosition2*WorldSize.z;
					FanQuat[0] = _FanRotation0;
					FanQuat[1] = _FanRotation1;
					FanQuat[2] = _FanRotation2;

					int i;
					for( i = 0; i < 3; i++ )
					{
						float3 FanStart = FanPos[i].xyz;
						float FanStrength = FanPos[i].w;
						float3 FanVector = normalize( qtransform( q_inverse( FanQuat[i] ), float3( 0, 1, 0 ) ) );
						
						float3 RelPos = Position - FanStart;
						float t = dot( RelPos, FanVector ); //Distance along fan vector
						float3 lpos = FanVector * t;
						float d = length( RelPos - lpos ); //Distance from fan vector
						
						float dforce = 1 - d;
						dforce = min( dforce, (5*FanStrength-t)*.5 ); //Force contribution at extent
						dforce = min( t + 1, dforce ); //Force contribution behind.
												
						if( dforce > 0 )
						{
							Velocity.xyz += FanVector.xyz * dforce * .15;
						}
					}
				}
				
				//Attract to dragdropper
				if( 1 )
				{
					const static float dragdropforce = 0.008;
					float l, intensity;
					float3 diff;
					
					diff = _MagnetPos0.xyz - Position.xyz;
					l = length( diff );
					intensity = 5.*sqrt(_MagnetPos0.w) - l;					
					if( intensity > 0 )
					{
						diff = normalize( diff )*.8;
						Velocity.xyz += diff * dragdropforce * pow( intensity, 1.55 );
					}


					diff = _MagnetPos1.xyz - Position.xyz;
					l = length( diff );
					intensity = 5.*sqrt(_MagnetPos1.w) - l;					
					if( intensity > 0 )
					{
						diff = normalize( diff )*.8;
						Velocity.xyz += diff * dragdropforce * pow( intensity, 1.55 );
					}


					diff = _MagnetPos2.xyz - Position.xyz;
					l = length( diff );
					intensity = 5.*sqrt(_MagnetPos2.w) - l;					
					if( intensity > 0 )
					{
						diff = normalize( diff )*.8;
						Velocity.xyz += diff * dragdropforce * pow( intensity, 1.55 );
					}

				}

				// Disperse from shrooms because having drugs in your balls are bad.

				if( REPEL_MODE_NEW )
				{
					const static float repelforce = 0.17;
					float l, intensity;
					float3 diff;
					
					diff = Position.xyz - _ShroomPos0.xyz;
					l = length( diff );
					intensity = 2.25*_ShroomPos0.w - l;					
					if( intensity > 0 )
					{
						diff = normalize( diff );
						//Velocity.xyz += diff * repelforce * exp(1.-intensity*intensity);
						//Velocity.xyz += diff * repelforce * exp(1.-intensity) * normalize(cross(Position.xyz, _ShroomPos0));
						Velocity.xyz += repelforce * exp(1.-intensity*intensity) * normalize(cross(Position.xyz, _ShroomPos0));
					}
					
					diff = Position.xyz - _ShroomPos1.xyz;
					l = length( diff );
					intensity = 2.0*_ShroomPos1.w - l;					
					if( intensity > 0 )
					{
						diff = normalize( diff );
						Velocity.xyz += diff * repelforce * exp(1.-intensity*intensity*intensity);
						//Velocity.xyz += diff * repelforce * exp(1.-intensity) * normalize(cross(Position.xyz, _ShroomPos1));
				
					}
					
					diff = Position.xyz - _ShroomPos2.xyz;
					l = length( diff );
					intensity = 2.5*_ShroomPos2.w - l;					
					if( intensity > 0 )
					{
						diff = normalize( diff );
						float b = 9.* asin(diff.y / l);
						float a = 9.* atan2(diff.x, diff.z);						
						Velocity.xyz += exp(intensity*intensity) * 0.15 * diff * repelforce + 0.15 * normalize(exp(intensity*intensity) *  float3(sin(b) * sin(a), cos(b), sin(b) * cos(a)));								
						//Velocity.xyz += diff * repelforce * exp(1.-intensity) * normalize(cross(Position.xyz, _ShroomPos2));
					}
					
					diff = Position.xyz - _ShroomPos3.xyz;
					l = length( diff );
					intensity = 2.25*_ShroomPos3.w - l;					
					if( intensity > 0 )
					{
						diff = normalize( diff );
						//Velocity.xyz += diff * repelforce * exp(1.-intensity*intensity*intensity*intensity);
						Velocity.xyz += diff * repelforce * exp(1.-intensity) * normalize(cross(Position.xyz, _ShroomPos3));

						//Velocity.xyz += diff * repelforce * exp(1.-intensity) * normalize(cross(Position.xyz, _ShroomPos3));
					}
					
					diff = Position.xyz - _ShroomPos4.xyz;
					l = length( diff );
					intensity = 2.0*_ShroomPos4.w - l;					
					if( intensity > 0 )
					{
						diff = normalize( diff );
						//Velocity.xyz += diff * repelforce * exp(1.-intensity*intensity);
						Velocity.xyz += diff * repelforce * exp(1.-intensity*intensity);
					}
					
					diff = Position.xyz - _ShroomPos5.xyz;
					l = length( diff );
					intensity = 2.5*_ShroomPos5.w - l;					
					if( intensity > 0 )
					{
						//Velocity.xyz += repelforce * exp(1.-intensity*intensity);
						float b = 9.* asin(diff.y / l);
						float a = 9.* atan2(diff.x, diff.z);						
						Velocity.xyz += exp(intensity*intensity) * 0.15 * diff * repelforce + 0.15 * normalize(exp(intensity*intensity) *  float3(sin(b) * sin(a), cos(b), sin(b) * cos(a)));	
					}												
				}
				else
				{
					const static float repelforce = 0.17;
					float l, intensity;
					float3 diff;
					
					diff = Position.xyz - _ShroomPos0.xyz;
					l = length( diff );
					intensity = 1.5*_ShroomPos0.w - l;					
					if( intensity > 0 )
					{
						diff = normalize( diff );
						Velocity.xyz += diff * repelforce * exp(1.-intensity*intensity*intensity*intensity*intensity);
					}
					
					diff = Position.xyz - _ShroomPos1.xyz;
					l = length( diff );
					intensity = 1.5*_ShroomPos1.w - l;					
					if( intensity > 0 )
					{
						diff = normalize( diff );
						Velocity.xyz += diff * repelforce * exp(1.-intensity*intensity*intensity*intensity*intensity);
					}
					
					diff = Position.xyz - _ShroomPos2.xyz;
					l = length( diff );
					intensity = 1.5*_ShroomPos2.w - l;					
					if( intensity > 0 )
					{
						diff = normalize( diff );
						Velocity.xyz += diff * repelforce * exp(1.-intensity*intensity*intensity*intensity*intensity);
					}
					
					diff = Position.xyz - _ShroomPos3.xyz;
					l = length( diff );
					intensity = 1.5*_ShroomPos3.w - l;					
					if( intensity > 0 )
					{
						diff = normalize( diff );
						Velocity.xyz += diff * repelforce * exp(1.-intensity*intensity*intensity*intensity*intensity);
					}
					
					diff = Position.xyz - _ShroomPos4.xyz;
					l = length( diff );
					intensity = 1.5*_ShroomPos4.w - l;					
					if( intensity > 0 )
					{
						diff = normalize( diff );
						Velocity.xyz += diff * repelforce * exp(1.-intensity*intensity*intensity*intensity*intensity);
					}
					
					diff = Position.xyz - _ShroomPos5.xyz;
					l = length( diff );
					intensity = 1.5*_ShroomPos5.w - l;					
					if( intensity > 0 )
					{
						diff = normalize( diff );
						Velocity.xyz += diff * repelforce * exp(1.-intensity*intensity*intensity*intensity*intensity);
					}												
				}				

				// Step 2: Actually perform physics.
				Velocity.y -= _GravityValue*dt;
				
				Position.xyz = Position.xyz + Velocity.xyz * dt;
				
				Velocity.xyz = Velocity.xyz * (1 - _Friction );

				ret.Pos = Position;
				ret.Vel = Velocity;

				return ret;
			}
			ENDCG
		}
	}
}
