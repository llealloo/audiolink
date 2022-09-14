Shader "NoteCRTShader"
{
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
        }

        Pass
        {
            CGINCLUDE
            #pragma target 5.0
            #pragma vertex CustomRenderTextureVertexShader
            #pragma fragment frag

            #define _SelfTexture2D _JunkTexture
            #include "UnityCustomRenderTexture.cginc"
            #undef _SelfTexture2D
            Texture2D<float4> _SelfTexture2D;

            #include "UnityCG.cginc"
            #include "Packages/com.llealloo.audiolink/Runtime/Shaders/AudioLink.cginc"

            float4 _SelfTexture2D_TexelSize;
            ENDCG

            Name "History"
            CGPROGRAM
            float4 frag(v2f_customrendertexture IN) : SV_Target
            {
                float2 guv = IN.globalTexcoord.xy;
                uint2 coordinateGlobal = round(guv / _SelfTexture2D_TexelSize.xy - 0.5);

                float4 color;

                if (coordinateGlobal.y == 0)
                {
                    color.x = pow(AudioLinkGetAmplitudesAtNote(coordinateGlobal.x).y,2);
                }
                else
                {
                    color.x = _SelfTexture2D[coordinateGlobal - uint2(0, 1)].w;
                }
                color.y = _SelfTexture2D[coordinateGlobal].x;
                color.z = _SelfTexture2D[coordinateGlobal].y;
                color.w = _SelfTexture2D[coordinateGlobal].z;

                return color;
            }
            ENDCG
        }
        Pass
        {
            Name "Average"
            CGPROGRAM
            float4 frag(v2f_customrendertexture IN) : SV_Target
            {
                float2 guv = IN.globalTexcoord.xy;
                uint2 coordinateGlobal = round(guv / _SelfTexture2D_TexelSize.xy - 0.5);

                float4 color;

                uint y;
                uint x;

                _SelfTexture2D.GetDimensions(x,y);
                
                for (uint i = 0; i < (y-1); i++)
                {
                    color += _SelfTexture2D[uint2(coordinateGlobal.x, i)];
                }
                color = color.x + color.y + color.z + color.w;

                return color / ((y - 1) * 4);
            }
            ENDCG


        }
    }
}
