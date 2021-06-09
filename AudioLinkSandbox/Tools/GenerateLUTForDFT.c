#!tcc -run GenerateLUTForDFT.cabs

#include <stdio.h>
#include <math.h>
#include "unitytexturewriter.h"

#define AUDIOLINK_SAMPHIST (4092/2)
float asset2d[256][AUDIOLINK_SAMPHIST][4] = {0};

#define AUDIOLINK_EXPBINS 24
#define AUDIOLINK_BOTTOM_FREQUENCY 13.75
#define AUDIOLINK_SPS 48000.0
#define UNITY_TWO_PI (3.141592653589*2)
#define AUDIOLINK_DFT_Q 4.0

float max( float a, float b ) { return (a>b)?a:b; }

int main()
{
	int note = 0;
	for( note = 0; note < 256; note++ )
//	note = 120;
	{
		float phaseDelta = pow(2, (note)/((float)AUDIOLINK_EXPBINS));
		phaseDelta = ((phaseDelta * AUDIOLINK_BOTTOM_FREQUENCY) / AUDIOLINK_SPS) * UNITY_TWO_PI * 2.; // 2 here because we're at 24kSPS                          
		float halfWindowSize = AUDIOLINK_DFT_Q / (phaseDelta / UNITY_TWO_PI);
		float phase = 0;
		
		int p;
		float sumtotalrms = 0;
		float this_window_strength = 1;
		const float window_falloff = .6;
		for( p = 0; halfWindowSize > 1;  )
		{
			float sincostot[2] = { 0 };
			float sc;
			float localphase = phase;
			float windowtot = 0;
			float shift;
			int framesleft = AUDIOLINK_SAMPHIST - p - 1;
			if( halfWindowSize*2 >= framesleft ) halfWindowSize = framesleft / 2;
			
			//Figure out what the sine/cosine would look like.
			for( sc = 0; sc < halfWindowSize*2; sc++ )
			{
                float window = max(0, halfWindowSize - abs(sc - halfWindowSize ) ) * this_window_strength;
				sincostot[0] += sin( localphase ) * window;
				sincostot[1] += cos( localphase ) * window;
				localphase += phaseDelta;
				windowtot += window;
			}
			
			//We have to correct for the total window size & offset.
			printf( "WT: %f\n", windowtot );
			float shifts[2] = { -sincostot[0] / ( windowtot ), -sincostot[1] / ( windowtot ) };
			sincostot[0] = 0;
			sincostot[1] = 0;
			localphase = phase;
			windowtot = 0;
			for( sc = 0; sc < halfWindowSize*2; sc++ )
			{
                float window = max(0, halfWindowSize - abs(sc - halfWindowSize ) ) * this_window_strength;
				float s = (sin( localphase ) + shifts[0]) * window;
				float c = (cos( localphase ) + shifts[1]) * window;
				sincostot[0] += s;
				sincostot[1] += c;
				asset2d[note][(int)(p+sc)][0] = s;
				asset2d[note][(int)(p+sc)][1] = c;
				asset2d[note][(int)(p+sc)][2] = 1;
				asset2d[note][(int)(p+sc)][3] = 0;
				sumtotalrms += sqrt(s*s+c*c);
				localphase += phaseDelta;
				windowtot += window;
			}
			//For last frame in window, we want to collapse the phasor. 
			asset2d[note][(int)(p+sc-1)][2] = 0;
			asset2d[note][(int)(p+sc-1)][3] = 1;
			printf( "%d %f %f\n", (int)(p+sc-1), sincostot[0], sincostot[1]) ;
			p += sc;
			phase = localphase;
			this_window_strength *= window_falloff;
		}
		for( ; p < AUDIOLINK_SAMPHIST; p++ )
		{
			asset2d[note][(int)(p)][0] = 0;
			asset2d[note][(int)(p)][1] = 0;
			asset2d[note][(int)(p)][2] = 0;
			asset2d[note][(int)(p)][3] = 0;
		}
		if( sumtotalrms > 0. )
		{
			for( p = 0; p < AUDIOLINK_SAMPHIST; p++ )
			{
				asset2d[note][p][0] /= sumtotalrms;
				asset2d[note][p][1] /= sumtotalrms;
			}
		}
	}
	WriteUnityImageAsset( "tex_AudioLinkLUTForDFT.asset", asset2d, sizeof(asset2d), AUDIOLINK_SAMPHIST, 256, 0, UTE_RGBA_FLOAT );
}