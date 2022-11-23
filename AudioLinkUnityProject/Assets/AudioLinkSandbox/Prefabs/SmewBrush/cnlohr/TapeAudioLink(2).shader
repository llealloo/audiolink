// "Look At" Code
//    Storage for distribution - phi16
//    https://github.com/phi16/VRC_storage
//    rounded_trail.unitypackage
//    LICENSE : CC0
// 2020-04-16 seeing vertex color.
// 2019-09-26 customized for QvPen v2.
// 2019-09-09 customized for QvPen.
//
// AudioLink code: (C) 2022 Charles Lohr, LICENSE : CC0 (2022-01-30)



Shader "cnlohr/TapeAudioLink"
{
	Properties
	{
		_Intensity ("Intensity", float) = 8.0
		_Width ("Width (where applicable)", float) = 0.05
		[Toggle(DONTLOOKAT)]  DONTLOOKAT ("Don't Look At", int ) = 0
		[Toggle(INCLUDECONNECTIVE)]  INCLUDECONNECTIVE ("Include Connective", int ) = 1
		[Toggle(CCLIGHTS)]  CCLIGHTS ("CC Lights", int ) = 1
		_DriftAmount ("Drift Amount", float) = 0.1//0.1
		_DriftSpeed ("Drift Speed", float) = .5//.1
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" "Queue"="Transparent" "DisableBatching" ="True"}
		Cull Off

		Blend One One 
		ZWrite Off
		
		//Blend SrcAlpha OneMinusSrcAlpha  // Premultiplied transparency

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma geometry geo

			#pragma multi_compile_local _ DONTLOOKAT
			#pragma multi_compile_local _ INCLUDECONNECTIVE
			#pragma multi_compile_local _ CCLIGHTS

			#include "UnityCG.cginc"
			#include "Packages/com.llealloo.audiolink/Runtime/Shaders/AudioLink.cginc"
			#include "Assets/AudioLinkSandbox/Shaders/hashwithoutsine/hashwithoutsine.cginc"

			//#include "./AudioLink/Shaders/AudioLink.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2g
			{
				float2 uv : TEXCOORD0;

				float4 vertex : SV_POSITION;
			};

			struct g2f
			{
				float4 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float d : TEXCOORD3;
			};

			float _Intensity;
			float _Width;
			float _DriftAmount;
			float _DriftSpeed;

			v2g vert (appdata v)
			{
				v2g o;
				o.vertex = v.vertex;
				o.uv = v.uv;
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			
			
			[maxvertexcount(12)]
			void geo(triangle v2g IN[3], inout TriangleStream<g2f> stream, uint id : SV_PrimitiveID)
			{
				g2f pIn;
				pIn.uv = 0.;

//#define DONTLOOKAT
#ifdef DONTLOOKAT
				pIn.d = 0.;
				pIn.vertex =  UnityObjectToClipPos( IN[0].vertex );
				pIn.uv.zw = IN[0].uv;

				stream.Append(pIn);

				pIn.vertex =  UnityObjectToClipPos( IN[1].vertex );
				pIn.uv.zw = IN[1].uv;

				stream.Append(pIn);

				pIn.vertex =  UnityObjectToClipPos( IN[2].vertex );
				pIn.uv.zw = IN[2].uv;

				stream.Append(pIn);
#else
#if defined(USING_STEREO_MATRICES)
    float3 PlayerCenterCamera = ( unity_StereoWorldSpaceCameraPos[0] + unity_StereoWorldSpaceCameraPos[1] ) / 2;
#else
    float3 PlayerCenterCamera = _WorldSpaceCameraPos.xyz;
#endif

				float dist = length(PlayerCenterCamera - mul(unity_ObjectToWorld, IN[0].vertex));

				g2f o;
				o.uv = 0;
				
				if(IN[0].uv.x + IN[2].uv.x > IN[1].uv.x * 2)
					return;

				float usetime = (_Time.y * _DriftSpeed);
				
				float3 offset = _DriftAmount *.01*float3( csimplex3( float3( usetime, id*10, 0 ) ),
					csimplex3( float3( usetime+.2, id*10, 3 ) ),
					csimplex3( float3( usetime+.7, id*10, 5 ) ) );
				
				//float3 offset = _DriftAmount *.01 * float3( sin(usetime+id), sin(usetime*3.2914+id*35), sin(usetime*5.3425-id*93) );

				#define OTER_VERT 2
				float4 p = UnityObjectToClipPos(IN[0].vertex+offset);
				float4 q = UnityObjectToClipPos(IN[OTER_VERT].vertex+offset); //XXX TODO MAYBE CHANGE THIS TO 1.
				
				float2 d = p.xy / p.w - q.xy / q.w;
				float aspectRatio = -_ScreenParams.y / _ScreenParams.x;
				d.x /= aspectRatio;
				o.d = length(d);
				if(length(d) < 0.00001) d = float2(1, 0);
				else d = normalize(d);

				float2 w = _Width * length( IN[0].vertex.xyz - IN[OTER_VERT].vertex.xyz );
				w *= float2(aspectRatio, -1);
				
				#if defined(USING_STEREO_MATRICES)
					w *= (unity_StereoCameraProjection[0]._m11+unity_StereoCameraProjection[1]._m11)/2 / 1.732;
				#else
					w *= unity_CameraProjection._m11 / 1.732;
				#endif
				float4 n = {d.yx, 0, 0};
				n.xy *= w;

				o.d = 0;

#ifdef INCLUDECONNECTIVE
				// Actual strip.
				o.vertex = p + n;
				o.uv.zw = float2( IN[0].uv.x, IN[0].uv.y );
				stream.Append(o);
				o.vertex = p - n;
				o.uv.zw = float2( IN[0].uv.x, IN[1].uv.y );
				stream.Append(o);
				o.vertex = q + n;
				o.uv.zw = float2( IN[2].uv.x, IN[0].uv.y );
				stream.Append(o);
				o.vertex = q - n;
				o.uv.zw = float2( IN[2].uv.x, IN[1].uv.y );
				stream.Append(o);
				stream.RestartStrip();
	#endif
	
				o.uv.zw = 1;
				
				// Circle on each end.
				o.d = 1;
				w *= 2;
				
				if(IN[1].uv.x >= 0.999999) {
					n.xy = (o.uv.xy = float2(0, 1)) * w;
					o.uv.zw = float2( IN[1].uv.x, IN[1].uv.y );
					o.vertex = q + n;
					stream.Append(o);
					n.xy = (o.uv.xy = float2(-0.866, -0.5)) * w;
					o.uv.zw = float2( IN[1].uv.x, IN[1].uv.y );
					o.vertex = q + n;
					stream.Append(o);
					o.uv.zw = float2( IN[1].uv.x, IN[0].uv.y );
					n.xy = (o.uv.xy = float2(0.866, -0.5)) * w;
					o.vertex = q + n;
					stream.Append(o);
					stream.RestartStrip();
				}

				n.xy = (o.uv.xy = float2(-1, -1)*0.5) * w;
				o.uv.zw = float2( IN[0].uv.x, IN[1].uv.y );
				o.vertex = p + n;
				stream.Append(o);
				
				n.xy = (o.uv.xy = float2(1, -1)*0.5) * w;
				o.uv.zw = float2( IN[0].uv.x, IN[1].uv.y );
				o.vertex = p + n;
				stream.Append(o);
				
				n.xy = (o.uv.xy = float2(-1, 1)*0.5) * w;
				o.uv.zw = float2( IN[0].uv.x, IN[0].uv.y );
				o.vertex = p + n;
				stream.Append(o);

				n.xy = (o.uv.xy = float2(1,1)*0.5) * w;
				o.uv.zw = float2( IN[0].uv.x, IN[0].uv.y );
				o.vertex = p + n;
				stream.Append(o);
				
				stream.RestartStrip();

#endif
			}
			

			float4 frag (g2f i) : SV_Target
			{
				// sample the texture
				float4 col = 0.;

#if 0
				float l = length(i.uv.xy);
				clip(0.5 - min(i.d, l));
				if( length( i.uv ) == 0 ) return 1.;
				return float4(i.uv.zw, 0., 1);
#endif

				//i.uv.z = how far along
				//i.uv.w = side-to-side.


				float2 useuv;
				if( length( i.uv.xy ) == 0.0 )
				{
					// Just use the same.
					useuv = i.uv.zw;
				}
				else
				{
					useuv.x = i.uv.z;
					useuv.y = length( i.uv.xy )+0.5;
				}

				float3 color = 
				#ifdef CCLIGHTS
					AudioLinkData( ALPASS_CCLIGHTS + uint2( uint(useuv.x * 333)%128, 0.0 ) );
				#else
					AudioLinkLerp( ALPASS_CCSTRIP + uint2( useuv.x * 127., 0.0 ) );
				#endif
				float4 intens = 0.1;
				if( length( color ) < .01 )
					color = AudioLinkHSVtoRGB( float3( frac( _Time.y * .1 ), 1, 1 ) );
				else
				{
					color = normalize( color );
				}

				if( AudioLinkIsAvailable() )
				{
					intens = float4(
						AudioLinkLerp( ALPASS_AUDIOLINK + float2( useuv.x * 127, 0.0 ) ).r,
						AudioLinkLerp( ALPASS_AUDIOLINK + float2( useuv.x * 127, 1.0 ) ).r,
						AudioLinkLerp( ALPASS_AUDIOLINK + float2( useuv.x * 127, 2.0 ) ).r,
						AudioLinkLerp( ALPASS_AUDIOLINK + float2( useuv.x * 127, 3.0 ) ).r
					);
				}
					
				float iv = abs( useuv.y - 0.5 )*1.0;
				float im = length(intens)/6.0 - pow( iv.x, 2 ) + 0.03;

				col.rgb = im * color * _Intensity;

				col.rgb = max( col.rgb , 0. );
				if( length( col.rgb ) < 0.01 ) discard;
				
				
				//col.a = saturate( length( col.rgb ) );
				return col;
			}
			ENDCG
		}
	}
}
