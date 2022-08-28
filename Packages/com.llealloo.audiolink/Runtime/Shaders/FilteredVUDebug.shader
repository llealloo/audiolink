Shader "Unlit/FilteredVUDebug"
{
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "AudioLink.cginc"

            struct appdata
            {
                float2 uv : TEXCOORD0;
                float4 vertex : POSITION;
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
                i.uv.x *= 1.125;

                // Dividers
                if (frac(i.uv.x*4) < 0.02)
                    return float4(1, 0, 0, 1);

                // Show ground truth marker value
                if (i.uv.x > 1)
                    return (i.uv.y < AudioLinkData(ALPASS_GENERALVU + uint2(9, 0)).r) * float4( 0.8, 0.8, 0.8, 1.);

                // Sample filtered VU / markers
                float vu = AudioLinkData(ALPASS_FILTEREDVU_INTENSITY + uint2(i.uv.x*4, 0)).r;
                float marker = AudioLinkData(ALPASS_FILTEREDVU_MARKER + uint2(i.uv.x*4, 0)).r;

                // Show max markers
                if (abs(i.uv.y - marker) < 0.015)
                    return float4(0, 1, 0, 1);
                
                // Show columns
                return (i.uv.y < vu) * float4( 0.7, 0.7, 0.7, 1.);
            }
            ENDCG
        }
    }
}
