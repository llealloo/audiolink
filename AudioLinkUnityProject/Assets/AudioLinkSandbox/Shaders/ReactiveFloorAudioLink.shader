// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "ReactiveFloorAudioLink"
{
	Properties
	{
		_AudioLinkRadius("AudioLinkRadius", Float) = 0
		_GridRadius("GridRadius", Float) = 0
		_Color1("Color1", Color) = (0,0,0,0)
		_Color2("Color2", Color) = (0,0,0,0)
		_TextureSample0("Texture Sample 0", 2D) = "white" {}
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Custom"  "Queue" = "Transparent+0" }
		Cull Off
		ZWrite Off
		Blend One One
		
		CGPROGRAM
		#include "UnityPBSLighting.cginc"
		#pragma target 3.0
		#include "Packages/com.llealloo.audiolink/Runtime/Shaders/AudioLink.cginc"
		#pragma surface surf StandardCustomLighting keepalpha addshadow fullforwardshadows 
		struct Input
		{
			float3 worldPos;
			float2 uv_texcoord;
		};

		struct SurfaceOutputCustomLightingCustom
		{
			half3 Albedo;
			half3 Normal;
			half3 Emission;
			half Metallic;
			half Smoothness;
			half Occlusion;
			half Alpha;
			Input SurfInput;
			UnityGIInput GIData;
		};

		uniform float4 FeetPositions[200];
		uniform float _AudioLinkRadius;
		uniform float4 _Color1;
		uniform float4 _Color2;
		uniform sampler2D _TextureSample0;
		uniform float4 _TextureSample0_ST;
		uniform float4 PlayerPositions[100];
		uniform float _GridRadius;


		float4 AudioLinkIntensity3( float4 VectorArray, float Radius, float3 TestPosition, float4 ColorA, float4 ColorB )
		{
			float4 intensity = 0;
			for (int i = 0; i < 200; i++)
			{
				float dist = length(FeetPositions[i].xyz - TestPosition);
				float normalizedDist = dist / Radius;
				//float delay = pow((1 - saturate(normalizedDist)), 2) * 128;
				float delay = pow(normalizedDist, 3) * 128;
				float amplitude = AudioLinkLerp( ALPASS_AUDIOLINK + float2(delay, 0 )).r;
				intensity += lerp(lerp(ColorA * amplitude, ColorB * amplitude, normalizedDist), 0, normalizedDist);
			}
			return intensity;
		}


		float GridIntensity25( float4 VectorArray, float Radius, float3 TestPosition, float3 DebugPosition )
		{
			float intensity = 0;
			for (int i = 0; i < 100; i++)
			{
				float dist = length(PlayerPositions[i].xyz - TestPosition);
			//	float dist = length(DebugPosition.xyz - TestPosition);
				float normalizedDist = dist / Radius;
				//float delay = pow((saturate(normalizedDist)), 2) * 128;
				float delay = pow(normalizedDist, 3);
				intensity += 1 - normalizedDist;
			}
			return intensity;
		}


		inline half4 LightingStandardCustomLighting( inout SurfaceOutputCustomLightingCustom s, half3 viewDir, UnityGI gi )
		{
			UnityGIInput data = s.GIData;
			Input i = s.SurfInput;
			half4 c = 0;
			float4 VectorArray3 = FeetPositions[0];
			float Radius3 = _AudioLinkRadius;
			float3 ase_worldPos = i.worldPos;
			float3 TestPosition3 = ase_worldPos;
			float4 ColorA3 = _Color1;
			float4 ColorB3 = _Color2;
			float4 localAudioLinkIntensity3 = AudioLinkIntensity3( VectorArray3 , Radius3 , TestPosition3 , ColorA3 , ColorB3 );
			float2 uv_TextureSample0 = i.uv_texcoord * _TextureSample0_ST.xy + _TextureSample0_ST.zw;
			float4 VectorArray25 = PlayerPositions[0];
			float Radius25 = _GridRadius;
			float3 TestPosition25 = ase_worldPos;
			float3 DebugPosition25 = float3( 0,0,0 );
			float localGridIntensity25 = GridIntensity25( VectorArray25 , Radius25 , TestPosition25 , DebugPosition25 );
			c.rgb = ( localAudioLinkIntensity3 + saturate( ( tex2D( _TextureSample0, uv_TextureSample0 ) * localGridIntensity25 ) ) ).xyz;
			c.a = 1;
			return c;
		}

		inline void LightingStandardCustomLighting_GI( inout SurfaceOutputCustomLightingCustom s, UnityGIInput data, inout UnityGI gi )
		{
			s.GIData = data;
		}

		void surf( Input i , inout SurfaceOutputCustomLightingCustom o )
		{
			o.SurfInput = i;
		}

		ENDCG
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=18935
3099.2;21.6;2708;1570;1345.024;594.5079;1.849427;True;False
Node;AmplifyShaderEditor.WorldPosInputsNode;5;-790.6498,536.9501;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;24;-762.501,857.9602;Inherit;False;Property;_GridRadius;GridRadius;2;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GlobalArrayNode;32;-834.4102,739.4553;Inherit;False;PlayerPositions;0;100;2;False;False;0;1;False;Object;1;4;0;INT;0;False;2;INT;0;False;1;INT;0;False;3;INT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SamplerNode;16;-434.7013,485.5096;Inherit;True;Property;_TextureSample0;Texture Sample 0;5;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.CustomExpressionNode;25;-428.2015,712.1096;Inherit;False;float intensity = 0@$for (int i = 0@ i < 100@ i++)${$	float dist = length(PlayerPositions[i].xyz - TestPosition)@$//	float dist = length(DebugPosition.xyz - TestPosition)@$	float normalizedDist = dist / Radius@$	//float delay = pow((saturate(normalizedDist)), 2) * 128@$	float delay = pow(normalizedDist, 3)@$	intensity += 1 - normalizedDist@$}$return intensity@;1;Create;4;True;VectorArray;FLOAT4;0,0,0,0;In;;Inherit;False;True;Radius;FLOAT;0;In;;Inherit;False;True;TestPosition;FLOAT3;0,0,0;In;;Inherit;False;True;DebugPosition;FLOAT3;0,0,0;In;;Inherit;False;Grid Intensity;True;False;0;;False;4;0;FLOAT4;0,0,0,0;False;1;FLOAT;0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;14;-801.3004,290.8706;Inherit;False;Property;_Color2;Color2;4;0;Create;True;0;0;0;False;0;False;0,0,0,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;13;-802.3004,94.87057;Inherit;False;Property;_Color1;Color1;3;0;Create;True;0;0;0;False;0;False;0,0,0,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;21;-13.10172,595.6095;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;4;-771.1495,-157.7499;Inherit;False;Property;_AudioLinkRadius;AudioLinkRadius;0;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GlobalArrayNode;1;-800.4501,-49.69999;Inherit;False;FeetPositions;0;200;2;False;False;0;1;False;Object;1;4;0;INT;0;False;2;INT;0;False;1;INT;0;False;3;INT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SaturateNode;31;233.3985,357.9096;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.CustomExpressionNode;3;-434.8,82.8;Inherit;False;float4 intensity = 0@$for (int i = 0@ i < 200@ i++)${$	float dist = length(FeetPositions[i].xyz - TestPosition)@$	float normalizedDist = dist / Radius@$	//float delay = pow((1 - saturate(normalizedDist)), 2) * 128@$	float delay = pow(normalizedDist, 3) * 128@$	float amplitude = AudioLinkLerp( ALPASS_AUDIOLINK + float2(delay, 0 )).r@$	intensity += lerp(lerp(ColorA * amplitude, ColorB * amplitude, normalizedDist), 0, normalizedDist)@$}$return intensity@;4;Create;5;True;VectorArray;FLOAT4;0,0,0,0;In;;Inherit;False;True;Radius;FLOAT;0;In;;Inherit;False;True;TestPosition;FLOAT3;0,0,0;In;;Inherit;False;True;ColorA;FLOAT4;0,0,0,0;In;;Inherit;False;True;ColorB;FLOAT4;0,0,0,0;In;;Inherit;False;AudioLink Intensity;True;False;0;;False;5;0;FLOAT4;0,0,0,0;False;1;FLOAT;0;False;2;FLOAT3;0,0,0;False;3;FLOAT4;0,0,0,0;False;4;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleAddOpNode;18;435.2984,186.3096;Inherit;False;2;2;0;FLOAT4;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;28;650.1999,-93.9;Float;False;True;-1;2;ASEMaterialInspector;0;0;CustomLighting;ReactiveFloorAudioLink;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;Off;2;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Custom;0;True;True;0;True;Custom;;Transparent;All;18;all;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;True;4;1;False;-1;1;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;True;Relative;0;;1;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;1;Include;Packages/com.llealloo.audiolink/Runtime/Shaders/AudioLink.cginc;False;;Custom;0;0;False;0.1;False;-1;0;False;-1;False;15;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;25;0;32;0
WireConnection;25;1;24;0
WireConnection;25;2;5;0
WireConnection;21;0;16;0
WireConnection;21;1;25;0
WireConnection;31;0;21;0
WireConnection;3;0;1;0
WireConnection;3;1;4;0
WireConnection;3;2;5;0
WireConnection;3;3;13;0
WireConnection;3;4;14;0
WireConnection;18;0;3;0
WireConnection;18;1;31;0
WireConnection;28;13;18;0
ASEEND*/
//CHKSM=19F89D93DF9E62C2823C3F54A2F4057FA4610B96