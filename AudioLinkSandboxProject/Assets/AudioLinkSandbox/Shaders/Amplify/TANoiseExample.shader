// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "TANoiseExample"
{
	Properties
	{
		_TANoiseTex("TANoiseTex", 2D) = "white" {}
		_TANoiseTexNearest("TANoiseTexNearest", 2D) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" "IsEmissive" = "true"  }
		Cull Back
		CGPROGRAM
		#pragma target 3.0
		#include "../../Prefabs/cnlohr/Shaders/tanoise/tanoise.cginc"
		#pragma surface surf Unlit keepalpha addshadow fullforwardshadows 
		struct Input
		{
			float3 worldPos;
		};

		uniform sampler2D _TANoiseTex;
		uniform sampler2D _TANoiseTexNearest;


		inline float4 tanoise43_g5( float4 Input, sampler2D TANoiseTex, sampler2D TANoiseTexNearest )
		{
			return tanoise4(InputVector);
		}


		inline half4 LightingUnlit( SurfaceOutput s, half3 lightDir, half atten )
		{
			return half4 ( 0, 0, 0, s.Alpha );
		}

		void surf( Input i , inout SurfaceOutput o )
		{
			float3 ase_worldPos = i.worldPos;
			float4 Input3_g5 = float4( ase_worldPos , 0.0 );
			sampler2D TANoiseTex3_g5 = _TANoiseTex;
			sampler2D TANoiseTexNearest3_g5 = _TANoiseTexNearest;
			float4 localtanoise43_g5 = tanoise43_g5( Input3_g5 , TANoiseTex3_g5 , TANoiseTexNearest3_g5 );
			o.Emission = localtanoise43_g5.xyz;
			o.Alpha = 1;
		}

		ENDCG
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=18935
3080;263.2;1392;1050;845;338;1;True;False
Node;AmplifyShaderEditor.WorldPosInputsNode;2;-400,189;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.TexturePropertyNode;7;-448,-35;Inherit;True;Property;_TANoiseTexNearest;TANoiseTexNearest;1;0;Create;True;0;0;0;False;0;False;None;None;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.TexturePropertyNode;6;-444,-262;Inherit;True;Property;_TANoiseTex;TANoiseTex;0;0;Create;True;0;0;0;False;0;False;None;None;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.FunctionNode;9;-86,18;Inherit;False;TANoise4;-1;;5;bd902443b7def774099e6eac04f6f125;0;3;1;SAMPLER2D;0;False;2;SAMPLER2D;0;False;4;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;304,-152;Float;False;True;-1;2;ASEMaterialInspector;0;0;Unlit;TANoiseExample;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;Back;0;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Opaque;0.5;True;True;0;False;Opaque;;Geometry;All;18;all;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;True;0;0;False;-1;0;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;True;Relative;0;;-1;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;False;15;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;9;1;6;0
WireConnection;9;2;7;0
WireConnection;9;4;2;0
WireConnection;0;2;9;0
ASEEND*/
//CHKSM=E76B0723931E54343BB37FD443D1EDB8C5F34706