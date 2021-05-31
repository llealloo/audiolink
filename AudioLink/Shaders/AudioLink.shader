Shader "AudioLink/AudioLink"
{
    //Example CRT with multiple passed, used to read its own texture and write into another place.
    //Example of usage is in colorchord scene.
    //This shows how to read from other coordiantes within the CRT texture when using multiple passes.

    Properties
    {
        // Phase 3 (AudioLink 4 Band)
        _Gain("Gain", Range(0, 2)) = 1.0

        _FadeLength("Fade Length", Range(0 , 1)) = 0.8
        _FadeExpFalloff("Fade Exp Falloff", Range(0 , 1)) = 0.3
        _Bass("Bass", Range(0 , 4)) = 1.0
        _Treble("Treble", Range(0 , 4)) = 1.0
        
        _X0("X0", Range(0.0, 0.168)) = 0.25
        _X1("X1", Range(0.242, 0.387)) = 0.25
        _X2("X2", Range(0.461, 0.628)) = 0.5
        _X3("X3", Range(0.704, 0.953)) = 0.75

        _Threshold0("Threshold 0", Range(0.0, 1.0)) = 0.45
        _Threshold1("Threshold 1", Range(0.0, 1.0)) = 0.45
        _Threshold2("Threshold 2", Range(0.0, 1.0)) = 0.45
        _Threshold3("Threshold 3", Range(0.0, 1.0)) = 0.45
 
        [ToggleUI] _AudioSource2D("Audio Source 2D", float) = 0
        
        [ToggleUI] _EnableAutogain("Enable Autogain", float) = 1
        _AutogainDerate ("Autogain Derate", Range(.001, .5)) = 0.1
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

            #if UNITY_UV_STARTS_AT_TOP
            #define AUDIO_LINK_ALPHA_START(BASECOORDY) \
                float2 guv = IN.globalTexcoord.xy; \
                uint2 coordinateGlobal = round(guv/_SelfTexture2D_TexelSize.xy - 0.5); \
                uint2 coordinateLocal = uint2(coordinateGlobal.x - BASECOORDY.x, coordinateGlobal.y - BASECOORDY.y);
            #else
            #define AUDIO_LINK_ALPHA_START(BASECOORDY) \
                float2 guv = IN.globalTexcoord.xy; \
                guv.y = 1.-guv.y; \
                uint2 coordinateGlobal = round(guv/_SelfTexture2D_TexelSize.xy - 0.5); \
                uint2 coordinateLocal = uint2(coordinateGlobal.x - BASECOORDY.x, coordinateGlobal.y - BASECOORDY.y);
            #endif

            #pragma target 4.0
            #pragma vertex CustomRenderTextureVertexShader
            #pragma fragment frag
            #include "AudioLinkCRT.cginc"
            #include "UnityCG.cginc"
            #include "AudioLink.cginc"
            uniform half4 _SelfTexture2D_TexelSize; 

            cbuffer SampleBuffer {
                float _AudioFrames[1023*4] : packoffset(c0);  
                float _Samples0[1023] : packoffset(c0);
                float _Samples1[1023] : packoffset(c1023);
                float _Samples2[1023] : packoffset(c2046);
                float _Samples3[1023] : packoffset(c3069);
            };
            
            // This pulls data from this texture.
            #define GetSelfPixelData(xy) _SelfTexture2D[xy]
            
            // DFT
            const static float _BottomFrequency = 13.75;
            const static float _BaseAmplitude = 2.5;
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
            uniform float _X0;
            uniform float _X1;
            uniform float _X2;
            uniform float _X3;
            uniform float _Threshold0;
            uniform float _Threshold1;
            uniform float _Threshold2;
            uniform float _Threshold3;
            uniform float _AudioSource2D;

            // Extra Properties
            uniform float4 _AdvancedTimeProps;
            uniform float4 _VersionNumberAndFPSProperty;


            uniform float _EnableAutogain;
            uniform float _AutogainDerate;
            
            const static float _TrebleCorrection = 5.0;

            const static float _LogAttenuation = 0.68;
            const static float _ContrastSlope = 0.63;
            const static float _ContrastOffset = 0.62;

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
                AUDIO_LINK_ALPHA_START(ALPASS_DFT)

                //Uncomment to enable debugging of where on the CRT this pass is.
                //return float4(coordinateLocal, 0., 1.);

                float4 last = GetSelfPixelData(coordinateGlobal);

                int note = coordinateLocal.y * 128 + coordinateLocal.x;

                float2 ampl = 0.;
                float pha = 0;
                float phadelta = pow(2, (note)/((float)EXPBINS));
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

                if(_DFTMode < 1.0)
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
                        float window = max(0, HalfWindowSize - abs(idx - (SAMPHIST/2-HalfWindowSize)));
                        float af = GetSelfPixelData(ALPASS_WAVEFORM + uint2(idx%128, idx/128)).r;
                        
                        //Sin and cosine components to convolve.
                        float2 sc; sincos(pha, sc.x, sc.y);

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

                        uint idx = round(clamp(fra, 0, 2046));
                        float af = GetSelfPixelData(ALPASS_WAVEFORM + uint2(idx%128, idx/128)).r;

                        // Step through, one sample at a time, multiplying the sin
                        // and cos values by the incoming signal.
                        ampl += sc * af * window;

                        fra += invphaadv;

                        totalwindow += window;
                    }
                }
                float mag = length(ampl);
                mag /= totalwindow;
                mag *= _BaseAmplitude * _Gain;

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
                AUDIO_LINK_ALPHA_START(ALPASS_WAVEFORM)

                //XXX Hack: Force the compiler to keep Samples0 and Samples1.
                if(guv.x < 0)
                    return _Samples0[0] + _Samples1[0] + _Samples2[0] + _Samples3[0]; // slick, thanks @lox9973

                uint frame = coordinateLocal.x + coordinateLocal.y * 128;
                if(frame >= SAMPHIST) frame = SAMPHIST - 1; //Prevent overflow.

                //Uncomment to enable debugging of where on the CRT this pass is.
                //return float4( frame/1000., coordinateLocal/10., 1. );

                float Blue = 0;
                if(frame*4 < SAMPHIST)
                    Blue = (_AudioFrames[frame*4+0] + _AudioFrames[frame*4+1] + _AudioFrames[frame*4+2] + _AudioFrames[frame*2+3])/4.;
                
                float incomingGain = ((_AudioSource2D > 0.5) ? 1.f : 100.f);
                
                // Enable/Disable autogain.
                if( _EnableAutogain )
                {
                    float4 LastAutogain = GetSelfPixelData(ALPASS_GENERALVU + int2(11, 0));

                    //Divide by the running volume.
                    incomingGain *= 1./(LastAutogain.x + _AutogainDerate);
                }
                

                return float4( 
                    (_AudioFrames[frame * 2 + 0] + _AudioFrames[frame * 2 + 1]) / 2.,   //RED: 24kSPS
                    _AudioFrames[frame],                                                //Green: 48kSPS
                    Blue,                                                               //Blue:  12kSPS 
                    1) * incomingGain;
            }
            ENDCG
        }

        Pass
        {
            Name "Pass3AudioLink4Band"
            CGPROGRAM

            float4 frag (v2f_customrendertexture IN) : SV_Target
            {
                AUDIO_LINK_ALPHA_START(ALPASS_AUDIOLINK)

                float audioBands[4] = {_X0, _X1, _X2, _X3};
                float audioThresholds[4] = {_Threshold0, _Threshold1, _Threshold2, _Threshold3};

                int band = min(coordinateLocal.y, 3);
                int delay = coordinateLocal.x;
                if (delay == 0) 
                {
                    // Get average of samples in the band
                    float total = 0.;
                    uint totalBins = EXPBINS * EXPOCT;
                    uint binStart = Remap(audioBands[band], 0., 1., AL4BAND_FREQFLOOR * totalBins, AL4BAND_FREQCEILING * totalBins);
                    uint binEnd = (band != 3) ? Remap(audioBands[band + 1], 0., 1., AL4BAND_FREQFLOOR * totalBins, AL4BAND_FREQCEILING * totalBins) : AL4BAND_FREQCEILING * totalBins;
                    float threshold = audioThresholds[band];
                    for (uint i=binStart; i<binEnd; i++)
                    {
                        int2 spectrumCoord = int2(i % 128, i / 128);
                        float rawMagnitude = GetSelfPixelData(ALPASS_DFT + spectrumCoord).g;
                        //rawMagnitude *= LinearEQ(_Gain, _Bass, _Treble, (float)i / totalBins);
                        total += rawMagnitude;
                    }
                    float magnitude = total / (binEnd - binStart);

                    // Log attenuation
                    magnitude = saturate(magnitude * (log(1.1) / (log(1.1 + pow(_LogAttenuation, 4) * (1.0 - magnitude))))) / pow(threshold, 2);

                    // Contrast
                    magnitude = saturate(magnitude * tan(1.57 * _ContrastSlope) + magnitude + _ContrastOffset * tan(1.57 * _ContrastSlope) - tan(1.57 * _ContrastSlope));

                    // Fade
                    float lastMagnitude = GetSelfPixelData(ALPASS_AUDIOLINK + int2(0, band)).g;
                    lastMagnitude -= -1.0 * pow(_FadeLength-1.0, 3);                                                                            // Inverse cubic remap
                    lastMagnitude = saturate(lastMagnitude * (1.0 + (pow(lastMagnitude - 1.0, 4.0) * _FadeExpFalloff) - _FadeExpFalloff));     // Exp falloff

                    magnitude = max(lastMagnitude, magnitude);

                    return float4(magnitude, magnitude, magnitude, 1.);

                // If part of the delay
                } else {
                    // Return pixel to the left
                    return GetSelfPixelData(ALPASS_AUDIOLINK + int2(coordinateLocal.x - 1, coordinateLocal.y));
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
                AUDIO_LINK_ALPHA_START(ALPASS_GENERALVU)
                uint i;

                float total = 0;
                float Peak = 0;
                
                // Only VU over 768 12kSPS samples
                for( i = 0; i < 768; i++ )
                {
                    float af = GetSelfPixelData(ALPASS_WAVEFORM + uint2(i%128, i/128)).b;
                    total += af*af;
                    Peak = max(Peak, abs(af));
                }

                float PeakRMS = sqrt( total / i );
                float4 MarkerValue = GetSelfPixelData(ALPASS_GENERALVU + int2(9, 0));
                float4 MarkerTimes = GetSelfPixelData(ALPASS_GENERALVU + int2(10, 0));
                float4 LastAutogain = GetSelfPixelData(ALPASS_GENERALVU + int2(11, 0));
                float Time = _Time.y;
                
                if(Time - MarkerTimes.x > 1.0) MarkerValue.x = -1;
                if(Time - MarkerTimes.y > 1.0) MarkerValue.y = -1;
                
                if(MarkerValue.x < PeakRMS)
                {
                    MarkerValue.x = PeakRMS;
                    MarkerTimes.x = Time;
                }

                if(MarkerValue.y < Peak)
                {
                    MarkerValue.y = Peak;
                    MarkerTimes.y = Time;
                }

                if(coordinateLocal.x >= 8)
                {
                    if(coordinateLocal.x == 8)
                    {
                        //First pixel: Current value.
                        return float4(PeakRMS, Peak, 0, 1.);
                    }
                    else if(coordinateLocal.x == 9)
                    {
                        //Second pixel: Limit Output
                        return MarkerValue;
                    }
                    else if(coordinateLocal.x == 10)
                    {
                        //Second pixel: Limit Time
                        return MarkerTimes;
                    }
                    else if(coordinateLocal.x == 11)
                    {
                        //Third pixel: Auto Gain / Volume Monitor for ColorChord
                        
                        //Compensate for the fact that we've already gain'd our samples.
                        float deratePeak = Peak / (LastAutogain.x + _AutogainDerate);
                        
                        if(deratePeak > LastAutogain.x)
                        {
                            LastAutogain.x = lerp(deratePeak, LastAutogain.x, .5); //Make attack quick
                        }
                        else
                        {
                            LastAutogain.x = lerp(deratePeak, LastAutogain.x, .995); //Make decay long.
                        }
                        
                        LastAutogain.y = lerp(Peak, LastAutogain.y, 0.95);
                        return LastAutogain;
                    }
                }
                else
                {
                    if(coordinateLocal.x == 0)
                    {
                        //Pixel 0 = Version
                        return _VersionNumberAndFPSProperty;
                    }
                    else if(coordinateLocal.x == 1)
                    {
                        //Pixel 1 = Frame Count, if we did not repeat, this would stop counting after ~51 hours.
                        // Note: This is also used to measure FPS.
                        
                        float4 lastval = GetSelfPixelData(ALPASS_GENERALVU + int2(1, 0 ));
                        float framecount = lastval.r;
                        float framecountfps = lastval.g;
                        float framecountlastfps = lastval.b;
                        float lasttimefps = lastval.a;
                        framecount++;
                        if(framecount >= 7776000) //~24 hours.
                            framecount = 0;
                            
                        framecountfps++;

                        // See if we've been reset.
                        if(lasttimefps > _Time.y)
                        {
                            lasttimefps = 0;
                        }

                        // After one second, take the running FPS and present it as the now FPS.
                        if(_Time.y > lasttimefps + 1)
                        {
                            framecountlastfps = framecountfps;
                            framecountfps = 0;
                            lasttimefps = _Time.y;
                        }
                        return float4(framecount, framecountfps, framecountlastfps, lasttimefps);
                    }
                    else if(coordinateLocal.x == 2)
                    {
                        // Output of this is daytime, in milliseconds
                        // as an int.  But, we only have half4's.
                        // so we have to get creative.

                        //_AdvancedTimeProps.x = seconds % 1024
                        //_AdvancedTimeProps.y = seconds / 1024

                        // This is done a little awkwardly as to prevent any overflows.
                        uint dtms = _AdvancedTimeProps.x * 1000;
                        uint dtms2 = _AdvancedTimeProps.y * 1000 + (dtms>>10);
                        return float4(
                            (float)(dtms & 0x3ff),
                            (float)((dtms2) & 0x3ff),
                            (float)((dtms2 >> 10) & 0x3ff),
                            (float)((dtms2 >> 20) & 0x3ff)
                            );
                    }
                    else if(coordinateLocal.x == 3)
                    {
                        int ftpa = _AdvancedTimeProps.z * 1000.;
                        return float4(ftpa & 0x3ff, (ftpa >> 10) & 0x3ff, (ftpa >> 20), 0);
                    }
                    else if(coordinateLocal.x == 4)
                    {
                        return float4(0, 0, 0, 0);
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
            
            float NoteWrap(float Note1, float Note2)
            {
                float diff = Note2 - Note1;
                diff = glsl_mod(diff, EXPBINS);
                if(diff > EXPBINS/2)
                    return diff - EXPBINS;
                else
                    return diff;
            }
            
            float4 frag (v2f_customrendertexture IN) : SV_Target
            {
                AUDIO_LINK_ALPHA_START(ALPASS_CCINTERNAL)
                uint i;

                #define CCMAXNOTES 10
                #define EMAXBIN 192
                #define EBASEBIN 24
                
                float VUAmplitudeNow = GetSelfPixelData(ALPASS_GENERALVU + int2(8, 0)).y * _Gain;
                float NOTE_MINIMUM = 0.00 + 0.1 * VUAmplitudeNow;
                
                static const float NOTECLOSEST = 3.0;
                static const float IIR1_DECAY = 0.90;
                static const float CONSTANT1_DECAY = 0.01;
                static const float IIR2_DECAY = 0.85;
                static const float CONSTANT2_DECAY = 0.00;
                static const float _NewNoteGain = 8.;

                //Note structure:
                // .x = Note frequency (0...ETOTALBINS, but floating point)
                // .y = The incoming intensity.
                // .z = Lagged intensity.         ---> This is what decides if a note is going to disappear.
                // .w = Quicker lagged intensity.
                
                //NoteB Structure
                // .x = Note Number  ::: NOTE if .y < 0 this is the index of where this note _went_ or what note it was joined to.
                // .y = Time this note has existed.
                // .z = Sorted-by-frequency position. (With note 0 being the 0th note)
                
                //Summary:
                // .x = Total number of notes.
                // .y .z .w = sum of note's yzw.
                
                //SummaryB:
                // .x = Latest note number.
                // .y = _RootNote
                // .z = number of populated notes.
                
                float4 Notes[CCMAXNOTES];
                float4 NotesB[CCMAXNOTES];

                for(i = 0; i < CCMAXNOTES; i++)
                {
                    NotesB[i] = GetSelfPixelData(ALPASS_CCINTERNAL + uint2(i+1, 1));
                    Notes[i] =  GetSelfPixelData(ALPASS_CCINTERNAL + uint2(i+1, 0)) * float4(1, 0, 1, 1);
                }

                float4 NoteSummary = GetSelfPixelData(ALPASS_CCINTERNAL);
                float4 NoteSummaryB = GetSelfPixelData(ALPASS_CCINTERNAL + int2(0, 1));

                float Last = GetSelfPixelData(ALPASS_DFT + uint2(EBASEBIN, 0)).b;
                float This = GetSelfPixelData(ALPASS_DFT + uint2(1 + EBASEBIN, 0)).b;
                for(i = EBASEBIN+2; i < EMAXBIN; i++)
                {
                    float Next = GetSelfPixelData(ALPASS_DFT + uint2(i % 128, i / 128)).b;
                    if(This > Last && This > Next && This > NOTE_MINIMUM)
                    {
                        //Find actual peak by looking ahead and behind.
                        float DiffA = This - Next;
                        float DiffB = This - Last;
                        float NoteFreq = glsl_mod(i - 1, EXPBINS);
                        if(DiffA < DiffB)
                        {
                            //Behind
                            NoteFreq -= 1. - DiffA / DiffB; //Ratio must be between 0 .. 0.5
                        }
                        else
                        {
                            //Ahead
                            NoteFreq += 1. - DiffB / DiffA;
                        }
                        

                        uint j;
                        int closest_note = -1;
                        int free_note = -1;
                        float closest_note_distance = NOTECLOSEST;
                                                
                        // Search notes to see what the closest note to this peak is.
                        // also look for any empty notes.
                        for(j = 0; j < CCMAXNOTES; j++)
                        {
                            float dist = abs(NoteWrap(Notes[j].x, NoteFreq));
                            if(Notes[j].z <= 0)
                            {
                                if(free_note == -1)
                                    free_note = j;
                            }
                            else if(dist < closest_note_distance)
                            {
                                closest_note_distance = dist;
                                closest_note = j;
                            }
                        }
                        
                        float ThisIntensity = This*_NewNoteGain;
                        
                        if(closest_note != -1)
                        {
                            float4 n = Notes[closest_note];
                            // Note to combine peak to has been found, roll note in.
                            
                            float drag = NoteWrap(n.x, NoteFreq) * 0.05;

                            //float2 newn = max( n.yz, ThisIntensity.xx  );
                            
                            float mn = max(n.y, This * _NewNoteGain)
                                // Technically the above is incorrect without the below, additional notes found should controbute.
                                // But I'm finding it looks better w/o it.  Well, the 0.3 is arbitrary.  But, it isn't right to
                                // only take max.
                                + This * _NewNoteGain * 0.3
                                ;
                            Notes[closest_note] = float4( n.x + drag, mn, n.z, n.a );
                        }
                        else if(free_note != -1)
                        {

                            int jc = 0;
                            int ji = 0;
                            // uuuggghhhh Ok, so this's is probably just me being paranoid
                            // but I really wanted to make sure all note IDs are unique
                            // in case another tool would care about the uniqueness.
                            [loop]
                            for(ji = 0; ji < CCMAXNOTES && jc != CCMAXNOTES; ji++)
                            {
                                NoteSummaryB.x = NoteSummaryB.x + 1;
                                if(NoteSummaryB.x > 1023) NoteSummaryB.x = 0;
                                [loop]
                                for(jc = 0; jc < CCMAXNOTES; jc++)
                                {
                                    if(NotesB[jc].x == NoteSummaryB.x)
                                        break;
                                }
                            }

                            // Couldn't find note.  Create a new note.
                            Notes[free_note]  = float4(NoteFreq, ThisIntensity, ThisIntensity, ThisIntensity);
                            NotesB[free_note] = float4(NoteSummaryB.x, unity_DeltaTime.x, 0, 0);
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
                float4 NewNoteSummaryB = NoteSummaryB;
                NewNoteSummaryB.y = _RootNote;

                [loop]
                for(i = 0; i < CCMAXNOTES; i++)
                {
                    uint j;
                    float4 n1 = Notes[i];
                    float4 n1B = NotesB[i];

                    
                    [loop]
                    for(j = 0; j < CCMAXNOTES; j++)
                    {
                        // 🤮 Shader compiler can't do triangular loops.
                        // We don't want to iterate over a cube just compare ith and jth note once.

                        float4 n2 = Notes[j];

                        if(n2.z > 0 && j > i && n1.z > 0)
                        {
                            // Potentially combine notes
                            float dist = abs(NoteWrap(n1.x, n2.x));
                            if(dist < NOTECLOSEST)
                            {
                                //Found combination of notes.  Nil out second.
                                float drag = NoteWrap(n1.x, n2.x) * 0.5;//n1.z/(n2.z+n1.y);
                                n1 = float4(n1.x + drag, n1.y + This, n1.z, n1.a);

                                //n1B unchanged.

                                Notes[j] = 0;
                                NotesB[j] = float4(i, -1, 0, 0);
                            }
                        }
                    }
                    
                    //Filter n1.z from n1.y.
                    if(n1.z >= 0)
                    {
                        // Make sure we're wrapped correctly.
                        n1.x = glsl_mod(n1.x, EXPBINS);
                        
                        // Apply filtering
                        n1.z = lerp(n1.y, n1.z, IIR1_DECAY) - CONSTANT1_DECAY; //Make decay slow.
                        n1.w = lerp(n1.y, n1.w, IIR2_DECAY) - CONSTANT2_DECAY; //Make decay slow.

                        n1B.y += unity_DeltaTime.x;


                        if(n1.z < NOTE_MINIMUM)
                        {
                            n1 = -1;
                            n1B = 0;
                        }
                        //XXX TODO: Do uniformity calculation on n1 for n1.a.
                    }

                    if(n1.z >= 0)
                    {
                        // Compute Y to create a "unified" value.  This is good for understanding
                        // the ratio of how "important" this note is.
                        n1.y = pow(max(n1.z - NOTE_MINIMUM*10, 0), 1.5);
                    
                        NewNoteSummary += float4(1., n1.y, n1.z, n1.w);
                    }
                    
                    Notes[i] = n1;
                    NotesB[i] = n1B;
                }

                // Sort by frequency and count notes.
                // These loops are phrased funny because the unity shader compiler gets really
                // confused easily.
                float SortedNoteSlotValue = -1000;
                int sortplace = 0;
                NewNoteSummaryB.z = 0;
                [loop]
                for(i = 0; i < CCMAXNOTES; i++)
                {
                    //Count notes
                    NewNoteSummaryB.z += (Notes[i].z > 0) ? 1 : 0;

                    float ClosestToSlotWithoutGoingOver = 100;
                    int sortid = -1;
                    int j;
                    for(j = 0; j < CCMAXNOTES; j++)
                    {
                        float4 n2 = Notes[j];
                        float notefreq = glsl_mod(-Notes[0].x + 0.5 + n2.x , EXPBINS);
                        if(n2.z > 0 && notefreq > SortedNoteSlotValue && notefreq < ClosestToSlotWithoutGoingOver)
                        {
                            ClosestToSlotWithoutGoingOver = notefreq;
                            sortid = j;
                        }
                    }
                    SortedNoteSlotValue = ClosestToSlotWithoutGoingOver;
                    NotesB[i] = NotesB[i] * float4(1, 1, 0, 1) + float4(0, 0, sortid, 0);
                }

                // We now have a condensed list of all Notes that are playing.
                if( coordinateLocal.x == 0 )
                {
                    // Summary note.
                    return (coordinateLocal.y) ? NewNoteSummaryB : NewNoteSummary;
                }
                else
                {
                    // Actual Note Data
                    return (coordinateLocal.y) ? NotesB[coordinateLocal.x - 1] : Notes[coordinateLocal.x - 1];
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
                AUDIO_LINK_ALPHA_START(ALPASS_AUTOCORRELATOR)
                uint i;

                #define EMAXBIN 120
                #define EBASEBIN 0

                float PlaceInWave = (float)coordinateLocal.x;
                float2 fvtot = 0;
                float fvr = 15.;

                // This computes both the regular autocorrelator in the R channel
                // as well as a uncorrelated autocorrelator in the G channel
                for(i = EBASEBIN; i < EMAXBIN; i++)
                {
                    float Bin = GetSelfPixelData(ALPASS_DFT + uint2( i%128, i/128)).b;
                    float freq = pow(2, i/24.) * _BottomFrequency / _SamplesPerSecond * 3.14159 * 2.;
                    float2 csv = float2(cos(freq * PlaceInWave * fvr ), cos(freq * PlaceInWave * fvr + i * .32));
                    csv.g *= step(i % 4, 1) * 4.;
                    fvtot += csv * (Bin * Bin);
                }

                return float4(fvtot, 0, 1);
            }
            ENDCG
        }

        Pass
        {
            Name "Pass8-ColorChord-Linear"
            CGPROGRAM
            
            float4 frag (v2f_customrendertexture IN) : SV_Target
            {
                AUDIO_LINK_ALPHA_START(ALPASS_CCSTRIP)

                int p;
                
                const float Brightness = .3;
                const float RootNote = 0;
                
                float4 NotesSummary = GetSelfPixelData(ALPASS_CCINTERNAL);

                float TotalPower = 0.0;
                TotalPower = NotesSummary.y;
                

                float PowerPlace = 0.0;
                for(p = 0; p < CCMAXNOTES; p++)
                {
                    float4 NotesB = GetSelfPixelData(ALPASS_CCINTERNAL + int2(1 + p, 1));
                    float4 Peak = GetSelfPixelData(ALPASS_CCINTERNAL + int2(1 + NotesB.z, 0));
                    if(Peak.y <= 0) continue;

                    float Power = Peak.y/TotalPower;
                    PowerPlace += Power;
                    if(PowerPlace >= IN.globalTexcoord.x) 
                    {
                        return float4(CCtoRGB(Peak.x, Peak.a*Brightness, _RootNote), 1.0);
                    }
                }
                
                return float4(0., 0., 0., 1.);
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

            float SetNewCellValue(float a)
            {
                return a*.5;
            }


            float4 frag(v2f_customrendertexture IN) : SV_Target
            {
                AUDIO_LINK_ALPHA_START(ALPASS_CCLIGHTS)
                
                float4 NotesSummary = GetSelfPixelData(ALPASS_CCINTERNAL);
                
                #define NOTESUFFIX(n) n.y       //was pow(n.z, 1.5)
                
                float4 ComputeCell = GetSelfPixelData(ALPASS_CCLIGHTS + int2(coordinateLocal.x, 1));
                //ComputeCell
                //    .x = Mated Cell # (Or -1 for black)
                //    .y = Minimum Brightness Before Jump
                //    .z = ???
                
                float4 ThisNote = GetSelfPixelData(ALPASS_CCINTERNAL + int2(ComputeCell.x + 1, 0));
                //  Each element:
                //   R: Peak Location (Note #)
                //   G: Peak Intensity
                //   B: Calm Intensity
                //   A: Other Intensity
                
                ComputeCell.y -= _PickNewSpeed * 0.01;


                if(NOTESUFFIX(ThisNote) < ComputeCell.y || ComputeCell.y <= 0 || ThisNote.z < 0)
                {
                    //Need to select new cell.
                    float min_to_acquire = tinyrand(float3(coordinateLocal.xy, _Time.x));
                    
                    int n;
                    float4 SelectedNote = 0.;
                    int SelectedNoteNo = -1;
                    
                    float cumulative = 0.0;
                    for(n = 0; n < CCMAXNOTES; n++)
                    {
                        float4 Note = GetSelfPixelData(ALPASS_CCINTERNAL + int2(n + 1, 0));
                        float unic = NOTESUFFIX(Note);
                        if(unic > 0)
                            cumulative += unic;
                    }

                    float sofar = 0.0;
                    for(n = 0; n < CCMAXNOTES; n++)
                    {
                        float4 Note = GetSelfPixelData(ALPASS_CCINTERNAL + int2(n + 1, 0));
                        float unic = NOTESUFFIX(Note);
                        if( unic > 0 ) 
                        {
                            sofar += unic;
                            if(sofar/cumulative > min_to_acquire)
                            {
                                SelectedNote = Note;
                                SelectedNoteNo = n;
                                break;
                            }
                        }
                    }
                
                    if(SelectedNote.z > 0.0)
                    {
                        ComputeCell.x = SelectedNoteNo;
                        ComputeCell.y = SetNewCellValue(NOTESUFFIX(SelectedNote));
                    }
                    else
                    {
                        ComputeCell.x = 0;
                        ComputeCell.y = 0;
                    }
                }
                
                ThisNote = GetSelfPixelData(ALPASS_CCINTERNAL + int2(ComputeCell.x + 1, 0));

                if(coordinateLocal.y < 0.5)
                {
                    // the light color output
                    if(ComputeCell.y <= 0)
                    {
                        return 0.;
                    }
                    
                    //XXX TODO: REVISIT THIS!! Ths is an arbitrary value!
                    float intensity = ThisNote.a/3;
                    return float4(CCtoRGB(glsl_mod(ThisNote.x,48.0 ),intensity, _RootNote), 1.0);
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
