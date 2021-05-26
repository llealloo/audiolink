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
                const uint rows = 10;
                const uint cols = 20;
                const uint number_area_cols = 10;
                
                float2 pos = iuv*float2(cols,rows);
                uint2 dig = (uint2)(pos);

                float2 fmxy = float2( 4, 6 ) - (glsl_mod(pos,1.)*float2(4.,6.));

                
                if( dig.x < cols - number_area_cols )
                {
                    uint sendchar = 0;
                    if( dig.y > 6 )
                    {
                        sendchar = (dig.y-6)*10 + dig.x;
                    }
                    else
                    {
                        #define L(x) ((uint)(x-'A'+13))
                        const uint sendarr[70] = { 
                            L('I'), L('N'), L('S'), L('T'), L('A'), L('N'), L('C'), L('E'), 12, 12,
                            L('W'), L('A'), L('L'), L('L'), L('C'), L('L'), L('O'), L('C'), L('K'), 12,
                            L('A'), L('U'), L('T'), L('O'), 12, L('G'), L('A'), L('I'), L('N'), 12,
                            L('P'), L('E'), L('A'), L('K'), 12, L('V'), L('A'), L('L'), L('U'), L('E'),
                            L('R'), L('M'), L('S'), 12, L('V'), L('A'), L('L'), L('U'), L('E'), 12,
                            L('F'), L('P'), L('S'), L('E'), L('S'), 12, 12, 12, 12, 12,
                            12, 12, 12, 12, 12, 12, 12, 12, 12, 12,
                            };
                        sendchar = sendarr[dig.x+dig.y*10];
                    }
                    return PrintChar( sendchar, fmxy );
                }
                
                dig.x -= cols - number_area_cols;
 
                int offset = 0;
                int xoffset = 0;
                bool leadingzero = false;

                switch( dig.y )
                {
                case 0:
                case 1:
                    // 2: Time since level start in milliseconds.
                    // 3: Time of day.
                    value = DecodeLongFloat( AudioLinkData( int2( ALPASS_GENERALVU + int2( dig.y+2, 0 ) ) ) ) / 1000;
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
                    value = AudioLinkData( int2( ALPASS_GENERALVU + int2( 8, 0 ) ) ).y; //Peak
                    offset = 6;
                    break;
                case 4:
                    value = AudioLinkData( int2( ALPASS_GENERALVU + int2( 8, 0 ) ) ).x; //RMS
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
                case 7:
                case 8:
                case 9:
                default:
                    break;
                }

                return PrintNumberOnLine( value, number_area_cols-offset, dig.x + xoffset, fmxy, offset, leadingzero );                
            }
            ENDCG
        }
    }
}
