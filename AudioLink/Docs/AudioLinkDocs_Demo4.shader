Shader "AudioLinkDocs/Demo4"
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
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float3 vpOrig : TEXCOORD0;
                float3 vpXform : TEXCOORD1;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                float3 vp = v.vertex;

                o.vpOrig = vp;

                // Generate a value for how far around the circle you are.
                // atan2 generates a number from -pi to pi.  We want to map
                // this from -1..1.  Tricky: add 0.001 to x otherwise
                // we lose a vertex at the poll because atan2 is undefined.
                float phi = atan2( vp.x+0.001, vp.z ) / 3.14159;
                
                // We want to mirror the -1..1 so that it's actually 0..1 but
                // mirrored.
                float placeinautocorrelator = abs( phi );
                
                // Note: We don't need lerp multiline because the autocorrelator
                // is only a single line.
                float autocorrvalue = AudioLinkLerp( ALPASS_AUTOCORRELATOR +
                    float2( placeinautocorrelator * AUDIOLINK_WIDTH, 0. ) );
                
                // Squish in the sides, and make it so it only perterbs
                // the surface.
                autocorrvalue = autocorrvalue * (.8-abs(vp.y)) * 0.3 + .6;

                vp *= autocorrvalue;

                o.vpXform = vp;                
                o.vertex = UnityObjectToClipPos(vp);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // Decide how we want to color from colorchord.
                float ccplace = length( i.vpXform.z );
                
                // Get a color from ColorChord
                float4 colorchordcolor = AudioLinkData( ALPASS_CCSTRIP + float2( AUDIOLINK_WIDTH * ccplace, 0. ) ) + 0.01;

                // Shade the color a little.
                colorchordcolor *= length( i.vpXform.xyz ) * 10. - 1.0;
                return colorchordcolor;
            }
            ENDCG
        }
    }
}