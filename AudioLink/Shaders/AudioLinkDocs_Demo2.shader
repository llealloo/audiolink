Shader "AudioLink/Examples/Demo2"
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


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {                
                float Sample = AudioLinkLerpMultiline( ALPASS_WAVEFORM + float2( 200. * i.uv.x, 0 ) ).r;
                return clamp( 1 - 50 * abs( Sample - i.uv.y* 2. + 1 ), 0, 1 );
            }
            ENDCG
        }
    }
}