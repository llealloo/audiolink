﻿Shader "Custom/DissolveWall"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf Standard fullforwardshadows alpha

		#include "Assets/AudioLinkSandbox/Shaders/hashwithoutsine/hashwithoutsine.cginc"
		#include "Packages/com.llealloo.audiolink/Runtime/Shaders/AudioLink.cginc"
        #pragma target 5.0

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
			float3 worldPos;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;
		
		

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
			float dist = length( _WorldSpaceCameraPos - IN.worldPos );
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
			
			dist = min( dist, 2.3 );

			float alpha = (csimplex3( IN.worldPos*5 + float3( 20, 20, frac( AudioLinkDecodeDataAsSeconds( ALPASS_GENERALVU_NETWORK_TIME ) / 10000 ) * 5000 ) )*.75 + dist-1.7);
            o.Albedo = c.rgb;
			o.Emission = saturate(c.rgb*6-.1)*saturate(alpha+1);
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
			
            o.Alpha = saturate(alpha);
        }
        ENDCG
    }
    FallBack "Diffuse"
}
