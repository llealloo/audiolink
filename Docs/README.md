# Using AudioLink

AudioLink can be used in 2 ways.
1. From Udon
2. Directly using the shader (on an Avatar or in a world)

## Using AudioLink in Udon

{ Llealloo, should this link to main page? See main readme and examples }

## The AudioLink Texture

The AudioLink Texture is a 128 x 64 px RGBA texture which contains several features which allow for the linking of audio and other data to avatars of a world.  It contains space for many more features than are currently implemented and may periodically add functionality. 

The basic map is sort of a hodgepodge of various features avatars may want.

<img src=https://raw.githubusercontent.com/cnlohr/vrc-udon-audio-link/dev/Docs/Materials/tex_AudioLinkDocs_BaseImage.png width=512 height=256>

{ Llealloo, Insert Avatar map }

## Using the AudioLink Texture

When using the AudioLink texture, there's a few things that may make sense to add to your shader.  You may either use `AudioLink.cginc` (recommended) or copy-paste the header info.

```hlsl

Shader "MyTestShader"
{
    Properties
    {
        _AudioLink ("AudioLink Texture", 2D) = "black" {}
    }
    SubShader
    {
        ... 
        
        Pass
        {
            CGPROGRAM

            ...

            #include "UnityCG.cginc"
    
            ...
            
            #include "../AudioLink/Shaders/AudioLink.cginc"
            ...
        }
    }
}

```

## What is in AudioLink.cginc.


```hlsl
// Map of where features in AudioLink are.
#define ALPASS_DFT                      int2(0,4)
#define ALPASS_WAVEFORM                 int2(0,6)
#define ALPASS_AUDIOLINK                int2(0,0)
#define ALPASS_AUDIOBASS                int2(0,0)
#define ALPASS_AUDIOLOWMIDS             int2(0,1)
#define ALPASS_AUDIOHIGHMIDS            int2(0,2)
#define ALPASS_AUDIOTREBLE              int2(0,3)
#define ALPASS_AUDIOLINKHISTORY         int2(1,0)
#define ALPASS_GENERALVU                int2(0,22)
#define ALPASS_GENERALVU_INSTANCE_TIME  int2(2,22)
#define ALPASS_GENERALVU_LOCAL_TIME     int2(3,22)
#define ALPASS_CCINTERNAL               int2(12,22)
#define ALPASS_CCSTRIP                  int2(0,24)
#define ALPASS_CCLIGHTS                 int2(0,25)
#define ALPASS_AUTOCORRELATOR           int2(0,27)
```

These are the base coordinates for the different data blocks in AudioLink.  For data groups that are multiline, all data is represented as left-to-right (increasing X) then incrementing Y and scanning X from left to right on the next line.  They are the following groups that contain the following data:

### `ALPASS_DFT`

A 128 x 2 block of data containing a DFT (like an FFT, but even intervals in chromatic space and discarding phase information).  There are a total of ten octaves of audio data, each octave taking up 24 pixels and having the following format per pixel:
 * RED: "mag" : Raw spectrum magnitude.
 * GRN: "magEQ" : Filtered power EQ'd, used by AudioLink
 * BLU: "magfilt" : Heavily filtered spectrum for use in ColorChord
 * ALP: RESERVED.

AudioLink reserves the right to change:
 * The window that is used for calculations.
 * The type of DFT performed.
 * The way the parts are EQd or IIRd
 * The alpha channel.
 * What bins 240-255 are used for.

A mechanism to use this field on a texture would be:
```hlsl
	return AudioLinkLerpMultiline( ALPASS_WAVEFORM + uint2( i.uv.x * AUDIOLINK_ETOTALBINS, 0 ) ).rrrr;
```

### `ALPASS_WAVEFORM`

Waveform data is stored in 16 rows, for a total of 2048 (2046 usable) points sample points.  The format per pixel is:
 * RED: 24,000 SPS audio, amplitude. Contains 2046 samples.
 * GRN: 48,000 SPS audio, amplitude. Contains 2048 samples.
 * BLU: 12,000 SPS audio, amplitude. Contains 1023 samples.
 * ALP: RESERVED.

The reason for the numbers are off by one is because shader parameters can only store 1023 values, not 1024 and AudioLink uses 4 blocks.

Every sample has the following gain applied to it:

```hlsl
float incomingGain = ((_AudioSource2D > 0.5) ? 1.f : 100.f);

// Enable/Disable autogain.
if( _EnableAutogain )
{
	float4 LastAutogain = GetSelfPixelData( ALPASS_GENERALVU + int2( 11, 0 ) );

	//Divide by the running volume.
	incomingGain *= 1./(LastAutogain.x + _AutogainDerate);
}
```


A mechanism to use this field on a texture would be:
```hlsl
	return AudioLinkLerpMultiline( ALPASS_WAVEFORM + uint2( i.uv.x * 1024, 0 ) ).rrrr;
```


### `ALPASS_AUDIOLINK`

AudioLink is the 1 x 4 px data at the far corner of the texture.  It is updated every frame with bass, low-mid, high-mid and treble ranges.  It triggers in amplitude, and contains the most recent frame.

The channels are:
 * RED: AudioLink Impulse Data
 * GRN / BLU: Currently the same as RED, but considering changing so that they may have sligthly different impulse response.
 * ALP: Reserved.
 
AudioLink v1 note: The 32x4 section of the AudioLink texture is still compatible with AudioLink v1 at the time of writing this.

A mechanism to use this field on a texture would be:
```hlsl
	return AudioLinkData( ALPASS_AUDIOLINK + uint2( 0, i.uv.y * 4. ) ).rrrr;
```

### `ALPASS_AUDIOLINKHISTORY`

The history of ALPASS_AUDIOLINK, cascading right in the texture, with the oldest copies of `ALPASS_AUDIOLINK` on the far right.

A mechanism to use this field smoothly would be the following - note that we use the `ALPASS_AUDIOLINK` instead of `ALPASS_AUDIOLINKHISTORY`:
```hlsl
	return AudioLinkLerp( ALPASS_AUDIOLINK + float2( i.uv.x * AUDIOLINK_WIDTH, i.uv.y * 4. ) ).rrrr;
```


### `ALPASS_GENERALVU`

This is the General Data and VU Data block. Note that for intensities, we use RMS and Peak, and do not currently take into account A and C weighting.

Note: LF's are decoded by passing the RGBA value into DecodeLongFloat which is used to encode a precise value into a half-float pixel, which can output an int32, uint32, or float, depending on context.

It contains the following dedicated pixels:

<table>
<tr><th>Pixel Offset</th><th>Absolute Pixel</th><th>Description</th><th>Red</th><th>Green</th><th>Blue</th><th>Alpha</th></tr	>
<tr><td>0, 0 </td><td>0, 22</td><td>Version Number and FPS</td><td>Version (Version Minor)</td><td>0 (Version Major)</td><td>System FPS</td><td></td></tr>
<tr><td>1, 0 </td><td>1, 22</td><td>AudioLink FPS</td><td></td><td>AudioLink FPS</td><td></td><td></td></tr>
<tr><td>2, 0 </td><td>2, 22</td><td>Milliseconds Since Instance Start</td><td colspan=4>`ALDecodeDataAs[UInt/float]( ALPASS_GENERALVU_INSTANCE_TIME )`</td></tr>
<tr><td>3, 0 </td><td>3, 22</td><td>Milliseconds Since 12:00 AM Local Time</td><td colspan=4>`ALDecodeDataAs[UInt/float]( ALPASS_GENERALVU_LOCAL_TIME )`</td></tr>
<tr><td>8, 0 </td><td>8, 22</td><td>Current Intensity</td><td>RMS</td><td>Peak</td><td></td><td></td></tr>
<tr><td>9, 0 </td><td>9, 22</td><td>Marker Value</td><td>RMS</td><td>Peak</td><td></td><td></td></tr>
<tr><td>10, 0</td><td>10, 22</td><td>Marker Times</td><td>RMS</td><td>Peak</td><td></td><td></td></tr>
<tr><td>11, 0</td><td>11, 22</td><td>Autogain</td><td>Asymmetrically Filtered Volume</td><td>Symmetrically filtered Volume</td><td></td><td></td></tr>
</table>

Note that for milliseconds since instance start, and milliseconds since 12:00 AM local time, you may use `ALPASS_GENERALVU_INSTANCE_TIME` and `ALPASS_GENERALVU_LOCAL_TIME` with `ALDecodeDataAsUInt(...)` and `ALDecodeDataAsFloat(...)`

```hlsl
#define ALPASS_GENERALVU_INSTANCE_TIME   int2(2,22)
#define ALPASS_GENERALVU_LOCAL_TIME      int2(3,22)
```


Various Usages of this field would be:
```hlsl
	AudioLinkData( ALPASS_GENERALVU + uint2( 0, 0 )).x;  //2.04 for AudioLink 2.4.
	AudioLinkData( ALPASS_GENERALVU + uint2( 1, 0 )).x;  //System FPS
	ALDecodeDataAsfloat( ALPASS_GENERALVU_INSTANCE_TIME ); //Time that matches for all players
	ALDecodeDataAsUInt( ALPASS_GENERALVU_LOCAL_TIME ); //Local time.
	AudioLinkData( ALPASS_GENERALVU + uint2( 8, 0 )).x;  // Current intensity of sound.
	AudioLinkData( ALPASS_GENERALVU + uint2( 11, 0 )).y;  // slow responce of volume of incoming sound.
```




### `ALPASS_CCINTERNAL`

Internal ColorChord note representation.  Subject to change.

### `ALPASS_CCSTRIP`

A single linear strip of ColorChord, think of it as a linear pie chart.  You can directly apply the colors here directly to surfaces.

<img src=https://github.com/cnlohr/vrc-udon-audio-link/raw/dev/Docs/Materials/tex_AudioLinkDocs_CCStrip.png width=512 height=20>

A mechanism to use this field smoothly would be:
```hlsl
	return AudioLinkLerp( ALPASS_CCSTRIP + float2( i.uv.x * AUDIOLINK_WIDTH, 0 ) ).rgba;
```

### `ALPASS_CCLIGHTS`

<img src=https://github.com/cnlohr/vrc-udon-audio-link/raw/dev/Docs/Materials/tex_AudioLinkDocs_CCLights.png width=512 height=20>

Two rows, the bottom row contains raw colorchord light values.  Useful for if you have individual objects or lights which need a sound-correlated color that are discrete.  I.e. pieces of confetti, lamps, speakers, blocks, etc.

The top (0,1) row is used to track internal aspects of ColorChord state.  Subject to change. Do not use.

A mechanism to use this field smoothly would be:
```hlsl
	return AudioLinkData( ALPASS_CCLIGHTS + uint2( uint( i.uv.x * 8 ) + uint(i.uv.y * 16) * 8, 0 ) ).rgba;
```

### `ALPASS_AUTOCORRELATOR`

The red channel of this row provides a fake autocorrelation of the waveform.  It resynthesizes the waveform from the DFT.  It is symmetric, so only the right half is presented via AudioLink.  To use it, we recommend mirroring it around the left axis.

<img src=https://github.com/cnlohr/vrc-udon-audio-link/raw/dev/Docs/Materials/tex_AudioLinkDocs_Autocor.png width=512 height=20>

Green, Blue, Alpha are reserved.

```hlsl
	return AudioLinkLerp( ALPASS_AUTOCORRELATOR + float2( ( 1. - abs( i.uv.x * 2. ) ) * AUDIOLINK_WIDTH, 0 ) ).rgba;
```


### Other defines

```hlsl
// Some basic constants to use (Note, these should be compatible with
// future version of AudioLink, but may change.
#define AUDIOLINK_SAMPHIST              3069 // Internal use for algos, do not change.
#define AUDIOLINK_SAMPLEDATA24          2046
#define AUDIOLINK_EXPBINS               24
#define AUDIOLINK_EXPOCT                10
#define AUDIOLINK_ETOTALBINS            (AUDIOLINK_EXPBINS * AUDIOLINK_EXPOCT)
#define AUDIOLINK_WIDTH                 128
#define AUDIOLINK_SPS                   48000 // Samples per second
#define AUDIOLINK_ROOTNOTE              0
#define AUDIOLINK_4BAND_FREQFLOOR       0.123
#define AUDIOLINK_4BAND_FREQCEILING     1
#define AUDIOLINK_BOTTOM_FREQUENCY      13.75
#define AUDIOLINK_BASE_AMPLITUDE        2.5
#define AUDIOLINK_DELAY_COEFFICIENT_MIN 0.3
#define AUDIOLINK_DELAY_COEFFICIENT_MAX 0.9
#define AUDIOLINK_DFT_Q                 4.0
#define AUDIOLINK_TREBLE_CORRECTION     5.0

// ColorChord constants
#define COLORCHORD_EMAXBIN              192
#define COLORCHORD_IIR_DECAY_1          0.90
#define COLORCHORD_IIR_DECAY_2          0.85
#define COLORCHORD_CONSTANT_DECAY_1     0.01
#define COLORCHORD_CONSTANT_DECAY_2     0.0
#define COLORCHORD_NOTE_CLOSEST         3.0
#define COLORCHORD_NEW_NOTE_GAIN        8.0
#define COLORCHORD_MAX_NOTES            10
```

The tools to read the data out of AudioLink.
 * `float4 AudioLinkData( int2 coord )` - Retrieve a bit of data from _AudioTexture, using whole numbers.
 * `float4 AudioLinkDataMultiline( int2 coord )` - Same as `AudioLinkData` except that if you read off the end of one line, it continues reading onthe next.
 * `float4 AudioLinkLerp( float2 fcoord )` - Interpolate between two pixels, useful for making shaders not look jaggedy.
 * `float4 AudioLinkLerpMultiline( float2 fcoord )` - `AudioLinkLerp` but wraps lines correctly.
 * `float Remap(float t, float a, float b, float u, float v)` - Remaps value t from [a; b] to [u; v]

A couple utility macros/functions

 * `glsl_mod( x, y )` - returns a well behaved in negative version of `fmod()`
 * `float4 CCHSVtoRGB( float3 hsv )` - Standard HSV/L to RGB function.
 * `float4 CCtoRGB( float bin, float intensity, int RootNote )` - ColorChord's standard color generation function.
 * `bool AudioLinkIsAvailable()` - Checks is AudioLink data texture is present
 * `float AudioLinkGetVersion()` - Returns the running version of AudioLink as a float


### Table for does it make sense to index with?

Where the following mapping is used:

 * Data = `AudioLinkData( ... )`
 * DataMultiline = `AudioLinkDataMultiline( ... )`
 * Lerp = `AudioLinkLerp( ... )`
 * LerpMultiline = `AudioLinkLerpMultiline( ... )`

| | Data | DataMultiline | Lerp | LerpMultiline | Start Coord | Size |
| --- | --- | --- | --- | --- | --- | --- |
| ALPASS_DFT  | ✅ | ✅ | ✅ | ✅ | 0,4 | 128, 2 |
| ALPASS_WAVEFORM  | ✅ | ✅ | ✅ | ✅ | 0, 6 | 128, 16 |
| ALPASS_AUDIOLINK  | ✅ |  | ✅ |  | 0, 0 | 1, 4 |
| ALPASS_AUDIOLINKHISTORY  | ✅ |  | ✅ |  | 1, 0 | 127, 4 |
| ALPASS_GENERALVU  | ✅ |  |  |  |  0, 22 | 12, 2 |
| ALPASS_CCINTERNAL  | ✅ |  |  |  | 12, 22 | 12, 2 |
| ALPASS_CCSTRIP  | ✅ |   | ✅ |   | 0, 24 | 128, 1 | 
| ALPASS_CCLIGHTS  | ✅ | ✅ |   |   | 0, 25 | 128, 2 |
| ALPASS_AUTOCORRELATOR  | ✅ |   | ✅ |   | 0, 27 | 128, 1 |


## Examples

### Basic Test with AudioLink
Once you have these pasted into your new shader and you drag the AudioLink texture onto your material, you can now retrieve data directly from the AudioLink texture.  For instance in this code 
snippet, we can make a cube display just the current 4 AudioLink values.  We set the X component in the texture to 0, and the Y component to be based on the Y coordinate in the texture.

```hlsl
fixed4 frag (v2f i) : SV_Target
{
    return AudioLinkData( ALPASS_AUDIOLINK + int2( 0, i.uv.y * 4. ) ).rrrr;
}
```

<img src=https://github.com/cnlohr/vrc-udon-audio-link/raw/dev/Docs/Materials/tex_AudioLinkDocs_Demo1.gif width=512 height=288>

### Basic Test with sample data.
Audio waveform data is in the ALPASS_WAVEFORM section of the AudioLink texture.  This red color of this group of 128x16 pixels represents the last 85ms of the incoming waveform data.  This
can be used to draw the waveform onto a surface or use it in other ways.

```hlsl
float Sample = AudioLinkLerpMultiline( ALPASS_WAVEFORM + float2( 200. * i.uv.x, 0 ) ).r;
return 1 - 50 * abs( Sample - i.uv.y* 2. + 1 );
```

<img src=https://github.com/cnlohr/vrc-udon-audio-link/raw/dev/Docs/Materials/tex_AudioLinkDocs_Demo2.gif width=512 height=288>

### Using the spectrogram

The spectrogram portion of audiolink contains the frequency amplitude of every 1/24th of an octave, starting at A-1 (13.75Hz).  This can be used to display something with frequency respones to it.
  
This demo shows off a few things.
 * Reading the spectrogram from `ALPASS_DFT`
 * Doing something a little more interesting with the surface.  Faking alpha with `discard`.

```hlsl
float noteno = i.uv.x*AUDIOLINK_ETOTALBINS;

float4 spectrum_value = AudioLinkLerpMultiline( ALPASS_DFT + float2( noteno, 0. ) )  + 0.5;

//If we are below the spectrum line, discard the pixel.
if( i.uv.y < spectrum_value.z )
    discard;
else if( i.uv.y < spectrum_value.z + 0.01 )
    return 1.;
return 0.1;
```

<img src=https://github.com/cnlohr/vrc-udon-audio-link/raw/dev/Docs/Materials/tex_AudioLinkDocs_Demo3.gif width=512 height=288>

### AutoCorrelator + ColorChord Linear + Geometry

This demo does several more things.
 * It operates in the vertex shader instead of the fragment shader mostly. 
 * It also reads the autocorrelator instead of the DFT or the Waveform data.  
 * It reads colorchord to apply some color to the object.

```hlsl
v2f vert (appdata v)
{
    v2f o;
    float3 vp = v.vertex;

    o.vpOrig = vp;

    // Generate a value for how far around the circle you are.
    // atan2 generates a number from -pi to pi.  We want to map
    // this from -1..1.  Tricky: add 0.001 to x otherwise
    // we lose a vertex at the poll because atan2 is undefined.
    float phi = atan2( vp.x+0.001, vp.z ) / 3.14159;
    
    // We want to mirror the -1..1 so that it's actually 0..1 but
    // mirrored.
    float placeinautocorrelator = abs( phi );
    
    // Note: We don't need lerp multiline because the autocorrelator
    // is only a single line.
    float autocorrvalue = AudioLinkLerp( ALPASS_AUTOCORRELATOR +
        float2( placeinautocorrelator * AUDIOLINK_WIDTH, 0. ) );
    
    // Squish in the sides, and make it so it only perterbs
    // the surface.
    autocorrvalue = autocorrvalue * (.5-abs(vp.y)) * 0.4 + .6;

    // Modify the original vertices by this amount.
    vp *= autocorrvalue;

    o.vpXform = vp;                
    o.vertex = UnityObjectToClipPos(vp);
    return o;
}

fixed4 frag (v2f i) : SV_Target
{
    // Decide how we want to color from colorchord.
    float ccplace = length( i.vpXform.xz ) * 2.;
    
    // Get a color from ColorChord
    float4 colorchordcolor = AudioLinkData( ALPASS_CCSTRIP + float2( AUDIOLINK_WIDTH * ccplace, 0. ) ) + 0.01;

    // Shade the color a little.
    colorchordcolor *= length( i.vpXform.xyz ) * 15. - 2.0;
    return colorchordcolor;
}
```

<img src=https://github.com/cnlohr/vrc-udon-audio-link/raw/dev/Docs/Materials/tex_AudioLinkDocs_Demo4.gif width=512 height=288>

### Using Ordinal UVs to make some neat speakers.

UVs go from 0 to 1, right?  Wrong!  You can make UVs anything you fancy, anything ±3.4028 × 10³⁸.  They don't care. So, while we can make the factional part of a UV still represent something meaningful in a texture or otherwise, we can use the whole number (ordinal) part to represent something else.  For instance, the band of AudioLink we want an object to respond to.

<img src=https://github.com/cnlohr/vrc-udon-audio-link/raw/dev/Docs/Materials/tex_AudioLinkDocs_Demo5.gif width=512 height=288>

```hlsl
v2f vert (appdata v)
{
	v2f o;
	float3 vp = v.vertex;

	// Pull out the ordinal value
	int whichzone = floor(v.uv.x-1);
	
	//Only affect it if the v.uv.x was greater than or equal to 1.0
	if( whichzone >= 0 )
	{
		float alpressure = AudioLinkData( ALPASS_AUDIOLINK + int2( 0, whichzone ) ).x;
		vp.x -= alpressure * .5;
	}

	o.opos = vp;
	o.uvw = float3( frac( v.uv ), whichzone + 0.5 );                
	o.vertex = UnityObjectToClipPos(vp);
	o.normal = UnityObjectToWorldNormal( v.normal );
	return o;
}

fixed4 frag (v2f i) : SV_Target
{
	float radius = length( i.uvw.xy - 0.5 ) * 30;
	float3 color = 0;
	if( i.uvw.z >= 0 )
	{
		// If a speaker, color it with a random ColorChord light.
		color = AudioLinkLerp( ALPASS_AUDIOLINK + float2( radius, i.uvw.z ) ).rgb * 10. + 0.5;
		
		//Adjust the coloring on the speaker by the normal
		color *= (dot(i.normal.xyz,float3(1,1,-1)))*.2;
		
		color *= AudioLinkData( ALPASS_CCLIGHTS + int2( i.uvw.z, 0) ).rgb;
	}
	else
	{
		// If the box, use the normal to color it.
		color = abs(i.normal.xyz)*.01+.02;
	}
	
	return float4( color ,1. );
}
```

### Using Virtual Clocks

You can virtually sync objects, which means they will be synced across the instance for all users, however they use no networking, syncing or Udon to do so.  Application would be effects that you want to have be in motion and appear the same on all player's screens.

If you were to make your effect using _Time, it would use the player's local instance time, but if you make your effect using `ALDecodeDataAsFloat(ALPASS_GENERALVU_INSTANCE_TIME)` then all players will see your effect exactly the same.

![Demo6](https://github.com/cnlohr/vrc-udon-audio-link/raw/dev/Docs/Materials/tex_AudioLinkDocs_Demo6.gif =512x288)

```hlsl
// Utility function to check if a point lies in the unit square. (0 ... 1)
float inUnit( float2 px ) { float2 tmp = step( 0, px ) - step( 1, px ); return tmp.x * tmp.y; }

float2 hash12(float2 n){ return frac( sin(dot(n, 4.1414)) * float2( 43758.5453, 38442.558 ) ); }

fixed4 frag (v2f i) : SV_Target
{
	// 23 and 31 LCM of 713 cycles for same corner bounce.
	const float2 collisiondiv = float2( 23, 31 );

	// Make the default size of the logo take up .2 of the overall object,
	// but let the user scale the size of their logo using the texture
	// repeat sliders.
	float2 logoSize = .2*_Logo_ST.xy;
	
	// Calculate the remaining area that the logo can bounce around.
	float2 remainder = 1. - logoSize;

	// Retrieve the instance time.
	float instanceTime = ALDecodeDataAsFloat( ALPASS_GENERALVU_INSTANCE_TIME );

	// Calculate the total progress made along X and Y irrespective of
	// the total number of bounces made.  But then compute where the
	// logo would have ended up after that long period of time.
	float2 logoUV = i.uv.xy / logoSize;
	float2 xyprogress = instanceTime * 1/collisiondiv;
	int totalbounces = floor( xyprogress * 2. ).x + floor( xyprogress * 2. ).y;
	float2 xyoffset = abs( frac( xyprogress ) * 2. - 1. );

	// Update the logo position with that location.
	logoUV -= (remainder*xyoffset)/logoSize;

	// Read that pixel.
	float4 logoTexel =  tex2D( _Logo, logoUV );
	
	// Change the color any time it would have hit a corner.
	float2 hash = hash12( totalbounces );
	
	// Abuse the colorchord hue function here to randomly color the logo.
	logoTexel.rgb *= CCHSVtoRGB( float3( hash.x, hash.y*0.5 + 0.5, 1. ) );

	// If we are looking for the logo where the logo is not
	// zero it out.
	logoTexel *= inUnit( logoUV );

	// Alpha blend the logo onto the background.
	float3 color = lerp( _Background.rgb, logoTexel.rgb, logoTexel.a ); 
	return clamp( float4( color, _Background.a + logoTexel.a ), 0, 1 );
}
```


### Application of ColorChord Lights

TODO

### Using the VU data and info block

TODO


## Pertinent Notes and Tradeoffs.

### Texture2D &lt;float4&gt; vs sampler2D

You can use either `Texture2D<float4>` and `.load()`/indexing or by using `sampler2D` and `tex2Dlod`.  We strongly recommend using the `Texture2D<float4>` method over the traditional `sampler2D` method.  This is both because of usabiity as well as a **measurable increase in perf**.  HOWEVER - in a traditional surface shader you cannot use the newer HLSL syntax.  AudioLink will automatically fallback to the old texture indexing but if you want to do it manually, you may `#define AUDIOLINK_STANDARD_INDEXING`.

There are situations where you may need to interpolate between two points in a shader, and we find that it's still worthwhile to just do it using the indexing method.

```hlsl
Texture2D<float4>   _SelfTexture2D;
#define GetAudioPixelData(xy) _SelfTexture2D[xy]
```

And the less recommended method.

```hlsl
// We recommend against this more traditional mechanism,
sampler2D _AudioTexture;
uniform float4 _AudioTexture_TexelSize;

float4 GetAudioPixelData( int2 pixelcoord )
{
    return tex2Dlod( _AudioTexture, float4( pixelcoord*_AudioTexture_TexelSize.xy, 0, 0 ) );
}
```

### FP16 vs FP32 (half/float)

As it currently stands, because the `rt_AudioLink` texture is used as both the input and output of the camera attached to the AudioLink object, it goes through an "Effect" pass which drives the precision to FP16 (half) from the `float` that the texture is by default.  Though, internally, the AudioLink texture is `float`, it means the values avatars are allowed to retrieve from it are limited to `half` precision.

### AudioLinkLerp vs AudioLinkData

`AudioLinkData` is designed to read a cell's data with the most integrety possible, i.e. not mixing colors or anything else.  But, sometimes you really want to get a filtered capture.  Instead of using a hardware interpolator, at this time, for control we just use lerp ourselves.

This is what sinewave would look like if one were to use `AudioLinkData`

<img src=https://raw.githubusercontent.com/cnlohr/vrc-udon-audio-link/dev/Docs/Materials/tex_AudioLinkDocs_ComparisonLookupNone.png width=512 height=288>

This is the same output, but with `AudioLinkLerp`.

<img src=https://raw.githubusercontent.com/cnlohr/vrc-udon-audio-link/dev/Docs/Materials/tex_AudioLinkDocs_ComparisonLookupLerp.png width=512 height=288>

### IIRs

IIR stands for infinite impulse response.  When things need to be filtered from frame to frame it is possible to use more complicated FIRs (Finite Impulse Response) filters, however, an IIR is absurdly simple to implement in GPUs and turn into a single `lerp` command.

Filtered Value = New Value * ( 1 - Filter Constant ) + Last Frame's Filtered Value * Filter Constant.

Or, in GPU Land, it turns into:

```hlsl
	filteredValue = lerp( newValue, lastFramesFilteredValue, filterConstant );
```

Where filter constant is between 0 and 1, where 0 is bypass, as though the filter doesn't exist, and 1 completely blocks any new values.  A value of 0.9 weights the incoming value smally, but after a few frames, the output will track it.

This makes new values impact the filtered value most, and as time goes on the impact of values diminishes to zero.

This is particularly useful as this sort of tracks the way we perceive information.

### What is ColorChord?

ColorChord is another project for doing sound reactive lighting IRL.  More info can be found on it here: https://github.com/cnlohr/colorchord