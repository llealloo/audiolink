//Only for personal use.  Not intended for medical diagnosis or anything else.

// tcc pnmtoasset.c -run
//
// Convert .bin (raw byte-grid) to 3D texture asset.

#include <stdio.h>
#include <stdlib.h>
#include "unitytexturewriter.h"
#define outx 256
#define outz 180
#define outy 256
uint8_t data[outx*outy*outz];

int main( int argc, const char ** argv )
{
	int x, y, z;
	for( z = 0; z < 180; z++ )
	{
		char sfn[256];
		sprintf( sfn, "%d", z*2 );
		FILE * f = fopen( sfn, "rb" );
		printf( "%d %p %s\n", z, f, sfn );
		uint16_t thisfile[512*512];
		fread( thisfile, sizeof(thisfile), 1, f );
		fclose( f );
		for( y = 0; y < 256; y++ )
		for( x = 0; x < 256; x++ )
		{
			uint32_t sum = 0;
			sum += thisfile[(x*2+0)+(y*2)*512]/256;
			sum += thisfile[(x*2+1)+(y*2)*512]/256;
			sum += thisfile[(x*2+0)+(y*2+1)*512]/256;
			sum += thisfile[(x*2+1)+(y*2+1)*512]/256;
			sum /= 4;
			data[x+y*256+z*256*256] = sum;
		}
	}
	WriteUnityImageAsset( "bunny.asset", data, outx*outy*outz, outx, outy, outz, UTE_ALPHA8 | UTE_FLAG_IS_3D );
	printf( "Write complete %d\n", z );
}