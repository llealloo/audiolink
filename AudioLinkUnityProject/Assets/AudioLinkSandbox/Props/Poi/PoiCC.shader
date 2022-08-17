Shader "AudioLink/AudioLinkSandbox/PoiCC"
{
    Properties
    {
        [HideInInspector] _TANoiseTex ("TANoise", 2D) = "white" {}
        _TimeCompensation ("Time Compensation", float ) = .1
    }
    SubShader
    {
        //Tags { "RenderType"="Opaque" }
        Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}
        Blend SrcAlpha One
        ZWrite Off
        Cull Off
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma geometry geo
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "Packages/com.llealloo.audiolink/Runtime/Shaders/AudioLink.cginc"
            #include "/Assets/AudioLinkSandbox/Shaders/tanoise/tanoise.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float3 tangent : TANGENT;
                float4 uv : TEXCOORD0;
            };
 
            struct v2g
            {
                float4 vertex : SV_POSITION;
                float3 normal : NORMAL;
                float3 tangent : TANGENT;
                float4 uv : TEXCOORD0;
            };
 
            struct g2f
            {
                float4 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float3 tangent : TANGENT;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };
 
 
            float _TimeCompensation;

 
            v2g vert (appdata v)
            {
                v2g o;
                o.vertex = v.vertex;
                o.uv = v.uv;
                o.normal = v.normal;
                o.tangent = v.tangent;
                
                return o;
            }
            
            [maxvertexcount(6)]
            void geo(triangle v2g IN[3], inout TriangleStream<g2f> triStream)
            {
                g2f o;
  
                //XXX TODO: This could be done in a vertex shder - go back to a vertex shader.
  
                for(int i = 0; i < 3; i++)
                {
                    float4 ivertex = IN[i].vertex;
                    float3 inorm = IN[i].normal;
                    float3 itan = IN[i].tangent;
                    float4 iuv = IN[i].uv;
                    float flip = (iuv.y > 0.5)?1.:-1.;
                    float extrathicc = 
                        //(AudioLinkLerp( ALPASS_AUTOCORRELATOR + uint2( 127-iuv.x*128, 0. )))*.3;
                        sin( iuv.x*3.14*8-.1 )*.1;
                    ivertex.xyz += cross( inorm, itan ) * extrathicc * flip;
                    
                    o.vertex = UnityObjectToClipPos(ivertex);
                    UNITY_TRANSFER_FOG(o,o.vertex);
                    o.uv = iuv;
                    o.normal = inorm;
                    o.tangent = itan;
                    if( extrathicc > -.11 )
                    {
                        triStream.Append(o);
                    }
                }
 
                triStream.RestartStrip();
            }
            
            fixed4 frag (g2f i) : SV_Target
            {
                //return float4( i.uv.xy*10., 1., 1. );
                float UseTime = AudioLinkDecodeDataAsSeconds( ALPASS_GENERALVU_NETWORK_TIME );
                float strippos = frac(i.uv.x - UseTime * _TimeCompensation) * 32;
                fixed4 col = AudioLinkLerp( ALPASS_CCLIGHTS + float2( strippos, 0. ) );//float4( , 0, 0, 1 );
                
                float fadeoff = 1. - abs( i.uv.y - 0.5 ) * 2.;
                col *= smoothstep( 0, 1, fadeoff );
                
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
