Shader "AudioLink/AudioLink"
{
    //Example CRT with multiple passed, used to read its own texture and write into another place.
    //Example of usage is in colorchord scene.
    //This shows how to read from other coordiantes within the CRT texture when using multiple passes.

    Properties
    {
        

        // Phase 3 (AudioLink 4 Band)
        _Gain("Gain", Range(0 , 2)) = 1.0

        _FadeLength("Fade Length", Range(0 , 1)) = 0.8
        _FadeExpFalloff("Fade Exp Falloff", Range(0 , 1)) = 0.3
        _Bass("Bass", Range(0 , 4)) = 1.0
        _Treble("Treble", Range(0 , 4)) = 1.0
        
        _X1("X1", Range(0.04882813, 0.2988281)) = 0.25
        _X2("X2", Range(0.375, 0.625)) = 0.5
        _X3("X3", Range(0.7021484, 0.953125)) = 0.75

        _Threshold0("Threshold 0", Range(0.0, 1.0)) = 0.45
        _Threshold1("Threshold 1", Range(0.0, 1.0)) = 0.45
        _Threshold2("Threshold 2", Range(0.0, 1.0)) = 0.45
        _Threshold3("Threshold 3", Range(0.0, 1.0)) = 0.45
 
        _AudioSource2D("Audio Source 2D", float) = 0
        
        [ToggleUI] _EnableAutogain("Enable Autogain", float) = 1
		_AutogainDerate ("Autogain Derate", Range(.001, .5)) = 0.1
		
        [HideInInspector]_FrameTimeProp("Frame Time Internal",Vector) = (0,0,0,0)
        [HideInInspector]_DayTimeProp("Day Time Internal",Vector) = (0,0,0,0)

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
            
            //Pass 1: DFT: 4,5 10.66 octaves, with 24 bins per octave.
            
            #define PASS_ONE_OFFSET    int2(0,4)  

            //Pass 2: Raw Waveform Data
            //   Red: 24kSPS, with 2046 samples
            // Green: 48kSPS, with 2046 samples
            //  Blue: Reserved
            // Alpha: Reserved
            
            #define PASS_TWO_OFFSET    int2(0,6)

            //Pass 3: Traditional 4 bands of AudioLink
            
            #define PASS_THREE_OFFSET  int2(0,0)
            
            //Pass 4: History from 4 bands of AudioLink
            
            #define PASS_FOUR_OFFSET   int2(1,0) 

            //Pass 5: General information and VU Meter
            //  PX 0:  AudioLink Version
            //  PX 1:  AudioLink Frame #
            //  PX 2:  < Current time in ms % 2^24, # of rollovers, 0, 0 >
            //  PX 8:  Current VU Level
            //  PX 9:  Historical VU Marker Value
            //  PX 10: Historical VU Marker Times
            
            #define PASS_FIVE_OFFSET   int2(0,22)  

            // Pass 6: ColorChord Internal Note Data
            //   PX 0: ColorChord Notes Summary
            //   PX 1-11: 10 ColorChord Notes.
            
            #define PASS_SIX_OFFSET    int2(12,22)

            // Pass 7: Autocorrelator output
            //  Whole line, fake autocorrelator (maybe someday a real autocorrelator)!
            #define PASS_SEVEN_OFFSET    int2(0,24)

            // Pass 8: ColorChord Strip
            //  Whole line, able to map directly to textues.
            #define PASS_EIGHT_OFFSET    int2(0,23)

            // Pass 9: ColorChord Individual Lights
            //  Row 25: Individual Light Colors (128 qty)
            //                R/G/B Color
            //  Row 26: Internal Data for Colors
            #define PASS_NINE_OFFSET    int2(0,25)


            #define CCMAXNOTES 10
            #define SAMPHIST 3069
            #define EXPBINS 24
            #define EXPOCT 10
            #define ETOTALBINS ((EXPBINS)*(EXPOCT))
            #define _SamplesPerSecond 48000
            #define _RootNote 0

            // AudioLink


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
            
            // DFT
            const static float _BottomFrequency = 13.75;
            //const static float _IIRCoefficient = 0.8;
            const static float _BaseAmplitude = 250.0;
            const static float _DecayCoefficient = 0.01;
            const static float _PhiDeltaCorrection = 4.0;
            const static float _DFTMode = 0.0;
            const static float _DFTQ = 4.0;

            // AudioLink
            uniform float _FadeLength;
            uniform float _FadeExpFalloff;
            uniform float _Gain;
            uniform float _Bass;
            uniform float _Treble;
            uniform float _X1;
            uniform float _X2;
            uniform float _X3;
            uniform float _Threshold0;
            uniform float _Threshold1;
            uniform float _Threshold2;
            uniform float _Threshold3;
            uniform float _AudioSource2D;

			// Extra Properties
            uniform float4 _FrameTimeProp;
            uniform float4 _DayTimeProp;
			uniform float _EnableAutogain;
            uniform float _AutogainDerate;
			
            const static float _FreqFloor = 0.123;
            const static float _FreqCeiling = 1.0;
            const static float _TrebleCorrection = 5.0;

            const static float _LogAttenuation = 0.68;
            const static float _ContrastSlope = 0.63;
            const static float _ContrastOffset = 0.62;

            #ifndef glsl_mod
            #define glsl_mod(x,y) (((x)-(y)*floor((x)/(y)))) 
            #endif

            //ColorChord related utility functions.

            #ifndef CCclamp
            #define CCclamp(x,y,z) clamp( x, y, z )
            #endif

            float Remap(float t, float a, float b, float u, float v) {return ( (t-a) / (b-a) ) * (v-u) + u;}

            float3 CCHSVtoRGB(float3 HSV)
            {
                float3 RGB = 0;
                float C = HSV.z * HSV.y;
                float H = HSV.x * 6;
                float X = C * (1 - abs(fmod(H, 2) - 1));
                if (HSV.y != 0)
                {
                    float I = floor(H);
                    if (I == 0) { RGB = float3(C, X, 0); }
                    else if (I == 1) { RGB = float3(X, C, 0); }
                    else if (I == 2) { RGB = float3(0, C, X); }
                    else if (I == 3) { RGB = float3(0, X, C); }
                    else if (I == 4) { RGB = float3(X, 0, C); }
                    else { RGB = float3(C, 0, X); }
                }
                float M = HSV.z - C;
                return RGB + M;
            }

            float3 CCtoRGB( float bin, float intensity, int RootNote )
            {
                float note = bin / EXPBINS;

                float hue = 0.0;
                note *= 12.0;
                note = glsl_mod( 4.-note + RootNote, 12.0 );
                {
                    if( note < 4.0 )
                    {
                        //Needs to be YELLOW->RED
                        hue = (note) / 24.0;
                    }
                    else if( note < 8.0 )
                    {
                        //            [4]  [8]
                        //Needs to be RED->BLUE
                        hue = ( note-2.0 ) / 12.0;
                    }
                    else
                    {
                        //             [8] [12]
                        //Needs to be BLUE->YELLOW
                        hue = ( note - 4.0 ) / 8.0;
                    }
                }
                float val = intensity-.1;
                return CCHSVtoRGB( float3( fmod(hue,1.0), 1.0, CCclamp( val, 0.0, 1.0 ) ) );
            }


            ENDCG

            Name "Pass1AudioDFT"
            
            CGPROGRAM

            const static float lut[240] = {0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.001, 0.002, 0.003, 0.004, 0.005, 0.006, 0.008, 0.01,
0.012, 0.014, 0.017, 0.02, 0.022, 0.025, 0.029, 0.032, 0.036, 0.04, 0.044, 0.048, 0.053, 0.057, 0.062, 0.067, 0.072, 0.078, 0.083, 0.089,
0.095, 0.101, 0.107, 0.114, 0.121, 0.128, 0.135, 0.142, 0.149, 0.157, 0.164, 0.172, 0.18, 0.188, 0.196, 0.205, 0.213, 0.222, 0.23, 0.239,
0.248, 0.257, 0.266, 0.276, 0.285, 0.294, 0.304, 0.313, 0.323, 0.333, 0.342, 0.352, 0.362, 0.372, 0.381, 0.391, 0.401, 0.411, 0.421, 0.431,
0.441, 0.451, 0.46, 0.47, 0.48, 0.49, 0.499, 0.509, 0.519, 0.528, 0.538, 0.547, 0.556, 0.565, 0.575, 0.584, 0.593, 0.601, 0.61, 0.619,
0.627, 0.636, 0.644, 0.652, 0.66, 0.668, 0.676, 0.684, 0.691, 0.699, 0.706, 0.713, 0.72, 0.727, 0.734, 0.741, 0.747, 0.754, 0.76, 0.766,
0.772, 0.778, 0.784, 0.79, 0.795, 0.801, 0.806, 0.811, 0.816, 0.821, 0.826, 0.831, 0.835, 0.84, 0.844, 0.848, 0.853, 0.857, 0.861, 0.864,
0.868, 0.872, 0.875, 0.879, 0.882, 0.885, 0.888, 0.891, 0.894, 0.897, 0.899, 0.902, 0.904, 0.906, 0.909, 0.911, 0.913, 0.914, 0.916, 0.918,
0.919, 0.921, 0.922, 0.924, 0.925, 0.926, 0.927, 0.928, 0.928, 0.929, 0.929, 0.93, 0.93, 0.93, 0.931, 0.931, 0.93, 0.93, 0.93, 0.93,
0.929, 0.929, 0.928, 0.927, 0.926, 0.925, 0.924, 0.923, 0.922, 0.92, 0.919, 0.917, 0.915, 0.913, 0.911, 0.909, 0.907, 0.905, 0.903, 0.9};


            float4 frag (v2f_customrendertexture IN) : SV_Target
            {
                AUDIO_LINK_ALPHA_START( PASS_ONE_OFFSET )

                //Uncomment to enable debugging of where on the CRT this pass is.
                //return float4( coordinateLocal, 0., 1. );

                float4 last = GetSelfPixelData( coordinateGlobal );

                int note = coordinateLocal.y * 128 + coordinateLocal.x;

                float2 ampl = 0.;
                float pha = 0;
                float phadelta = pow( 2, (note)/((float)EXPBINS) );
                phadelta *= _BottomFrequency;
                phadelta /= _SamplesPerSecond;
                phadelta *= 3.1415926 * 2.0;
                float integraldec = 0.;
                float totalwindow = 0;

                // 2 here because we're at 24kSPS
                phadelta *= 2.;

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
                    uint idx;

                    // For ??? reason, this is faster than doing a clever
                    // indexing which only searches the space that will be used.

                    for( idx = 0; idx < SAMPHIST / 2; idx++ )
                    {
                        // XXX TODO: Try better windows, this is just a triangle.
                        float window = max( 0, HalfWindowSize - abs(idx - (SAMPHIST/2-HalfWindowSize) ) );
                        float af = GetSelfPixelData( PASS_TWO_OFFSET + uint2( idx%128, idx/128 ) ).r;
                        
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
                    // Note, while this takes ~40us instead of ~90us, it
                    // doesn't look quite right.
                    float fvpha;
                    int place;

                    #define WINDOWSIZE (6.28*_DFTQ)
                    #define STEP 0.06
                    #define EXTENT ((int)(WINDOWSIZE/STEP))
                    float invphaadv = STEP / phadelta;

                    float fra = SAMPHIST/4 - (invphaadv*EXTENT); //We want the center to line up.

                    for( place = -EXTENT; place <= EXTENT; place++ )
                    {
                        float fvpha = place * STEP;
                        //Sin and cosine components to convolve.
                        float2 sc; sincos( fvpha, sc.x, sc.y );
                        float window = WINDOWSIZE - abs(fvpha);

                        uint idx = round( clamp( fra, 0, 2046 ) );
                        float af = GetSelfPixelData( PASS_TWO_OFFSET + uint2( idx%128, idx/128 ) ).r;

                        // Step through, one sample at a time, multiplying the sin
                        // and cos values by the incoming signal.
                        ampl += sc * af * window;

                        fra += invphaadv;

                        totalwindow += window;
                    }
                }
                float mag = length( ampl );
                mag /= totalwindow;
                mag *= _BaseAmplitude * _Gain * ((_AudioSource2D == 1.) ? 0.01 : 1.);

                //float mag2 = mag;
                float freqNormalized = note / float(EXPOCT*EXPBINS);

                // Treble compensation
                mag *= (lut[min(note, 239)] * _TrebleCorrection + 1);

                //Z component contains filtered output.
                //float magfilt = lerp(mag, last.z, _IIRCoefficient);
                float magfilt = lerp(mag, last.z, lerp(0.3, 0.9, _FadeLength));

                float magEQ = magfilt * (((1.0 - freqNormalized) * _Bass) + (freqNormalized * _Treble));

                return float4( 
                    mag,    //Red:   Spectrum power
                    magEQ,   //Green: Filtered power EQ'd, used by AudioLink
                    magfilt,      //Blue:  Filtered spectrum (For CC)
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

            float4 frag (v2f_customrendertexture IN) : SV_Target
            {
                AUDIO_LINK_ALPHA_START( PASS_TWO_OFFSET )

                //XXX Hack: Force the compiler to keep Samples0 and Samples1.
                if(guv.x < 0)
                    return _Samples0[0] + _Samples1[0] + _Samples2[0] + _Samples3[0]; // slick, thanks @lox9973

                uint frame = coordinateLocal.x + coordinateLocal.y * 128;
                if( frame >= SAMPHIST ) frame = SAMPHIST-1; //Prevent overflow.

                //Uncomment to enable debugging of where on the CRT this pass is.
                //return float4( frame/1000., coordinateLocal/10., 1. );

				float Blue = 0;
				if( frame*4 < SAMPHIST )
					Blue = (_AudioFrames[frame*4+0] + _AudioFrames[frame*4+1] + _AudioFrames[frame*4+2] + _AudioFrames[frame*2+3])/4.;



				
				float GAIN = 1;
				
				// Enable/Disable autogain.
				if( _EnableAutogain )
				{
					float4 LastAutogain = GetSelfPixelData( PASS_FIVE_OFFSET + int2( 11, 0 ) );

					//Divide by the running volume.
					GAIN = 1./(LastAutogain.x + _AutogainDerate);
				}
				

                return float4( 
                    (_AudioFrames[frame*2+0] + _AudioFrames[frame*2+1])/2., //RED: 24kSPS
                    _AudioFrames[frame],      //Green: 48kSPS
                    Blue,      //Blue:  12kSPS 
                    1 ) * GAIN;
            }
            ENDCG
        }

        Pass
        {
            Name "Pass3AudioLink4Band"
            CGPROGRAM


            float4 frag (v2f_customrendertexture IN) : SV_Target
            {
                AUDIO_LINK_ALPHA_START( PASS_THREE_OFFSET )

                float audioBands[4] = {0., _X1, _X2, _X3};
                float audioThresholds[4] = {_Threshold0, _Threshold1, _Threshold2, _Threshold3};

                int band = min(coordinateLocal.y, 3);
                int delay = coordinateLocal.x;
                if (delay == 0) 
                {
                    // Get average of samples in the band
                    float total = 0.;
                    uint totalBins = EXPBINS * EXPOCT;
                    uint binStart = Remap(audioBands[band], 0., 1., _FreqFloor * totalBins, _FreqCeiling * totalBins);
                    uint binEnd = (band != 3) ? Remap(audioBands[band + 1], 0., 1., _FreqFloor * totalBins, _FreqCeiling * totalBins) : _FreqCeiling * totalBins;
                    float threshold = audioThresholds[band];
                    for (uint i=binStart; i<binEnd; i++)
                    {
                        int2 spectrumCoord = int2(i % 128, i / 128);
                        float rawMagnitude = _SelfTexture2D[PASS_ONE_OFFSET + spectrumCoord].g;
                        //rawMagnitude *= LinearEQ(_Gain, _Bass, _Treble, (float)i / totalBins);
                        total += rawMagnitude;
                    }
                    float magnitude = total / (binEnd - binStart);

                    // Log attenuation
                    magnitude = saturate(magnitude * (log(1.1) / (log(1.1 + pow(_LogAttenuation, 4) * (1.0 - magnitude))))) / pow(threshold, 2);

                    // Contrast
                    magnitude = saturate(magnitude * tan(1.57 * _ContrastSlope) + magnitude + _ContrastOffset * tan(1.57 * _ContrastSlope) - tan(1.57 * _ContrastSlope));

                    // Fade
                    float lastMagnitude = _SelfTexture2D[PASS_THREE_OFFSET + int2(0, band)].g;
                    lastMagnitude -= -1.0 * pow(_FadeLength-1.0, 3);                                                                            // Inverse cubic remap
                    lastMagnitude = saturate(lastMagnitude * (1.0 + ( pow(lastMagnitude - 1.0, 4.0) * _FadeExpFalloff) - _FadeExpFalloff));     // Exp falloff

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
            Name "Pass5-VU-Meter-And-Other-Info"
            CGPROGRAM
            // The structure of the output is:
            // RED CHANNEL: Peak Amplitude
            // GREEN CHANNEL: RMS Amplitude.
            // BLUE CHANNEL: RESERVED.

            float4 frag (v2f_customrendertexture IN) : SV_Target
            {
                AUDIO_LINK_ALPHA_START( PASS_FIVE_OFFSET )
                uint i;

                float total = 0;
                float Peak = 0;
                
                // Only VU over 768 12kSPS samples
                for( i = 0; i < 768; i++ )
                {
                    float af = GetSelfPixelData( PASS_TWO_OFFSET + uint2( i%128, i/128 ) ).b;
                    total += af*af;
                    Peak = max( Peak, abs( af ) );
                }

                float PeakRMS = sqrt( total / i );
                float4 MarkerValue = GetSelfPixelData( PASS_FIVE_OFFSET + int2( 9, 0 ) );
                float4 MarkerTimes = GetSelfPixelData( PASS_FIVE_OFFSET + int2( 10, 0 ) );
                float4 LastAutogain = GetSelfPixelData( PASS_FIVE_OFFSET + int2( 11, 0 ) );
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

                if( coordinateLocal.x >= 8 )
                {
                    if( coordinateLocal.x == 8 )
                    {
                        //First pixel: Current value.
                        return float4( PeakRMS, Peak, 0, 1. );
                    }
                    else if( coordinateLocal.x == 9 )
                    {
                        //Second pixel: Limit Output
                        return MarkerValue;
                    }
                    else if( coordinateLocal.x == 10 )
                    {
                        //Second pixel: Limit Time
                        return MarkerTimes;
                    }
                    else if( coordinateLocal.x == 11 )
                    {
                        //Third pixel: Auto Gain
						
						//Compensate for the fact that we've already gain'd our samples.
						float deratePeak = Peak / ( LastAutogain.x + _AutogainDerate );
						
                        if( deratePeak > LastAutogain.x )
						{
							LastAutogain.x = lerp( deratePeak, LastAutogain.x, .5 ); //Make attack quick
						}
						else
						{
							LastAutogain.x = lerp( deratePeak, LastAutogain.x, .995 ); //Make decay long.
						}
						return LastAutogain;
                    }
                }
                else
                {
                    if( coordinateLocal.x == 0 )
                    {
                        //Pixel 0 = Version
                        return 2; //Version number
                    }
                    else if( coordinateLocal.x == 1 )
                    {
                        //Pixel 1 = Frame Count, if we did not repeat, this would stop counting after ~51 hours.
						// Note: This is also used to measure FPS.
						
						float4 lastval = GetSelfPixelData( PASS_FIVE_OFFSET + int2( 1, 0 ) );
                        float framecount = lastval.r;
						float framecountfps = lastval.g;
						float framecountlastfps = lastval.b;
						float lasttimefps = lastval.a;
                        framecount++;
                        if( framecount >= 7776000 ) //~24 hours.
                            framecount = 0;
							
						framecountfps++;

						// See if we've been reset.
						if( lasttimefps > _Time.y )
						{
							lasttimefps = 0;
						}

						// After one second, take the running FPS and present it as the now FPS.
						if( _Time.y > lasttimefps + 1 )
						{
							framecountlastfps = framecountfps;
							framecountfps = 0;
							lasttimefps = _Time.y;
						}
                        return float4( framecount, framecountfps, framecountlastfps, lasttimefps );
                    }
                    else if( coordinateLocal.x == 2 )
                    {
                        return _FrameTimeProp;
                    }
                    else if( coordinateLocal.x == 3 )
                    {
                        return _DayTimeProp;
                    }
                }

                //Reserved
                return 0;
            }
            ENDCG
        }

        Pass
        {
            Name "Pass6ColorChord-Notes"
            CGPROGRAM
            float _PeakDecay;
            float _PeakCloseEnough;
            float _PeakMinium;
            
            float NoteWrap( float Note1, float Note2 )
            {
                float diff = Note2 - Note1;
                diff = glsl_mod( diff, EXPBINS );
                if( diff > EXPBINS/2 )
                    return diff - EXPBINS;
                else
                    return diff;
            }
            
            float4 frag (v2f_customrendertexture IN) : SV_Target
            {
                AUDIO_LINK_ALPHA_START( PASS_SIX_OFFSET )
                uint i;

                #define CCMAXNOTES 10

                #define EMAXBIN 192
                #define EBASEBIN 24
                
                static const float NOTECLOSEST = 3.5;
                static const float NOTE_MINIMUM = 0.2;
                static const float IIR1_DECAY = 0.90;
                static const float CONSTANT1_DECAY = 0.01;
                static const float IIR2_DECAY = 0.85;
                static const float CONSTANT2_DECAY = 0.00;
                
                float4 NoteSummary = GetSelfPixelData( PASS_SIX_OFFSET );
                
                //Note structure:
                // .x = Note frequency (0...ETOTALBINS, but floating point)
                // .y = Re-porp intensity.
                // .z = Lagged intensity.
                // .a = Quicker lagged intensity.
                float4 Notes[CCMAXNOTES];
                
                
                
                for( i = 0; i < CCMAXNOTES; i++ )
                {
                    Notes[i] = GetSelfPixelData( PASS_SIX_OFFSET + uint2( i+1, 0 ) );
                    Notes[i].y = 0;
                }

                float Last = GetSelfPixelData( PASS_ONE_OFFSET + uint2( EBASEBIN, 0 ) ).b;
                float This = GetSelfPixelData( PASS_ONE_OFFSET + uint2( 1+EBASEBIN, 0 ) ).b;
                for( i = EBASEBIN+2; i < EMAXBIN; i++ )
                {
                    float Next = GetSelfPixelData( PASS_ONE_OFFSET + uint2( i % 128, i / 128 ) ).b;
                    if( This > Last && This > Next && This > NOTE_MINIMUM )
                    {
                        //Find actual peak by looking ahead and behind.
                        float DiffA = This - Next;
                        float DiffB = This - Last;
                        float NoteFreq = glsl_mod( i - 1, EXPBINS );
                        if( DiffA < DiffB )
                        {
                            //Behind
                            NoteFreq -= 1.-DiffA/DiffB; //Ratio must be between 0 .. 0.5
                        }
                        else
                        {
                            //Ahead
                            NoteFreq += 1.-DiffB/DiffA;
                        }
                        

                        uint j;
                        int closest_note = -1;
                        int free_note = -1;
                        float closest_note_distance = NOTECLOSEST;
                                                
                        // Search notes to see what the closest note to this peak is.
                        // also look for any empty notes.
                        for( j = 0; j < CCMAXNOTES; j++ )
                        {
                            float dist = abs( NoteWrap( Notes[j].x, NoteFreq ) );
                            if( Notes[j].z <= 0 )
                            {
                                if( free_note == -1 )
                                    free_note = j;
                            }
                            else if( dist < closest_note_distance )
                            {
                                closest_note_distance = dist;
                                closest_note = j;
                            }
                        }
                        
                        
                        if( closest_note != -1 )
                        {
                            float4 n = Notes[closest_note];
                            // Note to combine peak to has been found, roll note in.
                            
                            float drag = NoteWrap( n.x, NoteFreq ) * 0.05;//This/(This+n.z);

                            Notes[closest_note] = float4( n.x + drag, n.y + This, n.z + This, n.a );
                        }
                        else if( free_note != -1 )
                        {
                            // Couldn't find note.  Create a new note.
                            Notes[free_note] = float4( NoteFreq, This, This, This );
                        }
                        else
                        {
                            // Whelp, the note fell off the wagon.  Oh well!
                        }
                    }
                    Last = This;
                    This = Next;
                }

                float4 NewNoteSummary = 0.;

                [loop]
                for( i = 0; i < CCMAXNOTES; i++ )
                {
                    uint j;
                    float4 n1 = Notes[i];

                    
                    [loop]
                    for( j = 0; j < CCMAXNOTES; j++ )
                    {
                        // 🤮 Shader compiler can't do triangular loops.
                        // We don't want to iterate over a cube just compare ith and jth note once.

                         float4 n2 = Notes[j];
                        if( n2.z > 0 && j > i && n1.z > 0 )
                        {
                            // Potentially combine notes
                            float dist = abs( NoteWrap( n1.x, n2.x ) );
                            if( dist < NOTECLOSEST )
                            {
                                //Found combination of notes.  Nil out second.
                                float drag = NoteWrap( n1.x, n2.x ) * 0.5;//n1.z/(n2.z+n1.y);
                                n1 = float4( n1.x + drag, n1.y + This, n1.z, n1.a );
                                Notes[j] = 0;
                            }
                        }
                    }
                    
                    //Filter n1.z from n1.y.
                    if( n1.z >= 0 )
                    {
                        n1.z = lerp( n1.y, n1.z, IIR1_DECAY ) - CONSTANT1_DECAY; //Make decay slow.
                        n1.w = lerp( n1.y, n1.w, IIR2_DECAY ) - CONSTANT2_DECAY; //Make decay slow.
                        
                        if( n1.z < NOTE_MINIMUM )
                        {
                            n1 = -1;
                        }
                        //XXX TODO: Do uniformity calculation on n1 for n1.a.
                    }
                    
                    n1.y = max( 0, pow( n1.z, 1.5 ) - 50. );
                    n1.y = 0;
                    
                    if( n1.z >= 0 )
                    {
                        NewNoteSummary += float4( 0, n1.y, n1.z, n1.w );
                    }
                    
                    Notes[i] = n1;
                }

                // We now have a condensed list of all Notes that are playing.
                if( coordinateLocal.x == 0 )
                {
                    //Summary note.
                    return NewNoteSummary;
                }
                else
                {
                    float4 selnote = Notes[coordinateLocal.x-1];

                    // Make sure we're wrapped correctly.
                    selnote.x = glsl_mod( selnote.x, EXPBINS );
                    return selnote;
                }
            }
            ENDCG
        }

        Pass
        {
            Name "Pass7-AutoCorrelator"
            CGPROGRAM

            float4 frag (v2f_customrendertexture IN) : SV_Target
            {
                AUDIO_LINK_ALPHA_START( PASS_SEVEN_OFFSET )
                uint i;

                #define EMAXBIN 120
                #define EBASEBIN 0

                float PlaceInWave = (float)coordinateLocal.x;

                float fvtot = 0;

                float fvr = 15.;

                for( i = EBASEBIN; i < EMAXBIN; i++ )
                {
                    float Bin = GetSelfPixelData( PASS_ONE_OFFSET + uint2( i%128, i/128 ) ).b;
                    float freq = pow( 2, i/24. ) * _BottomFrequency / _SamplesPerSecond * 3.14159 * 2.;
                    float csv =  cos( freq * PlaceInWave * fvr );
                    fvtot += csv * (Bin*Bin);
                }

                return fvtot;
            }
            ENDCG
        }

        Pass
        {
            Name "Pass8-ColorChord-Linear"
            CGPROGRAM
            
            float4 frag (v2f_customrendertexture IN) : SV_Target
            {
                AUDIO_LINK_ALPHA_START( PASS_EIGHT_OFFSET )

                int p;
                
                const float Brightness = 2.0;
                const float RootNote = 0;
                
                float4 NotesSummary =  GetSelfPixelData( PASS_SIX_OFFSET );

                float TotalPower = 0.0;
                TotalPower = NotesSummary.z;

                float PowerPlace = 0.0;
                for( p = 0; p < CCMAXNOTES; p++ )
                {
                    float4 Peak = GetSelfPixelData( PASS_SIX_OFFSET + int2( 1+p, 0 ) );
                    if( Peak.z <= 0 ) continue;

                    float Power = Peak.z/TotalPower;
                    PowerPlace += Power;
                    if( PowerPlace >= IN.globalTexcoord.x ) 
                    {
                        return float4( CCtoRGB( Peak.x, Peak.a*0.5 * Brightness, _RootNote ), 1.0 );
                    }
                }
                
                return float4( 0., 0., 0., 1. );
            }
            ENDCG
        }
        
        
        
        Pass
        {
            Name "Pass9-ColorChord-Lights"
            CGPROGRAM


            static const float _PickNewSpeed = 1.0;
            
            float tinyrand(float3 uvw)
            {
                return frac(cos(dot(uvw, float3(137.945, 942.32, 593.46))) * 442.5662);
            }

            float SetNewCellValue( float a )
            {
                return a*.5;
            }


            float4 frag (v2f_customrendertexture IN) : SV_Target
            {
                AUDIO_LINK_ALPHA_START( PASS_NINE_OFFSET )
                
                float4 NotesSummary = GetSelfPixelData( PASS_SIX_OFFSET );
                
                #define NOTESUFFIX( n )  pow(n.z, 1.5)
                
                float4 ComputeCell = GetSelfPixelData( PASS_NINE_OFFSET + int2( coordinateLocal.x, 1 ) );
                //ComputeCell
                //    .x = Mated Cell # (Or -1 for black)
                //    .y = Minimum Brightness Before Jump
                //    .z = ???
                
                float4 ThisNote = GetSelfPixelData( PASS_SIX_OFFSET + int2( ComputeCell.x + 1, 0 ) );
                //  Each element:
                //   R: Peak Location (Note #)
                //   G: Peak Intensity
                //   B: Calm Intensity
                //   A: Other Intensity

                if( NOTESUFFIX( ThisNote ) < ComputeCell.y || ComputeCell.y <= 0 || ThisNote.z < 0 )
                {
                    //Need to select new cell.
                    float min_to_acquire = tinyrand( float3( coordinateLocal.xy, _Time.x ) );
                    
                    int n;
                    float4 SelectedNote = 0.;
                    int SelectedNoteNo = -1;
                    
                    float cumulative = 0.0;
                    for( n = 0; n < CCMAXNOTES; n++ )
                    {
                        float4 Note = GetSelfPixelData( PASS_SIX_OFFSET + int2( n + 1, 0 ) );
                        float unic = NOTESUFFIX( Note );
                        if( unic > 0 )
                            cumulative += unic;
                    }

                    float sofar = 0.0;
                    for( n = 0; n < CCMAXNOTES; n++ )
                    {
                        float4 Note = GetSelfPixelData( PASS_SIX_OFFSET + int2( n + 1, 0 ) );
                        float unic = NOTESUFFIX( Note );
                        if( unic > 0 ) 
                        {
                            sofar += unic;
                            if( sofar/cumulative > min_to_acquire )
                            {
                                SelectedNote = Note;
                                SelectedNoteNo = n;
                                break;
                            }
                        }
                    }
                    
                
                    if( SelectedNote.z > 0.0 )
                    {
                        ComputeCell.x = SelectedNoteNo;
                        ComputeCell.y = SetNewCellValue( NOTESUFFIX(SelectedNote) );
                    }
                    else
                    {
                        ComputeCell.x = 0;
                        ComputeCell.y = 0;
                    }
                }
                else
                {
                    ComputeCell.y -= _PickNewSpeed*0.01;
                }
                
                ThisNote = GetSelfPixelData( PASS_SIX_OFFSET + int2( ComputeCell.x + 1, 0 ) );

                if( coordinateLocal.y < 0.5 )
                {
                    // the light color output
                    if( ComputeCell.y <= 0 )
                    {
                        return 0.;
                    }
                    return float4( CCtoRGB( glsl_mod( ThisNote.x,48.0 ), ThisNote.z, _RootNote ), 1.0 );
                }
                else
                {
                    // the compute output
                    return ComputeCell;
                }
            }
            ENDCG
        }


        Pass 
        {
            Name "No-op"
            ColorMask 0
            ZWrite Off 
            
        }
    }
}
