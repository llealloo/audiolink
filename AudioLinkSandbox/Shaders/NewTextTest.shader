Shader "AudioLinkSandbox/NewTextTest"
{
    Properties
    {
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
            #pragma target 5.0
            #include "UnityCG.cginc"
            #include "../../AudioLink/Shaders/SmoothPixelFont.cginc"

            #define PIXELFONT_ROWS 20
            #define PIXELFONT_COLS 30

            #ifndef glsl_mod
            #define glsl_mod(x, y) (x - y * floor(x / y))
            #endif

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 iuv = i.uv;
                iuv.y = 1.0 - iuv.y;
                
                // Pixel location on font pixel grid
                float2 pos = iuv * float2(PIXELFONT_COLS, PIXELFONT_ROWS);

                // Pixel location as uint (floor)
                uint2 pixel = (uint2)pos;

                // This line of code is tricky;  We determine how much we should soften the edge of the text
                // based on how quickly the text is moving across our field of view.  This gives us realy nice
                // anti-aliased edges.
                float2 softness_uv = pos * float2( 4, 6 );
                float softness = 4./(pow( length( float2( ddx( softness_uv.x ), ddy( softness_uv.y ) ) ), 0.5 ))-1.;

                float2 charUV = float2(4, 6) - glsl_mod(pos, 1.0) * float2(4.0, 6.0);
                
                if (pixel.y < 2)
                {
                    uint charLines[11] = {__H, __e, __l, __l, __o, __SPACE, __w, __o, __r, __l, __d};
                    return PrintChar(charLines[pixel.x + pixel.y * 30], charUV, softness, 0);
                }
                else if (pixel.y == 2)
                {
                    if (pixel.x < 5)
                    {
                        float value = 1.0899;
                        return PrintNumberOnLine(value, charUV, softness, pixel.x, 1, 3, false, 0);                
                    }
                    else
                    {
                        float value = -2.3;
                        return PrintNumberOnLine(value, charUV, softness, pixel.x - 5, 3, 2, false, 0);                
                    }
                }
                else
                {
                    uint charNum = (pixel.y - 3) * 30 + pixel.x;
                    return PrintChar(charNum, charUV, softness, 0);
                }
            }
            ENDCG
        }
    }
}
