
#define _BallpitCameraHeight 20
#define MAX_BALLS 32768
#define CAMERA_Y_OFFSET -1
#define REPEL_MODE_NEW false


texture2D< float4 > _PositionsIn;
texture2D< float4 > _VelocitiesIn;
texture2D< float4 > _ColorsIn;
texture2D< float4 > _Adjacency0;

float4 _PositionsIn_TexelSize;
float4 _VelocitiesIn_TexelSize;
float4 _ColorsIn_TexelSize;
float4 _Adjacency0_TexelSize;

float4 GetPosition( uint ballid )
{
	return _PositionsIn[uint2(ballid%1024,ballid/1024)];
}

float4 GetVelocity( uint ballid )
{
	return _VelocitiesIn[uint2(ballid%1024,ballid/1024)];
}

float4 GetColorTex( uint ballid )
{
	return _ColorsIn[uint2(ballid%1024,ballid/1024)];
}


//NOTE BY CNL: Doing a hash appears to peform much worse than
// a procedural path, not in speed (though that's true) but it gets worse collisions.
//#define ACTUALLY_DO_COMPLEX_HASH_FUNCTION 1
//The size of each hashed bucket.

//@ .9 -> Tested: 9 is good, 8 oooccasssionallyyy tweaks.  10 is cruising.
//@ .8 -> Tested: 10 is almost perfect ... switch to 11 (if on 10M edge cube)
//@ .8 -> Tested: 9 is almost perfect on cylinder... But needs to be 10.
//
//NOTE: The combination of these settings are very carefully selected.
// HashCellRange effectively defines 1/size of cell in meters.
// Too many balls in one cell (too low a number) and you may lose balls.
// Too few and you may need to increase your search area.  Increasing
// SearchExtents incurs an O(n^3) performance impact.
//
// We actually can cull off corners of the search area a little. So, if
// we are outside the SeachExtentsRange, we know we can't have an intersection.
//
// If we have extra bins we can check per cell, but, this is a function of
// how many times we run the adjacency algorithm.  For this implementation
// we will always have 2.

// Current test for r = 0.1m
// @ 7,7,7 extents, sometimes we get balls popping around because we have
//   too many balls in one cell.
// @ 14,14,14 it becomes unstable, regardless of SeachExtentsRange because
//   the search radius is insufficient.
// @ 11,11,11 SeachExtentsRange=2.5 is on the hiary edge of insuficient.  Selecting 2.6?
//
//AT 10,10,10::2.4 NOT OK; 2.45 OK. (range of 6) ... Setting to range of sqrt(7) to be safe.

static const float3 HashCellRange = float3( 10,10,10 );
static const int SearchExtents = 2;
#define MAX_BINS_TO_CHECK 2
static const float SeachExtentsRange = 2.7; 

uint2 Hash3ForAdjacency( float3 rlcoord )
{
	//This may be a heavy handed hash algo.  It's currently 8 instructions.
	// Thanks, @D4rkPl4y3r for suggesting the hash buckets.

#if ACTUALLY_DO_COMPLEX_HASH_FUNCTION == 1
	//VERY BAD HASH
	static const uint3 xva = uint3( 7919, 1046527, 37633 );
	static const uint3 xvb = uint3( 7569, 334, 19937 );
	uint3 rlc = uint3( rlcoord * HashCellRange + HashCellRange * 100 );
	uint3 hva = xva * rlc;
	uint3 hvb = xvb * rlc;
	return uint2( hva.x+hva.y+hva.z, hvb.x+hvb.y+hvb.z) % 1024;
#else
	//OK but not graet hash.
	//Offset by 142 to prevent the value from ever going negative, also
	//it's pretty cause it puts the balls in the center of the hash texture.
	uint3 normcoord = int3( (rlcoord+127)*HashCellRange );
	return ( uint2( normcoord.x, normcoord.z ) + uint2( normcoord.y % 6, normcoord.y / 6 ) * 170 ) % 1024;
#endif
}