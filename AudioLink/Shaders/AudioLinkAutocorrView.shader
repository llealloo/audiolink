Shader "AudioLink/AudioLinkAutocorrView"
{
    Properties
    {
        _AudioLinkTexture ("Texture", 2D) = "white" {}
        _AutocorrIntensitiy ("Autocorr Intensity", Float) = 0.1
        _AutocorrNormalization("Normalization Amount", Float) = 1
        _AutocorrRound("Arroundate", Range(0,1)) = 1
        _ColorChord("ColorChord", Range(-1,1)) = 1
		_Fadeyness("Fadeyness",Range(-2,2))=1
		_ColorForeground("Color Foreground", Color) = (1, 1, 1, 1)
		_ColorBackground("Color Background", Color) = (0, 0, 0, 1)
        
        _BubbleSize ("Bubble Size", Float) = 2.
        _BubbleOffset ("Bubble Offset", Float) = .4
        _YOffset ("Y Offset", Float) = .1
        _BubbleRotationSpeed ("Bubble Rotation Speed", Float ) = 0
        _BubbleRotationMultiply ("Bubble Rotation Multiply", Float ) = 1
        _BubbleRotationOffset ("Bubble Rotation Offset",Float ) = -1
        _Brightness ("Colorcoded Brightness", Float )= 2.
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

            sampler2D _AudioLinkTexture;
            float4 _AudioLinkTexture_TexelSize;
            float4 _AudioLinkTexture_ST;
            float _AutocorrIntensitiy;
            float _AutocorrNormalization;
            float _AutocorrRound;
            float _ColorChord;
            
            float _BubbleSize;
            float _BubbleOffset;
            float _YOffset;
            float _BubbleRotationSpeed;
            float _BubbleRotationMultiply;
            float _BubbleRotationOffset;
            float _Brightness;
            float _Fadeyness;
			
			float4 _ColorForeground;
			float4 _ColorBackground;
			
            #ifndef glsl_mod
            #define glsl_mod(x,y) (((x)-(y)*floor((x)/(y)))) 
            #endif

            #define PASS_EIGHT_OFFSET    int2(0,23)


            float4 GetAudioPixelData( int2 pixelcoord )
            {
                return tex2D( _AudioLinkTexture, float2( pixelcoord*_AudioLinkTexture_TexelSize.xy) );
            }

            float4 forcefilt( sampler2D sample, float4 texelsize, float2 uv )
            {
                float4 A = tex2D( sample, uv );
                float4 B = tex2D( sample, uv + float2(texelsize.x, 0 ) );
                float4 C = tex2D( sample, uv + float2(0, texelsize.y ) );
                float4 D = tex2D( sample, uv + float2(texelsize.x, texelsize.y ) );
                float2 conv = frac(uv*texelsize.zw);
                //return float4(uv, 0., 1.);
                return lerp(
                    lerp( A, B, conv.x ),
                    lerp( C, D, conv.x ),
                    conv.y );
            }


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _AudioLinkTexture);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {

                // Get whole waveform would be / 1.
                float sinpull;
                

                float2 uvcenter = float2( i.uv.x, i.uv.y + _YOffset ) * 2 - 1;
                
                // Dear anyone who tries to understand the following line of code.
                //   I'm sorry.
                //     - Charles
                
                if( _AutocorrRound )
                    sinpull = glsl_mod( abs( glsl_mod( _BubbleRotationMultiply * atan2( uvcenter.x, uvcenter.y ) / 3.14159 + _BubbleRotationSpeed * _Time.y + _BubbleRotationOffset, 2.0 ) - 1.0 ) *127.5, 128 );
                else
                    sinpull = abs(i.uv.x*256-128);
                
				sinpull = lerp(
					abs(i.uv.x*256-128),
					glsl_mod( abs( glsl_mod( _BubbleRotationMultiply * atan2( uvcenter.x, uvcenter.y ) / 3.14159 + _BubbleRotationSpeed * _Time.y + _BubbleRotationOffset, 2.0 ) - 1.0 ) *127.5, 128 ),
					_AutocorrRound );
                
                float sinewaveval = forcefilt( _AudioLinkTexture, _AudioLinkTexture_TexelSize, 
                     float2((fmod(sinpull,128))/128.,((floor(sinpull/128.))/64.+24./64.)) );

				sinewaveval *= lerp( 1.0, rsqrt( GetAudioPixelData( int2( 0, 24 ) ) ), _AutocorrNormalization );

                sinewaveval *= _AutocorrIntensitiy;

                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                
				float reoff = lerp( _BubbleOffset, -_BubbleOffset,_AutocorrRound)*_ColorChord;
				float pullStrength = lerp( uvcenter.y, length(uvcenter),  _AutocorrRound );

				pullStrength  = lerp( pullStrength, abs(pullStrength )-reoff,_ColorChord );
				
				float rlen = sinewaveval * _BubbleSize - (pullStrength-(_AutocorrRound));
                
				float4 cccolor = GetAudioPixelData( 
						int2( PASS_EIGHT_OFFSET + int2( clamp( abs(rlen * 250), 0, 127) , 0 ) ) );
				float4 color = lerp( (rlen > 0)?_ColorForeground:_ColorBackground,  cccolor
					, _ColorChord );
					
				color = lerp( (_Fadeyness<0)?1:((rlen<0)?0:1), rlen, _Fadeyness ) *color;
				return _Brightness * color;
            }
            ENDCG
        }
    }
}
