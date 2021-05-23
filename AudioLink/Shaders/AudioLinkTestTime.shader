Shader "Unlit/AudioLinkTestTime"
{
    Properties
    {
        _AudioLinkTexture ("Texture", 2D) = "white" {}
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

            #include "UnityCG.cginc"
            #include "AudioLink.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };
            float4 _AudioLinkTexture_ST;
            
            #ifndef glsl_mod
            #define glsl_mod(x,y) (((x)-(y)*floor((x)/(y)))) 
            #endif            

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _AudioLinkTexture);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float value = 0;
                
                float2 iuv = i.uv;
                iuv.y = 1.-iuv.y;
                const int rows = 7;
                const int cols = 10;
                
                float2 pos = iuv*float2(cols,rows);
                uint2 dig = (uint2)(pos);

                float2 fmxy = float2( 4, 6 ) - (glsl_mod(pos,1.)*float2(4.,6.));
 
                int offset = 0;
                int xoffset = 0;
                bool leadingzero = false;

                switch( dig.y )
                {
                case 0:
                    // Time since level start in milliseconds.
                    value = DecodeLongFloat( AudioLinkData( int2( ALPASS_GENERALVU + int2( 2, 0 ) ) ) );
                    break;
                    
                case 1:
                    // Time of day.
                    value = DecodeLongFloat( AudioLinkData( int2( ALPASS_GENERALVU + int2( 3, 0 ) ) ) ) / 1000;
                    float seconds = glsl_mod( value, 60 );
                    int minutes = (value/60) % 60;
                    int hours = (value/3600);
                    value = hours * 10000 + minutes * 100 + seconds;
                    
                    if( dig.x < 3 )
                    {
                        value = hours;
                        xoffset = 8;
                        leadingzero = 1;
                    }
                    else if( dig.x < 6 )
                    {
                        value = minutes;
                        xoffset = 5;
                        leadingzero = 1;
                    }
                    else
                    {
                        value = seconds;
                        xoffset = 2;
                        leadingzero = 1;
                    }
                    break;
                    
                case 2:
                    value = AudioLinkData( int2( ALPASS_GENERALVU + int2( 11, 0 ) ) ); //Autogain Debug
                    offset = 6;
                    break;

                case 3:
                    value = AudioLinkData( int2( ALPASS_GENERALVU + int2( 8, 0 ) ) ).x; //RMS
                    offset = 6;
                    break;

                case 4:
                    value = AudioLinkData( int2( ALPASS_GENERALVU + int2( 8, 0 ) ) ).y; //Peak
                    offset = 6;
                    break;

                case 5:
                    if( dig.x < 6 )
                    {
                        value = AudioLinkData( int2( ALPASS_GENERALVU + int2( 0, 0 ) ) ).b; //True FPS
                        xoffset = 4;
                    }
                    else
                    {
                        value = AudioLinkData( int2( ALPASS_GENERALVU + int2( 1, 0 ) ) ).b; //AudioLink FPS
                    }
                    break;

                case 6:
                    value = AudioLinkData( int2( ALPASS_GENERALVU + int2( 4, 0 ) ) ).a; //100,000 sentinal test
                    break;
                    
                default:
                    break;
                }
                return PrintNumberOnLine( value, cols-offset, dig.x + xoffset, fmxy, offset, leadingzero );                
            }
            ENDCG
        }
    }
}
