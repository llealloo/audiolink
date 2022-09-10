// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "AudioInk/Ink0.2.1"
{
	Properties
	{
		_Frequency("Frequency", Range( 0 , 1)) = 1
		_Amplitude("Amplitude", Float) = 1
		_HueOffset("Hue Offset", Range( 0 , 1)) = 0
		_HueShift("Hue Shift", Range( 0 , 1)) = 0.3
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Custom"  "Queue" = "Transparent+0" "IgnoreProjector" = "True" }
		Cull Off
		ZWrite Off
		Blend One One
		
		CGPROGRAM
		#include "UnityPBSLighting.cginc"
		#pragma target 3.0
		#pragma exclude_renderers xbox360 xboxone ps4 psp2 n3ds wiiu switch nomrt 
		#pragma surface surf StandardCustomLighting keepalpha noshadow noambient novertexlights nolightmap  nodynlightmap nodirlightmap nofog nometa noforwardadd vertex:vertexDataFunc 
		struct Input
		{
			float4 vertexColor : COLOR;
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

		uniform sampler2D _AudioTexture;
		uniform float _Frequency;
		uniform float _Amplitude;
		uniform float _HueOffset;
		uniform float _HueShift;


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

		void vertexDataFunc( inout appdata_full v, out Input o )
		{
			UNITY_INITIALIZE_OUTPUT( Input, o );
			float2 appendResult138 = (float2(_Frequency , 0.0));
			float2 uv_TexCoord18 = v.texcoord.xy * appendResult138;
			float temp_output_144_0 = ( uv_TexCoord18.x * ( 1.0 - v.texcoord.xy.x ) );
			float2 appendResult146 = (float2(temp_output_144_0 , 0.0));
			float4 tex2DNode14 = tex2Dlod( _AudioTexture, float4( appendResult146, 0, 0.0) );
			float3 appendResult183 = (float3(0.0 , ( ( tex2DNode14.r * 4.0 ) * temp_output_144_0 * ( ( v.texcoord.xy.y - 0.5 ) * 2.0 ) * _Amplitude ) , 0.0));
			v.vertex.xyz += appendResult183;
			v.vertex.w = 1;
		}

		inline half4 LightingStandardCustomLighting( inout SurfaceOutputCustomLightingCustom s, half3 viewDir, UnityGI gi )
		{
			UnityGIInput data = s.GIData;
			Input i = s.SurfInput;
			half4 c = 0;
			float3 hsvTorgb86 = RGBToHSV( i.vertexColor.rgb );
			float temp_output_273_0 = ( hsvTorgb86.x + _HueOffset );
			float3 hsvTorgb87 = HSVToRGB( float3(( temp_output_273_0 + _HueShift ),hsvTorgb86.z,hsvTorgb86.y) );
			float2 appendResult138 = (float2(_Frequency , 0.0));
			float2 uv_TexCoord18 = i.uv_texcoord * appendResult138;
			float temp_output_144_0 = ( uv_TexCoord18.x * ( 1.0 - i.uv_texcoord.x ) );
			float2 appendResult146 = (float2(temp_output_144_0 , 0.0));
			float4 tex2DNode14 = tex2D( _AudioTexture, appendResult146 );
			float3 hsvTorgb272 = HSVToRGB( float3(temp_output_273_0,hsvTorgb86.y,hsvTorgb86.z) );
			c.rgb = ( ( hsvTorgb87 * tex2DNode14.r ) + ( hsvTorgb272 * ( 1.0 - tex2DNode14.r ) ) );
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
3190.4;344;1392;1050;976.156;-551.5866;1.38722;True;False
Node;AmplifyShaderEditor.VertexColorNode;46;-1201.069,408.2388;Inherit;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;141;-1729.78,818.4415;Inherit;False;Property;_Frequency;Frequency;0;0;Create;True;0;0;0;False;0;False;1;0.5;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;274;-934.258,313.4713;Inherit;False;Property;_HueOffset;Hue Offset;2;0;Create;True;0;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.TexCoordVertexDataNode;143;-1536.642,1066.725;Inherit;True;0;2;0;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;138;-1610.105,690.8992;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RGBToHSVNode;86;-935.0291,410.4535;Inherit;False;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;89;-403.2095,321.8733;Inherit;False;Property;_HueShift;Hue Shift;3;0;Create;True;0;0;0;False;0;False;0.3;0.3;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;273;-643.5927,408.6982;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;145;-1301.209,1001.429;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;18;-1430.601,675.5231;Inherit;True;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,-0.01;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;144;-1130.256,879.4457;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;88;-101.108,408.6471;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.HSVToRGBNode;87;196.8787,449.3783;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.DynamicAppendNode;146;-950.8447,806.7388;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;205;-1172.305,1213.909;Inherit;False;Constant;_Half;_Half;6;0;Create;True;0;0;0;False;0;False;0.5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;14;-778.8776,798.424;Inherit;True;Global;_AudioTexture;_AudioTexture;5;0;Create;True;0;0;0;False;0;False;-1;None;f51fa799ef0abde489235f40fc0328ef;True;0;False;black;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;206;-1035.935,1215.385;Inherit;False;Constant;_Double;_Double;6;0;Create;True;0;0;0;False;0;False;2;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;204;-1159.299,1130.535;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;278;-643.8494,1000.735;Inherit;False;Constant;_CorrectiveScale;_CorrectiveScale;6;0;Create;True;0;0;0;False;0;False;4;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;92;383.6787,586.7785;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;207;-1033.699,1130.81;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;279;-431.9391,933.3572;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;78;-419.5591,855.9169;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;93;-203.9214,578.9785;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.HSVToRGBNode;272;-497.4307,566.3671;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;269;-406.5787,1305.113;Inherit;False;Property;_Amplitude;Amplitude;1;0;Create;True;0;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;212;-235.752,1168.493;Inherit;True;4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;82;-204.535,636.3745;Inherit;True;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;81;-209.1008,845.2544;Inherit;True;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;84;122.7129,756.5486;Inherit;True;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DynamicAppendNode;183;192.9576,1092.897;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;16;409.3577,759.8949;Float;False;True;-1;2;ASEMaterialInspector;0;0;CustomLighting;AudioInk/Ink0.2.1;False;False;False;False;True;True;True;True;True;True;True;True;False;False;True;False;False;False;False;False;False;Off;2;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Custom;0;True;False;0;True;Custom;;Transparent;All;10;d3d9;d3d11_9x;d3d11;glcore;gles;gles3;metal;vulkan;xboxseries;playstation;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;False;4;1;False;-1;1;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;True;Relative;0;;4;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;False;15;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;138;0;141;0
WireConnection;86;0;46;0
WireConnection;273;0;86;1
WireConnection;273;1;274;0
WireConnection;145;0;143;1
WireConnection;18;0;138;0
WireConnection;144;0;18;1
WireConnection;144;1;145;0
WireConnection;88;0;273;0
WireConnection;88;1;89;0
WireConnection;87;0;88;0
WireConnection;87;1;86;3
WireConnection;87;2;86;2
WireConnection;146;0;144;0
WireConnection;14;1;146;0
WireConnection;204;0;143;2
WireConnection;204;1;205;0
WireConnection;92;0;87;0
WireConnection;207;0;204;0
WireConnection;207;1;206;0
WireConnection;279;0;14;1
WireConnection;279;1;278;0
WireConnection;78;0;14;1
WireConnection;93;0;92;0
WireConnection;272;0;273;0
WireConnection;272;1;86;2
WireConnection;272;2;86;3
WireConnection;212;0;279;0
WireConnection;212;1;144;0
WireConnection;212;2;207;0
WireConnection;212;3;269;0
WireConnection;82;0;93;0
WireConnection;82;1;14;1
WireConnection;81;0;272;0
WireConnection;81;1;78;0
WireConnection;84;0;82;0
WireConnection;84;1;81;0
WireConnection;183;1;212;0
WireConnection;16;13;84;0
WireConnection;16;11;183;0
ASEEND*/
//CHKSM=E1943D7083DEC74FDD0EEDD00C5C19DB33FDD3C0