# Using AudioLink

AudioLink can be used in 2 ways.
1. From Udon
2. Directly using the shader (on an Avatar or in a world)

## Using AudioLink in Udon

{ Llealloo, should this link to main page? See main readme and examples }

## The AudioLink Texture

The AudioLink Texture is a 128 x 64 px RGBA texture which contains several features which allow for the linking of audio and other data to avatars of a world.  It contains space for many more features than are currently implemented and may periodically add functionality. 

The basic map is sort of a hodgepodge of various features avatars may want.

![AudioLinkBaseTexture](https://github.com/cnlohr/vrc-udon-audio-link/blob/dev/AudioLink/Docs/AudioLinkImageBase.png?raw=true)

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
            
            ... OR ...

            // Map of where features in AudioLink are.
            #define ALPASS_DFT              int2(0,4)  
            #define ALPASS_WAVEFORM         int2(0,6)
            #define ALPASS_AUDIOLINK        int2(0,0)
            #define ALPASS_AUDIOLINKHISTORY int2(1,0) 
            #define ALPASS_GENERALVU        int2(0,22)  
            #define ALPASS_CCINTERNAL       int2(12,22)
            #define ALPASS_CCSTRIP          int2(0,24)
            #define ALPASS_CCLIGHTS         int2(0,25)
            #define ALPASS_AUTOCORRELATOR   int2(0,28)

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

            // We use glsl_mod for most calculations because it behaves better
            // on negative numbers, and in some situations actually outperforms
            // HLSL's modf().
            #ifndef glsl_mod
            #define glsl_mod(x,y) (((x)-(y)*floor((x)/(y)))) 
            #endif

            // Mechanism to index into texture.
            Texture2D<float4>   _AudioLinkTexture;
            uniform half4       _AudioLinkTexture_TexelSize; 

            // Simply read data from the AudioLink texture
            #define AudioLinkData(xycoord) _AudioLinkTexture[uint2(xycoord)]

            // Convenient mechanism to read from the AudioLink texture that handles reading off the end of one line and onto the next above it.
            float4 AudioLinkDataMultiline( uint2 xycoord) { return _AudioLinkTexture[uint2(xycoord.x % AUDIOLINK_WIDTH, xycoord.y + xycoord.x/AUDIOLINK_WIDTH)]; }

            // Mechanism to sample between two adjacent pixels and lerp between them, like "linear" supesampling
            float4 AudioLinkLerp(float2 xy) { return lerp( AudioLinkData(xy), AudioLinkData(xy+int2(1,0)), frac( xy.x ) ); }

            // Same as AudioLinkLerp but properly handles multiline reading.
            float4 AudioLinkLerpMultiline(float2 xy) { return lerp( AudioLinkDataMultiline(xy), AudioLinkDataMultiline(xy+float2(1,0)), frac( xy.x ) ); }

            ...
        }
    }
}

```


### Basic Test with AudioLink
Once you have these pasted into your new shader and you drag the AudioLink texture onto your material, you can now retrieve data directly from the AudioLink texture.  For instance in this code 
snippet, we can make a cube display just the current 4 AudioLink values.  We set the X component in the texture to 0, and the Y component to be based on the Y coordinate in the texture.

```glsl
fixed4 frag (v2f i) : SV_Target
{
    return AudioLinkData( ALPASS_AUDIOLINK + int2( 0, i.uv.y * 4. ) ).rrrr;
}
```

![Demo1](https://github.com/cnlohr/vrc-udon-audio-link/blob/dev/AudioLink/Docs/Demo1.gif?raw=true)

### Basic Test with sample data.
Audio waveform data is in the ALPASS_WAVEFORM section of the 

```glsl
float Sample = AudioLinkLerpMultiline( ALPASS_WAVEFORM + float2( 200. * i.uv.x, 0 ) ).r;
return 1 - 50 * abs( Sample - i.uv.y* 2. + 1 );
```

![Demo2](https://github.com/cnlohr/vrc-udon-audio-link/blob/dev/AudioLink/Docs/Demo2.gif?raw=true)

### Demo showing moving of geometry

TODO

### AutoCorrelator + ColorChord Linear

TODO

### Application of ColorChord Lights

TODO

### Using the VU data and info block

TODO


## Pertinent Notes and Tradeoffs.

### Texture2D<float4> vs sampler2D

You can use either `Texture2D<float4>` and `.load()`/indexing or by using `sampler2D` and `tex2Dlod`.  We strongly recommend using the `Texture2D<float4>` method over the traditional `sampler2D` method.  This is both because of usabiity as well as a **measurable increase in perf**.

There are situations where you may need to interpolate between two points in a shader, and we find that it's still worthwhile to  

`glsl
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
