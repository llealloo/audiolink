// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "AudioLink/AudioLinkPreview"
{
	Properties
	{
		_AudioLinkRenderTexture("AudioLink Render Texture", 2D) = "white" {}
		_Band0Color("Band 0 Color", Color) = (0,0,0,0)
		_Band1Color("Band 1 Color", Color) = (0,0,0,0)
		_Band2Color("Band 2 Color", Color) = (0,0,0,0)
		_Band3Color("Band 3 Color", Color) = (0,0,0,0)

	}
	
	SubShader
	{
		
		
		Tags { "RenderType"="Opaque" }
	LOD 100

		CGINCLUDE
		#pragma target 3.0
		ENDCG
		Blend Off
		AlphaToMask Off
		Cull Back
		ColorMask RGBA
		ZWrite On
		ZTest LEqual
		Offset 0 , 0
		
		
		
		Pass
		{
			Name "Unlit"
			Tags { "LightMode"="ForwardBase" }
			CGPROGRAM

			

			#ifndef UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX
			//only defining to not throw compilation error over Unity 5.5
			#define UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input)
			#endif
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_instancing
			#include "UnityCG.cginc"
			

			struct appdata
			{
				float4 vertex : POSITION;
				float4 color : COLOR;
				float4 ase_texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};
			
			struct v2f
			{
				float4 vertex : SV_POSITION;
				#ifdef ASE_NEEDS_FRAG_WORLD_POSITION
				float3 worldPos : TEXCOORD0;
				#endif
				float4 ase_texcoord1 : TEXCOORD1;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			uniform sampler2D _AudioLinkRenderTexture;
			uniform float4 _Band0Color;
			uniform float4 _Band1Color;
			uniform float4 _Band2Color;
			uniform float4 _Band3Color;

			
			v2f vert ( appdata v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				UNITY_TRANSFER_INSTANCE_ID(v, o);

				o.ase_texcoord1.xy = v.ase_texcoord.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord1.zw = 0;
				float3 vertexValue = float3(0, 0, 0);
				#if ASE_ABSOLUTE_VERTEX_POS
				vertexValue = v.vertex.xyz;
				#endif
				vertexValue = vertexValue;
				#if ASE_ABSOLUTE_VERTEX_POS
				v.vertex.xyz = vertexValue;
				#else
				v.vertex.xyz += vertexValue;
				#endif
				o.vertex = UnityObjectToClipPos(v.vertex);

				#ifdef ASE_NEEDS_FRAG_WORLD_POSITION
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				#endif
				return o;
			}
			
			fixed4 frag (v2f i ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(i);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
				fixed4 finalColor;
				#ifdef ASE_NEEDS_FRAG_WORLD_POSITION
				float3 WorldPosition = i.worldPos;
				#endif
				float2 texCoord9 = i.ase_texcoord1.xy * float2( 1,1 ) + float2( 0,0 );
				float4 temp_output_1_0_g1 = tex2D( _AudioLinkRenderTexture, ( texCoord9 * float2( 0.25,0.0625 ) ) );
				float4 break5_g1 = temp_output_1_0_g1;
				float2 texCoord8 = i.ase_texcoord1.xy * float2( 1,1 ) + float2( 0,0 );
				float band23 = floor( ( texCoord8.y * 4.0 ) );
				float4 temp_output_2_0_g1 = ( ( band23 == 0.0 ? _Band0Color : float4( 0,0,0,0 ) ) + ( band23 == 1.0 ? _Band1Color : float4( 0,0,0,0 ) ) + ( band23 == 2.0 ? _Band2Color : float4( 0,0,0,0 ) ) + ( band23 == 3.0 ? _Band3Color : float4( 0,0,0,0 ) ) );
				
				
				finalColor = ( ( ( break5_g1.r * 0.2 ) + ( break5_g1.g * 0.7 ) + ( break5_g1.b * 0.1 ) ) < 0.5 ? ( 2.0 * temp_output_1_0_g1 * temp_output_2_0_g1 ) : ( 1.0 - ( 2.0 * ( 1.0 - temp_output_1_0_g1 ) * ( 1.0 - temp_output_2_0_g1 ) ) ) );
				return finalColor;
			}
			ENDCG
		}
	}
	CustomEditor "ASEMaterialInspector"
	
	
}
/*ASEBEGIN
Version=18900
3158.4;25.6;2606;1380;1114.31;281.6356;1.200976;True;False
Node;AmplifyShaderEditor.CommentaryNode;17;-197.8064,-172.818;Inherit;False;866.5;262.63;Band;5;23;14;8;15;33;;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;15;-68.82617,2.212165;Inherit;False;Constant;_Float0;Float 0;5;0;Create;True;0;0;0;False;0;False;4;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;8;-147.8063,-122.8178;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;14;107.2037,-69.81778;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FloorOpNode;33;275.989,-49.94684;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;35;-185.1054,475.6019;Inherit;False;843.8865;824.7887;Color per band;13;18;30;22;28;26;6;7;4;27;5;29;24;25;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;12;-195.7497,129.2018;Inherit;False;486.8;309.8;Window UVs;3;10;11;9;;1,1,1,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;23;446.1939,-56.81787;Inherit;False;band;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;9;-145.7497,179.2018;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector2Node;11;-117.7496,308.2022;Inherit;False;Constant;_Vector0;Vector 0;5;0;Create;True;0;0;0;False;0;False;0.25,0.0625;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.GetLocalVarNode;25;74.39464,710.6021;Inherit;False;23;band;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;24;72.89463,533.602;Inherit;False;23;band;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;29;74.39464,1069.601;Inherit;False;23;band;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;27;72.39464,895.6021;Inherit;False;23;band;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;4;-129.1054,572.6022;Inherit;False;Property;_Band0Color;Band 0 Color;1;0;Create;True;0;0;0;False;0;False;0,0,0,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;7;-135.1054,1108.601;Inherit;False;Property;_Band3Color;Band 3 Color;4;0;Create;True;0;0;0;False;0;False;0,0,0,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;6;-131.1054,932.602;Inherit;False;Property;_Band2Color;Band 2 Color;3;0;Create;True;0;0;0;False;0;False;0,0,0,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;5;-133.1054,749.6021;Inherit;False;Property;_Band1Color;Band 1 Color;2;0;Create;True;0;0;0;False;0;False;0,0,0,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;10;151.2503,256.2022;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0.25,0.0625;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Compare;26;255.3946,701.5921;Inherit;False;0;4;0;FLOAT;0;False;1;FLOAT;1;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.Compare;28;253.3946,887.6021;Inherit;False;0;4;0;FLOAT;0;False;1;FLOAT;2;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.Compare;22;253.8946,525.6019;Inherit;False;0;4;0;FLOAT;0;False;1;FLOAT;0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.Compare;30;255.3946,1061.601;Inherit;False;0;4;0;FLOAT;0;False;1;FLOAT;3;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;18;497.9785,759.1658;Inherit;False;4;4;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SamplerNode;3;386.0552,205.9332;Inherit;True;Property;_AudioLinkRenderTexture;AudioLink Render Texture;0;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.FunctionNode;34;792.2722,457.0455;Inherit;False;BlendOverlay;-1;;1;6c2f15995e7c1bf4bafb65b1a44446b2;0;2;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1;1034.217,424.6281;Float;False;True;-1;2;ASEMaterialInspector;100;1;AudioLink/AudioLinkPreview;0770190933193b94aaa3065e307002fa;True;Unlit;0;0;Unlit;2;False;True;0;1;False;-1;0;False;-1;0;1;False;-1;0;False;-1;True;0;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;1;RenderType=Opaque=RenderType;True;2;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=ForwardBase;False;0;;0;0;Standard;1;Vertex Position,InvertActionOnDeselection;1;0;1;True;False;;False;0
WireConnection;14;0;8;2
WireConnection;14;1;15;0
WireConnection;33;0;14;0
WireConnection;23;0;33;0
WireConnection;10;0;9;0
WireConnection;10;1;11;0
WireConnection;26;0;25;0
WireConnection;26;2;5;0
WireConnection;28;0;27;0
WireConnection;28;2;6;0
WireConnection;22;0;24;0
WireConnection;22;2;4;0
WireConnection;30;0;29;0
WireConnection;30;2;7;0
WireConnection;18;0;22;0
WireConnection;18;1;26;0
WireConnection;18;2;28;0
WireConnection;18;3;30;0
WireConnection;3;1;10;0
WireConnection;34;1;3;0
WireConnection;34;2;18;0
WireConnection;1;0;34;0
ASEEND*/
//CHKSM=DC0A11FE767E958CED685F561628891042F732E6