// tcc bintoasset.c -run
//
// Convert .bin (raw byte-grid) to 3D texture asset.

#include <stdio.h>
#include <stdlib.h>
#include "unitytexturewriter.h"

int main( int argc, const char ** argv )
{
	if( argc != 5 )
	{
		fprintf( stderr, "Usage: bintoasset file.bin size_x size_y size_z\n" );
		return -1;
	}
	const char * filename = argv[1];
	int sx = atoi( argv[2] );
	int sy = atoi( argv[3] );
	int sz = atoi( argv[4] );
	FILE * f = fopen( filename, "rb" );
	if( !f || ferror( f ) )
	{
		fprintf( stderr, "Error: could not open file \"%s\"\n", filename );
		return -2;
	}
	if( sx == 0 || sy == 0 || sz == 0 )
	{
		fprintf( stderr, "Error: all axes must be nonzero numbers.\n" );
		return -3;
	}

	int total = sx * sy * sz;
	uint8_t * asset3d = malloc(total);
	int r = fread( asset3d, 1, total, f );
	if( r != total )
	{
		fprintf( stderr, "Error reading all bytes needed (%d/%d)\n", r, total );
		return -4;
	}
	char outfilename[1031];
	snprintf( outfilename, 1030, "%s.asset", filename );
	WriteUnityImageAsset( outfilename, asset3d, sx*sy*sz, sx, sy, sz, UTE_ALPHA8 | UTE_FLAG_IS_3D );
}