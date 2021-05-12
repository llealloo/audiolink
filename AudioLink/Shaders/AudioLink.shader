Shader "AudioLink/AudioLink"
{
    //Example CRT with multiple passed, used to read its own texture and write into another place.
    //Example of usage is in colorchord scene.
    //This shows how to read from other coordiantes within the CRT texture when using multiple passes.

    Properties
    {
        // Phase 1 (Audio DFT)
        _BottomFrequency("BottomFrequency", float ) = 13.75
        _IIRCoefficient("IIR Coefficient", float) = 0.85
        _BaseAmplitude("Base Amplitude Multiplier", float) = 2.0
        _DecayCoefficient("Decay Coefficient", float) = 0.01
        _PhiDeltaCorrection("Phi Delta Correction", float) = 4
        _DFTMode( "DFT mode", float) = 0.0
        _DFTQ( "Q Value", float ) = 4.0

        // Phase 2 (Waveform Data)
        // This has no parameters.

        // Phase 3 (AudioLink 4 Band)
        _Bands("Bands (Rows)", Float) = 4
        _Gain("Gain", Range(0 , 10)) = 0.2724236
        _TrebleCorrection("Treble Correction", Float) = 10
        _LogAttenuation("Log Attenuation", Range(0 , 1)) = 0
        _ContrastSlope("Contrast Slope", Range(0 , 1)) = 0
        _ContrastOffset("Contrast Offset", Range(0 , 1)) = 0
        _FadeLength("Fade Length", Range(0 , 1)) = 0
        _FadeExpFalloff("Fade Exp Falloff", Range(0 , 1)) = 0.3144608
        _Bass("Bass", Range(0 , 4)) = 1
        _Treble("Treble", Range(0 , 4)) = 1
        
        // ColorChord Notes (Pass 6)
        _PeakDecay ("Peak Decay", float) = 0.7
        _PeakCloseEnough ("Close Enough" , float) = 2.0
        _PeakMinium ("Peak Minimum", float) = 0.005
        _SortNotes ("Sort Notes", int) = 0
        _OctaveMerge ("Octave Merge", int) = 1
        
        _Uniformity( "Uniformitvity", float ) = 1.5
        _UniCutoff( "Uniformitvity Cutoff", float) = 0.0
        _UniAmp( "Uniformitvity Amplitude", float ) = 12.0
        _UniMaxPeak( "Uniformitvity Peak Reduction", float ) = 0.0
        _UniSumPeak( "Uniformitvity Sum Reduction", float ) = 0.1
        _UniNerfFromQ ("Uniformitvity Nerf from Bad Q", float ) = 0.05

    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        
        Cull Off
        Lighting Off        
        ZWrite Off
        ZTest Always

        Pass
        {
            CGINCLUDE

            // This determines the bottom-left corner of the various passes.
            #define PASS_ONE_OFFSET    int2(0,4)   //Pass 1: DFT: 4,5 10.66 octaves, with 24 bins per octave.
            //Row 9: Reserved.
            #define PASS_TWO_OFFSET    int2(0,10)  //Pass 2: Sample Data 10->19 10x128 samples = 1280 samples total.

            #define PASS_THREE_OFFSET  int2(0,0)  //Pass 3: Traditional 4 bands of AudioLink
            #define PASS_FOUR_OFFSET   int2(1,0)  //Pass 4: History from 4 bands of AudioLink

            #define PASS_FIVE_OFFSET   int2(0,20) //Pass 5: VU Meter
            #define PASS_SIX_OFFSET    int2(4,20) //Pass 6: ColorChord Notes Note: This is reserved to 32,16.

            #define SAMPHIST 2046
            #define EXPBINS 24
            #define EXPOCT 10
            #define ETOTALBINS ((EXPBINS)*(EXPOCT))
            #define _SamplesPerSecond 48000

            // AUDIO_LINK_ALPHA_START is a shortcut macro you can use at the top of your
            // fragment shader to quickly get coordinateLocal and coordinateGlobal.

            #if UNITY_UV_STARTS_AT_TOP
            #define AUDIO_LINK_ALPHA_START( BASECOORDY ) \
                float2 guv = IN.globalTexcoord.xy; \
                uint2 coordinateGlobal = round( guv/_SelfTexture2D_TexelSize.xy - 0.5 ); \
                uint2 coordinateLocal = uint2( coordinateGlobal.x - BASECOORDY.x, coordinateGlobal.y - BASECOORDY.y );
            #else
            #define AUDIO_LINK_ALPHA_START( BASECOORDY ) \
                float2 guv = IN.globalTexcoord.xy; \
                guv.y = 1.-guv.y; \
                uint2 coordinateGlobal = round( guv/_SelfTexture2D_TexelSize.xy - 0.5 ); \
                uint2 coordinateLocal = uint2( coordinateGlobal.x - BASECOORDY.x, coordinateGlobal.y - BASECOORDY.y );
            #endif

            #pragma target 4.0
            #pragma vertex CustomRenderTextureVertexShader
            #pragma fragment frag
            #include "AudioLinkCRT.cginc"
            #include "UnityCG.cginc"
            uniform half4 _SelfTexture2D_TexelSize; 

            cbuffer SampleBuffer {
                float _AudioFrames[1023*4] : packoffset(c0);  
                float _Samples0[1023] : packoffset(c0);
                float _Samples1[1023] : packoffset(c1023);
                float _Samples2[1023] : packoffset(c2046);
                float _Samples3[1023] : packoffset(c3069);
            };
            
            // This pulls data from this texture.
            float4 GetSelfPixelData( int2 pixelcoord )
            {
                //return tex2D( _SelfTexture2D, float2( pixelcoord*_SelfTexture2D_TexelSize.xy) );
                return _SelfTexture2D[pixelcoord];
            }

            // AudioLink
            uniform float _FadeLength;
            uniform float _FadeExpFalloff;
            uniform float _Gain;
            uniform float _Bass;
            uniform float _Treble;
            uniform float _Bands;
            uniform float _LogAttenuation;
            uniform float _ContrastSlope;
            uniform float _ContrastOffset;
            uniform float _TrebleCorrection;
            ENDCG

            Name "Pass1AudioDFT"
            
            CGPROGRAM

            uniform float _BottomFrequency;
            uniform float _IIRCoefficient;
            uniform float _BaseAmplitude;
            uniform float _DecayCoefficient;
            uniform float _PhiDeltaCorrection;

            uniform float _DFTMode;
            uniform float _DFTQ;


            fixed4 frag (v2f_customrendertexture IN) : SV_Target
            {
                AUDIO_LINK_ALPHA_START( PASS_ONE_OFFSET )

                //XXX Hack: Force the compiler to keep Samples0 and Samples1.
                if(guv.x < 0)
                    return _Samples0[0] + _Samples1[0] + _Samples2[0] + _Samples3[0] + _AudioFrames[0]; // slick, thanks @lox9973

                //Uncomment to enable debugging of where on the CRT this pass is.
                //return float4( coordinateLocal, 0., 1. );

                if(guv.x < 0)
                    return _Samples0[0] + _Samples1[0]; // slick, thanks @lox9973
        
                float4 last = GetSelfPixelData( coordinateGlobal );

                int note = coordinateLocal.y* 128 + coordinateLocal.x;

                float2 ampl = 0.;
                float pha = 0;
                float phadelta = pow( 2, (note)/((float)EXPBINS) );
                phadelta *= _BottomFrequency;
                phadelta /= _SamplesPerSecond;
                phadelta *= 3.1415926 * 2.0;
                float integraldec = 0.;
                float totalwindow = 0;

                // Align phase so 0 phaseis center of window.
                pha = -phadelta * SAMPHIST/2;

                // This determines the narrowness of our peaks.
                float Q = _DFTQ;

                if( _DFTMode < 1.0 )
                {
                    //Method 1: Convolve entire incoming waveform.
                    
                    float HalfWindowSize;
                    HalfWindowSize = (Q)/(phadelta/(3.1415926*2.0));

                    int windowrange = floor(HalfWindowSize)+1;
                    int idx;

                    // For ??? reason, this is faster than doing a clever
                    // indexing which only searches the space that will be used.

                    for( idx = 0; idx < SAMPHIST; idx++ )
                    {
                        float window = max( 0, HalfWindowSize - abs(idx - (SAMPHIST-HalfWindowSize) ) );

                        float af = _AudioFrames[idx];

                        //Sin and cosine components to convolve.
                        float2 sc; sincos( pha, sc.x, sc.y );

                        // Step through, one sample at a time, multiplying the sin
                        // and cos values by the incoming signal.
                        ampl += sc * af * window;

                        totalwindow += window;

                        pha += phadelta;
                    }
                }
                else
                {
                    //Method 2: Convolve only a set number of sampler per bin.
                    float fvpha;
                    int place;
                    
                    #define WINDOWSIZE (6.28*_DFTQ)
                    #define STEP 0.06
                    #define EXTENT ((int)(WINDOWSIZE/STEP))
                    float invphaadv = STEP / phadelta;
                    
                    float fra = SAMPHIST/2 - (invphaadv*EXTENT); //We want the center to line up.
                    
                    for( place = -EXTENT; place <= EXTENT; place++ )
                    {
                        float fvpha = place * STEP;
                        //Sin and cosine components to convolve.
                        float2 sc; sincos( fvpha, sc.x, sc.y );
                        float window = WINDOWSIZE - abs(fvpha);
                        
                        float af = _AudioFrames[round( fra )];
                        
                        // Step through, one sample at a time, multiplying the sin
                        // and cos values by the incoming signal.
                        ampl += sc * af * window;
                        
                        fra += invphaadv;

                        totalwindow += window;
                    }
                }

                float mag = length( ampl );
                mag /= totalwindow;
                mag *= _BaseAmplitude;

                float mag2 = mag;


                // Treble compensation
                mag *= ((note / float(EXPOCT*EXPBINS) )*_TrebleCorrection + 1.0);

                //Z component contains filtered output.
                float magfilt = (lerp(mag, last.z, _IIRCoefficient ));

                // Treble compensation
                float lastMagnitude = last.g;

                // Fade
                lastMagnitude -= -1.0 * pow(_FadeLength-1.0, 3);
                // FadeExpFalloff
                lastMagnitude = lastMagnitude * (1.0 + ( pow(lastMagnitude-1.0, 4.0) * _FadeExpFalloff ) - _FadeExpFalloff);
                // Do the fade
                mag2 = (max(lastMagnitude, mag2));

                return float4( 
                    mag,    //Red:   Spectrum power
                    mag2,   //Green: Filtered power
                    magfilt,  //Blue:  Filtered spectrum (For CC)
                    1 );
            }
            ENDCG
        }

        Pass
        {
            Name "Pass2WaveformData"
            CGPROGRAM
            // The structure of the output is:
            // RED CHANNEL: Mono Audio
            // GREEN/BLUE: Reserved (may be left/right)
            //   8 Rows, each row contains 128 samples. Note: The last sample may be repeated.

            float _BaseAmplitude;

            fixed4 frag (v2f_customrendertexture IN) : SV_Target
            {
                AUDIO_LINK_ALPHA_START( PASS_TWO_OFFSET )

                //XXX Hack: Force the compiler to keep Samples0 and Samples1.
                if(guv.x < 0)
                    return _Samples0[0] + _Samples1[0] + _Samples2[0] + _Samples3[0]; // slick, thanks @lox9973

                uint frame = coordinateLocal.x + coordinateLocal.y * 128;
                if( frame >= SAMPHIST ) frame = SAMPHIST-1; //Prevent overflow.

                //Uncomment to enable debugging of where on the CRT this pass is.
                //return float4( frame/1000., coordinateLocal/10., 1. );

                return float4( 
                    _AudioFrames[frame],    //Red:   Spectrum power
                    0,      //Green: Reserved
                    0,      //Blue:  Reserved
                    1 );
            }
            ENDCG
        }

        Pass
        {
            Name "Pass3AudioLink4Band"
            CGPROGRAM

            
            
            //uniform float _Lut[4];
            //uniform float _Chunks[4];
            uniform float _AudioBands[4];
            uniform float _AudioThresholds[4];

            float LinearEQ( float gain, float bassLevel, float trebleLevel, float freq )
            {
                return gain*(((1.0-freq)*bassLevel)+(freq*trebleLevel));
            }
            float LogAttenuation( float input, float attenuation )
            {
                return saturate(input * (log(1.1)/(log(1.1+pow(attenuation, 4)*(1.0-input)))));
            }
            float InvCubeRemap( float input )
            {
                return -1.0 * pow(input-1.0, 3);
            }
            float CubicAttenuation( float input, float attenuation )
            {
                return saturate(input * (1.0 + ( pow(input-1.0, 4.0) * attenuation ) - attenuation));
            }
            float Contrast( float input, float slope, float offset )
            {
                return saturate(input*tan(1.57*slope) + input + offset*tan(1.57*slope) - tan(1.57*slope));
            }

            fixed4 frag (v2f_customrendertexture IN) : SV_Target
            {
                AUDIO_LINK_ALPHA_START( PASS_THREE_OFFSET )

                int band = coordinateLocal.y;
                int delay = coordinateLocal.x;
                //int pointer = (int)_Lut[band];
                //int size = (int)_Chunks[band];
                // If leftmost pixel (where band averaging occurs)
                if (delay == 0) 
                {
                    float total = 0.;
                    uint binStart = _AudioBands[band];
                    uint binEnd = (band < 3) ? _AudioBands[band + 1] : 1023;
                    float threshold = _AudioThresholds[band];

                    for (uint i=binStart; i<binEnd; i++)
                    {
                        int2 spectrumCoord = int2(i % 128, i / 128);
                        float rawMagnitude = _SelfTexture2D[PASS_ONE_OFFSET + spectrumCoord].r;
                        //rawMagnitude *= ((float)i / 1023.) * pow(_TrebleCorrection, 2);
                        rawMagnitude *= LinearEQ(_Gain, _Bass, _Treble, (float)i / 1023.);
                        total += rawMagnitude;
                    }
                    //total /= size;

                    float magnitude = total / (binEnd - binStart);
                    magnitude = LogAttenuation(magnitude, _LogAttenuation) / pow(threshold, 2);
                    magnitude = Contrast(magnitude, _ContrastSlope, _ContrastOffset);

                    float lastMagnitude = _SelfTexture2D[PASS_THREE_OFFSET + int2(0, band)].r;
                    lastMagnitude -= InvCubeRemap(_FadeLength);
                    lastMagnitude = CubicAttenuation(lastMagnitude, _FadeExpFalloff);

                    magnitude = max(lastMagnitude, magnitude);

                    return float4(magnitude, magnitude, magnitude, 1.);

                // If part of the delay
                } else {
                    // Return pixel to the left
                    return _SelfTexture2D[PASS_THREE_OFFSET + int2(coordinateLocal.x - 1, coordinateLocal.y)];
                }
            }


            ENDCG
        }

        Pass 
        {
            Name "TestPass"
            CGPROGRAM



            fixed4 frag (v2f_customrendertexture IN) : SV_Target
            {

                AUDIO_LINK_ALPHA_START( int2(0, 0) )

                if (coordinateLocal.x > 64) 
                {
                    return float4(1., 1., 1., 1.);
                } else {
                    return float4(0., 0., 0., 1.);
                }
                
            }
            ENDCG 
        }
        
        Pass
        {
            Name "Pass5-VU-Meter"
            CGPROGRAM
            // The structure of the output is:
            // RED CHANNEL: Peak Amplitude
            // GREEN CHANNEL: RMS Amplitude.
            // BLUE CHANNEL: RESERVED.

            float _BaseAmplitude;

            fixed4 frag (v2f_customrendertexture IN) : SV_Target
            {
                AUDIO_LINK_ALPHA_START( PASS_FIVE_OFFSET )
                int i;
                
                float total = 0;
                float Peak = 0;
                for( i = 0; i < 1023; i++ )
                {
                    float af = _AudioFrames[i];
                    total += af*af;
                    Peak = max( Peak, af );
                    Peak = max( Peak, -af );
                }

                float PeakRMS = sqrt( total / 1023. );
                float4 MarkerValue = GetSelfPixelData( PASS_FIVE_OFFSET + int2( 1, 0 ) );
                float4 MarkerTimes = GetSelfPixelData( PASS_FIVE_OFFSET + int2( 2, 0 ) );
                float Time = _Time.y;
                
                if( Time - MarkerTimes.x > 1.0 ) MarkerValue.x = -1;
                if( Time - MarkerTimes.y > 1.0 ) MarkerValue.y = -1;
                
                if( MarkerValue.x < PeakRMS )
                {
                    MarkerValue.x = PeakRMS;
                    MarkerTimes.x = Time;
                }

                if( MarkerValue.y < Peak )
                {
                    MarkerValue.y = Peak;
                    MarkerTimes.y = Time;
                }


                if( coordinateLocal.x == 0 )
                {
                    //First pixel: Current value.
                    return float4( PeakRMS, Peak, 0., 1. );
                }
                else if( coordinateLocal.x == 1 )
                {
                    //Second pixel: Limit Output
                    return MarkerValue;
                }
                else if( coordinateLocal.x == 2 )
                {
                    //Second pixel: Limit Time
                    return MarkerTimes;
                }
                else
                {
                    //Reserved
                    return 0;
                }
            }
            ENDCG
        }

        /*Pass
        {
            Name "Pass6ColorChord-Notes"
            CGPROGRAM
            float _PeakDecay;
            float _PeakCloseEnough;
            float _PeakMinium;
            int _SortNotes;
            int _OctaveMerge;
            
            float _Uniformity;
            float _UniCutoff;
            float _UniAmp;
            float _UniMaxPeak;
            float _UniSumPeak;
            float _UniNerfFromQ;
            
            fixed4 frag (v2f_customrendertexture IN) : SV_Target
            {
                AUDIO_LINK_ALPHA_START( PASS_SIX_OFFSET )

                #define MAXPEAKS 16
                float3 Peaks[MAXPEAKS];
                int NumPeaks = 0;

                int notes = MAXPEAKS;
                int noteno = coordinateLocal.x-1;
                float4 LastPeaksSummary = GetSelfPixelData( PASS_SIX_OFFSET );
                
                // This finds the peaks and assigns them to notes.
                
                {
                    float bindata[ETOTALBINS];
                    int bins = EXPBINS;//round( 1./_DFTData_TexelSize.x );
                    int octs = EXPOCT;//round( 1./_DFTData_TexelSize.y );

                    uint o;
                    uint i;
                    for( o = 0; o < EXPOCT; o++ )
                    {
                        uint b;
                        for( b = 0; b < EXPBINS; b++ )
                        {
                            bindata[o*EXPBINS+b] = GetSelfPixelData( PASS_ONE_OFFSET + int2( (o%2)*64 + b, o/2 ) ).r;
                        }
                    }
                
#if 0
                    if( noteno == 0 )
                    {
                        int besti = -1;
                        float bb = 0;
                        for( i = 0; i < 64*8; i++ )
                            if(  bindata[i] > bb ) { bb = bindata[i]; besti = i; }
                        return float4( besti, 10, 0, 1 );
                    }
#endif
                    int check[ETOTALBINS];
                    for( i = 0; i < ETOTALBINS; i++ )
                    {
                        check[i] = 0;
                    }
                    int bestbin;
                    float bestbval;
                    //Fill out the Peaks structure.
                    [loop]
                    for( i = 0; i < MAXPEAKS; i++ )
                    {
                        float prev = bindata[0];
                        float this = bindata[1];
                        bestbin = ETOTALBINS;
                        bestbval = 0.;
                        int b;
                        [loop]
                        for( b = 1; b < ETOTALBINS-1; b++ )
                        {
                            float next = bindata[b+1];
                            
                            if( this > bestbval && this > prev && this > next && check[b] == 0 )
                            {
                                bestbin = b;
                                bestbval = this;
                            }
                            
                            prev = this;
                            this = next;
                        }

                        if( bestbin < ETOTALBINS )
                        {
                            check[bestbin] = 1;
                            
                            float analogbin = bestbin;
                            float bd = bindata[b];
                            float tweakbinDown = bd - bindata[b-1];
                            float tweakbinUp = bd - bindata[b+1];
                            if( tweakbinDown < tweakbinUp )
                            {
                                //closer to bottom bin
                                float diff = tweakbinDown / tweakbinUp;
                                //The closer to 1, the closer to center.
                                //The closer to 0, the further toward the lower bin.
                                //Mathematically, this should be limited from 0 to 1.
                                analogbin -= 0.5*(1.-diff);
                            }
                            else
                            {
                                //Closer to top bin.
                                float diff = tweakbinUp / tweakbinDown;
                                //The closer to 1, the closer to center.
                                //The closer to 0, the further toward the upper bin.
                                //Mathematically, this should be limited from 0 to 1.
                                analogbin += 0.5*(1.-diff);
                            }
                            
                            #define glsl_mod(x,y) (((x)-(y)*floor((x)/(y)))) 
                            
                            float q = (tweakbinDown + tweakbinUp) / (bd*2);

                            if( !!_OctaveMerge ) analogbin = glsl_mod( analogbin, EXPBINS );

                            Peaks[i] = float3( analogbin, bestbval, q );
                            NumPeaks++;
                        }
                        else
                        {
                            break;
                        }
                    }
                }


                {
                    //OK! Now, we have NumPeaks in Peaks array.
                    //Next, we scour through last frame's array.
                    //In order to merge in the peaks.
                    float3 NewPeaks[MAXPEAKS];
                    int NumNewPeaks;
                    int p, np;
                    [loop]
                    for( p = 0; p < MAXPEAKS; p++ )
                    {
                        float3 Peak = GetSelfPixelData( PASS_SIX_OFFSET + int2( p+1, 0 ) );
                        if( Peak.x >= 0 )
                        {
                            Peak.y *= _PeakDecay;
                            [loop]
                            for( np = 0; np < MAXPEAKS; np++ )
                            {
                                float3 ThisPeak = Peaks[np];
                                float diff = abs( ThisPeak.x - Peak.x );

                                if( diff < _PeakCloseEnough )
                                {
                                    //Roll Peak[np] into last peak.
                                    float percentage = ThisPeak.y / (ThisPeak.y + Peak.y);
                                    Peak.y += ThisPeak.y;
                                    Peak.x = lerp( Peak.x, ThisPeak.x, percentage );
                                    Peak.z = lerp( Peak.z, ThisPeak.z, percentage );
                                    Peaks[np] = -1;
                                }
                            }
                            if( Peak.y < _PeakMinium )
                            {
                                //Nix this peak.
                                Peak = -1;
                            }
                            NewPeaks[p] = Peak;
                        }
                        else
                        {
                            NewPeaks[p] = -1;
                        }
                    }
                    
                    //Next, load in any remaining unassigned peaks.
                    for( np = 0; np < NumPeaks; np++ )
                    {
                        float3 ThisPeak = Peaks[np];

                        if( ThisPeak.y >= _PeakMinium )
                        {
                            //Find an open slot in the peaks list and drop this in.
                            for( p = 0; p < MAXPEAKS; p++ )
                            {
                                if( NewPeaks[np].y < 0 )
                                {
                                    NewPeaks[np] = ThisPeak;
                                }
                            }
                        }
                    }

                    //We are no longer going to use "Peaks"

                    if( !!_SortNotes )
                    {
                        //Lastly, we need to sort the New Peaks.
                        //Let's use insertion sort, because we're a mostly sorted list.
                        for( np = 0; np < MAXPEAKS; np++ )
                        {
                            float3 SelectedItem = NewPeaks[np];
                            for( p = np+1; p < MAXPEAKS; p++ )
                            {
                                if( SelectedItem.y > NewPeaks[p].y )
                                {
                                    SelectedItem = NewPeaks[p];
                                }
                                else
                                {
                                    NewPeaks[p-1] = NewPeaks[p];
                                    NewPeaks[p] = SelectedItem;
                                }
                            }
                        }
                    }
                    
                    //Find the most intense peak + PEak totals.
                    float maxpeak = 0.0;
                    float peaktot = 0.0;
                    for( np = 0; np <= MAXPEAKS-1; np++ )
                    {
                        float peakamp = NewPeaks[np].y;
                        if( peakamp > maxpeak )
                            maxpeak = peakamp;
                        if( peakamp > 0.0 )
                        {
                            peaktot += peakamp;
                        }
                    }
                    float peaktotrun = lerp( LastPeaksSummary.z, peaktot, 0.9 );
                    
                    if( noteno == -1 )
                    {
                        //This is the first, special pixel that gives metadata instead.
                        
                        float unitot = 0.0;
                        for( np = 0; np < MAXPEAKS-1; np++ )
                        {
                            float peakamp = NewPeaks[np].y;
                            if( peakamp > 0.0 )
                            {

                                float pu = ( pow( peakamp, _Uniformity )) * _UniAmp  - _UniCutoff - pow( maxpeak, _Uniformity ) * _UniMaxPeak + (1. - NewPeaks[np].z*_UniNerfFromQ) -  pow( peaktotrun, _Uniformity ) * _UniSumPeak;
                                if( pu > 0. )
                                    unitot += pu;
                            }
                        }
                        
                        float avgphase1 = 0;

                        uint o, b;
                        for( o = 0; o < EXPOCT; o++ )
                        for( b = 0; b < EXPBINS; b++ )
                        {
                            avgphase1 += GetSelfPixelData( PASS_ONE_OFFSET + uint2( (o%2)*64 + b, o/2 ) ).r;
                        }
                        avgphase1 /= (EXPOCT*EXPBINS);
                        
                        return float4( peaktot, avgphase1, peaktotrun, unitot );
                    }   


                    //We've now merged any of the peaks we could.
                    //Next, forget dead peaks.
                    
                    float3 thisNote =  NewPeaks[noteno];

                    if( noteno >= NumPeaks || thisNote.y <= 0.0 )
                        return float4( -1, -1, -1, -1 );
                    else
                    {
                        float pu = ( pow( thisNote.y, _Uniformity )) * _UniAmp  - _UniCutoff - pow( maxpeak, _Uniformity ) * _UniMaxPeak  + (1. - thisNote.z*_UniNerfFromQ) - pow( peaktotrun, _Uniformity ) * _UniSumPeak;
                        return float4( thisNote, pu );
                    }
                }
            }
            ENDCG
        }*/

        Pass 
        {
            Name "No-op"
            ColorMask 0
            ZWrite Off 
            
        }
    }


}
