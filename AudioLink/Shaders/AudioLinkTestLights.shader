Shader "AudioLink/AudioLinkTestLights"
{
    Properties
    {
        _AudioLinkTexture ("Texture", 2D) = "white" {}
        _AutocorrIntensitiy ("Autocorr Intensity", Float) = 0.1
        [ToggleUI] _AutocorrNormalize("Normalize Waveform", Float) = 0
        [ToggleUI] _AutocorrRound("Arroundate", Float) = 0
        [ToggleUI] _ColorChord("ColorChord", Float) = 0
        
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
            float _AutocorrNormalize;
            float _AutocorrRound;
            float _ColorChord;
            
            float _BubbleSize;
            float _BubbleOffset;
            float _YOffset;
            float _BubbleRotationSpeed;
            float _BubbleRotationMultiply;
            float _BubbleRotationOffset;
            float _Brightness;
            
            #ifndef glsl_mod
            #define glsl_mod(x,y) (((x)-(y)*floor((x)/(y)))) 
            #endif

            #define PASS_NINE_OFFSET    int2(0,25)

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

				int lampno = floor(i.uv.x*16) + floor(i.uv.y*8)*16;
				return GetAudioPixelData( int2( PASS_NINE_OFFSET + int2( lampno, 0 ) ) );
            }
            ENDCG
        }
    }
}
