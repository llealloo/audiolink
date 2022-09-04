Shader "Custom/AudioLinkMixedBands (HSV)" {
        Properties
        {

		[HDR][Header(Color)]
		_Hue ("Hue", Range(0,360)) = 0
		_Saturation ("Saturation", Range(0,1)) = 1
		_Brightness ("Brightness", Range(0,4)) = 1

			
		[HDR][Header(Textures)]
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (UV1)", 2D) = "white" {}

		_Detail ("Detail (UV2)", 2D) = "white" {}
			
		[HDR][Header(Surface)]
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_Metallic ("Metallic", Range(0,1)) = 0.0

			
		[HDR][Header(Emission)]
		_EmissionColor ("Color", Color) = (1,1,1,1)
        _EmissionMap ("Emission", 2D) = "white" {}
		
		[HDR][Header(AudioLink)]
		_ALInfluence("Influence", Range(0.0, 1.0)) = 1

		_ALTrebel("Trebel", Range(0.0, 1.0)) = 1
		_ALMidHigh("MidHigh", Range(0.0, 1.0)) = 1
		_ALMidLow("MidLow", Range(0.0, 1.0)) = 1
		_ALBass("Bass", Range(0.0, 1.0)) = 1

		
		[HDR][Header(Rendering)]
    	[Enum(UnityEngine.Rendering.CullMode)] _CullMode("Cull Mode", Int) = 0

        }
        SubShader
        {
             Tags {
				 "RenderType"="Transparent"
				 "Queue"="Transparent"
			 }
            LOD 200
             Pass {
                 ColorMask 0
             }
                 ZWrite Off
                 Blend SrcAlpha OneMinusSrcAlpha
				 Cull [_CullMode]
 
   
            CGPROGRAM
 
            #pragma surface surf Standard fullforwardshadows alpha:fade
            #pragma target 3.0

			#include "Packages/com.llealloo.audiolink/Runtime/Shaders/AudioLink.cginc"
 
 
 
            sampler2D _MainTex;
			sampler2D _Detail;
			sampler2D _EmissionMap;
	
			struct Input {
				float2 uv_MainTex;
				float2 uv2_Detail;
				float2 uv_EmissionMap;
			};
 
            half _Glossiness;
            half _Metallic;
            fixed4 _Color;
			fixed4 _EmissionColor;

			uniform float _Hue;
			uniform float _Brightness;
			uniform float _Saturation;

			uniform float _ALInfluence;
			uniform float _ALBass;
			uniform float _ALMidLow;
			uniform float _ALMidHigh;
			uniform float _ALTrebel;

			float3 shift_col(float3 RGB, float3 shift)
			{
				float3 RESULT = float3(RGB);
				float VSU = shift.z*shift.y*cos(shift.x*3.14159265 / 180);
				float VSW = shift.z*shift.y*sin(shift.x*3.14159265 / 180);

				RESULT.x = (.299*shift.z + .701*VSU + .168*VSW)*RGB.x
					+ (.587*shift.z - .587*VSU + .330*VSW)*RGB.y
					+ (.114*shift.z - .114*VSU - .497*VSW)*RGB.z;

				RESULT.y = (.299*shift.z - .299*VSU - .328*VSW)*RGB.x
					+ (.587*shift.z + .413*VSU + .035*VSW)*RGB.y
					+ (.114*shift.z - .114*VSU + .292*VSW)*RGB.z;

				RESULT.z = (.299*shift.z - .3*VSU + 1.25*VSW)*RGB.x
					+ (.587*shift.z - .588*VSU - 1.05*VSW)*RGB.y
					+ (.114*shift.z + .886*VSU - .203*VSW)*RGB.z;

				return (RESULT);
			}
 
            void surf (Input IN, inout SurfaceOutputStandard o)
            {

				float AL1 = AudioLinkIsAvailable() ? ( AudioLinkData(ALPASS_AUDIOLINK + int2( IN.uv_MainTex.y * 127 , 0 )).g) : 0;
				float AL2 = AudioLinkIsAvailable() ? ( AudioLinkData(ALPASS_AUDIOLINK + int2( IN.uv_MainTex.y * 127 , 1 )).g) : 0;
				float AL3 = AudioLinkIsAvailable() ? ( AudioLinkData(ALPASS_AUDIOLINK + int2( IN.uv_MainTex.y * 127 , 2 )).g) : 0;
				float AL4 = AudioLinkIsAvailable() ? ( AudioLinkData(ALPASS_AUDIOLINK + int2(IN.uv_MainTex.y * 127 , 3 )).g) : 0;

				float AL = ( ((AL1 * _ALBass) + (AL2 * _ALMidLow) + (AL3  *_ALMidHigh) + (AL4 * _ALTrebel)) / 4 ) * _ALInfluence;

				fixed4 e = tex2D(_EmissionMap, IN.uv_EmissionMap) * _EmissionColor * AL;

                fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
				fixed4 d = tex2D(_Detail, IN.uv2_Detail);
				
				fixed4 combined = c * d;

				o.Albedo = shift_col(combined.rgb,float3(_Hue, _Saturation, _Brightness));
				o.Metallic = _Metallic;
				o.Smoothness = _Glossiness;
				o.Emission = shift_col(e.rgb,float3(_Hue, _Saturation, AL * 10));

                o.Alpha = c.a;
            }
            ENDCG
        }
        FallBack "Standard"
    }