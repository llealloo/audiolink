Shader "DensitiesCRT"
{
	Properties
	{
		_Tex2D ("Texture (2D)", 2D) = "white" {}
		_ColorRamp( "Color Ramp", 2D ) = "white" { }
		_TANoiseTex ("TANoise", 2D) = "white" {}
	}

	SubShader
	{
		Tags { }
		ZTest always
		ZWrite Off
		
		CGINCLUDE
		#include "../../tanoise/tanoise.cginc"
		#define CRTTEXTURETYPE float4
		ENDCG

		Pass
		{
			Name "Pepper"
			
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			#pragma geometry geo
			#pragma multi_compile_fog
			#pragma target 5.0

			#include "flexcrt.cginc"
			#include "../../hashwithoutsine/hashwithoutsine.cginc"

			struct v2g
			{
				float4 vertex : SV_POSITION;
				uint2 batchID : TEXCOORD0;
			};

			struct g2f
			{
				float4 vertex : SV_POSITION;
				float4 color : TEXCOORD0;
			};

			// The vertex shader doesn't really perform much anything.
			v2g vert( appdata_customrendertexture IN )
			{
				v2g o;
				o.batchID = IN.vertexID / 6;

				// This is unused, but must be initialized otherwise things get janky.
				o.vertex = 0.;
				return o;
			}

			[maxvertexcount(2)]
			[instance(1)]
			void geo( point v2g input[1], inout PointStream<g2f> stream,
				uint instanceID : SV_GSInstanceID, uint geoPrimID : SV_PrimitiveID )
			{
				// Just FYI you get 64kB of local variable space.
				
				int batchID = input[0].batchID;

				int operationID = geoPrimID * 1 + ( instanceID - batchID );
				
				g2f o;

				uint PixelID = operationID * 1;
				
				// We first output random noise, then we output a stable block.
				float4 randval = chash44( float4( operationID, _Time.y, 0, 0 ) );

				if( randval.w < .01 )
				{
					uint3 coordOut3D = randval.xyz * int3( FlexCRTSize.xx, FlexCRTSize.y / FlexCRTSize.x );
					uint2 coordOut2D;
					coordOut2D = uint2( coordOut3D.x, coordOut3D.y + coordOut3D.z * FlexCRTSize.x );
					
					o.vertex = FlexCRTCoordinateOut( coordOut2D );
					o.color = float4( -randval.z*10000., 0.0, 0.0, 1.0 );
					stream.Append(o);

					int dir = (randval.w * 6000) % 6;
					if( dir == 0 ) coordOut3D.x += 3;
					if( dir == 1 ) coordOut3D.x -= 3;
					if( dir == 2 ) coordOut3D.y += 3;
					if( dir == 3 ) coordOut3D.y -= 3;
					if( dir == 4 ) coordOut3D.z += 3;
					if( dir == 5 ) coordOut3D.z -= 3;
					coordOut2D = uint2( coordOut3D.x, coordOut3D.y + coordOut3D.z * FlexCRTSize.x );
					o.vertex = FlexCRTCoordinateOut( coordOut2D );
					o.color = float4( randval.z*10000., 0.0, 0.0, 1.0 );
					stream.Append(o);
				}
			}

			float4 frag( g2f IN ) : SV_Target
			{
				return IN.color;
			}
			ENDCG
		}
		
		Pass
		{
			Name "Fade"
			CGPROGRAM

			#pragma vertex DefaultCustomRenderTextureVertexShader
			#pragma fragment frag
			#pragma multi_compile_fog
			#pragma target 5.0

			#define CRTTEXTURETYPE float4
			#include "flexcrt.cginc"

			float4 getVirtual3DVoxel( int3 voxel )
			{
				if( any( voxel < 0 ) || voxel.x >= FlexCRTSize.x || voxel.y >= FlexCRTSize.x || voxel.z >= FlexCRTSize.x * FlexCRTSize.y )
				{
					return 0;
				}
				return _SelfTexture2D.Load( int3( voxel.x, voxel.y + voxel.z * FlexCRTSize.x, 0 ) );
			}
			

			float4 frag( v2f_customrendertexture IN ) : SV_Target
			{
				int3 vox = int3( IN.globalTexcoord * FlexCRTSize.xy, 0 );
				vox.z = vox.y / FlexCRTSize.x;
				vox.y %= FlexCRTSize.x;

				float4 tv = getVirtual3DVoxel( vox );
				float4 vusum = 0;

				if( 0 )
				{
					float4 vus[6] = {
						getVirtual3DVoxel( vox + int3( -1, 0, 0 ) ),
						getVirtual3DVoxel( vox + int3( 1, 0, 0 ) ),
						getVirtual3DVoxel( vox + int3( 0, -1, 0 ) ),
						getVirtual3DVoxel( vox + int3( 0, 1, 0 ) ),
						getVirtual3DVoxel( vox + int3( 0, 0, -1 ) ),
						getVirtual3DVoxel( vox + int3( 0, 0, 1 ) ),
						};
					int i;
					for( i = 0; i < 6; i++ )
					{
						vusum += vus[i];
					}
					vusum/= 7.0;
				}
				else
				{
					float vutot = 0.0;
					int3 offset;
					for( offset.z = -1; offset.z <= 1; offset.z++ )
					for( offset.y = -1; offset.y <= 1; offset.y++ )
					for( offset.x = -1; offset.x <= 1; offset.x++ )
					{
						if( length( offset ) < 0.01 ) continue;
						float inten = 1.0 / length( offset );
						vutot += inten;
						vusum += getVirtual3DVoxel( vox + offset );
					}
					vusum /= vutot;
				}
				
				float timestep = 0.1;
				float decay = 0.92;
				
				float velocity = tv.z;
				float value = tv.x;
				float laplacian = 2.0*(vusum.x - value);
				value+=velocity*timestep;
				velocity+=laplacian*timestep;

				return float4( value * decay, 0, velocity * decay, value );
			}
			
			ENDCG
		}
		
		Pass
		{
			Name "Display"
			CGPROGRAM

			#pragma vertex DefaultCustomRenderTextureVertexShader
			#pragma fragment frag
			#pragma multi_compile_fog
			#pragma target 5.0

			#define CRTTEXTURETYPE float4
			#include "flexcrt.cginc"
			
			Texture2D<float4> _Tex2D;
			sampler2D _ColorRamp;

			float4 frag( v2f_customrendertexture IN ) : SV_Target
			{
				float4 value = _Tex2D.Load( int3(IN.globalTexcoord * FlexCRTSize.xy, 0 ) );
				float3 color = tex2Dlod( _ColorRamp, float4( pow( abs( value.x ), 0.1 ) * sign( value.x ), 0, 0, 0 ) );
				return saturate( float4( color, saturate( abs( value.x ) )/10.0 ) );
			}
			
			ENDCG
		}


		Pass
		{
			Name "Display2"
			CGPROGRAM

			#pragma vertex DefaultCustomRenderTextureVertexShader
			#pragma fragment frag
			#pragma multi_compile_fog
			#pragma target 5.0

			#define CRTTEXTURETYPE float4
			#include "flexcrt.cginc"
			
			Texture2D<float4> _Tex2D;
			sampler2D _ColorRamp;

			float4 frag( v2f_customrendertexture IN ) : SV_Target
			{
				int3 vox = int3( IN.globalTexcoord * FlexCRTSize.xy, 0 );
				vox.z = vox.y / FlexCRTSize.x;
				vox.y %= FlexCRTSize.x;
				
				float4 noise4 = tanoise4( float4( vox*.2 + float3( 0, _Time.y*.05, _Time.y*.25 ), _Time.y * .1 ) );
				float4 noiseB = tanoise4( float4( vox*.2 + float3( 0, _Time.y*.05, -_Time.y*.25 ), _Time.y * 1.1 ) );


				float4 color = saturate( float4( 0, 0, 0, -.4 ) + float4( noiseB.rgb, noise4.a ) * float4( 1, 1, 1, 0.6 ) );
				
				// Force vividness to be high.
				float minc = min( min( color.r, color.g ), color.b );
				color.rgb = normalize( color.rgb - minc )*1.4;
				return color;
			}
			
			ENDCG
		}
	}
}
