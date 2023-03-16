//Only for personal use.  Not intended for medical diagnosis or anything else.

// tcc pnmtoasset.c -run
//
// Convert .bin (raw byte-grid) to 3D texture asset.

#include <stdio.h>
#include <stdlib.h>
#include "unitytexturewriter.h"

int main( int argc, const char ** argv )
{
	if( argc != 4 )
	{
		fprintf( stderr, "Usage: pnmtoasset out_file_name.asset nr_of_files file_start_offset\nExpected: I#####" );
		return -1;
	}

	int total;
	uint8_t * asset3d;
	
	int z_ofs = 0;
	
	int sx = -1;
	int sy = -1;
	int sz = atoi( argv[2] );
	int fso = atoi( argv[3] );
	if( sx == 0 || sy == 0 || sz == 0 )
	{
		fprintf( stderr, "Error: all axes must be nonzero numbers.\n" );
		return -3;
	}

	int z;
	uint16_t * block = 0;
	for( z = 0; z < sz; z++ )
	{
		char fin[128];
		int lx, ly;
		int depth;
		sprintf( fin, "o%07d.pnm", z+fso );
		char fmt[128];
		FILE * f = fopen( fin, "rb" );
		printf( "Open: %s = %p\n", fin, f );
		fscanf( f, "%127s\n", fmt );
		fscanf( f, "%d %d\n", &lx, &ly );
		fscanf( f, "%d\n", &depth );
		if( lx == 0 || ly == 0 ) { fprintf( stderr, "Error: cannot open %s\n", fin ); exit( 6 ); }
		if( depth != 65535 ) { fprintf( stderr, "Error: depth not valid.\n" ); exit( 7 ); }
		if( !block ) block = malloc( lx * ly * 2 );
		
		if( sx == -1 )
		{
			sx = lx;
			sy = ly;
			total = sx * sy * sz;
			asset3d = malloc(total);
		}
		else
		{
			if( sx != lx || sy != ly )
			{
				fprintf( stderr, "Error: different size file at %s\n", fin );
			}
		}
		
		printf( "Reading slice [%d x %d]\n", sx, sy );
		int r = fread( block, sx, sy*2, f );
		printf( "Read %d rows\n", r );
		fclose( f );

		int x, y;
		for( y = 0; y < sy; y++ )
		{
			for( x = 0; x < sx; x++ )
			{
				uint16_t temp = block[x+y*sx]%256;
				if( temp < 0 ) temp = 0;
				if( temp > 255 ) temp = 255;
				//if( z == 0 )
				//	temp = x;
				asset3d[x+y*sx+((z+z_ofs)%sz)*sx*sy] = temp;
			}
		}
		printf( "Loaded slice %d\n", z );
	}
	char outfilename[1031];
	snprintf( outfilename, 1030, "%s.asset", argv[1] );
	printf( "Writing: %s\n", outfilename );
	WriteUnityImageAsset( outfilename, asset3d, sx*sy*sz, sx, sy, sz, UTE_ALPHA8 | UTE_FLAG_IS_3D );
	printf( "Write complete %d\n", z );
}