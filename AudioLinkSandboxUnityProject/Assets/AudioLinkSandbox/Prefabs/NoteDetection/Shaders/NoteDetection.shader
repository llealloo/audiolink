Shader "3/NoteDetection"
{
    Properties
    {
        [NonModifiableTextureData] [HideInInspector] _AudioLink ("Texture", 2D) = "black" {}
        [NonModifiableTextureData] [HideInInspector] _NoteArray ("Note Array", 2DArray) = "" {}
        _Texture ("Texture", 2D) = "black" {}
    }

    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
        }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Packages/com.llealloo.audiolink/Runtime/Shaders/AudioLink.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                nointerpolation float2 index: TEXCOORD1;
                float4 vertex : SV_POSITION;
            };

            sampler2D _AudioLink;
            Texture2D<float4> _Texture;
            sampler2D _DFTHistory;
            UNITY_DECLARE_TEX2DARRAY(_NoteArray);

            v2f vert(const appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;

                float local_max = 0;
                uint index = 0;


                for (int j = 0; j < 12; j++)
                {
                    float amplitude = _Texture[uint2(j, 63)].r;

                    if (amplitude > local_max)
                    {
                        local_max = amplitude;
                        index = j;
                    }
                }

                o.index = float2(index, local_max);
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                float index = i.index.x;

                uint note = index;

                return UNITY_SAMPLE_TEX2DARRAY(_NoteArray, float3(i.uv,note));
            }
            ENDCG
        }
    }
}
