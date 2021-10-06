Shader "AudioLink/Internal/AudioTextureExport"
{
    Properties
    {
        //_MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "AudioLinkExport"="AudioLinkExport"}
        LOD 100
        GrabPass {"_AudioTexture"}
        Pass {
        CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            float4 vert (float4 v: POSITION) : SV_Position { return 1; }
            float4 frag (float4 f: SV_Position) : SV_Target { return 1; }
        ENDCG
        }
    }
}
