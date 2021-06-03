Shader "AudioLinkSandbox/TrollTextTest"
{
    Properties
    {
		_TextThicknessTexture("Texture", 2D) = "white" {}
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

            #define PIXELFONT_ROWS 35
            #define PIXELFONT_COLS 80

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
			
			
			#ifndef glsl_mod
			#define glsl_mod(x,y) (((x)-(y)*floor((x)/(y))))
			#endif

            ////////////////////////////////////////////////////////////////////
            // General debug functions below here

            // Shockingly, including the ability to render text doesn't
            // slow down number printing if text isn't used.
            // A basic versino of the debug screen without text was only 134
            // instructions.

            float PrintChar(uint charNum, float2 charUV, float2 softness, float weight )
            {
                // .x = 15% .y = 35% added, it's 1.0. ( 0 1 would be 35% )
                //charUV += float2(0, 0.5);
                uint2 bitmap = bitmapFont[charNum];
                uint4 bitmapA = bitmap.xxxx;
                uint4 bitmapB = bitmap.yyyy;
                uint2 pixel = charUV;
                uint index = pixel.x + pixel.y * 4;
                uint4 shift = uint4(0, 1, 4, 5) + index;
                uint4 bitSelect = uint4(1, 1, 1, 1);
                bitmapA = (bitmapA >> shift) & bitSelect;
                bitmapB = (bitmapB >> shift) & bitSelect;
                float4 neighbors = (bitmapB & 1) ? (bitmapA ? 1 : 0.35) : (bitmapA ? 0.15 : 0);
                float2 pixelUV = smoothstep(0, 1, frac(charUV));
                float o = lerp(
                          lerp(neighbors.x, neighbors.y, pixelUV.x),
                          lerp(neighbors.z, neighbors.w, pixelUV.x), pixelUV.y) + weight;
                return saturate(o * softness - softness / 2);
            }

            // Print a number on a line
            //
            // value            (float) Number value to display
            // charUV           (float2) coordinates on the character to render
            // softness
            // digit            (uint) Digit in number to render
            // digitOffset      (uint) Shift digits to the right
            // numFractDigits   (uint) Number of digits to round to after the decimal
            //
            float PrintNumberOnLine(float value, float2 charUV, float2 softness, uint digit, uint digitOffset, uint numFractDigits, bool leadZero, float weight )
            {
                uint charNum;
                if (value < 0 && digit == 0) 
                { 
                    charNum = __DASH;
                }
                else
                {
                    value = abs(value);

                    if (digit == digitOffset)
                    {
                        charNum = __PERIOD;
                    }
                    else
                    {
                        int dmfd = (int)digit - (int)digitOffset;
                        if (dmfd > 0)
                        {
                            //fractional part.
                            uint fpart = round(frac(value) * pow(10, numFractDigits));
                            uint l10 = pow(10.0, numFractDigits - dmfd);
                            charNum = ((uint)(fpart / l10)) % 10;
                        }
                        else
                        {
                            float l10 = pow(10.0, (float)(dmfd + 1));
                            charNum = (uint)(value * l10);

                            //Disable leading 0's?
                            if (!leadZero && dmfd != -1 && charNum == 0 && dmfd < 0.5)
                                charNum = 10; // space
                            else
                                charNum %= (uint)10;
                        }
                    }
                }

                return PrintChar(charNum, charUV, softness, weight);
            }

			sampler2D _TextThicknessTexture;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }
			
			float hash12(float2 p)
			{
				float3 p3  = frac(float3(p.xyx) * .1031);
				p3 += dot(p3, p3.yzx + 33.33);
				return frac((p3.x + p3.y) * p3.z);
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
                float2 softness = 1.5 / pow(length(float2(ddx(pos.x), ddy(pos.y))), 0.5);

                // Another option would be to set softness to 20 and YOLO it.
                float2 charUV = float2(4, 6) - glsl_mod(pos, 1.0) * float2(4.0, 6.0);
                
				// Swirley
				//float2 gcrv = i.uv-.5;
				//float weight = 	sin( length(i.uv-.5) * 40. - _Time.y * 4. + atan2(gcrv.x,gcrv.y) ) * .5;
				float weight = (length( tex2D( _TextThicknessTexture, float2( 0., 1. ) + i.uv * float2( 1, -1 )  ) ))*.97 - 1.45;

                if (pixel.y < 2)
                {
                    uint charLines[11] = {__H, __e, __l, __l, __o, __SPACE, __w, __o, __r, __l, __d};
                    return PrintChar(charLines[pixel.x + pixel.y * 30], charUV, softness, weight);
                }
                else if (pixel.y == 2)
                {
                    if (pixel.x < 5)
                    {
                        float value = 1.0899;
                        return PrintNumberOnLine(value, charUV, softness, pixel.x, 1, 3, false, weight );
                    }
                    else
                    {
                        float value = _Time.y;
                        return PrintNumberOnLine(value, charUV, softness, pixel.x - 5, 3, 5, false, weight);
                    }
                }
                else
                {
                    //uint charNum = ( glsl_mod( (((pixel.y - 3) * 30 + pixel.x)), 80 ) );
                    uint charNum = glsl_mod( floor( hash12( pixel ) * 100 + _Time.y*2.), 80. );
                    return PrintChar(charNum, charUV, softness, weight);
                }
            }
            ENDCG
        }
    }
}
