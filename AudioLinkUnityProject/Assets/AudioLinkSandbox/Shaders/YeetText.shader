Shader "Custom/Yeet"
{
	Properties
	{
		_TextData ("TextData", 2D) = "white" {}
		_BackgroundColor( "Background Color", Color ) = ( 0, 0, 0, 0 )
		_ForegroundColor( "Foreground Color", Color ) = ( 1, 1, 1, 1 )
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" "Queue" = "Transparent-1000"  }
		LOD 100
		Cull Off
		Blend SrcAlpha OneMinusSrcAlpha

        // shadow caster rendering pass, implemented manually
        // using macros from UnityCG.cginc
        Pass
        {
            Tags {"LightMode"="ShadowCaster"}

			CGINCLUDE
            #pragma vertex vert
            #pragma fragment frag
			#pragma multi_compile_fog
			#pragma multi_compile_instancing
			#pragma target 5.0
			#include "UnityCG.cginc"
			#include "Packages/com.llealloo.audiolink/Runtime/Shaders/SmoothPixelFont.cginc"

			
			#ifndef glsl_mod
			#define glsl_mod(x, y) (x - y * floor(x / y))
			#endif

			Texture2D<float4> _TextData;
			float4 _TextData_TexelSize;
			float4 _BackgroundColor;
			float4 _ForegroundColor;

			float4 ColorCompute( float2 iuv, float facing, float3 hitworld, out float outDepth )
			{
				if( facing < 0.5 )
					iuv.x = 1.0 - iuv.x;
				iuv.y = 1.0 - iuv.y;

				// Pixel location on font pixel grid
				float2 pos = iuv * float2(_TextData_TexelSize.zw);

				// Character location as uint (floor)
				uint2 character = (uint2)pos;

				float4 dataatchar = _TextData[character];
				
				// This line of code is tricky;  We determine how much we should soften the edge of the text
				// based on how quickly the text is moving across our field of view.  This gives us realy nice
				// anti-aliased edges.
				float2 softness_uv = pos * float2( 4, 6 );
				float softness = 4./(pow( length( float2( ddx( softness_uv.x ), ddy( softness_uv.y ) ) ), 0.5 ))-1.;

				float2 charUV = float2(4, 6) - glsl_mod(pos, 1.0) * float2(4.0, 6.0);
				
				float weight = (floor(dataatchar.w)/2.-1.)*.3;
				int charVal = frac(dataatchar.w)*256;
				float4 col = lerp( lerp( _BackgroundColor, float4( 0., 0., 0., 0. ), 1. - saturate( facing ) ), _ForegroundColor, saturate( PrintChar( charVal, charUV, softness, weight )*float4(dataatchar.rgb,1.) ) );
				
				float4 clipPos = mul(UNITY_MATRIX_VP, float4(hitworld, 1.0));
				outDepth = clipPos.z / clipPos.w;
				

				return col;
			}
			
			
			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
			};

			ENDCG

            CGPROGRAM
            #pragma multi_compile_shadowcaster

            struct v2f { 
				float2 uv : TEXCOORD0;
				float3 hitworld : TEXCOORD1;
                V2F_SHADOW_CASTER;
            };

            v2f vert(appdata v)
            {
                v2f o;
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
				o.hitworld = mul( unity_ObjectToWorld, v.vertex );
				o.uv = v.uv;
                return o;
            }

            float4 frag(v2f i, fixed facing : VFACE, out float outDepth : SV_DepthLessEqual, out uint Coverage[1] : SV_Coverage) : SV_Target
            {
				float4 ret = ColorCompute( i.uv, facing, i.hitworld, outDepth );;
				//clip( ret.a < 0.5 ? -1 : 1 );
				Coverage[0] = ( 1u << ((uint)(ret.a*GetRenderTargetSampleCount() + 0.5)) ) - 1;

				return ret;
            }
            ENDCG
        }


		Pass
		{
			CGPROGRAM
			// make fog work
			#pragma multi_compile_fog
			#pragma target 5.0

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float3 hitworld : TEXCOORD1;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
			};

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				UNITY_TRANSFER_FOG(o,o.vertex);
				o.hitworld = mul( unity_ObjectToWorld, v.vertex );
				return o;
			}

			fixed4 frag (v2f i, fixed facing : VFACE, out float outDepth : SV_DepthLessEqual, out uint Coverage[1] : SV_Coverage) : SV_Target
			{
				//Tricky if we're an ortho camera don't show the backside - yeeters should behave weird with balls.
				if ((UNITY_MATRIX_P[3].x == 0.0) && (UNITY_MATRIX_P[3].y == 0.0) && (UNITY_MATRIX_P[3].z == 0.0))
				{
					if( facing < 0.5 )
					{
						outDepth = 0;
					}
				}
				float4 col = ColorCompute( i.uv, facing, i.hitworld, outDepth );
				Coverage[0] = ( 1u << ((uint)(col.a*GetRenderTargetSampleCount() + 0.5)) ) - 1;

				return col;
			}
			ENDCG
		}
	}
}
