Shader "AudioLink/AudioLinkSandbox/WallLightEffect"
{
    Properties
    {
		_HashAdjust( "Randomizer", float ) = 0.0
		_UniqueColors( "Unique Colors", Range( 0, 4 ) ) = 1
		_Pieces( "Unique Pieces", Range( 1, 4 ) ) = 1
		_AudioReactivity ("Audio Reactivity", Range(0.0,1.0) ) = 0.5
		_EdgeDefinition ("Edge Definition", Range(0.0,1.0) ) = 0.5
		_Brightness ("Brightness", float ) = 0.5
		_Size( "Size", float ) = 1.2
		_Scatteredness( "Scatteredness", float ) = 1.2
		_Responsiveness( "Responsiveness", Range( 0,15 ) ) = 4
		[HDR] _PlainColor( "Plain Color (If unique=0)", Color ) = (.25, .5, .5, 1)
	}
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            #include "Packages/com.llealloo.audiolink/Runtime/Shaders/AudioLink.cginc"

			// Hash without Sine
			// Original code MIT License...
			// Copyright (c)2014 David Hoskins. (Under MIT license)
			// More here: https://github.com/cnlohr/shadertrixx/blob/main/Assets/hashwithoutsine/hashwithoutsine.cginc
			float4 hash42(float2 p)
			{
				float4 p4 = frac(float4(p.xyxy) * float4(.1031, .1030, .0973, .1099));
				p4 += dot(p4, p4.wzxy+33.33);
				return frac((p4.xxyz+p4.yzzw)*p4.zywx);
			}

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
				float4 color : TEXCOORD1;
                float4 vertex : SV_POSITION;
				float3 normal : NORMAL;
                UNITY_FOG_COORDS(1)
            };

			float _HashAdjust;
			float _UniqueColors;
			float _Pieces;
			float4 _PlainColor;
			float _AudioReactivity;
			float _EdgeDefinition;
			float _Brightness;
			float _Responsiveness;
			float _Size, _Scatteredness;

            v2f vert (appdata v)
            {
                v2f o;
				float4 vi = v.vertex;
				
				int id = floor( v.uv.x );
				float4 hashperterb = hash42( float2( id, _HashAdjust ) );
				vi.zy *= (hashperterb.zw+0.5) * _Size;
				vi.zy += (hashperterb.xy - 0.5) * .02 * _Scatteredness;
				
				if( id >= _Pieces - 0.5 ) vi = 0;
				
				float4 ColorOut = 0;
				
				if( _UniqueColors < 1 )
				{
					ColorOut = _PlainColor;
				}
				else
				{
				    float4 ThisNote = AudioLinkData(ALPASS_CCINTERNAL + uint2( glsl_mod( id, (int)_UniqueColors ), 0 ) );
					ColorOut = (ThisNote.x>=0) ? float4( AudioLinkCCtoRGB( ThisNote.x, 1, 0 ), 1. ) : _PlainColor;
				}
								
				o.color = ColorOut * lerp( 1.0, AudioLinkData( ALPASS_FILTEREDAUDIOLINK + uint2( floor( _Responsiveness ), id ) ), _AudioReactivity );
				
                o.vertex = UnityObjectToClipPos(vi);
                o.uv = v.uv;
				o.normal = v.normal;
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = i.color * _Brightness * lerp( 1., dot( i.normal, _WorldSpaceLightPos0.xyz ), _EdgeDefinition );
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
