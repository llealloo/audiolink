Shader "AudioLinkSandbox/ApplySmoothText"
{
	Properties
	{
		_TextData ("TextData", 2D) = "white" {}
		_BackgroundColor( "Background Color", Color ) = ( 0, 0, 0, 0 )
		_ForegroundColor( "Foreground Color", Color ) = ( 1, 1, 1, 1 )
		_AAAmt( "AA Amount", float ) = 0.4
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
			#pragma multi_compile_instancing
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
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
			float _AAAmt;

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 pos : SV_POSITION;
			};

			ENDCG
			CGPROGRAM
			v2f vert (appdata_base v)
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				//o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.texcoord;
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}

			fixed4 frag (v2f i, out uint Coverage[1] : SV_Coverage) : SV_Target
			{
				float2 iuv = i.uv;
				iuv.y = 1.0 - iuv.y;

				// Pixel location on font pixel grid
				float2 pos = iuv * float2(_TextData_TexelSize.zw);

				// Character location as uint (floor)
				uint2 character = (uint2)pos;

				float4 dataatchar = _TextData[character];

				float4 col = 0;
				float2 tpos = pos;
				// This line of code is tricky;  We determine how much we should soften the edge of the text
				// based on how quickly the text is moving across our field of view.  This gives us realy nice
				// anti-aliased edges.
				float2 softness_uv = tpos * float2( 4, 6 );
				float softness = 4./(pow( length( float2( ddx( softness_uv.x ), ddy( softness_uv.y ) ) ), 0.5 ))-1.;

				float2 charUV = float2(4, 6) - glsl_mod(tpos, 1.0) * float2(4.0, 6.0);
				
				float weight = (floor(dataatchar.w)/2.-1.)*.3;
				int charVal = frac(dataatchar.w)*256;
				col += lerp( _BackgroundColor, _ForegroundColor, saturate( PrintChar( charVal, charUV, softness, weight )*float4(dataatchar.rgb,1.) ) );

				
				//Thanks, D4rkPl4y3r.
				Coverage[0] = ( 1u << ((uint)(col.a*GetRenderTargetSampleCount() + 0.5)) ) - 1;

				SHADOW_CASTER_FRAGMENT(i)

				return col;
			}
	
			ENDCG
		}
		Pass
		{
			Tags { "RenderType"="Opaque" "LightModel"="ForwardBase"}

			CGPROGRAM
			#pragma multi_compile_instancing

			v2f vert (appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				UNITY_TRANSFER_FOG(o,o.pos);
				return o;
			}

			fixed4 frag (v2f i, out uint Coverage[1] : SV_Coverage) : SV_Target
			{
				float2 iuv = i.uv;
				iuv.y = 1.0 - iuv.y;

				// Pixel location on font pixel grid
				float2 pos = iuv * float2(_TextData_TexelSize.zw);

				// Character location as uint (floor)
				uint2 character = (uint2)pos;

				float4 dataatchar = _TextData[character];

				float4 col = 0;
				float dx, dy;
				[unroll]
				for( dy = 0; dy < 2; dy++ )
				[unroll]
				for( dx = 0; dx < 2; dx++ )
				{
					float mx = (dx - 0.5) * _AAAmt;
					float my = (dy - 0.5) * _AAAmt;
					float2 tpos = pos + float2( ddx( pos.x ), ddy( pos.x ) ) * mx + float2( ddx( pos.y ), ddy( pos.y ) ) * my;
					// This line of code is tricky;  We determine how much we should soften the edge of the text
					// based on how quickly the text is moving across our field of view.  This gives us realy nice
					// anti-aliased edges.
					float2 softness_uv = tpos * float2( 4, 6 );
					float softness = 4./(pow( length( float2( ddx( softness_uv.x ), ddy( softness_uv.y ) ) ), 0.5 ))-1.;

					float2 charUV = float2(4, 6) - glsl_mod(tpos, 1.0) * float2(4.0, 6.0);
					
					float weight = (floor(dataatchar.w)/2.-1.)*.3;
					int charVal = frac(dataatchar.w)*256;
					col += lerp( _BackgroundColor, _ForegroundColor, saturate( PrintChar( charVal, charUV, softness, weight )*float4(dataatchar.rgb,1.) ) );
				}
				col/=4;
				//Thanks, D4rkPl4y3r.
				Coverage[0] = ( 1u << ((uint)(col.a*GetRenderTargetSampleCount() + 0.5)) ) - 1;

				return col;
			}
			ENDCG
		}
	}
}
