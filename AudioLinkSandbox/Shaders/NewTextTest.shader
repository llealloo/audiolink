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
            #include "SmoothPixelFont.cginc"

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

            ////////////////////////////////////////////////////////////////////
            // General debug functions below here

            // Shockingly, including the ability to render text doesn't
            // slow down number printing if text isn't used.
            // A basic versino of the debug screen without text was only 134
            // instructions.

            float PrintChar(uint selChar, float2 charUV, float2 softness)
            {
                // .x = 15% .y = 35% added, it's 1.0. ( 0 1 would be 35% )
                charUV += float2(0, 0.5);
                uint2 bitmap = bitmapFont[selChar];
                uint4 bma = bitmap.xxxx;
                uint4 bmb = bitmap.yyyy;
                uint2 charXY = charUV;
                uint index = charXY.x + charXY.y * 4 - 4;
                uint4 shft = uint4(0, 1, 4, 5) + index;
                uint4 andone = uint4(1, 1, 1, 1);
                bma = (bma >> shft) & andone;
                bmb = (bmb >> shft) & andone;
                float4 neighbors = (bmb & 1) ? (bma ? 1 : 0.35) : (bma ? 0.15 : 0);
                float2 shift = smoothstep(0, 1, frac(charUV));
                float o = lerp(
                          lerp(neighbors.x, neighbors.y, shift.x),
                          lerp(neighbors.z, neighbors.w, shift.x), shift.y);
                return saturate(o * softness - softness / 2);
            }

            // Used for debugging
            float PrintNumberOnLine(float number, uint fixedDiv, uint digit, float2 charUV, uint numFractDigits, bool leadZero, float2 softness)
            {
                uint selNum;
                if (number < 0 && digit == 0)
                {
                    selNum = 22;  // - sign
                }
                else
                {
                    number = abs(number);

                    if (digit == fixedDiv)
                    {
                        selNum = 23; 
                    }
                    else
                    {
                        int dmfd = (int)digit - (int)fixedDiv;
                        if (dmfd > 0)
                        {
                            //fractional part.
                            uint fpart = round(frac(number) * pow(10, numFractDigits));
                            uint l10 = pow(10.0, numFractDigits - dmfd);
                            selNum = ((uint)(fpart / l10)) % 10;
                        }
                        else
                        {
                            float l10 = pow(10.0, (float)(dmfd + 1));
                            selNum = (uint)(number * l10);

                            //Disable leading 0's?
                            if (!leadZero && dmfd != -1 && selNum == 0 && dmfd < 0.5)
                                selNum = 10; // space
                            else
                                selNum %= (uint)10;
                        }
                    }
                }

                return PrintChar(selNum, charUV, softness);
            }

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
                
                float2 pos = iuv * float2(PIXELFONT_COLS, PIXELFONT_ROWS);
                uint2 dig = (uint2)pos;

                // This line of code is tricky;  We determine how much we should soften the edge of the text
                // based on how quickly the text is moving across our field of view.  This gives us realy nice
                // anti-aliased edges.
                float2 softness = 2.0 / pow(length(float2(ddx(pos.x), ddy(pos.y))), 0.5);

                // Another option would be to set softness to 20 and YOLO it.
                float2 fmxy = float2(4, 6) - glsl_mod(pos, 1.0) * float2(4.0, 6.0);
                
                if (dig.y < 2)
                {
                    uint charLines[11] = {__H, __E, __L, __L, __O, __SPACE, __W, __O, __R, __L, __D};
                    return PrintChar(charLines[dig.x + dig.y * 30], fmxy, softness);
                }
                else if (dig.y == 2)
                {
                    if (dig.x < 5)
                    {
                        float value = 1.0899;
                        return PrintNumberOnLine(value, 1, dig.x, fmxy, 3, false, softness);                
                    }
                    else
                    {
                        float value = -2.3;
                        return PrintNumberOnLine(value, 3, dig.x - 5, fmxy, 2, false, softness);                
                    }
                }
                else
                {
                    uint sendChar = (dig.y - 3) * 30 + dig.x;
                    return PrintChar(sendChar, fmxy, softness);
                }
            }
            ENDCG
        }
    }
}
