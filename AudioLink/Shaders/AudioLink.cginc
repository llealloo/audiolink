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
#define ALPASS_GENERALVU_NETWORK_TIME   int2(4,22)
#define ALPASS_GENERALVU_PLAYERINFO     int2(6,22)
#define ALPASS_CCINTERNAL               int2(12,22)
#define ALPASS_CCSTRIP                  int2(0,24)
#define ALPASS_CCLIGHTS                 int2(0,25)
#define ALPASS_AUTOCORRELATOR           int2(0,27)
#define ALPASS_FILTEREDAUDIOLINK        int2(0,28)

// Some basic constants to use (Note, these should be compatible with
// future version of AudioLink, but may change.
#define AUDIOLINK_SAMPHIST              3069        // Internal use for algos, do not change.
#define AUDIOLINK_SAMPLEDATA24          2046
#define AUDIOLINK_EXPBINS               24
#define AUDIOLINK_EXPOCT                10
#define AUDIOLINK_ETOTALBINS            (AUDIOLINK_EXPBINS * AUDIOLINK_EXPOCT)
#define AUDIOLINK_WIDTH                 128
#define AUDIOLINK_SPS                   48000       // Samples per second
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

// We use glsl_mod for most calculations because it behaves better
// on negative numbers, and in some situations actually outperforms
// HLSL's modf().
#ifndef glsl_mod
#define glsl_mod(x,y) (((x)-(y)*floor((x)/(y))))
#endif

uniform float4               _AudioTexture_TexelSize;

#ifdef SHADER_TARGET_SURFACE_ANALYSIS
#define AUDIOLINK_STANDARD_INDEXING
#endif

// Mechanism to index into texture.
#ifdef AUDIOLINK_STANDARD_INDEXING
    sampler2D _AudioTexture;
    #define AudioLinkData(xycoord) tex2Dlod(_AudioTexture, float4(uint2(xycoord) * _AudioTexture_TexelSize.xy, 0, 0))
#else
    uniform Texture2D<float4>   _AudioTexture;
    #define AudioLinkData(xycoord) _AudioTexture[uint2(xycoord)]
#endif

// Convenient mechanism to read from the AudioLink texture that handles reading off the end of one line and onto the next above it.
float4 AudioLinkDataMultiline(uint2 xycoord) { return AudioLinkData(uint2(xycoord.x % AUDIOLINK_WIDTH, xycoord.y + xycoord.x/AUDIOLINK_WIDTH)); }

// Mechanism to sample between two adjacent pixels and lerp between them, like "linear" supesampling
float4 AudioLinkLerp(float2 xy) { return lerp( AudioLinkData(xy), AudioLinkData(xy+int2(1,0)), frac( xy.x ) ); }

// Same as AudioLinkLerp but properly handles multiline reading.
float4 AudioLinkLerpMultiline(float2 xy) { return lerp(AudioLinkDataMultiline(xy), AudioLinkDataMultiline(xy+float2(1,0)), frac(xy.x)); }

//Tests to see if Audio Link texture is available
bool AudioLinkIsAvailable()
{
    #if !defined(AUDIOLINK_STANDARD_INDEXING)
        int width, height;
        _AudioTexture.GetDimensions(width, height);
        return width > 16;
    #else
        return _AudioTexture_TexelSize.z > 16;
    #endif
}

//Get version of audiolink present in the world, 0 if no audiolink is present
float AudioLinkGetVersion()
{
    int2 dims;
    #if !defined(AUDIOLINK_STANDARD_INDEXING)
        _AudioTexture.GetDimensions(dims.x, dims.y);
    #else
        dims = _AudioTexture_TexelSize.zw;
    #endif

    if (dims.x >= 128)
        return AudioLinkData(ALPASS_GENERALVU).x;
    else if (dims.x > 16)
        return 1;
    else
        return 0;
}

// This pulls data from this texture.
#define AudioLinkGetSelfPixelData(xy) _SelfTexture2D[xy]

// Extra utility functions for time.
uint AudioLinkDecodeDataAsUInt(uint2 indexloc)
{
    half4 rpx = AudioLinkData(indexloc);
    return ((uint)rpx.r + ((uint)rpx.g)*1024 + ((uint)rpx.b) * 1048576 + ((uint)rpx.a) * 1073741824);
}

//Note: This will truncate time to every 134,217.728 seconds (~1.5 days of an instance being up) to prevent floating point aliasing.
// if your code will alias sooner, you will need to use a different function.  It should be safe to use this on all times.
float AudioLinkDecodeDataAsSeconds(uint2 indexloc)
{
    uint time = AudioLinkDecodeDataAsUInt(indexloc) & 0x7ffffff;
    //Can't just divide by float.  Bug in Unity's HLSL compiler.
    return float(time / 1000) + float( time % 1000 ) / 1000.; 
}

float AudioLinkRemap(float t, float a, float b, float u, float v) { return ((t-a) / (b-a)) * (v-u) + u; }

float3 AudioLinkHSVtoRGB(float3 HSV)
{
    float3 RGB = 0;
    float C = HSV.z * HSV.y;
    float H = HSV.x * 6;
    float X = C * (1 - abs(fmod(H, 2) - 1));
    if (HSV.y != 0)
    {
        float I = floor(H);
        if (I == 0) { RGB = float3(C, X, 0); }
        else if (I == 1) { RGB = float3(X, C, 0); }
        else if (I == 2) { RGB = float3(0, C, X); }
        else if (I == 3) { RGB = float3(0, X, C); }
        else if (I == 4) { RGB = float3(X, 0, C); }
        else { RGB = float3(C, 0, X); }
    }
    float M = HSV.z - C;
    return RGB + M;
}

float3 AudioLinkCCtoRGB(float bin, float intensity, int rootNote)
{
    float note = bin / AUDIOLINK_EXPBINS;

    float hue = 0.0;
    note *= 12.0;
    note = glsl_mod(4. - note + rootNote, 12.0);
    {
        if(note < 4.0)
        {
            //Needs to be YELLOW->RED
            hue = (note) / 24.0;
        }
        else if(note < 8.0)
        {
            //            [4]  [8]
            //Needs to be RED->BLUE
            hue = (note-2.0) / 12.0;
        }
        else
        {
            //             [8] [12]
            //Needs to be BLUE->YELLOW
            hue = (note - 4.0) / 8.0;
        }
    }
    float val = intensity - 0.1;
    return AudioLinkHSVtoRGB(float3(fmod(hue, 1.0), 1.0, clamp(val, 0.0, 1.0)));
}