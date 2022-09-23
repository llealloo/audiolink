# tanoise

Texture-assisted, extremely fast smooth multidimensional noise.

tanoise -> Extremely fast noise that does repeat, but "feels" like perlin noise... Ok, not perlin but smooth noise.  It can be used like perlin noise in many applications. Rewritten to avoid license issues.

![Demo Image](https://raw.githubusercontent.com/cnlohr/shadertrixx/main/Assets/tanoise/demo.png)

Above is a picture of it in-use, with 4 layers are only 4 texture lookups and a handful of calls.  The above is shaded with:

```hlsl
	col = tanoise3_1d( pos.xyz*20. ) * 0.5 +
	tanoise3_1d( pos.xyz*40.1 ) * 0.25 +
	tanoise3_1d( pos.xyz*80.1 ) * 0.125 +
	tanoise3_1d( pos.xyz*160.1 ) * .125;
	col = pow( col.rrrr, 1.8); //Fix gamma
```

Usage:
* For normal (not 1D) lookups, just use any white noise map.
* For 1D Output textures, you will need an offset texture map.
* For 4D->1D and 3D->2D Lookups, you will need to make sure SRGB on your tex is OFF!
* For 3D->1D Lookups, it only uses the .r and .g channels of the texture.
* There is a possible benefit to using tanoise2,3,4 on an 1-channel texture in that you could make it larger to support less repeating. 

```hlsl
float4 tanoise4( in float4 x )    //4 Texture Lookups
float tanoise4_1d( in float4 x )  //1 Texture Lookup
float4 tanoise3( in float3 x )    //2 Texture Lookups
float tanoise3_1d( in float3 x )  //1 Texture Lookup
float2 tanoise3_2d( in float3 x ) //1 Texture Lookup
float4 tanoise2( in float2 x )    //1 Texture Lookup
```

The texture should be the noise texture bound, standard as a 2D texture to _TANoiseTex and _TANoiseTex_TexelSize should be the texel size.

NOTE: You must:
    * Disable compression (unless you want it muted)
    * Use bilinear filtering. 
    * Use repeat wrapping.
    * If you are using the single-texel lookups, disable sRGB.

Map Generation:
	* The C rand() function is insufficient for generation of this texture. (It has obvious patterns).
	* Recommended use an LFSR.
	* See appendix at end.

TODO: Improve matrix for non-ordinal-direction viewing.  It should be
possible to make the noise resistant to 90-degree angle artifacts even
when viewerd from other axes.

The original version of this noise is restrictively licensed.  Code was
re-written for HLSL 2020 <>< CNLohr, code henseforth may be liberally
licensed under MIT-X11, NewBSD or Any Creative Commons License including
CC0.

You can see a shadertoy version of the 3D single texture lookup version in the clouds shader here: https://www.shadertoy.com/view/3syfRd