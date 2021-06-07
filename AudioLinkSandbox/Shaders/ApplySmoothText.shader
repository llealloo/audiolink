Shader "AudioLinkSandbox/ApplySmoothText"
{
    Properties
    {
		_TextData ("TextData", 2D) = "white" {}
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


            #ifndef glsl_mod
            #define glsl_mod(x, y) (x - y * floor(x / y))
            #endif

			Texture2D<float4> _TextData;
			float4 _TextData_TexelSize;

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
                float2 pos = iuv * float2(_TextData_TexelSize.zw);

                // Character location as uint (floor)
                uint2 character = (uint2)pos;

				float4 dataatchar = _TextData[character];
				
                // This line of code is tricky;  We determine how much we should soften the edge of the text
                // based on how quickly the text is moving across our field of view.  This gives us realy nice
                // anti-aliased edges.
                float2 softness_uv = pos * float2( 4, 6 );
                float softness = 4./(pow( length( float2( ddx( softness_uv.x ), ddy( softness_uv.y ) ) ), 0.5 ))-1.;

                float2 charUV = float2(4, 6) - glsl_mod(pos, 1.0) * float2(4.0, 6.0);
                
				float weight = (floor(dataatchar.w)/2.-1.)*.3;
				int charVal = frac(dataatchar.w)*256;
				return PrintChar( charVal, charUV, softness, weight )*float4(dataatchar.rgb,1.);
            }
            ENDCG
        }
    }
}
