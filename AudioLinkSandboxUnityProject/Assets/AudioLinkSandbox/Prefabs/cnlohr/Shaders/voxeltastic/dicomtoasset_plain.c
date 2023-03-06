//Only for personal use.  Not intended for medical diagnosis or anything else.

// tcc dicomtoasset_plain.c
//
// Convert .bin (raw byte-grid) to 3D texture asset.

#include <stdio.h>
#include <stdlib.h>
#include "unitytexturewriter.h"

int main( int argc, const char ** argv )
{
	if( argc != 6 )
	{
		fprintf( stderr, "Usage: dicomtoasset out_file_name.asset size_x size_y nr_of_files file_start_offset\nExpected: I#####" );
		return -1;
	}

	int sx = atoi( argv[2] );
	int sy = atoi( argv[3] );
	int sz = atoi( argv[4] );
	int fso = atoi( argv[5] );
	if( sx == 0 || sy == 0 || sz == 0 )
	{
		fprintf( stderr, "Error: all axes must be nonzero numbers.\n" );
		return -3;
	}
	int total = sx * sy * sz;
	uint8_t * asset3d = malloc(total);

	int z;
	int bytes = sx*sy*2;
	for( z = 0; z < sz; z++ )
	{
		char fin[128];
		sprintf( fin, "i%05d", z+fso );
		FILE * f = fopen( fin, "rb" );
		if( !f || ferror( f ) )
		{
			fprintf( stderr, "Error: could not open file \"%s\"\n", fin );
			return -2;
		}
		fseek( f, 0, SEEK_END );
		int len = ftell( f );
		if( len < bytes )
		{
			fprintf( stderr, "Error: File too small.\n" );
			return -5;
		}
		fseek( f, len - bytes, SEEK_SET );
		int x, y;
		for( y = 0; y < sy; y++ )
			for( x = 0; x < sx; x++ )
			{
				int16_t temp;
				int r = fread( &temp, 1, 2, f );
				temp/=4;
				if( r != 2 )
				{
					fprintf( stderr, "Error reading all bytes needed (%d/%d)\n", r, total );
					return -4;
				}
				if( temp < 0 ) temp = 0;
				if( temp > 255 ) temp = 255;
				asset3d[x+y*sx+z*sx*sy] = temp;
			}
		printf( "Loaded slice %d\n", z );
	}
	char outfilename[1031];
	snprintf( outfilename, 1030, "%s.asset", argv[1] );
	printf( "Writing: %s\n", outfilename );
	WriteUnityImageAsset( outfilename, asset3d, sx*sy*sz, sx, sy, sz, UTE_ALPHA8 | UTE_FLAG_IS_3D );
	printf( "Write complete %d\n", z );
}