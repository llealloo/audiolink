Shader "AudioLink/AudioLinkSpectrumUI"
{
    Properties
    {
        _AudioLinkTexture ("Texture", 2D) = "white" {}

        _SpectrumGain ("Spectrum Gain", Float) = 1.
        _SeparatorColor ("Seperator Color", Color) = (.5,.5,0.,1.)

        _SpectrumFixedColor ("Spectrum Fixed color", Color) = (.9, .9, .9,1.)
        _BaseColor ("Base Color", Color) = (0, 0, 0, 0)
        _UnderSpectrumColor ("Under-Spectrum Color", Color) = (1, 1, 1, .1)

        _SpectrumVertOffset( "Spectrum Vertical OFfset", Float ) = 0.0
        _SpectrumThickness ("Spectrum Thickness", Float) = .01

        _SegmentThickness("Segment Thickness", Float) = .01
        _SegmentColor("Segment Color", Color) = (.5,.5,0.,1.)
        _ThresholdThickness("Threshold Bar Thickness", Float) = .01
        _ThresholdDottedLine("Threshold Dotted Line Width", Float) = .001
        _ThresholdColor("Threshold Color", Color) = (.5,.5,0.,1.)


        _Band0Color ("Band 0 Color", Color) = (.5,.5,0.,1.)
        _Band1Color ("Band 1 Color", Color) = (.5,.5,0.,1.)
        _Band2Color ("Band 2 Color", Color) = (.5,.5,0.,1.)
        _Band3Color ("Band 3 Color", Color) = (.5,.5,0.,1.)
        _BandDelayPulse("Band Delay Pulse", Float) = 0.1
        _BandDelayPulseOpacity("Band Delay Pulse", Float) = 0.5

        _FreqFloor("Frequency Floor", Range(0, 1)) = 0
        _FreqCeiling("Frequency Ceiling", Range(0, 1)) = 1

        _X0("X0", Range(0.0, 0.168)) = 0.0
        _X1("X1", Range(0.242, 0.387)) = 0.25
        _X2("X2", Range(0.461, 0.628)) = 0.5
        _X3("X3", Range(0.704, 0.953)) = 0.75

        _Threshold0("Threshold 0", Range(0.0, 1.0)) = 0.45
        _Threshold1("Threshold 1", Range(0.0, 1.0)) = 0.45
        _Threshold2("Threshold 2", Range(0.0, 1.0)) = 0.45
        _Threshold3("Threshold 3", Range(0.0, 1.0)) = 0.45
        
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
            
            #define glsl_mod(x,y) (((x)-(y)*floor((x)/(y))))
            #define EXPBINS 24
            #define EXPOCT 10
            #define ETOTALBINS (EXPOCT*EXPBINS)         

            #define _RootNote 0

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
            uniform float4 _AudioLinkTexture_TexelSize;

            // usually {0, 256, 512, 768} by default
            //uniform float _AudioBands[4];
            // usually {0.5, 0.5, 0.5, 0.5} by default
            //uniform float _AudioThresholds[4];

            uniform float _FreqFloor;
            uniform float _FreqCeiling;

            uniform float _X0;
            uniform float _X1;
            uniform float _X2;
            uniform float _X3;

            uniform float _Threshold0;
            uniform float _Threshold1;
            uniform float _Threshold2;
            uniform float _Threshold3;
            
            float _SpectrumGain;
            float _SpectrumColorMix;
            float4 _SeparatorColor;
            float _SpectrumThickness;
        
            float4 _SpectrumFixedColor;
            float4 _BaseColor;
            float4 _UnderSpectrumColor;
            
            float _SpectrumVertOffset;
            float _SegmentThickness;
            float _ThresholdThickness;
            float _ThresholdDottedLine;
            float4 _ThresholdColor;
            float4 _SegmentColor;

            float4 _Band0Color;
            float4 _Band1Color;
            float4 _Band2Color;
            float4 _Band3Color;

            float _BandDelayPulse;
            float _BandDelayPulseOpacity;


            

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
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
            
            float4 GetAudioPixelData( int2 pixelcoord )
            {
                return tex2D( _AudioLinkTexture, float2( pixelcoord*_AudioLinkTexture_TexelSize.xy) );
            }

            float Remap(float t, float a, float b, float u, float v)
            {
                return ( (t-a) / (b-a) ) * (v-u) + u;
            }
            
            fixed4 frag (v2f IN) : SV_Target
            {
                float2 iuv = IN.uv;


                float audioBands[4] = {_X0, _X1, _X2, _X3};
                float audioThresholds[4] = {_Threshold0, _Threshold1, _Threshold2, _Threshold3};

                float4 intensity = 0;

                uint totalBins = EXPBINS * EXPOCT;

                uint noteno = Remap(iuv.x, 0., 1., _FreqFloor * totalBins, _FreqCeiling * totalBins); //iuv.x * EXPBINS * EXPOCT; 
                float notenof = Remap(iuv.x, 0., 1., _FreqFloor * totalBins, _FreqCeiling * totalBins); //iuv.x * EXPBINS * EXPOCT;
                //int readno = noteno % EXPBINS;
                //float readnof = fmod( notenof, EXPBINS );
                //int reado = (noteno/EXPBINS);
                //float readof = notenof/EXPBINS;

                {
                    float4 spectrum_value_lower  =  tex2D(_AudioLinkTexture, float2((fmod(noteno,128))/128.,((noteno/128)/64.+4./64.)) );
                    float4 spectrum_value_higher =  tex2D(_AudioLinkTexture, float2((fmod((noteno+1),128))/128.,(((noteno+1)/128)/64.+4./64.)) );
                    intensity = lerp(spectrum_value_lower, spectrum_value_higher, frac(notenof) )* _SpectrumGain;
                }

                intensity.x *= 1.;
                intensity.y *= 1.;
            
                float4 c = _BaseColor;

                // Band segments
                float segment = 0.;
                for (int i=0; i<4; i++)
                {
                    segment += saturate(_SegmentThickness - abs(iuv.x - audioBands[i])) * 1000.;
                }

                segment = saturate(segment) * _SegmentColor;

                // Band threshold lines
                //float totalBins = EXPBINS * EXPOCT;
                float threshold = 0;
                float minHeight = 0.186;
                float maxHeight = 0.875
                ;
                int band = 0;
                for (int j=1; j<4; j++)
                {
                    band += (iuv.x > audioBands[j]);
                }
                for (int k=0; k<4; k++)
                {
                    threshold += (band == i) * saturate(_ThresholdThickness - abs(iuv.y - lerp(minHeight, maxHeight, audioThresholds[k]))) * 1000.;
                }

                threshold = saturate(threshold) * _ThresholdColor * (1. - round((iuv.x % _ThresholdDottedLine) / _ThresholdDottedLine));
                threshold *= (iuv.x > _X0);


                // Colored areas
                float4 bandColor = 0;
                bandColor += (band == 0) * _Band0Color;
                bandColor += (band == 1) * _Band1Color;
                bandColor += (band == 2) * _Band2Color;
                bandColor += (band == 3) * _Band3Color;

                bandColor *= (iuv.x > _X0);

                float bandIntensity = tex2D(_AudioLinkTexture, float2(0., (float)band * 0.015625));
                
                // Under-spectrum first
                float rval = clamp( _SpectrumThickness - iuv.y + intensity.g + _SpectrumVertOffset, 0., 1. );
                rval = min( 1., 1000*rval );
                c = lerp( c, _UnderSpectrumColor, rval * _UnderSpectrumColor.a );
                
                // Spectrum-Line second
                rval = max( _SpectrumThickness - abs( intensity.g - iuv.y + _SpectrumVertOffset), 0. );
                rval = min( 1., 1000*rval );
                rval *= (iuv.x > _X0);
                c = lerp( c, _SpectrumFixedColor, rval * bandIntensity );

                // Pulse
                //float4 pulse = tex2D(_AudioLinkTexture, float2(iuv.y * _BandDelayPulse, (float)band * 0.015625)) * _BandDelayPulseOpacity * bandColor;


                // Overlay blending mode
                float4 a = c;
                float4 b = bandColor;
                if (0.2 * a.r + 0.7 * a.g + 0.1 * a.b < 0.5)
                {
                    c = 2. * a * b;
                } else {
                    c = 1. - 2. * (1. - a) * (1. - b);
                }
                

                return (segment + threshold) * _SeparatorColor + c;

                //Graph-based spectrogram.
            }
            ENDCG
        }
    }
}
