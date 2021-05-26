// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "AudioLink/AudioLinkAmplify"
{
	Properties
	{
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" "IsEmissive" = "true"  }
		Cull Back
		CGPROGRAM
		#pragma target 3.0
		#define ASE_USING_SAMPLING_MACROS 1
		#pragma surface surf Standard keepalpha addshadow fullforwardshadows 
		struct Input
		{
			half filler;
		};

		UNITY_DECLARE_TEX2D_NOSAMPLER(_AudioTexture);
		SamplerState sampler_AudioTexture;


		float IfAudioLinkv1Exists2(  )
		{
			float w = 0; 
			float h; 
			float res = 0;
			#ifndef SHADER_TARGET_SURFACE_ANALYSIS
			_AudioTexture.GetDimensions(w, h); 
			#endif
			if (w == 32) res = 1;
			return res;
		}


		float IfAudioLinkv2Exists3(  )
		{
			float w = 0; 
			float h; 
			float res = 0;
			#ifndef SHADER_TARGET_SURFACE_ANALYSIS
			_AudioTexture.GetDimensions(w, h); 
			#endif
			if (w == 128) res = 1;
			return res;
		}


		void surf( Input i , inout SurfaceOutputStandard o )
		{
			float4 color5 = IsGammaSpace() ? float4(0,1,0.1694546,0) : float4(0,1,0.02437263,0);
			float localIfAudioLinkv1Exists2 = IfAudioLinkv1Exists2();
			float4 color7 = IsGammaSpace() ? float4(1,0,0,0) : float4(1,0,0,0);
			float localIfAudioLinkv2Exists3 = IfAudioLinkv2Exists3();
			o.Emission = ( ( color5 * localIfAudioLinkv1Exists2 ) + ( color7 * localIfAudioLinkv2Exists3 ) ).rgb;
			o.Alpha = 1;
		}

		ENDCG
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=18900
3240;268;2347;1269;1980.216;1069.617;1.47;True;False
Node;AmplifyShaderEditor.CustomExpressionNode;2;40.67894,-364.5634;Inherit;False;float w = 0@ $float h@ $float res = 0@$#ifndef SHADER_TARGET_SURFACE_ANALYSIS$_AudioTexture.GetDimensions(w, h)@ $#endif$if (w == 32) res = 1@$return res@;1;False;0;If AudioLink v1 Exists;True;False;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.CustomExpressionNode;3;63.59348,14.00286;Inherit;False;float w = 0@ $float h@ $float res = 0@$#ifndef SHADER_TARGET_SURFACE_ANALYSIS$_AudioTexture.GetDimensions(w, h)@ $#endif$if (w == 128) res = 1@$return res@;1;False;0;If AudioLink v2 Exists;True;False;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;5;40.6787,-561.8099;Inherit;False;Constant;_Color0;Color 0;0;0;Create;True;0;0;0;False;0;False;0,1,0.1694546,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;7;58.76401,-179.3972;Inherit;False;Constant;_Color1;Color 0;0;0;Create;True;0;0;0;False;0;False;1,0,0,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;4;308.3711,-399.0031;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;6;326.5886,-18.87146;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SamplerNode;1;-985.4575,-753.0421;Inherit;True;Global;_AudioTexture;Audio Texture;0;0;Create;True;0;0;0;True;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;8;626.9036,-205.9172;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;937.3516,-267.7489;Float;False;True;-1;2;ASEMaterialInspector;0;0;Standard;AudioLink/AudioLinkAmplify;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;Back;0;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Opaque;0.5;True;True;0;False;Opaque;;Geometry;All;14;all;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;True;0;0;False;-1;0;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;-1;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;True;16;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;4;0;5;0
WireConnection;4;1;2;0
WireConnection;6;0;7;0
WireConnection;6;1;3;0
WireConnection;8;0;4;0
WireConnection;8;1;6;0
WireConnection;0;2;8;0
ASEEND*/
//CHKSM=AB33089C07CB8DC73A55957880E4EE8B448F27AD