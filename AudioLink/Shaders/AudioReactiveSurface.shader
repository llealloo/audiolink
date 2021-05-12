// Upgrade NOTE: upgraded instancing buffer 'AudioLinkAudioReactiveSurface' to new syntax.

// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "AudioLink/AudioReactiveSurface"
{
	Properties
	{
		_MainTex("Albedo", 2D) = "white" {}
		_Color("Color", Color) = (0.4980392,0.4980392,0.4980392,1)
		_Metallic("Metallic", Range( 0 , 1)) = 0
		_Smoothness("Smoothness", Range( 0 , 1)) = 0.5
		_BumpMap("Normal Map", 2D) = "bump" {}
		_BumpScale("Normal Scale", Float) = 1
		_EmissionMap("Emission Map", 2D) = "gray" {}
		[HDR]_EmissionColor("Emission Color", Color) = (0,0,0,1)
		_Emission("Emission Scale", Float) = 1
		[Header(Audio Section)][IntRange]_Band("Band", Range( 0 , 3)) = 0
		_Delay("Delay", Range( 0 , 1)) = 0
		_HueShift("Hue Shift", Float) = 0
		[Header(Pulse Across UVs)]_Pulse("Pulse", Range( 0 , 1)) = 0
		_PulseRotation("Pulse Rotation", Range( 0 , 360)) = 0
		[Header(Internal)]_AudioSpectrum("Audio Spectrum Render Texture", 2D) = "black" {}
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" "IsEmissive" = "true"  }
		Cull Back
		CGPROGRAM
		#pragma target 3.0
		#pragma multi_compile_instancing
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

		UNITY_DECLARE_TEX2D_NOSAMPLER(_BumpMap);
		SamplerState sampler_BumpMap;
		uniform float _BumpScale;
		UNITY_DECLARE_TEX2D_NOSAMPLER(_MainTex);
		SamplerState sampler_MainTex;
		uniform float4 _Color;
		uniform float _HueShift;
		UNITY_DECLARE_TEX2D_NOSAMPLER(_AudioSpectrum);
		SamplerState sampler_linear_clamp;
		UNITY_DECLARE_TEX2D_NOSAMPLER(_EmissionMap);
		SamplerState sampler_EmissionMap;
		uniform float4 _EmissionColor;
		uniform float _Metallic;
		uniform float _Smoothness;

		UNITY_INSTANCING_BUFFER_START(AudioLinkAudioReactiveSurface)
			UNITY_DEFINE_INSTANCED_PROP(float4, _BumpMap_ST)
#define _BumpMap_ST_arr AudioLinkAudioReactiveSurface
			UNITY_DEFINE_INSTANCED_PROP(float4, _EmissionMap_ST)
#define _EmissionMap_ST_arr AudioLinkAudioReactiveSurface
			UNITY_DEFINE_INSTANCED_PROP(float, _PulseRotation)
#define _PulseRotation_arr AudioLinkAudioReactiveSurface
			UNITY_DEFINE_INSTANCED_PROP(float, _Pulse)
#define _Pulse_arr AudioLinkAudioReactiveSurface
			UNITY_DEFINE_INSTANCED_PROP(float, _Delay)
#define _Delay_arr AudioLinkAudioReactiveSurface
			UNITY_DEFINE_INSTANCED_PROP(float, _Band)
#define _Band_arr AudioLinkAudioReactiveSurface
			UNITY_DEFINE_INSTANCED_PROP(float, _Emission)
#define _Emission_arr AudioLinkAudioReactiveSurface
		UNITY_INSTANCING_BUFFER_END(AudioLinkAudioReactiveSurface)


		float3 HSVToRGB( float3 c )
		{
			float4 K = float4( 1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0 );
			float3 p = abs( frac( c.xxx + K.xyz ) * 6.0 - K.www );
			return c.z * lerp( K.xxx, saturate( p - K.xxx ), c.y );
		}


		float3 RGBToHSV(float3 c)
		{
			float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
			float4 p = lerp( float4( c.bg, K.wz ), float4( c.gb, K.xy ), step( c.b, c.g ) );
			float4 q = lerp( float4( p.xyw, c.r ), float4( c.r, p.yzx ), step( p.x, c.r ) );
			float d = q.x - min( q.w, q.y );
			float e = 1.0e-10;
			return float3( abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
		}

		void surf( Input i , inout SurfaceOutputStandard o )
		{
			float4 _BumpMap_ST_Instance = UNITY_ACCESS_INSTANCED_PROP(_BumpMap_ST_arr, _BumpMap_ST);
			float2 uv_BumpMap = i.uv_texcoord * _BumpMap_ST_Instance.xy + _BumpMap_ST_Instance.zw;
			o.Normal = ( UnpackNormal( SAMPLE_TEXTURE2D( _BumpMap, sampler_BumpMap, uv_BumpMap ) ) * _BumpScale );
			float3 hsvTorgb32 = RGBToHSV( ( SAMPLE_TEXTURE2D( _MainTex, sampler_MainTex, i.uv_texcoord ) * _Color ).rgb );
			float hueShift33 = _HueShift;
			float2 break6_g1 = i.uv_texcoord;
			float temp_output_5_0_g1 = ( break6_g1.x - 0.5 );
			float _PulseRotation_Instance = UNITY_ACCESS_INSTANCED_PROP(_PulseRotation_arr, _PulseRotation);
			float temp_output_2_0_g1 = radians( _PulseRotation_Instance );
			float temp_output_3_0_g1 = cos( temp_output_2_0_g1 );
			float temp_output_8_0_g1 = sin( temp_output_2_0_g1 );
			float temp_output_20_0_g1 = ( 1.0 / ( abs( temp_output_3_0_g1 ) + abs( temp_output_8_0_g1 ) ) );
			float temp_output_7_0_g1 = ( break6_g1.y - 0.5 );
			float2 appendResult16_g1 = (float2(( ( ( temp_output_5_0_g1 * temp_output_3_0_g1 * temp_output_20_0_g1 ) + ( temp_output_7_0_g1 * temp_output_8_0_g1 * temp_output_20_0_g1 ) ) + 0.5 ) , ( ( ( temp_output_7_0_g1 * temp_output_3_0_g1 * temp_output_20_0_g1 ) - ( temp_output_5_0_g1 * temp_output_8_0_g1 * temp_output_20_0_g1 ) ) + 0.5 )));
			float _Pulse_Instance = UNITY_ACCESS_INSTANCED_PROP(_Pulse_arr, _Pulse);
			float _Delay_Instance = UNITY_ACCESS_INSTANCED_PROP(_Delay_arr, _Delay);
			float _Band_Instance = UNITY_ACCESS_INSTANCED_PROP(_Band_arr, _Band);
			float2 appendResult9_g1 = (float2(( (_Delay_Instance + (( appendResult16_g1.x * _Pulse_Instance ) - 0.0) * (1.0 - _Delay_Instance) / (1.0 - 0.0)) % 1.0 ) , ( ( _Band_Instance * 0.25 ) + 0.125 )));
			float4 tex2DNode19 = SAMPLE_TEXTURE2D( _AudioSpectrum, sampler_linear_clamp, appendResult9_g1 );
			float amplitude36 = tex2DNode19.r;
			float3 hsvTorgb39 = HSVToRGB( float3(( hsvTorgb32.x + ( hueShift33 * amplitude36 ) ),hsvTorgb32.y,hsvTorgb32.z) );
			o.Albedo = hsvTorgb39;
			float4 _EmissionMap_ST_Instance = UNITY_ACCESS_INSTANCED_PROP(_EmissionMap_ST_arr, _EmissionMap_ST);
			float2 uv_EmissionMap = i.uv_texcoord * _EmissionMap_ST_Instance.xy + _EmissionMap_ST_Instance.zw;
			float3 hsvTorgb40 = RGBToHSV( ( SAMPLE_TEXTURE2D( _EmissionMap, sampler_EmissionMap, uv_EmissionMap ) * _EmissionColor * tex2DNode19 ).rgb );
			float3 hsvTorgb45 = HSVToRGB( float3(( hsvTorgb40.x + ( hueShift33 * amplitude36 ) ),hsvTorgb40.y,hsvTorgb40.z) );
			float _Emission_Instance = UNITY_ACCESS_INSTANCED_PROP(_Emission_arr, _Emission);
			o.Emission = ( hsvTorgb45 * _Emission_Instance );
			o.Metallic = _Metallic;
			o.Smoothness = _Smoothness;
			o.Alpha = 1;
		}

		ENDCG
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=18900
3128;250.4;2905;1248;2227.89;742.3698;1.3;True;False
Node;AmplifyShaderEditor.RangedFloatNode;49;-2249.751,903.5178;Inherit;False;InstancedProperty;_PulseRotation;Pulse Rotation;13;0;Create;True;0;0;0;False;0;False;0;0;0;360;0;1;FLOAT;0
Node;AmplifyShaderEditor.RadiansOpNode;51;-1951.405,892.3098;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;50;-2253.101,764.4777;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.FunctionNode;61;-1754.95,797.4008;Inherit;False;RotateUVFill;-1;;1;459952d587cbfe742a7e7f4a8a0a4169;0;2;1;FLOAT2;0,0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;18;-1753.685,1022.604;Inherit;False;InstancedProperty;_Delay;Delay;10;0;Create;True;0;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;17;-1755.335,920.8885;Inherit;False;InstancedProperty;_Band;Band;9;2;[Header];[IntRange];Create;True;1;Audio Section;0;0;False;0;False;0;0;0;3;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;57;-1751.707,1123.366;Inherit;False;InstancedProperty;_Pulse;Pulse;12;1;[Header];Create;True;1;Pulse Across UVs;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerStateNode;58;-1310.388,1022.886;Inherit;False;1;1;1;1;-1;1;0;SAMPLER2D;;False;1;SAMPLERSTATE;0
Node;AmplifyShaderEditor.FunctionNode;68;-1356.29,861.939;Inherit;False;BandDelayUV;-1;;1;77035fcd565301248a2dfb20abb4c96b;0;4;6;FLOAT2;0,0;False;1;FLOAT;0;False;10;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;19;-1067.84,907.5126;Inherit;True;Property;_AudioSpectrum;Audio Spectrum Render Texture;14;1;[Header];Create;False;1;Internal;0;0;False;0;False;-1;None;None;True;0;False;black;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;31;-1390.638,-584.899;Inherit;False;Property;_HueShift;Hue Shift;11;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;36;-682.4827,961.1632;Inherit;False;amplitude;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;14;-989.8879,298.6613;Inherit;True;Property;_EmissionMap;Emission Map;6;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;gray;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TextureCoordinatesNode;6;-1357,-367;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RegisterLocalVarNode;33;-1046.295,-583.8591;Inherit;False;hueShift;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;3;-981.4803,559.1005;Inherit;False;Property;_EmissionColor;Emission Color;7;1;[HDR];Create;True;0;0;0;False;0;False;0,0,0,1;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;15;-528.8879,636.6613;Inherit;False;3;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SamplerNode;4;-1039,-416;Inherit;True;Property;_MainTex;Albedo;0;0;Create;False;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;2;-955,-202.5;Inherit;False;Property;_Color;Color;1;0;Create;True;0;0;0;False;0;False;0.4980392,0.4980392,0.4980392,1;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;42;-304.7005,662.272;Inherit;False;33;hueShift;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;41;-311.1783,767.5342;Inherit;False;36;amplitude;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RGBToHSVNode;40;-310.7005,431.272;Inherit;False;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.GetLocalVarNode;37;-372.7727,-36.59692;Inherit;False;36;amplitude;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;5;-597,-280;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;43;-91.17834,730.5342;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;34;-366.2949,-141.8591;Inherit;False;33;hueShift;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;44;70.29944,482.272;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;38;-152.7727,-73.59692;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RGBToHSVNode;32;-372.2949,-372.8591;Inherit;False;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;46;255.5175,800.3702;Inherit;False;InstancedProperty;_Emission;Emission Scale;8;0;Create;False;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;10;-812,202;Inherit;False;Property;_BumpScale;Normal Scale;5;0;Create;False;0;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.HSVToRGBNode;45;252.8217,636.5342;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SamplerNode;9;-936,-2;Inherit;True;Property;_BumpMap;Normal Map;4;0;Create;False;0;0;0;False;0;False;-1;None;None;True;0;False;bump;Auto;True;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;35;8.705078,-321.8591;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;11;-502,92;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.HSVToRGBNode;39;191.2273,-167.5969;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;47;534.9175,735.4701;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;13;258.2,923.202;Inherit;False;Property;_Metallic;Metallic;2;0;Create;True;0;0;0;False;0;False;0;0.5;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;12;261.2,1021.201;Inherit;False;Property;_Smoothness;Smoothness;3;0;Create;True;0;0;0;False;0;False;0.5;0.5;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;824,664;Float;False;True;-1;2;ASEMaterialInspector;0;0;Standard;AudioLink/AudioReactiveSurface;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;Back;0;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Opaque;0.5;True;True;0;False;Opaque;;Geometry;All;14;all;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;True;0;0;False;-1;0;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;-1;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;True;16;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;51;0;49;0
WireConnection;61;1;50;0
WireConnection;61;2;51;0
WireConnection;68;6;61;0
WireConnection;68;1;17;0
WireConnection;68;10;18;0
WireConnection;68;2;57;0
WireConnection;19;1;68;0
WireConnection;19;7;58;0
WireConnection;36;0;19;1
WireConnection;33;0;31;0
WireConnection;15;0;14;0
WireConnection;15;1;3;0
WireConnection;15;2;19;0
WireConnection;4;1;6;0
WireConnection;40;0;15;0
WireConnection;5;0;4;0
WireConnection;5;1;2;0
WireConnection;43;0;42;0
WireConnection;43;1;41;0
WireConnection;44;0;40;1
WireConnection;44;1;43;0
WireConnection;38;0;34;0
WireConnection;38;1;37;0
WireConnection;32;0;5;0
WireConnection;45;0;44;0
WireConnection;45;1;40;2
WireConnection;45;2;40;3
WireConnection;35;0;32;1
WireConnection;35;1;38;0
WireConnection;11;0;9;0
WireConnection;11;1;10;0
WireConnection;39;0;35;0
WireConnection;39;1;32;2
WireConnection;39;2;32;3
WireConnection;47;0;45;0
WireConnection;47;1;46;0
WireConnection;0;0;39;0
WireConnection;0;1;11;0
WireConnection;0;2;47;0
WireConnection;0;3;13;0
WireConnection;0;4;12;0
ASEEND*/
//CHKSM=06FBD272E168A5505365F3D83854EBDA8FF9C8C7