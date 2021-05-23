# Using AudioLink

AudioLink can be used in 2 ways.
1. From Udon
2. Directly using the shader (on an Avatar or in a world)

## Using AudioLink in Udon

{ Llealloo, should this link to main page? See main readme and examples }

## The AudioLink Texture

The AudioLink Texture is a 128 x 64 px RGBA texture which contains several features which allow for the linking of audio and other data to avatars of a world.  It contains space for many more features than are currently implemented and may periodically add functionality. 

The basic map is sort of a hodgepodge of various features avatars may want.

![AudioLinkBaseTexture](https://raw.githubusercontent.com/cnlohr/vrc-udon-audio-link/dev/AudioLink/Docs/AudioLinkDocs_BaseImage.png)

{ Llealloo, Insert Avatar map }

## Using the AudioLink Texture

When using the AudioLink texture, there's a few things that may make sense to add to your shader.  You may either use `AudioLink.cginc` (recommended) or copy-paste the header info.

```glsl

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

### What is in AudioLink.cginc.


```glsl
// Map of where features in AudioLink are.
#define ALPASS_DFT              int2(0,4)  
#define ALPASS_WAVEFORM         int2(0,6)
#define ALPASS_AUDIOLINK        int2(0,0)
#define ALPASS_AUDIOLINKHISTORY int2(1,0) 
#define ALPASS_GENERALVU        int2(0,22)  
#define ALPASS_CCINTERNAL       int2(12,22)
#define ALPASS_CCSTRIP          int2(0,24)
#define ALPASS_CCLIGHTS         int2(0,25)
#define ALPASS_AUTOCORRELATOR   int2(0,27)
```

```glsl
// Some basic constants to use (Note, these should be compatible with
// future version of AudioLink, but may change.
#define CCMAXNOTES 10
#define SAMPHIST 3069 //Internal use for algos, do not change.
#define SAMPLEDATA24 2046
#define EXPBINS 24
#define EXPOCT 10
#define ETOTALBINS ((EXPBINS)*(EXPOCT))
#define AUDIOLINK_WIDTH  128
#define _SamplesPerSecond 48000
#define _RootNote 0
```

A couple utility macros/functions

 * `glsl_mod( x, y )` - returns a well behaved in negative version of `fmod()`
 * `float4 AudioLinkData( int2 coord )` - Retrieve a bit of data from _AudioLinkTexture, using whole numbers.
 * `float4 AudioLinkDataMultiline( int2 coord )` - Same as `AudioLinkData` except that if you read off the end of one line, it continues reading onthe next.
 * `float4 AudioLinkLerp( float2 fcoord )` - Interpolate between two pixels, useful for making shaders not look jaggedy.
 * `float4 AudioLinkLerpMultiline( float2 fcoord )` - `AudioLinkLerp` but wraps lines correctly.
 * `float4 CCHSVtoRGB( float3 hsv )` - Standard HSV/L to RGB function.
 * `float4 CCtoRGB( float bin, float intensity, int RootNote )` - ColorChord's standard color generation function.


### Basic Test with AudioLink
Once you have these pasted into your new shader and you drag the AudioLink texture onto your material, you can now retrieve data directly from the AudioLink texture.  For instance in this code 
snippet, we can make a cube display just the current 4 AudioLink values.  We set the X component in the texture to 0, and the Y component to be based on the Y coordinate in the texture.

```glsl
fixed4 frag (v2f i) : SV_Target
{
    return AudioLinkData( ALPASS_AUDIOLINK + int2( 0, i.uv.y * 4. ) ).rrrr;
}
```

![Demo4](https://github.com/cnlohr/vrc-udon-audio-link/raw/dev/AudioLink/Docs/AudioLinkDocs_Demo1.gif)

### Basic Test with sample data.
Audio waveform data is in the ALPASS_WAVEFORM section of the 

```glsl
float Sample = AudioLinkLerpMultiline( ALPASS_WAVEFORM + float2( 200. * i.uv.x, 0 ) ).r;
return 1 - 50 * abs( Sample - i.uv.y* 2. + 1 );
```

![Demo4](https://github.com/cnlohr/vrc-udon-audio-link/raw/dev/AudioLink/Docs/AudioLinkDocs_Demo2.gif)

### Using the spectrogram

This demo shows off a few things.
 * Reading the spectrogram from `ALPASS_DFT`
 * Doing something a little more interesting with the surface

```glsl
float noteno = i.uv.x*ETOTALBINS;

float4 spectrum_value = AudioLinkLerpMultiline( ALPASS_DFT + float2( noteno, 0. ) )  + 0.5;

//If we are below the spectrum line, discard the pixel.
if( i.uv.y < spectrum_value.z )
    discard;
else if( i.uv.y < spectrum_value.z + 0.01 )
    return 1.;
return 0.1;
```
 
![Demo4](https://github.com/cnlohr/vrc-udon-audio-link/raw/dev/AudioLink/Docs/AudioLinkDocs_Demo3.gif)

### AutoCorrelator + ColorChord Linear + Geometry

This demo does several more things.
 * It operates in the vertex shader instead of the fragment shader mostly. 
 * It also reads the autocorrelator instead of the DFT or the Waveform data.  
 * It reads colorchord to apply some color to the object.

```glsl
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

![Demo4](https://github.com/cnlohr/vrc-udon-audio-link/raw/dev/AudioLink/Docs/AudioLinkDocs_Demo4.gif)

### Application of ColorChord Lights

TODO

### Using the VU data and info block

TODO

### Using Ordinal UVs to make some neat speakers.

TODO


## Pertinent Notes and Tradeoffs.

### Texture2D &lt;float4&gt; vs sampler2D

You can use either `Texture2D<float4>` and `.load()`/indexing or by using `sampler2D` and `tex2Dlod`.  We strongly recommend using the `Texture2D<float4>` method over the traditional `sampler2D` method.  This is both because of usabiity as well as a **measurable increase in perf**.  HOWEVER - in a traditional surface shader you cannot use the newer HLSL syntax.  AudioLink will automatically fallback to the old texture indexing but if you want to do it manually, you may `#define AUDIOLINK_STANDARD_INDEXING`.

There are situations where you may need to interpolate between two points in a shader, and we find that it's still worthwhile to just do it using the indexing method.

```glsl
Texture2D<float4>   _SelfTexture2D;
#define GetAudioPixelData(xy) _SelfTexture2D[xy]
```

And the less recommended method.

```glsl
// We recommend against this more traditional mechanism,
sampler2D _AudioLinkTexture;
uniform float4 _AudioLinkTexture_TexelSize;

float4 GetAudioPixelData( int2 pixelcoord )
{
    return tex2Dlod( _AudioLinkTexture, float4( pixelcoord*_AudioLinkTexture_TexelSize.xy, 0, 0 ) );
}
```

### FP16 vs FP32 (half/float)

As it currently stands, because the `rt_AudioLink` texture is used as both the input and output of the camera attached to the AudioLink object, it goes through an "Effect" pass which drives the precision to FP16 (half) from the `float` that the texture is by default.  Though, internally, the AudioLink texture is `float`, it means the values avatars are allowed to retrieve from it are limited to `half` precision.

### AudioLinkLerp vs AudioLinkData

`AudioLinkData` is designed to read a cell's data with the most integrety possible, i.e. not mixing colors or anything else.  But, sometimes you really want to get a filtered capture.  Instead of using a hardware interpolator, at this time, for control we just use lerp ourselves.

This is what sinewave would look like if one were to use `AudioLinkData`

![None Lookup](https://raw.githubusercontent.com/cnlohr/vrc-udon-audio-link/dev/AudioLink/Docs/AudioLinkDocs_ComparisonLookupNone.png)

This is the same output, but with `AudioLinkLerp`.

![Lerp Lookup](https://raw.githubusercontent.com/cnlohr/vrc-udon-audio-link/dev/AudioLink/Docs/AudioLinkDocs_ComparisonLookupLerp.png)
