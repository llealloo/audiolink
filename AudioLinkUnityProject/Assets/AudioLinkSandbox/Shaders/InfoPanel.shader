// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "InfoPanel"
{
	Properties
	{
		_MainTex("Main Tex", 2D) = "white" {}
		_TextureScale("Texture Scale", Float) = 0
		_TextureOffset("Texture Offset", Vector) = (0,0,0,0)
		_ColorFar("Color Far", Color) = (0.5,0.5,0.5,0)
		_ColorClose("Color Close", Color) = (1,1,1,0)
		_FadeDistance("Fade Distance", Float) = 0
		_AudioLinkPower("AudioLink Power", Range( 0 , 1)) = 0.8
		_PulseWidth("Pulse Width", Range( 0 , 1)) = 0.5
		_AutoCorrBassBand("AutoCorr / BassBand", Range( 0 , 1)) = 0.5
		_BackBrightness("Back Brightness", Float) = 0
		_MixCameraObjectPosition("Mix Camera / Object Position", Range( 0 , 1)) = 0
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Custom"  "Queue" = "Transparent+0" "IsEmissive" = "true"  }
		Cull Off
		ZWrite Off
		Blend One One
		
		CGINCLUDE
		#include "UnityShaderVariables.cginc"
		#include "UnityPBSLighting.cginc"
		#include "Lighting.cginc"
		#pragma target 3.0
		#include "Packages/com.llealloo.audiolink/Runtime/Shaders/AudioLink.cginc"
		struct Input
		{
			float3 worldNormal;
			float3 viewDir;
			float3 worldPos;
		};

		uniform float _BackBrightness;
		uniform sampler2D _MainTex;
		uniform float _TextureScale;
		uniform float3 _TextureOffset;
		uniform float _FadeDistance;
		uniform float _MixCameraObjectPosition;
		uniform float _PulseWidth;
		uniform float _AutoCorrBassBand;
		uniform float _AudioLinkPower;
		uniform float4 _ColorFar;
		uniform float4 _ColorClose;


		float2 CubicWorldTextureUV5( float3 Normal, float3 Position, float Scale, float3 Offset )
		{
			float scaleInv = 1 / Scale;
			if (abs(Normal.x) > 0.5)
			{
				return Position.yz * scaleInv + Offset.yz;
			}
			else if (abs(Normal.z) > 0.5)
			{
				return Position.xy * scaleInv + Offset.xy;
			}
			else
			{
				return Position.xz * scaleInv + Offset.xz;
			}
		}


		inline float AudioLinkLerp2_g7( float Sample )
		{
			return AudioLinkLerp( ALPASS_AUTOCORRELATOR + float2( Sample * 128., 0 ) ).g;;
		}


		inline float AudioLinkLerp3_g6( int Band, float Delay )
		{
			return AudioLinkLerp( ALPASS_AUDIOLINK + float2( Delay, Band ) ).r;
		}


		inline half4 LightingUnlit( SurfaceOutput s, half3 lightDir, half atten )
		{
			return half4 ( 0, 0, 0, s.Alpha );
		}

		void surf( Input i , inout SurfaceOutput o )
		{
			float3 ase_worldNormal = i.worldNormal;
			float dotResult56 = dot( ase_worldNormal , i.viewDir );
			float backFace63 = ( dotResult56 > 0.0 ? 1.0 : 0.0 );
			float3 Normal5 = ase_worldNormal;
			float3 ase_worldPos = i.worldPos;
			float3 Position5 = ase_worldPos;
			float Scale5 = _TextureScale;
			float3 Offset5 = _TextureOffset;
			float2 localCubicWorldTextureUV5 = CubicWorldTextureUV5( Normal5 , Position5 , Scale5 , Offset5 );
			float temp_output_71_0 = ( backFace63 == 0.0 ? _BackBrightness : tex2D( _MainTex, localCubicWorldTextureUV5 ).r );
			float4 transform86 = mul(unity_ObjectToWorld,float4( 0,0,0,1 ));
			float4 lerpResult82 = lerp( float4( _WorldSpaceCameraPos , 0.0 ) , transform86 , _MixCameraObjectPosition);
			float4 testPoint84 = lerpResult82;
			float smoothstepResult27 = smoothstep( 0.0 , 1.0 , saturate( ( ( _FadeDistance - abs( length( ( float4( ase_worldPos , 0.0 ) - testPoint84 ) ) ) ) / _FadeDistance ) ));
			float prox72 = smoothstepResult27;
			float4 temp_cast_2 = (prox72).xxxx;
			float4 temp_output_1_0_g8 = temp_cast_2;
			float4 break5_g8 = temp_output_1_0_g8;
			float Sample2_g7 = saturate( prox72 );
			float localAudioLinkLerp2_g7 = AudioLinkLerp2_g7( Sample2_g7 );
			int Band3_g6 = 0;
			float smoothstepResult79 = smoothstep( 0.0 , 1.0 , ( abs( ( 0.5 - prox72 ) ) * 2.0 ));
			float Delay3_g6 = ( smoothstepResult79 * 128.0 * _PulseWidth );
			float localAudioLinkLerp3_g6 = AudioLinkLerp3_g6( Band3_g6 , Delay3_g6 );
			float lerpResult54 = lerp( localAudioLinkLerp2_g7 , localAudioLinkLerp3_g6 , _AutoCorrBassBand);
			float lerpResult49 = lerp( 0.5 , saturate( lerpResult54 ) , _AudioLinkPower);
			float4 temp_cast_3 = (lerpResult49).xxxx;
			float4 temp_output_2_0_g8 = temp_cast_3;
			float4 fade34 = ( ( ( break5_g8.r * 0.2 ) + ( break5_g8.g * 0.7 ) + ( break5_g8.b * 0.1 ) ) < 0.5 ? ( 2.0 * temp_output_1_0_g8 * temp_output_2_0_g8 ) : ( 1.0 - ( 2.0 * ( 1.0 - temp_output_1_0_g8 ) * ( 1.0 - temp_output_2_0_g8 ) ) ) );
			float lerpResult37 = lerp( ( 1.0 - temp_output_71_0 ) , temp_output_71_0 , ( 1.0 - fade34 ).r);
			float4 lerpResult16 = lerp( _ColorFar , _ColorClose , fade34);
			float4 temp_output_29_0 = saturate( ( lerpResult37 * lerpResult16 ) );
			o.Emission = temp_output_29_0.rgb;
			o.Alpha = 1;
		}

		ENDCG
		CGPROGRAM
		#pragma surface surf Unlit keepalpha fullforwardshadows 

		ENDCG
		Pass
		{
			Name "ShadowCaster"
			Tags{ "LightMode" = "ShadowCaster" }
			ZWrite On
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			#pragma multi_compile_shadowcaster
			#pragma multi_compile UNITY_PASS_SHADOWCASTER
			#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
			#include "HLSLSupport.cginc"
			#if ( SHADER_API_D3D11 || SHADER_API_GLCORE || SHADER_API_GLES || SHADER_API_GLES3 || SHADER_API_METAL || SHADER_API_VULKAN )
				#define CAN_SKIP_VPOS
			#endif
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"
			struct v2f
			{
				V2F_SHADOW_CASTER;
				float3 worldPos : TEXCOORD1;
				float3 worldNormal : TEXCOORD2;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};
			v2f vert( appdata_full v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID( v );
				UNITY_INITIALIZE_OUTPUT( v2f, o );
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );
				UNITY_TRANSFER_INSTANCE_ID( v, o );
				float3 worldPos = mul( unity_ObjectToWorld, v.vertex ).xyz;
				half3 worldNormal = UnityObjectToWorldNormal( v.normal );
				o.worldNormal = worldNormal;
				o.worldPos = worldPos;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET( o )
				return o;
			}
			half4 frag( v2f IN
			#if !defined( CAN_SKIP_VPOS )
			, UNITY_VPOS_TYPE vpos : VPOS
			#endif
			) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				Input surfIN;
				UNITY_INITIALIZE_OUTPUT( Input, surfIN );
				float3 worldPos = IN.worldPos;
				half3 worldViewDir = normalize( UnityWorldSpaceViewDir( worldPos ) );
				surfIN.viewDir = worldViewDir;
				surfIN.worldPos = worldPos;
				surfIN.worldNormal = IN.worldNormal;
				SurfaceOutput o;
				UNITY_INITIALIZE_OUTPUT( SurfaceOutput, o )
				surf( surfIN, o );
				#if defined( CAN_SKIP_VPOS )
				float2 vpos = IN.pos;
				#endif
				SHADOW_CASTER_FRAGMENT( IN )
			}
			ENDCG
		}
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=18935
3099.2;21.6;1335;889;2131.865;-1192.542;1.375;True;False
Node;AmplifyShaderEditor.WorldSpaceCameraPos;17;-2193.041,2067.373;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;83;-2229.489,2456.854;Inherit;False;Property;_MixCameraObjectPosition;Mix Camera / Object Position;11;0;Create;True;0;0;0;False;0;False;0;0.572;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.ObjectToWorldTransfNode;86;-2159.364,2236.854;Inherit;False;1;0;FLOAT4;0,0,0,1;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LerpOp;82;-1768.864,2249.229;Inherit;False;3;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0,0,0,0;False;2;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;84;-1519.989,2311.104;Inherit;False;testPoint;-1;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.CommentaryNode;74;-2346.166,1432.323;Inherit;False;1710.977;452.65;Proximity to Camera;11;22;24;25;27;72;23;21;20;19;18;85;;0.7607273,0.6179246,1,1;0;0
Node;AmplifyShaderEditor.WorldPosInputsNode;18;-2228.166,1519.373;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.GetLocalVarNode;85;-2210.239,1697.854;Inherit;False;84;testPoint;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;19;-2008.791,1619.623;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.LengthOpNode;20;-1836.415,1669.998;Inherit;False;1;0;FLOAT4;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.AbsOpNode;21;-1689.414,1637.748;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;23;-1775.615,1482.323;Inherit;False;Property;_FadeDistance;Fade Distance;6;0;Create;True;0;0;0;False;0;False;0;10.1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;22;-1531.665,1593.473;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;24;-1365.745,1516.329;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;25;-1208.81,1560.554;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;27;-1050.432,1537.283;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;72;-859.9889,1597.479;Inherit;False;prox;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;73;-473.614,1644.229;Inherit;False;72;prox;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;78;-455.739,1921.979;Inherit;False;2;0;FLOAT;0.5;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.AbsOpNode;76;-294.864,2004.479;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;77;-88.61401,1972.854;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;2;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;51;-51.15515,2177.564;Inherit;False;Property;_PulseWidth;Pulse Width;8;0;Create;True;0;0;0;False;0;False;0.5;0.308;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;79;64.01099,1842.229;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;43;277.2747,1893.078;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;128;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;75;-2342.965,998.2378;Inherit;False;847.2349;396.8512;Is Back Face?;5;58;59;56;62;63;;0,0.7605362,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;53;398.825,1598.964;Inherit;False;Property;_AutoCorrBassBand;AutoCorr / BassBand;9;0;Create;True;0;0;0;False;0;False;0.5;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;42;390.854,1488.929;Inherit;False;4BandAmplitudeLerp;-1;;6;3cf4b6e83381a9a4f84f8cf857bc3af5;0;2;2;INT;0;False;4;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;48;347.8147,1390.484;Inherit;False;AutoCorrelatorUncorrelated;-1;;7;7fdb22cc62063814cb854a23c9992c11;0;1;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldNormalVector;59;-2292.965,1048.238;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.LerpOp;54;722.825,1478.964;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;58;-2264.585,1209.489;Inherit;False;World;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;52;790.825,1814.964;Inherit;False;Property;_AudioLinkPower;AudioLink Power;7;0;Create;True;0;0;0;False;0;False;0.8;0.333;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;47;923.079,1560.689;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;56;-2065.925,1115.318;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldPosInputsNode;7;-1473.315,213.253;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;8;-1470.315,365.253;Inherit;False;Property;_TextureScale;Texture Scale;2;0;Create;True;0;0;0;True;0;False;0;0.125;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.Vector3Node;10;-1477.315,453.253;Inherit;False;Property;_TextureOffset;Texture Offset;3;0;Create;True;0;0;0;True;0;False;0,0,0;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.WorldNormalVector;4;-1485.5,64.76498;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.Compare;62;-1916.284,1139.829;Inherit;False;2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;49;1144.974,1711.674;Inherit;False;3;0;FLOAT;0.5;False;1;FLOAT;0.5;False;2;FLOAT;0.6;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;63;-1720.53,1181.789;Inherit;False;backFace;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;46;1380.224,1644.863;Inherit;False;BlendOverlay;-1;;8;6c2f15995e7c1bf4bafb65b1a44446b2;0;2;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.CustomExpressionNode;5;-1193.23,251.385;Inherit;False;float scaleInv = 1 / Scale@$if (abs(Normal.x) > 0.5)${$	return Position.yz * scaleInv + Offset.yz@$}$else if (abs(Normal.z) > 0.5)${$	return Position.xy * scaleInv + Offset.xy@$}$else${$	return Position.xz * scaleInv + Offset.xz@$};2;Create;4;True;Normal;FLOAT3;0,0,0;In;;Inherit;False;True;Position;FLOAT3;0,0,0;In;;Inherit;False;True;Scale;FLOAT;0;In;;Inherit;False;True;Offset;FLOAT3;0,0,0;In;;Inherit;False;Cubic World Texture UV;True;False;0;;False;4;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;3;FLOAT3;0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;66;-756.5543,-162.0157;Inherit;False;63;backFace;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;70;-784.9341,1.81425;Inherit;False;Property;_BackBrightness;Back Brightness;10;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;6;-872.4749,202.68;Inherit;True;Property;_MainTex;Main Tex;1;0;Create;True;0;0;0;False;0;False;-1;None;2ab312c3b30c1cd439554d97a4c9cd52;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RegisterLocalVarNode;34;1612.39,1716.324;Float;False;fade;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;35;84.56062,816.8828;Inherit;False;34;fade;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.Compare;71;-378.739,112.4793;Inherit;False;0;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;14;70.31519,973.4981;Inherit;False;Property;_ColorFar;Color Far;4;0;Create;True;0;0;0;False;0;False;0.5,0.5,0.5,0;0,0.08547584,0.2627451,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.OneMinusNode;40;162.6656,587.4839;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.ColorNode;15;74.88029,1171.253;Inherit;False;Property;_ColorClose;Color Close;5;0;Create;True;0;0;0;False;0;False;1,1,1,0;0.3803921,0.7009753,0.7176471,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.OneMinusNode;39;181.4905,264.9489;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;37;376.0166,488.339;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;16;453.8804,1048.253;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;33;614.0239,169.7086;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;61;1210.695,556.5141;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SaturateNode;29;807.4478,343.1684;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;60;1028.805,481.6941;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;13;1424.915,76.92998;Float;False;True;-1;2;ASEMaterialInspector;0;0;Unlit;InfoPanel;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;Off;2;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Custom;0;True;True;0;True;Custom;;Transparent;All;18;all;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;True;4;1;False;-1;1;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;True;Relative;0;;0;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;False;15;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;82;0;17;0
WireConnection;82;1;86;0
WireConnection;82;2;83;0
WireConnection;84;0;82;0
WireConnection;19;0;18;0
WireConnection;19;1;85;0
WireConnection;20;0;19;0
WireConnection;21;0;20;0
WireConnection;22;0;23;0
WireConnection;22;1;21;0
WireConnection;24;0;22;0
WireConnection;24;1;23;0
WireConnection;25;0;24;0
WireConnection;27;0;25;0
WireConnection;72;0;27;0
WireConnection;78;1;73;0
WireConnection;76;0;78;0
WireConnection;77;0;76;0
WireConnection;79;0;77;0
WireConnection;43;0;79;0
WireConnection;43;2;51;0
WireConnection;42;4;43;0
WireConnection;48;1;73;0
WireConnection;54;0;48;0
WireConnection;54;1;42;0
WireConnection;54;2;53;0
WireConnection;47;0;54;0
WireConnection;56;0;59;0
WireConnection;56;1;58;0
WireConnection;62;0;56;0
WireConnection;49;1;47;0
WireConnection;49;2;52;0
WireConnection;63;0;62;0
WireConnection;46;1;73;0
WireConnection;46;2;49;0
WireConnection;5;0;4;0
WireConnection;5;1;7;0
WireConnection;5;2;8;0
WireConnection;5;3;10;0
WireConnection;6;1;5;0
WireConnection;34;0;46;0
WireConnection;71;0;66;0
WireConnection;71;2;70;0
WireConnection;71;3;6;1
WireConnection;40;0;35;0
WireConnection;39;0;71;0
WireConnection;37;0;39;0
WireConnection;37;1;71;0
WireConnection;37;2;40;0
WireConnection;16;0;14;0
WireConnection;16;1;15;0
WireConnection;16;2;35;0
WireConnection;33;0;37;0
WireConnection;33;1;16;0
WireConnection;61;0;60;0
WireConnection;29;0;33;0
WireConnection;60;0;29;0
WireConnection;13;2;29;0
ASEEND*/
//CHKSM=7E01424D4F5EAC2D1647DFEE3C96C28687246C98