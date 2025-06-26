﻿Shader "AudioLink/Debug/AudioLinkQuickView"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
		_MainTex ("Normal", 2D) = "white" {}
    }
    SubShader
    {
		Tags {"Queue" = "Transparent" "RenderType"="Opaque" }
		AlphaToMask On

        LOD 200
        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite On

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 5.0

            #include "UnityCG.cginc"
            #include "Packages/com.llealloo.audiolink/Runtime/Shaders/AudioLink.cginc"
            #include "Packages/com.llealloo.audiolink/Runtime/Shaders/SmoothPixelFont.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            half _Glossiness;
            half _Metallic;
            fixed4 _Color;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 c = 0.;

                float value = 0;

                float2 iuv = i.uv;
                iuv.y = 1.-iuv.y;
                const uint rows = 11;
                const uint cols = 21;
                const uint number_area_cols = 11;

                float2 pos = iuv*float2(cols,rows);
                uint2 dig = (uint2)(pos);

                // Calculate softness for anti-aliasing based on derivative
                float2 softness = 2./pow(length(float2(ddx(pos.x), ddy(pos.y))), 0.5);

                float2 fmxy = float2(4, 6) - (glsl_mod(pos,1.)*float2(4.,6.));

                value = 0;
                int xoffset = 5;
                bool leadingzero = false;
                int points_after_decimal = 0;
                int max_decimals = 5;

                if (pos.y > 10.9)
                {
                    // Prevent ugly under-chart next line.
                    c = 0;
                }
                else if (dig.x < cols - number_area_cols && dig.y < 8)
                {
                    uint sendchar = 0;
                    const uint sendarr[80] = {
                        'I', 'n', 's', 't', 'a', 'n', 'c', 'e', ' ', ' ',
                        'W', 'a', 'l', 'l', 'c', 'l', 'o', 'c', 'k', ' ',
                        'N', 'e', 't', 'w', 'o', 'r', 'k', ' ', ' ', ' ',
                        'A', 'u', 't', 'o', ' ', 'g', 'a', 'i', 'n', ' ',
                        'V', 'e', 'r', 's', 'i', 'o', 'n', ' ', ' ', ' ',
                        'R', 'M', 'S', ' ', 'v', 'a', 'l', 'u', 'e', ' ',
                        'F', 'P', 'S', ' ', 'T', '/', 'A', 'L', ' ', ' ',
                        'P', 'l', 'a', 'y', 'e', 'r', 'I', 'n', 'f', 'o'
                    };
                    sendchar = sendarr[dig.x+dig.y*10];
                    c += PrintChar(sendchar, fmxy, softness, 0.0);
                }
                else
                {
                    if (dig.y < 10)
                        dig.x -= cols - number_area_cols;

                    switch (dig.y)
                    {
                    case 0:
                    case 1:
                        // Time since level start in milliseconds.
                        // Time of day.
                        value = AudioLinkDecodeDataAsSeconds(dig.y?ALPASS_GENERALVU_LOCAL_TIME:ALPASS_GENERALVU_INSTANCE_TIME);
                        float seconds = glsl_mod(value, 60);
                        int minutes = (value/60) % 60;
                        int hours = (value/3600);
                        value = hours * 10000 + minutes * 100 + seconds;

                        if (dig.x < 3)
                        {
                            value = hours;
                            xoffset = 2;
                            leadingzero = 1;
                        }
                        else if (dig.x < 5)
                        {
                            value = minutes;
                            xoffset = 5;
                            leadingzero = 1;
                        }
                        else if (dig.x > 5)
                        {
                            value = seconds;
                            xoffset = 8;
                            leadingzero = 1;
                        }
                        break;
                    case 2:
                        if (dig.x < 8)
                        {
                            value = AudioLinkDecodeDataAsUInt(ALPASS_GENERALVU_NETWORK_TIME)/1000;
                            xoffset = 7;
                        }
                        else
                        {
                            value = AudioLinkDecodeDataAsUInt(ALPASS_GENERALVU_NETWORK_TIME)%1000;
                            xoffset = 11;
                            leadingzero = 1;
                        }
                        break;
                    case 3:
                        value = AudioLinkData(int2(ALPASS_GENERALVU + int2(11, 0))); //Autogain Debug
                        break;
                    case 4:
                        if (dig.x < 7)
                        {
                            xoffset = 6;
                            value = AudioLinkData(int2(ALPASS_GENERALVU + int2(0, 0))).g; //Version Major
                        }
                        else
                        {
                            xoffset = 8;
                            value = AudioLinkData(int2(ALPASS_GENERALVU + int2(0, 0))).r; //Version Minor
                        }
                        break;
                    case 5:
                        value = AudioLinkData(int2(ALPASS_GENERALVU + int2(8, 0))).x; //RMS
                        break;
                    case 6:
                        if (dig.x < 7)
                        {
                            value = AudioLinkData(int2(ALPASS_GENERALVU + int2(0, 0))).b; //True FPS
                            xoffset = 7;
                        }
                        else
                        {
                            value = AudioLinkData(int2(ALPASS_GENERALVU + int2(1, 0))).b; //AudioLink FPS
                            xoffset = 11;
                        }
                        break;
                    case 7:
                        if (dig.x < 3)
                        {
                            value = AudioLinkData(int2(ALPASS_GENERALVU_PLAYERINFO)).r;
                            xoffset = 3;
                        }
                        else if (dig.x < 9)
                        {
                            value = AudioLinkData(int2(ALPASS_GENERALVU_PLAYERINFO)).g;
                            xoffset = 9;
                        }
                        else
                        {
                            value = AudioLinkData(int2(ALPASS_GENERALVU_PLAYERINFO)).b;
                            xoffset = 11;
                        }
                        break;
                    case 8:
                    case 9:
                    case 10:
                        if (dig.y < 10)
                        {
                            value = AudioLinkData(int2(ALPASS_GENERALVU + int2(7, 0)))[dig.y-8];
                        }
                        else
                        {
                            float3 wp = mul(unity_ObjectToWorld, float4(0., 0., 0., 1.));
                            if (dig.x < 6)
                            {
                                value = wp.x;
                                xoffset = 6;
                            }
                            else if (dig.x < 14)
                            {
                                value = wp.y;
                                xoffset = 14;
                            }
                            else
                            {
                                value = wp.z;
                                xoffset = 21;
                            }
                        }

                        float4 amplitudemon = AudioLinkData(ALPASS_WAVEFORM + int2(iuv.x*128, 0));
                        float2 uvin = (iuv.xy*float2(1., 11./3.)-float2(0., 8./3.));
                        float r = amplitudemon.r + amplitudemon.a;
                        float l = amplitudemon.r - amplitudemon.a;
                        float comp = uvin.y * 2. - 1.;
                        float ramp = saturate((.05 - abs(r - comp)) * 40.);
                        float lamp = saturate((.05 - abs(l - comp)) * 40.);
                        c.xyz += float3(1., 0.2, 0.2) * ramp + float3(.2, .2, 1.) * lamp;
                        c.a = saturate(ramp + lamp);
                        break;
                    default:
                        c = 0;
                        break;
                    }
                    float num = PrintNumberOnLine(value, fmxy, softness, dig.x - xoffset, points_after_decimal, max_decimals, leadingzero, 0);
                    c.rgb = lerp(c.rgb, 1.0, num);
                    c.a += num;
                }

                return c;
            }
            ENDCG
        }

        // shadow caster rendering pass, implemented manually
        // using macros from UnityCG.cginc
        Pass
        {
            Tags {"LightMode"="ShadowCaster"}

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_shadowcaster
            #include "UnityCG.cginc"

            struct v2f {
                V2F_SHADOW_CASTER;
            };

            v2f vert(appdata_base v)
            {
                v2f o;
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                SHADOW_CASTER_FRAGMENT(i)
            }
            ENDCG
        }

        Pass
        {
            Name "DepthOnly"
            Tags {"LightMode" = "DepthOnly"}

            ZWrite On
            ColorMask 0

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 5.0

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                return 0;
            }
            ENDCG
        }

        Pass
        {
            Name "DepthNormals"
            Tags {"LightMode" = "DepthNormals"}

            ZWrite On

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 5.0

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                float3 normal = normalize(i.normal);
                float2 encodedNormal = normalize(normal.xy) * sqrt(normal.z * 0.5 + 0.5);
                encodedNormal = encodedNormal * 0.5 + 0.5;
                return float4(encodedNormal, 0, 0);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
