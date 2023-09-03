Shader "AudioLink/Invisible"
{
    SubShader
    {
        Pass
        {
            CGPROGRAM
            #pragma vertex empty
            #pragma fragment empty
            #include "UnityCG.cginc"
            void empty() {}
            ENDCG
        }
    }
}
