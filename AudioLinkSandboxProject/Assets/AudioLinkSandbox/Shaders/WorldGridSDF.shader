// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "WorldGridSDF"
{
	Properties
	{
		_LineThickness("Line Thickness", Float) = 0.1
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" "IsEmissive" = "true"  }
		Cull Back
		CGPROGRAM
		#pragma target 3.0
		#pragma surface surf Standard keepalpha addshadow fullforwardshadows 
		struct Input
		{
			float3 worldPos;
		};

		uniform float _LineThickness;

		void surf( Input i , inout SurfaceOutputStandard o )
		{
			float3 temp_cast_0 = (_LineThickness).xxx;
			float3 ase_worldPos = i.worldPos;
			float3 temp_output_15_0_g1 = float3( 0,0,0 );
			float3 temp_output_17_0_g1 = ( float3( 1,1,1 ) / float3( 1,1,1 ) );
			float3 temp_output_3_0 = abs( ( ase_worldPos - ( ( round( ( ( ase_worldPos + temp_output_15_0_g1 ) * temp_output_17_0_g1 ) ) / temp_output_17_0_g1 ) - temp_output_15_0_g1 ) ) );
			o.Emission = saturate( ( temp_cast_0 - temp_output_3_0 ) );
			o.Alpha = 1;
		}

		ENDCG
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=18935
3099.2;328.8;2085;1050;918;408.0001;1;True;False
Node;AmplifyShaderEditor.WorldPosInputsNode;6;-1132,-111;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.FunctionNode;1;-891.8333,7.999901;Inherit;False;QuantizeVector;-1;;1;69cf507c3daae8e4681450ea1a0e61bb;0;3;13;FLOAT3;0,0,0;False;15;FLOAT3;0,0,0;False;16;FLOAT3;1,1,1;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;2;-626.8333,-84.00011;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;14;-307,72.99988;Inherit;False;Property;_LineThickness;Line Thickness;0;0;Create;True;0;0;0;False;0;False;0.1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.AbsOpNode;3;-436.8333,-106.0001;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;19;-10,434.9999;Inherit;False;2;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.Compare;8;-5,-132.0001;Inherit;False;4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Compare;15;1,29.99988;Inherit;False;4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Compare;16;2,190.9999;Inherit;False;4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;17;236,44.99988;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.BreakToComponentsNode;13;-245,-135.0001;Inherit;False;FLOAT3;1;0;FLOAT3;0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.SaturateNode;18;424,68.99988;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;20;220,363.9999;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;869,-55;Float;False;True;-1;2;ASEMaterialInspector;0;0;Standard;WorldGridSDF;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;Back;0;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Opaque;0.5;True;True;0;False;Opaque;;Geometry;All;18;all;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;True;0;0;False;-1;0;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;True;Relative;0;;-1;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;False;16;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;1;13;6;0
WireConnection;2;0;6;0
WireConnection;2;1;1;0
WireConnection;3;0;2;0
WireConnection;19;0;14;0
WireConnection;19;1;3;0
WireConnection;8;0;13;0
WireConnection;8;1;14;0
WireConnection;15;0;13;1
WireConnection;15;1;14;0
WireConnection;16;0;13;2
WireConnection;16;1;14;0
WireConnection;17;0;8;0
WireConnection;17;1;15;0
WireConnection;17;2;16;0
WireConnection;13;0;3;0
WireConnection;18;0;17;0
WireConnection;20;0;19;0
WireConnection;0;2;20;0
ASEEND*/
//CHKSM=8CB26BA9CB1813EEF3D283DBFF61F60C2E2165EE