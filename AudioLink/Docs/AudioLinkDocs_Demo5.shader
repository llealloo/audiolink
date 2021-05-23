Shader "AudioLinkDocs/Demo5"
{
    Properties
    {
        _AudioLinkTexture ("AudioLink Texture", 2D) = "" {}
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

            #include "../Shaders/AudioLink.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float3 uvw : TEXCOORD0;
				float3 normal : TEXCOORD8;
				float3 opos : TEXCOORD9;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                float3 vp = v.vertex;

				int whichzone = floor(v.uv.x-1);
                float alpressure = AudioLinkData( ALPASS_AUDIOLINK + int2( 0, whichzone ) ).x;

				vp.x -= alpressure * .5;

				o.opos = vp;
                o.uvw = float3( frac( v.uv ), whichzone + 0.5 );                
                o.vertex = UnityObjectToClipPos(vp);
				o.normal = v.normal;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
				float radius = length( i.uvw.xy - 0.5 ) * 30;
				float3 color = 0;
				if( i.uvw.z >= 0 )
				{
					color = AudioLinkData( ALPASS_AUDIOLINK + int2( radius, i.uvw.z ) ).rgb * 10. + 0.5;
					color = (dot(i.normal.xyz,float3(-1,1,1)))*.2;
					color *= AudioLinkData( ALPASS_CCLIGHTS + int2( i.uvw.z, 0) ).rgb;
				}
				else
				{
					color = abs(i.normal.xzy)*.01+.02;
				}
				
                return float4( color ,1. );
            }
            ENDCG
        }
    }
}