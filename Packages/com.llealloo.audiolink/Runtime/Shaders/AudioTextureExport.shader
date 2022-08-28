Shader "AudioLink/Internal/AudioTextureExport"
{
    Properties
    {
        [HideInInspector] _MainTex ("MainTex", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "Queue"="Geometry" "RenderType"="Opaque" "AudioLinkExport"="AudioLinkExport" }
        Pass
        {
            Tags { "LightMode"="Vertex" }
            ColorMask 0
            ZTest Off
        }
        GrabPass
        {
            Tags { "LightMode"="Vertex" }
            "_AudioTexture"
        }
        Pass
        {
            Tags { "LightMode"="ForwardBase" }
            ColorMask 0
            ZTest Off
        }
    }
}