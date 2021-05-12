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
            uniform float _AudioBands[4];
            // usually {0.5, 0.5, 0.5, 0.5} by default
            uniform float _AudioThresholds[4];
            
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
            
            fixed4 frag (v2f IN) : SV_Target
            {
                float2 iuv = IN.uv;

                float4 intensity = 0;

                int noteno = iuv.x * EXPBINS * EXPOCT;
                float notenof = iuv.x * EXPBINS * EXPOCT;
                int readno = noteno % EXPBINS;
                float readnof = fmod( notenof, EXPBINS );
                int reado = (noteno/EXPBINS);
                float readof = notenof/EXPBINS;

                intensity = forcefilt(_AudioLinkTexture, _AudioLinkTexture_TexelSize, 
                     float2((fmod(notenof,128))/128.,((noteno/128)/64.+4./64.)) ) * _SpectrumGain;
                
                intensity.x *= 1.;
                intensity.y *= 1.;
            
                float4 c = _BaseColor;

                // Band segments
                float segment = 0.;
                for (int i=1; i<4; i++)
                {
                    segment += saturate(_SegmentThickness - abs(iuv.x - _AudioBands[i]/1024.)) * 1000.;
                }
                //segment += saturate(_SegmentThickness - abs(iuv.x - _AudioBands[1]/1024.)) * 1000.;
                //segment += saturate(_SegmentThickness - abs(iuv.x - _AudioBands[2]/1024.)) * 1000.;
                //segment += saturate(_SegmentThickness - abs(iuv.x - _AudioBands[3]/1024.)) * 1000.;

                segment = saturate(segment) * _SegmentColor;

                // Band threshold lines
                float threshold = 0;
                float minHeight = 0.21;
                float maxHeight = 0.85;
                int band = 0;
                for (int i=1; i<4; i++)
                {
                    band += (iuv.x > _AudioBands[i]/1024.);
                }
                for (int i=0; i<4; i++)
                {
                    threshold += (band == i) * saturate(_ThresholdThickness - abs(iuv.y - lerp(minHeight, maxHeight, _AudioThresholds[i]))) * 1000.;
                }
                //threshold += (band == 0) * saturate(_ThresholdThickness - abs(iuv.y - lerp(minHeight, maxHeight, _AudioThresholds[0]))) * 1000.;
                //threshold += (band == 1) * saturate(_ThresholdThickness - abs(iuv.y - lerp(minHeight, maxHeight, _AudioThresholds[1]))) * 1000.;
                //threshold += (band == 2) * saturate(_ThresholdThickness - abs(iuv.y - lerp(minHeight, maxHeight, _AudioThresholds[2]))) * 1000.;
                //threshold += (band == 3) * saturate(_ThresholdThickness - abs(iuv.y - lerp(minHeight, maxHeight, _AudioThresholds[3]))) * 1000.;

                threshold = saturate(threshold) * _ThresholdColor * (1. - round((iuv.x % _ThresholdDottedLine) / _ThresholdDottedLine));


                // Colored areas
                float4 bandColor = 0;
                bandColor += (band == 0) * _Band0Color;
                bandColor += (band == 1) * _Band1Color;
                bandColor += (band == 2) * _Band2Color;
                bandColor += (band == 3) * _Band3Color;



                //segment = round(segment);

                //float3 vertical_bars = max(0.,1.3-length(readnof-1.3) );
                //c += float4( vertical_bars * _SeparatorColor, 1. );
                
                //Under-spectrum first
                float rval = clamp( _SpectrumThickness - iuv.y + intensity.z + _SpectrumVertOffset, 0., 1. );
                rval = min( 1., 1000*rval );
                c = lerp( c, _UnderSpectrumColor, rval * _UnderSpectrumColor.a );
                
                //Spectrum-Line second
                rval = max( _SpectrumThickness - abs( intensity.z - iuv.y + _SpectrumVertOffset), 0. );
                rval = min( 1., 1000*rval );
                c = lerp( c, _SpectrumFixedColor, rval );

                // float4 c;

                // Overlay blending mode
                float4 a = c;
                float4 b = bandColor;
                if (length(a) < 0.5)
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
