// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "InfinityPlane"
{
	Properties
	{
		_Opacity("Opacity", Float) = 0
		_AudioLinkRadius("AudioLinkRadius", Float) = 0
		_Color1("Color1", Color) = (0,0,0,0)
		_Color2("Color2", Color) = (0,0,0,0)
		_Step("Step", Float) = 0
		_HeightMod("HeightMod", Float) = 0
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Custom"  "Queue" = "Transparent+0" "IgnoreProjector" = "True" }
		Cull Back
		ZWrite Off
		Blend One One
		
		CGPROGRAM
		#include "UnityPBSLighting.cginc"
		#pragma target 3.0
		#include "Packages/com.llealloo.audiolink/Runtime/Shaders/AudioLink.cginc"
		#pragma surface surf StandardCustomLighting keepalpha noshadow 
		struct Input
		{
			float3 worldPos;
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

		uniform float _Opacity;
		uniform float4 FeetPositions[200];
		uniform float _AudioLinkRadius;
		uniform float _Step;
		uniform float _HeightMod;
		uniform float4 _Color1;
		uniform float4 _Color2;


		float4 AudioLinkIntensity14( float4 VectorArray, float Radius, float3 TestPosition, float4 ColorA, float4 ColorB, float4 DebugPosition )
		{
			float4 intensity = 0;
			for (int i = 0; i < 200; i++)
			{
				float dist = length(FeetPositions[i].xyz - TestPosition);
				//float dist = length(DebugPosition.xyz - TestPosition);
				float normalizedDist = dist / Radius;
				float delay = pow(normalizedDist, 3) * 128;
				float amplitude = AudioLinkLerp( ALPASS_AUDIOLINK + float2(delay, 0 )).r;
				intensity += lerp(lerp(ColorA * amplitude, ColorB * amplitude, normalizedDist), 0, normalizedDist);
			}
			return intensity;
		}


		inline half4 LightingStandardCustomLighting( inout SurfaceOutputCustomLightingCustom s, half3 viewDir, UnityGI gi )
		{
			UnityGIInput data = s.GIData;
			Input i = s.SurfInput;
			half4 c = 0;
			float4 VectorArray14 = FeetPositions[0];
			float Radius14 = _AudioLinkRadius;
			float3 ase_worldPos = i.worldPos;
			float3 break21 = ase_worldPos;
			float temp_output_2_0_g5 = 1000.0;
			float temp_output_3_0_g5 = _Step;
			float temp_output_5_0_g5 = ( ( break21.x - temp_output_2_0_g5 ) / temp_output_3_0_g5 );
			float temp_output_7_0_g5 = ( temp_output_5_0_g5 % 1.0 );
			float temp_output_2_0_g6 = 1000.0;
			float temp_output_3_0_g6 = ( _Step * _HeightMod );
			float temp_output_5_0_g6 = ( ( break21.y - temp_output_2_0_g6 ) / temp_output_3_0_g6 );
			float temp_output_7_0_g6 = ( temp_output_5_0_g6 % 1.0 );
			float temp_output_2_0_g7 = 1000.0;
			float temp_output_3_0_g7 = _Step;
			float temp_output_5_0_g7 = ( ( break21.z - temp_output_2_0_g7 ) / temp_output_3_0_g7 );
			float temp_output_7_0_g7 = ( temp_output_5_0_g7 % 1.0 );
			float4 appendResult25 = (float4(( temp_output_7_0_g5 >= 0.5 ? ( ( ( ( 1.0 - temp_output_7_0_g5 ) + temp_output_5_0_g5 ) * temp_output_3_0_g5 ) + temp_output_2_0_g5 ) : ( temp_output_2_0_g5 + ( temp_output_3_0_g5 * ( temp_output_5_0_g5 - temp_output_7_0_g5 ) ) ) ) , ( temp_output_7_0_g6 >= 0.5 ? ( ( ( ( 1.0 - temp_output_7_0_g6 ) + temp_output_5_0_g6 ) * temp_output_3_0_g6 ) + temp_output_2_0_g6 ) : ( temp_output_2_0_g6 + ( temp_output_3_0_g6 * ( temp_output_5_0_g6 - temp_output_7_0_g6 ) ) ) ) , ( temp_output_7_0_g7 >= 0.5 ? ( ( ( ( 1.0 - temp_output_7_0_g7 ) + temp_output_5_0_g7 ) * temp_output_3_0_g7 ) + temp_output_2_0_g7 ) : ( temp_output_2_0_g7 + ( temp_output_3_0_g7 * ( temp_output_5_0_g7 - temp_output_7_0_g7 ) ) ) ) , 0.0));
			float3 TestPosition14 = appendResult25.xyz;
			float4 ColorA14 = _Color1;
			float4 ColorB14 = _Color2;
			float3 objToWorld2 = mul( unity_ObjectToWorld, float4( float3( 0,0,0 ), 1 ) ).xyz;
			float4 DebugPosition14 = float4( objToWorld2 , 0.0 );
			float4 localAudioLinkIntensity14 = AudioLinkIntensity14( VectorArray14 , Radius14 , TestPosition14 , ColorA14 , ColorB14 , DebugPosition14 );
			c.rgb = ( ( _Opacity * localAudioLinkIntensity14 ) + float4( 0,0,0,0 ) ).xyz;
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
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=18935
3088.8;208.8;2349;1215;1356.159;649.5257;1.32;True;False
Node;AmplifyShaderEditor.WorldPosInputsNode;3;-430.8953,316.6578;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;22;-390.4872,528.8936;Inherit;False;Property;_Step;Step;5;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;27;-377.6938,661.1695;Inherit;False;Property;_HeightMod;HeightMod;6;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.BreakToComponentsNode;21;-175.3173,366.0999;Inherit;False;FLOAT3;1;0;FLOAT3;0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;28;-195.6939,606.1695;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TransformPositionNode;2;5.576031,731.8046;Inherit;False;Object;World;False;Fast;True;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.FunctionNode;19;1.509442,294.971;Inherit;False;Quantize;-1;;5;822689d78347e8143a60ba794cf28ce4;0;3;1;FLOAT;0;False;2;FLOAT;1000;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;23;11.30624,418.1696;Inherit;False;Quantize;-1;;6;822689d78347e8143a60ba794cf28ce4;0;3;1;FLOAT;0;False;2;FLOAT;1000;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;24;9.306241,555.1695;Inherit;False;Quantize;-1;;7;822689d78347e8143a60ba794cf28ce4;0;3;1;FLOAT;0;False;2;FLOAT;1000;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;16;-49.45991,-244.5201;Inherit;False;Property;_Color1;Color1;3;0;Create;True;0;0;0;False;0;False;0,0,0,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GlobalArrayNode;17;-64.9599,-407.5202;Inherit;False;FeetPositions;0;200;2;False;False;0;1;False;Object;1;4;0;INT;0;False;2;INT;0;False;1;INT;0;False;3;INT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.WireNode;26;397.3063,424.1696;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ColorNode;15;-48.45991,-48.51997;Inherit;False;Property;_Color2;Color2;4;0;Create;True;0;0;0;False;0;False;0,0,0,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;25;318.1463,202.8497;Inherit;False;FLOAT4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RangedFloatNode;18;-28.95995,175.4799;Inherit;False;Property;_AudioLinkRadius;AudioLinkRadius;2;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.CustomExpressionNode;14;583.5762,-0.9555922;Inherit;False;float4 intensity = 0@$for (int i = 0@ i < 200@ i++)${$	float dist = length(FeetPositions[i].xyz - TestPosition)@$	//float dist = length(DebugPosition.xyz - TestPosition)@$	float normalizedDist = dist / Radius@$	float delay = pow(normalizedDist, 3) * 128@$	float amplitude = AudioLinkLerp( ALPASS_AUDIOLINK + float2(delay, 0 )).r@$	intensity += lerp(lerp(ColorA * amplitude, ColorB * amplitude, normalizedDist), 0, normalizedDist)@$}$return intensity@;4;Create;6;True;VectorArray;FLOAT4;0,0,0,0;In;;Inherit;False;True;Radius;FLOAT;0;In;;Inherit;False;True;TestPosition;FLOAT3;0,0,0;In;;Inherit;False;True;ColorA;FLOAT4;0,0,0,0;In;;Inherit;False;True;ColorB;FLOAT4;0,0,0,0;In;;Inherit;False;True;DebugPosition;FLOAT4;0,0,0,0;In;;Inherit;False;AudioLink Intensity;True;False;0;;False;6;0;FLOAT4;0,0,0,0;False;1;FLOAT;0;False;2;FLOAT3;0,0,0;False;3;FLOAT4;0,0,0,0;False;4;FLOAT4;0,0,0,0;False;5;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RangedFloatNode;9;558.0402,-153.52;Inherit;False;Property;_Opacity;Opacity;1;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;10;864.2798,-96.35999;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleAddOpNode;32;1163.266,222.6897;Inherit;False;2;2;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;1428,-128;Float;False;True;-1;2;ASEMaterialInspector;0;0;CustomLighting;InfinityPlane;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;False;False;False;False;False;False;Back;2;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Custom;0;True;False;0;True;Custom;;Transparent;All;18;all;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;False;4;1;False;-1;1;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;True;Relative;0;;0;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;1;Include;Packages/com.llealloo.audiolink/Runtime/Shaders/AudioLink.cginc;False;;Custom;0;0;False;0.1;False;-1;0;False;-1;False;15;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;21;0;3;0
WireConnection;28;0;22;0
WireConnection;28;1;27;0
WireConnection;19;1;21;0
WireConnection;19;3;22;0
WireConnection;23;1;21;1
WireConnection;23;3;28;0
WireConnection;24;1;21;2
WireConnection;24;3;22;0
WireConnection;26;0;2;0
WireConnection;25;0;19;0
WireConnection;25;1;23;0
WireConnection;25;2;24;0
WireConnection;14;0;17;0
WireConnection;14;1;18;0
WireConnection;14;2;25;0
WireConnection;14;3;16;0
WireConnection;14;4;15;0
WireConnection;14;5;26;0
WireConnection;10;0;9;0
WireConnection;10;1;14;0
WireConnection;32;0;10;0
WireConnection;0;13;32;0
ASEEND*/
//CHKSM=1A091D46909DEF68DC605819244D39CC33BAAF82