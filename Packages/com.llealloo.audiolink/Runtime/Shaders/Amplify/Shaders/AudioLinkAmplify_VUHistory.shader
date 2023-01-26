// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "AudioLink/Amplify/AudioLinkAmplify_VUHistory"
{
	Properties
	{
		
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
			#include "Packages/com.llealloo.audiolink/Runtime/Shaders/AudioLink.cginc"


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

			float GetVUHistory2_g1( int Delay )
			{
				uint rowWidth = AUDIOLINK_WIDTH * 4;
				uint row = uint(Delay) / rowWidth;
				uint column = uint(Delay) % AUDIOLINK_WIDTH;
				/*
				uint channel = ((uint(Delay) % AUDIOLINK_WIDTH) - (row * rowWidth)) / AUDIOLINK_WIDTH;
				float4 pixel = AudioLinkData(ALPASS_VUHISTORY + uint2( row, column ));
				uint result = 
					(channel == 0) ? pixel.r : 0 +
					(channel == 1) ? pixel.g : 0 +
					(channel == 2) ? pixel.b : 0 +
					(channel == 3) ? pixel.a : 0;
				*/
				uint channel = uint(uint(Delay) / AUDIOLINK_WIDTH) % 4;
				float4 pixel = AudioLinkData(ALPASS_VUHISTORY + uint2( column, row ));
				float result = 
					(channel == 0) ? pixel.r : 0 +
					(channel == 1) ? pixel.g : 0 +
					(channel == 2) ? pixel.b : 0 +
					(channel == 3) ? pixel.a : 0;
				return result;
			}
			

			
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
				float2 texCoord3 = i.ase_texcoord1.xy * float2( 1,1 ) + float2( 0,0 );
				int Delay2_g1 = (int)( texCoord3.x * 2560.0 );
				float localGetVUHistory2_g1 = GetVUHistory2_g1( Delay2_g1 );
				float4 temp_cast_1 = (( texCoord3.y <= localGetVUHistory2_g1 ? 1.0 : 0.0 )).xxxx;
				
				
				finalColor = temp_cast_1;
				return finalColor;
			}
			ENDCG
		}
	}
	CustomEditor "ASEMaterialInspector"
	
	
}
/*ASEBEGIN
Version=18935
3099.2;21.6;2621;1479;1116.5;479;1;True;False
Node;AmplifyShaderEditor.TextureCoordinatesNode;3;-271.5,117.5;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;4;99.5,244.5;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;2560;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;17;313.5,265.5;Inherit;False;VUHistory;-1;;1;d2e7b3a2c39c7ad48b3323946139af4f;0;1;1;INT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Compare;6;624.5,157.5;Inherit;False;5;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1;860,93;Float;False;True;-1;2;ASEMaterialInspector;100;1;AudioLink/Amplify/AudioLinkAmplify_VUHistory;0770190933193b94aaa3065e307002fa;True;Unlit;0;0;Unlit;2;False;True;0;1;False;-1;0;False;-1;0;1;False;-1;0;False;-1;True;0;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;1;RenderType=Opaque=RenderType;True;2;False;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=ForwardBase;False;False;0;;0;0;Standard;1;Vertex Position,InvertActionOnDeselection;1;0;0;1;True;False;;False;0
WireConnection;4;0;3;1
WireConnection;17;1;4;0
WireConnection;6;0;3;2
WireConnection;6;1;17;0
WireConnection;1;0;6;0
ASEEND*/
//CHKSM=DB37712146221740C93147259BC7F848A2638D15