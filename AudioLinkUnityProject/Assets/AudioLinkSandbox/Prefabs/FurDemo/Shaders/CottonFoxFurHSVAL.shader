// Custom shader made by Juice...
Shader "Custom/CottonFoxFurHSVAL"
{
    Properties
    {
		[Header(Color)]
        _Emission__FurPrimary ("Emission", Range(0.0, 1.0)) = .5
		_Hue__FurPrimary ("Hue", Range(0.0, 360.0)) = 0.0
		_Sat__FurPrimary ("Saturation", Range(0.0, 1.0)) = 1.0
        _Invert__FurPrimary ("Invert", Range(0.0, 1.0)) = 0

		[Header(Environment)]
        _Specular__FurPrimary ("Specular", Range(0, 1)) = .25
		_DL__FurPrimary("Directional Light Influence", Range(0,1)) = 1
		_LP__FurPrimary("Light Probe Influence", Range(0,1)) = 1
		_Gloss__FurPrimary("Smoothness", Range(0,1)) = 0.5

		[HDR][Header(Texture (UV1))]
        _Color__FurPrimary ("Color", Color) = (1, 1, 1, 1)
        _MainTex__FurPrimary ("Texture", 2D) = "white" { }

		[Header(Fur (UV2))]
        _FurMap__FurPrimary ("Fur Map", 2D) = "white" { }
        _Density__FurPrimary ("Fur Density", Range(0.0, 1.0)) = .5
        _Length__FurPrimary ("Fur Length", Range(0.0, 1)) = 0.5
        _Shading__FurPrimary ("Fur Shading", Range(0.0, 1)) = 0.25

		[HDR][Header(Emission Mask (UV3))]
        _EmissionMask__FurPrimary ("Emission Mask", 2D) = "white" { }

		[Header(AudioLink (UV4))]
		_ALEmission__FurPrimary("AudioLink Emission", Range(0.0, 1.0)) = 1
		_ALFur__FurPrimary("AudioLink Fur", Range(0.0, 1.0)) = 1
        _ALRotation__FurPrimary("Rotation (π)", Range(-1.57075,  3.14159)) = 0.0
		_ALLength__FurPrimary("Wave Length", Range(0.0, 1.0)) = 1
		_ALTrebel__FurPrimary("Trebel", Range(0.0, 1.0)) = 1
		_ALMidHigh__FurPrimary("MidHigh", Range(0.0, 1.0)) = 1
		_ALMidLow__FurPrimary("MidLow", Range(0.0, 1.0)) = 1
		_ALBass__FurPrimary("Bass", Range(0.0, 1.0)) = 1

		[Header(Proximity Fading)]
        _Dither__FurPrimary ("Dither", Range(0,1)) = 1.0
        _MinDistance__FurPrimary ("Minimum Distance", float) = .2
        _MaxDistance__FurPrimary ("Maximum Distance", float) = .5
    }


    Category
    {

        Tags {
            "RenderType" = "Transparent"
            "Queue" = "Transparent"
            "LightMode" = "ForwardBase"
            }
        Cull Back
        ZWrite On
        Blend SrcAlpha OneMinusSrcAlpha
        
        SubShader
        {
            Pass {
                Tags { "LightMode" = "ShadowCaster" }
            }
            Pass {
                CGPROGRAM
                #pragma vertex vert_surface
                #pragma fragment frag_surface
                #define FURSTEP 0.00
                #include "CottonFoxFurHSVALHelper.cginc"
                ENDCG
            }
            Pass {
                CGPROGRAM
                #pragma vertex vert_base
                #pragma fragment frag_base
                #define FURSTEP 0.05
                #include "CottonFoxFurHSVALHelper.cginc"
                ENDCG
            }
            Pass {
                CGPROGRAM
                #pragma vertex vert_base
                #pragma fragment frag_base
                #define FURSTEP 0.10
                #include "CottonFoxFurHSVALHelper.cginc"
                ENDCG
            }
            Pass {
                CGPROGRAM
                #pragma vertex vert_base
                #pragma fragment frag_base
                #define FURSTEP 0.15
                #include "CottonFoxFurHSVALHelper.cginc"
                ENDCG
            }
            Pass {
                CGPROGRAM
                #pragma vertex vert_base
                #pragma fragment frag_base
                #define FURSTEP 0.20
                #include "CottonFoxFurHSVALHelper.cginc"
                ENDCG
            }
            Pass {
                CGPROGRAM
                #pragma vertex vert_base
                #pragma fragment frag_base
                #define FURSTEP 0.25
                #include "CottonFoxFurHSVALHelper.cginc"
                ENDCG
            }
            Pass {
                CGPROGRAM
                #pragma vertex vert_base
                #pragma fragment frag_base
                #define FURSTEP 0.30
                #include "CottonFoxFurHSVALHelper.cginc"
                ENDCG
            }
            Pass {
                CGPROGRAM
                #pragma vertex vert_base
                #pragma fragment frag_base
                #define FURSTEP 0.35
                #include "CottonFoxFurHSVALHelper.cginc"
                ENDCG
            }
            Pass {
                CGPROGRAM
                #pragma vertex vert_base
                #pragma fragment frag_base
                #define FURSTEP 0.40
                #include "CottonFoxFurHSVALHelper.cginc"
                ENDCG
            }
            Pass {
                CGPROGRAM
                #pragma vertex vert_base
                #pragma fragment frag_base
                #define FURSTEP 0.45
                #include "CottonFoxFurHSVALHelper.cginc"
                ENDCG
            }
            Pass {
                CGPROGRAM
                #pragma vertex vert_base
                #pragma fragment frag_base
                #define FURSTEP 0.50
                #include "CottonFoxFurHSVALHelper.cginc"
                ENDCG
            }
            Pass {
                CGPROGRAM
                #pragma vertex vert_base
                #pragma fragment frag_base
                #define FURSTEP 0.55
                #include "CottonFoxFurHSVALHelper.cginc"
                ENDCG
            }
            Pass {
                CGPROGRAM
                #pragma vertex vert_base
                #pragma fragment frag_base
                #define FURSTEP 0.60
                #include "CottonFoxFurHSVALHelper.cginc"
                ENDCG
            }
            Pass {
                CGPROGRAM
                #pragma vertex vert_base
                #pragma fragment frag_base
                #define FURSTEP 0.65
                #include "CottonFoxFurHSVALHelper.cginc"
                ENDCG
            }
            Pass {
                CGPROGRAM
                #pragma vertex vert_base
                #pragma fragment frag_base
                #define FURSTEP 0.70
                #include "CottonFoxFurHSVALHelper.cginc"
                ENDCG
            }
            Pass {
                CGPROGRAM
                #pragma vertex vert_base
                #pragma fragment frag_base
                #define FURSTEP 0.75
                #include "CottonFoxFurHSVALHelper.cginc"
                ENDCG
            }
            Pass {
                CGPROGRAM
                #pragma vertex vert_base
                #pragma fragment frag_base
                #define FURSTEP 0.80
                #include "CottonFoxFurHSVALHelper.cginc"
                ENDCG
            }
            Pass {
                CGPROGRAM
                #pragma vertex vert_base
                #pragma fragment frag_base
                #define FURSTEP 0.85
                #include "CottonFoxFurHSVALHelper.cginc"
                ENDCG
            }
            Pass {
                CGPROGRAM
                #pragma vertex vert_base
                #pragma fragment frag_base
                #define FURSTEP 0.90
                #include "CottonFoxFurHSVALHelper.cginc"
                ENDCG
            }
            Pass {
                CGPROGRAM
                #pragma vertex vert_base
                #pragma fragment frag_base
                #define FURSTEP 0.95
                #include "CottonFoxFurHSVALHelper.cginc"
                ENDCG
            }
            Pass {
                CGPROGRAM
                #pragma vertex vert_base
                #pragma fragment frag_base
                #define FURSTEP 1.00
                #include "CottonFoxFurHSVALHelper.cginc"
                ENDCG
            }
        }
    }
}