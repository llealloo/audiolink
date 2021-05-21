Shader "Unlit/AudioLinkTestTime"
{
    Properties
    {
        _AudioLinkTexture ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

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
            };

            float4 _AudioLinkTexture_TexelSize;
            float4 _AudioLinkTexture_ST;
			
            #ifndef glsl_mod
            #define glsl_mod(x,y) (((x)-(y)*floor((x)/(y)))) 
            #endif


            #define PASS_FIVE_OFFSET   int2(0,22)  

//            Texture2D<float4> _AudioLinkTexture;
//            #define GetAudioPixelData( pxcoord ) _AudioLinkTexture.Load( int3( pxcoord, 0 ) )

//			sampler2D_float  _AudioLinkTexture;
//            float4 GetAudioPixelData( int2 pixelcoord )
//           {
//                return tex2Dlod( _AudioLinkTexture, float4( pixelcoord*_AudioLinkTexture_TexelSize.xy, 0 ,0) );
//            }

			Texture2D_float _AudioLinkTexture;
			SamplerState sampler_AudioLinkTexture;			
			#define UNITY_SAMPLE_TEX2D_LOD_SAMPLER(tex,samplertex,coord) tex.SampleLevel(sampler##samplertex,(coord).xy,(coord).w)
            #define GetAudioPixelData( pxcoord ) UNITY_SAMPLE_TEX2D_LOD_SAMPLER( _AudioLinkTexture, _AudioLinkTexture ,  float4( pxcoord*_AudioLinkTexture_TexelSize.xy, 0 ,0) )
			

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _AudioLinkTexture);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

			float PrintNumberOnLine( float number, uint fixeddiv, uint digit, uint2 mxy )
			{
				uint selnum = 0;
				if( number < 0 && digit == 0 ) selnum = 11;
				
				number = abs( number );
				
				const static uint BitmapNumberFont[12] = {
					15379168,  // '0' 1110 / 1010 / 1010 / 1010 / 1110 / 0000
					4473920,   // '1' 0100 / 0100 / 0100 / 0100 / 0100 / 0000
					14870752,  // '2' 1110 / 0010 / 1110 / 1000 / 1110 / 0000
					14836448,  // '3' 1110 / 0010 / 0110 / 0010 / 1110 / 0000
					11199008,  // '4' 1010 / 1010 / 1110 / 0010 / 0010 / 0000
					15262432,  // '5' 1110 / 1000 / 1110 / 0010 / 1110 / 0000
					15264480,  // '6' 1110 / 1000 / 1110 / 1010 / 1110 / 0000
					14820416,  // '7' 1110 / 0010 / 0010 / 0100 / 0100 / 0000
					15395552,  // '8' 1110 / 1010 / 1110 / 1010 / 1110 / 0000
					15393344,  // '9' 1110 / 1010 / 1110 / 0010 / 0100 / 0000
					64,        // '.' 0000 / 0000 / 0000 / 0000 / 0100 / 0000
					57344,     // '-' 0000 / 0000 / 1110 / 0000 / 0000 / 0000
				};
								
				// decimal.
				if( selnum == 0 )
				{
					if( digit == fixeddiv )
					{
						selnum = 10;
					}
					else
					{
						int dmfd = (int)digit - (int)fixeddiv;
						if( dmfd > 0 )
						{
							//fractional part.
							float l10 = pow( 10., dmfd-6 );
							selnum = ((uint)( number *1000000 * l10 )) % 10;
						}
						else
						{
							float l10 = pow( 10., (float)(dmfd + 1) );
							selnum = ((uint)( number * l10 ));

							//Disable leading 0's?
							if( selnum == 0 && dmfd < 0.5 ) return 0;
							selnum %= (uint)10;
						}
					}
				}
				
				uint bitmap = BitmapNumberFont[selnum];
				return ((bitmap >> (mxy.x+mxy.y*4)) & 1)?1.0:0.0;
			}


            float4 frag (v2f i) : SV_Target
            {
				float value ;
				
				float2 iuv = i.uv;
				iuv.y = 1.-iuv.y;
				float2 pos = iuv*float2(16,10);
				uint2 dig = (uint2)(pos);
				float2 fmxy = float2( 4, 6 ) - (glsl_mod(pos,1.)*float2(4.,6.));
				uint2 mxy = (uint2)(fmxy);
				
				if( dig.y == 0 )
						value = GetAudioPixelData( int2( PASS_FIVE_OFFSET + int2( 2, 0 ) ) );
				else if( dig.y == 1 )
						value = GetAudioPixelData( int2( int2( 2, 0 ) ) );
				else
						value = 0;

				float4 col = 0.;

				{
					col = PrintNumberOnLine( value, 9, dig.x, mxy );
				}
				

				return col + clamp( 1.-abs(2.-fmxy.y*5.), 0, 1 );;
				
            }
            ENDCG
		}
    }
}
