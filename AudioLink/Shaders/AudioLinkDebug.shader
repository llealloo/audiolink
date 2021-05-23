Shader "AudioLink/AudioLinkDebug"
{
    Properties
    {
        _AudioLinkTexture ("Texture", 2D) = "white" {}
        _SpectrumGain ("Spectrum Gain", Float) = 1.
        _SampleGain ("Sample Gain", Float) = 1.
        _SeparatorColor ("Seperator Color", Color) = (.5,.5,0.,1.)

        _SpectrumColorMix ("Spectrum Color Mix", Range(0, 1)) = 0

		

        _SampleColor ("Sample Color", Color) = (.9, .9, .9,1.)
        _SpectrumFixedColor ("Spectrum Fixed color", Color) = (.9, .9, .9,1.)
        _SpectrumFixedColorForSlow ("Spectrum Fixed color for slow", Color) = (.9, .9, .9,1.)
        _BaseColor ("Base Color", Color) = (0, 0, 0, 0)
        _UnderSpectrumColor ("Under-Spectrum Color", Color) = (1, 1, 1, .1)

        _SampleVertOffset( "Sample Vertical OFfset", Float ) = 0.0
        _SpectrumVertOffset( "Spectrum Vertical OFfset", Float ) = 0.0
        _SampleThickness ("Sample Thickness", Float) = .02
        _SpectrumThickness ("Spectrum Thickness", Float) = .01
        
        _WaveformZoom ("Waveform Zoom", Float) = 2.0
        
        _VUOpacity( "VU Opacity", Float) = 0.5
        
        [ToggleUI] _ShowVUInMain("Show VU In Main", Float) = 0
        [ToggleUI] _EnableColorChord("Show ColorChord", Float) = 0
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
			#include "AudioLink.cginc"

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

            float4 _AudioLinkTexture_ST;
            
            float _SpectrumGain;
            float _SampleGain;
            float _SpectrumColorMix;
            float4 _SeparatorColor;
            float _SampleThickness;
            float _SpectrumThickness;
        
            float _SampleVertOffset;
            float4 _SampleColor;
            float4 _SpectrumFixedColor;
            float4 _SpectrumFixedColorForSlow;
            float4 _BaseColor;
            float4 _UnderSpectrumColor;
            
            float _SpectrumVertOffset;
            
            float _VUOpacity;
            float _ShowVUInMain;
            float _WaveformZoom;
			
			float _EnableColorChord;
            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv * _AudioLinkTexture_ST;
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                float2 iuv = i.uv;

                float4 spectrum_value = 0;

                uint noteno = iuv.x * EXPBINS * EXPOCT;
                float notenof = iuv.x * EXPBINS * EXPOCT;
                uint readno = noteno % EXPBINS;
                float readnof = fmod( notenof, EXPBINS );
                int reado = (noteno/EXPBINS);
                float readof = notenof/EXPBINS;

                spectrum_value = AudioLinkLerpMultiline( ALPASS_DFT + float2( notenof, 0 ) ) * _SpectrumGain;

                spectrum_value.x *= 1.; // Quick, unfiltered spectrum.
                spectrum_value.y *= 1.; // Slower, filtered spectrum
            
                float4 coloro = _BaseColor;


                //Output any debug notes
				if( _EnableColorChord > 0.5 )
                {
                    #define MAXNOTES 10
                    #define PASS_SIX_OFFSET    int2(12,22) //Pass 6: ColorChord Notes Note: This is reserved to 32,16.

                    int selnote = (int)(iuv.x * 10);
                    float4 NoteSummary = AudioLinkData( ALPASS_CCINTERNAL );
                    float4 Note = AudioLinkData( ALPASS_CCINTERNAL + uint2(selnote+1,0) );   

                    float intensity = clamp( Note.z * .01, 0, 1 );
                    if( abs( iuv.y - intensity ) < 0.05 && intensity > 0 )
                    {
                        return float4(CCtoRGB( Note.x, 1.0, _RootNote ), 1.);
                    }

					if( iuv.y > 1 )
					{
						#define PASS_EIGHT_OFFSET    int2(0,24)
						//Output Linear
						return AudioLinkData( PASS_EIGHT_OFFSET + uint2( iuv.x * 128, 0 ) );
					}
				}

                if( iuv.x < 1. )
                {
                    //The first-note-segmenters
                    float3 vertical_bars = max(0.,1.3-length(readnof-1.3) );
                    coloro += float4( vertical_bars * _SeparatorColor, 1. );
                    
                    //Waveform
                    // Get whole waveform would be / 1.
                    float sinpull = (EXPBINS*EXPOCT - 1 - notenof )/ _WaveformZoom; //2. zooms into the first half.
                    float sinewaveval = AudioLinkLerpMultiline( ALPASS_WAVEFORM + float2( sinpull, 0 ) ) * _SampleGain;

                    //If line has more significant slope, roll it extra wide.
                    float ddd = 1.+length(float2(ddx( sinewaveval ),ddy(sinewaveval)))*20;
                    coloro += _SampleColor * max( 100.*((_SampleThickness*ddd)-abs( sinewaveval - iuv.y*2.+1. + _SampleVertOffset )), 0. );
                    
                    //Under-spectrum first
                    float rval = clamp( _SpectrumThickness - iuv.y + spectrum_value.z + _SpectrumVertOffset, 0., 1. );
                    rval = min( 1., 1000*rval );
                    coloro = lerp( coloro, _UnderSpectrumColor, rval * _UnderSpectrumColor.a );
                    
                    //Spectrum-Line second
                    rval = max( _SpectrumThickness - abs( spectrum_value.z - iuv.y + _SpectrumVertOffset), 0. );
                    rval = min( 1., 1000*rval );
                    coloro = lerp( coloro, fixed4( lerp( CCtoRGB(noteno, 1.0, _RootNote ), _SpectrumFixedColor, _SpectrumColorMix ), 1.0 ), rval );

                    //Other Spectrum-Line second
                    rval = max( _SpectrumThickness - abs( spectrum_value.x - iuv.y + _SpectrumVertOffset), 0. );
                    rval = min( 1., 1000*rval );
                    coloro = lerp( coloro, fixed4( lerp( CCtoRGB(noteno, 1.0, _RootNote ), _SpectrumFixedColorForSlow, _SpectrumColorMix ), 1.0 ), rval );
                }
                
                //Potentially draw 
                if( _ShowVUInMain > 0.5 && iuv.x > 1-1/8. && iuv.x < 1. && iuv.y > 0.5 )
                {
                    iuv.x = (((iuv.x * 8.)-7) + 1.);
                    iuv.y = (iuv.y*2.) -1.;
                }

                if( iuv.x >= 1 && iuv.x < 2. )
                {
                    float UVy = iuv.y;
                    float UVx = iuv.x-1.;
                    
                    
                    float Marker = 0.;
                    float Value = 0.;
                    float4 Marker4 = AudioLinkData( ALPASS_GENERALVU + int2( 9, 0 ) );
                    float4 Value4 = AudioLinkData( ALPASS_GENERALVU + int2( 8, 0 ) );
                    if( UVx < 0.125 )
                    {
                        //P-P
                        Marker = Marker4.x;
                        Value = Value4.x;
                    }
                    else
                    {
                        //RMS
                        Marker = Marker4.y;
                        Value = Value4.y;
                    }

                    Marker = log( Marker ) * 10.;
                    Value  = log( Value  ) * 10.;
                    
                    float4 VUColor = 0.;
                    
                    int c = floor( UVy * 20 );
                    float cp = glsl_mod( UVy * 20, 1. );

                    float guard_separator = 0.02;
                    float gsx = guard_separator * (.8-100.*length( float2( ddx(UVx), ddy(UVx))) )*1.;
                    float gsy = guard_separator * (.8-100.*length( float2( ddx(UVy), ddy(UVy))) )*1.;

                    if( UVx > 0.50 + gsx )
                    {
                        if( c > 18 )
                            VUColor = float4( 1., 0., 0., 1. );
                        else if( c > 15 )
                            VUColor = float4( 0.8, 0.8, 0., 1. );
                        else
                            VUColor = float4( 0., 1., 0., 1. );
                    }
                    else if( UVx <= 0.50 - gsx )
                    {
                        if( c > 15 )
                            VUColor = float4( 1., 0., 0., 1. );
                        else if( c > 12 )
                            VUColor = float4( 0.8, 0.8, 0., 1. );
                        else
                            VUColor = float4( 0., 1., 0., 1. );
                    }
                    
                    float thisdb = (-1+UVy) * 30;
                    
                    float VUColorspectrum_valuesity = 0.;
                    
                    //Historical Peak
                    if( abs( thisdb - Marker ) < 0.2 ) 
                    {
                        VUColorspectrum_valuesity = 1.;
                    }
                    else
                    {
                        if( cp > gsy*20. )
                        {
                            if( thisdb < Value )
                            {
                                VUColorspectrum_valuesity = 0.4;
                            }
                        }
                        else
                        {
                                VUColorspectrum_valuesity = 0.02;
                        }
                    }
                    VUColor *= VUColorspectrum_valuesity;

                    coloro = lerp( VUColor, coloro, _VUOpacity );
                }

                
                return coloro;

                //Graph-based spectrogram.
            }
            ENDCG
        }
    }
}
