// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "AudioLink/Amplify/AudioLinkAmplify_Waveform"
{
	Properties
	{
		_WaveformHeight("Waveform Height", Range( 0 , 1)) = 0.5
		_WaveformThickness("Waveform Thickness", Range( 0 , 1)) = 0.05
		_WaveformLineSmoothing("Waveform Line Smoothing", Range( 0.0001 , 1)) = 0.01
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" "IsEmissive" = "true"  }
		Cull Back
		CGPROGRAM
		#pragma target 3.0
		#define ASE_USING_SAMPLING_MACROS 1
		#if defined(SHADER_API_D3D11) || defined(SHADER_API_XBOXONE) || defined(UNITY_COMPILER_HLSLCC) || defined(SHADER_API_PSSL) || (defined(SHADER_TARGET_SURFACE_ANALYSIS) && !defined(SHADER_TARGET_SURFACE_ANALYSIS_MOJOSHADER))//ASE Sampler Macros
		#define SAMPLE_TEXTURE2D(tex,samplerTex,coord) tex.Sample(samplerTex,coord)
		#else//ASE Sampling Macros
		#define SAMPLE_TEXTURE2D(tex,samplerTex,coord) tex2D(tex,coord)
		#endif//ASE Sampling Macros

		#pragma surface surf Standard keepalpha addshadow fullforwardshadows 
		struct Input
		{
			float2 uv_texcoord;
		};

		UNITY_DECLARE_TEX2D_NOSAMPLER(_AudioTexture);
		SamplerState sampler_AudioTexture;
		uniform float _WaveformThickness;
		uniform float _WaveformHeight;
		uniform float _WaveformLineSmoothing;

		void surf( Input i , inout SurfaceOutputStandard o )
		{
			float temp_output_8_0_g1 = ( i.uv_texcoord.x * 16.0 );
			float2 appendResult11_g1 = (float2(( temp_output_8_0_g1 % 1.0 ) , ( ( floor( temp_output_8_0_g1 ) * 0.015625 ) + 0.1015625 )));
			float3 temp_cast_0 = (( saturate( ( _WaveformThickness - abs( ( ( SAMPLE_TEXTURE2D( _AudioTexture, sampler_AudioTexture, appendResult11_g1 ).r + _WaveformHeight ) - i.uv_texcoord.y ) ) ) ) / _WaveformLineSmoothing )).xxx;
			o.Emission = temp_cast_0;
			o.Alpha = 1;
		}

		ENDCG
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=18900
3240;268;2347;1269;1308.708;1035.957;1.17;True;False
Node;AmplifyShaderEditor.TextureCoordinatesNode;18;-696.7983,-363.2065;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.FunctionNode;29;-424.188,-308.2164;Inherit;False;WaveformUV;-1;;1;36027df3dbcf2fa4f9ec5f2e5959c444;0;1;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;16;-180.8279,-362.0365;Inherit;True;Property;_TextureSample0;Texture Sample 0;0;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Instance;14;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;20;-156.2578,-153.7764;Inherit;False;Property;_WaveformHeight;Waveform Height;1;0;Create;True;0;0;0;False;0;False;0.5;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;15;-698.8281,-757.187;Inherit;False;372.4;280;Audio Texture Import;1;14;;1,1,1,1;0;0
Node;AmplifyShaderEditor.SimpleAddOpNode;31;195.912,-255.5666;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;22;198.2521,-401.8164;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;25;195.9112,-139.7364;Inherit;False;Property;_WaveformThickness;Waveform Thickness;2;0;Create;True;0;0;0;False;0;False;0.05;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;32;200.5919,-41.45654;Inherit;False;Property;_WaveformLineSmoothing;Waveform Line Smoothing;3;0;Create;True;0;0;0;False;0;False;0.01;0;0.0001;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;14;-648.8281,-707.187;Inherit;True;Global;_AudioTexture;_AudioTexture;0;0;Create;True;0;0;0;True;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.FunctionNode;30;558.6118,-287.1565;Inherit;False;DrawLine;-1;;2;b931a6c4da53ab6489d06086e5e19048;0;4;5;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;918.632,-411.6588;Float;False;True;-1;2;ASEMaterialInspector;0;0;Standard;AudioLink/Amplify/AudioLinkAmplify_Waveform;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;Back;0;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Opaque;0.5;True;True;0;False;Opaque;;Geometry;All;14;all;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;True;0;0;False;-1;0;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;-1;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;True;16;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;29;1;18;1
WireConnection;16;1;29;0
WireConnection;31;0;16;1
WireConnection;31;1;20;0
WireConnection;30;5;22;2
WireConnection;30;1;31;0
WireConnection;30;2;25;0
WireConnection;30;3;32;0
WireConnection;0;2;30;0
ASEEND*/
//CHKSM=DBDA7D5C3798AE0943817697922096DB515007C3