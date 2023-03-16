#include <stdio.h>
#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"

//You can use other sizes. On most objects, maps as small as 64x64 are ok.
//For larger non-repeating areas, use a larger texture.

#define NOISEBIGX 64
#define NOISEBIGY 64

//From Wikipedia LFSR page.
unsigned lfsr2(void)
{
    static uint32_t start_state = 0x1u;  // Any nonzero start state 
    static uint32_t lfsr = 0x1u;
    unsigned period = 0;

	unsigned lsb = lfsr & 1u;  // Get LSB (i.e., the output bit).
	lfsr >>= 1;                // Shift register
	if (lsb)                   // If the output bit is 1,
		lfsr ^= (1<<19)|(1<<16);       //  apply toggle mask.
		//Polynomial #20 on Wikipedia, period of 1,048,575 
	++period;

    return lfsr;
}
uint8_t lfsru8()
{
	uint8_t ret = 0;
	int i;
	for( i = 0; i < 8; i++ )
	{
		ret |= lfsr2() & 1;
		ret <<= 1;
	}
	return ret;
}

int main()
{
	uint8_t NoiseBig[NOISEBIGX*NOISEBIGY][4];   //This is a regular white noise texture.
	uint8_t NoiseBig1D[NOISEBIGX*NOISEBIGY][4]; //This one lets you use the 1D commands.

	uint8_t * NoiseAll = (uint8_t*)NoiseBig;
	uint8_t * NoiseOffset = (uint8_t*)NoiseBig1D;
	int x,y;
	for( y = 0; y < NOISEBIGY; y++ )
	for( x = 0; x < NOISEBIGX; x++ )
	{
		NoiseAll[(x+y*NOISEBIGX)*4+0] = lfsru8();
		NoiseAll[(x+y*NOISEBIGX)*4+1] = lfsru8();
		NoiseAll[(x+y*NOISEBIGX)*4+2] = lfsru8();
		NoiseAll[(x+y*NOISEBIGX)*4+3] = lfsru8();
	}
	
	for( y = 0; y < NOISEBIGY; y++ )
	for( x = 0; x < NOISEBIGX; x++ )
	{
		NoiseOffset[(x+y*NOISEBIGX)*4+0] = NoiseAll[(((x+0     +256)%NOISEBIGX)+((y+0     +256)%NOISEBIGY)*NOISEBIGX)*4+0];
		NoiseOffset[(x+y*NOISEBIGX)*4+1] = NoiseAll[(((x+51    +256)%NOISEBIGX)+((y-111   +256)%NOISEBIGY)*NOISEBIGX)*4+0];
		NoiseOffset[(x+y*NOISEBIGX)*4+2] = NoiseAll[(((x+103   +256)%NOISEBIGX)+((y-61    +256)%NOISEBIGY)*NOISEBIGX)*4+0];
		NoiseOffset[(x+y*NOISEBIGX)*4+3] = NoiseAll[(((x+51+103+256)%NOISEBIGX)+((y-61-111+256)%NOISEBIGY)*NOISEBIGX)*4+0];
	}
	int l = stbi_write_png("noisebig.png", NOISEBIGX,NOISEBIGY, 4, NoiseBig, NOISEBIGX*4);
	l = stbi_write_png("tanoise.png", NOISEBIGX,NOISEBIGY, 4, NoiseBig1D, NOISEBIGX*4);
}