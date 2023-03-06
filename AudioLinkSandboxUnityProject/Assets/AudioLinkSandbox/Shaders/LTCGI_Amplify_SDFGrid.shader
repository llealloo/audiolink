// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "LTCGI_Amplify_WorldSpaceTex"
{
	Properties
	{
		_MainTex("Main Tex", 2D) = "white" {}
		[Normal]_BumpMap("BumpMap", 2D) = "bump" {}
		_Smoothness("Smoothness", Range( 0 , 1)) = 0.5
		_TextureScale("Texture Scale", Float) = 0
		_TextureOffset("Texture Offset", Vector) = (0,0,0,0)
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] _texcoord2( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" "IsEmissive" = "true"  "LTCGI"="ALWAYS" }
		Cull Back
		CGINCLUDE
		#include "UnityShaderVariables.cginc"
		#include "UnityPBSLighting.cginc"
		#include "Lighting.cginc"
		#pragma target 3.0
		#include "Assets/_pi_/_LTCGI/Shaders/LTCGI.cginc"
		#ifdef UNITY_PASS_SHADOWCASTER
			#undef INTERNAL_DATA
			#undef WorldReflectionVector
			#undef WorldNormalVector
			#define INTERNAL_DATA half3 internalSurfaceTtoW0; half3 internalSurfaceTtoW1; half3 internalSurfaceTtoW2;
			#define WorldReflectionVector(data,normal) reflect (data.worldRefl, half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal)))
			#define WorldNormalVector(data,normal) half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal))
		#endif
		struct Input
		{
			float3 worldNormal;
			INTERNAL_DATA
			float3 worldPos;
			float2 uv_texcoord;
			float2 uv2_texcoord2;
		};

		uniform sampler2D _MainTex;
		uniform float _TextureScale;
		uniform float3 _TextureOffset;
		uniform sampler2D _BumpMap;
		uniform float4 _BumpMap_ST;
		uniform float _Smoothness;


		float2 CubicWorldTextureUV54( float3 Normal, float3 Position, float Scale, float3 Offset )
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


		void surf( Input i , inout SurfaceOutputStandard o )
		{
			o.Normal = float3(0,0,1);
			float3 ase_worldNormal = WorldNormalVector( i, float3( 0, 0, 1 ) );
			float3 Normal54 = ase_worldNormal;
			float3 ase_worldPos = i.worldPos;
			float3 Position54 = ase_worldPos;
			float Scale54 = _TextureScale;
			float3 Offset54 = _TextureOffset;
			float2 localCubicWorldTextureUV54 = CubicWorldTextureUV54( Normal54 , Position54 , Scale54 , Offset54 );
			float2 worldUV58 = localCubicWorldTextureUV54;
			o.Albedo = tex2D( _MainTex, worldUV58 ).rgb;
			float localLTCGI15_g1 = ( 0.0 );
			float3 worldPos15_g1 = ase_worldPos;
			float2 uv_BumpMap = i.uv_texcoord * _BumpMap_ST.xy + _BumpMap_ST.zw;
			float3 normalizeResult9_g1 = normalize( (WorldNormalVector( i , UnpackNormal( tex2D( _BumpMap, uv_BumpMap ) ) )) );
			float3 worldNorm15_g1 = normalizeResult9_g1;
			float3 normalizeResult12_g1 = normalize( ( _WorldSpaceCameraPos - ase_worldPos ) );
			float3 cameraDir15_g1 = normalizeResult12_g1;
			float roughness15_g1 = ( 1.0 - _Smoothness );
			float2 lightmapUV15_g1 = i.uv2_texcoord2;
			float3 diffuse15_g1 = float3( 0,0,0 );
			float3 specular15_g1 = float3( 0,0,0 );
			float specularIntensity15_g1 = 0;
			{
			LTCGI_Contribution(worldPos15_g1, worldNorm15_g1, cameraDir15_g1, roughness15_g1, lightmapUV15_g1, diffuse15_g1, specular15_g1, specularIntensity15_g1);
			}
			float3 ltcgi47 = ( ( diffuse15_g1 * 0.05 ) + ( specular15_g1 * 1.0 ) );
			o.Emission = ltcgi47;
			o.Alpha = 1;
		}

		ENDCG
		CGPROGRAM
		#pragma surface surf Standard keepalpha fullforwardshadows 

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
				float4 customPack1 : TEXCOORD1;
				float4 tSpace0 : TEXCOORD2;
				float4 tSpace1 : TEXCOORD3;
				float4 tSpace2 : TEXCOORD4;
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
				Input customInputData;
				float3 worldPos = mul( unity_ObjectToWorld, v.vertex ).xyz;
				half3 worldNormal = UnityObjectToWorldNormal( v.normal );
				half3 worldTangent = UnityObjectToWorldDir( v.tangent.xyz );
				half tangentSign = v.tangent.w * unity_WorldTransformParams.w;
				half3 worldBinormal = cross( worldNormal, worldTangent ) * tangentSign;
				o.tSpace0 = float4( worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x );
				o.tSpace1 = float4( worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y );
				o.tSpace2 = float4( worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z );
				o.customPack1.xy = customInputData.uv_texcoord;
				o.customPack1.xy = v.texcoord;
				o.customPack1.zw = customInputData.uv2_texcoord2;
				o.customPack1.zw = v.texcoord1;
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
				surfIN.uv_texcoord = IN.customPack1.xy;
				surfIN.uv2_texcoord2 = IN.customPack1.zw;
				float3 worldPos = float3( IN.tSpace0.w, IN.tSpace1.w, IN.tSpace2.w );
				half3 worldViewDir = normalize( UnityWorldSpaceViewDir( worldPos ) );
				surfIN.worldPos = worldPos;
				surfIN.worldNormal = float3( IN.tSpace0.z, IN.tSpace1.z, IN.tSpace2.z );
				surfIN.internalSurfaceTtoW0 = IN.tSpace0.xyz;
				surfIN.internalSurfaceTtoW1 = IN.tSpace1.xyz;
				surfIN.internalSurfaceTtoW2 = IN.tSpace2.xyz;
				SurfaceOutputStandard o;
				UNITY_INITIALIZE_OUTPUT( SurfaceOutputStandard, o )
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
3856.8;22.4;1940;1560;857.9202;469.5634;1;True;False
Node;AmplifyShaderEditor.CommentaryNode;46;-1474.065,472.188;Inherit;False;1426.865;507.2731;LTCGI;11;47;26;12;21;35;25;24;20;5;2;6;;0,1,0.266294,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;6;-1310.315,620.0759;Inherit;False;Constant;_Float0;Float 0;3;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;2;-1424.065,522.188;Inherit;False;Property;_Smoothness;Smoothness;2;0;Create;True;0;0;0;False;0;False;0.5;0.925;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.TexturePropertyNode;20;-1264.664,755.3642;Inherit;True;Property;_BumpMap;BumpMap;1;1;[Normal];Create;True;0;0;0;False;0;False;None;None;True;bump;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.SimpleSubtractOpNode;5;-1124.993,610.1395;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;49;-1468.165,-305.3486;Inherit;False;846.5942;624.088;World UV;6;54;53;52;51;50;58;;0.7314231,1,0.3349057,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;24;-744.2743,646.6233;Inherit;False;Constant;_Float1;Float 1;3;0;Create;True;0;0;0;False;0;False;0.05;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;35;-966.9304,732.7902;Inherit;False;LTCGI_Contribution;-1;;1;d3ea6060590627141a6e856295f0e87c;0;2;18;SAMPLER2D;0;False;21;FLOAT;0;False;3;FLOAT3;16;FLOAT;17;FLOAT3;0
Node;AmplifyShaderEditor.Vector3Node;52;-1409.98,129.1979;Inherit;False;Property;_TextureOffset;Texture Offset;4;0;Create;True;0;0;0;True;0;False;0,0,0;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;25;-744.2739,872.7543;Inherit;False;Constant;_Float2;Float 2;3;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;53;-1401.009,39.22718;Inherit;False;Property;_TextureScale;Texture Scale;3;0;Create;True;0;0;0;True;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.WorldPosInputsNode;51;-1405.98,-106.8609;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.WorldNormalVector;50;-1418.165,-255.3487;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;21;-586.5086,680.806;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;12;-583.9532,806.337;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CustomExpressionNode;54;-1125.896,-68.72875;Inherit;False;float scaleInv = 1 / Scale@$if (abs(Normal.x) > 0.5)${$	return Position.yz * scaleInv + Offset.yz@$}$else if (abs(Normal.z) > 0.5)${$	return Position.xy * scaleInv + Offset.xy@$}$else${$	return Position.xz * scaleInv + Offset.xz@$};2;Create;4;True;Normal;FLOAT3;0,0,0;In;;Inherit;False;True;Position;FLOAT3;0,0,0;In;;Inherit;False;True;Scale;FLOAT;0;In;;Inherit;False;True;Offset;FLOAT3;0,0,0;In;;Inherit;False;Cubic World Texture UV;True;False;0;;False;4;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;3;FLOAT3;0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;26;-424.7989,742.5975;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;58;-849.3069,-97.23495;Inherit;False;worldUV;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;47;-257.521,789.7518;Inherit;False;ltcgi;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;56;-268.3913,-8.254925;Inherit;False;58;worldUV;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;48;104.3378,138.1628;Inherit;False;47;ltcgi;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SamplerNode;57;-22.69211,-129.1549;Inherit;True;Property;_MainTex;Main Tex;0;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;45;387.8991,5.103931;Float;False;True;-1;2;ASEMaterialInspector;0;0;Standard;LTCGI_Amplify_WorldSpaceTex;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;Back;0;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Opaque;0.5;True;True;0;False;Opaque;;Geometry;All;18;all;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;True;0;0;False;-1;0;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;True;Relative;0;;-1;-1;-1;-1;1;LTCGI=ALWAYS;False;0;0;False;-1;-1;0;False;-1;1;Include;Assets/_pi_/_LTCGI/Shaders/LTCGI.cginc;False;;Custom;0;0;False;0.1;False;-1;0;False;-1;False;16;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;5;0;6;0
WireConnection;5;1;2;0
WireConnection;35;18;20;0
WireConnection;35;21;5;0
WireConnection;21;0;35;0
WireConnection;21;1;24;0
WireConnection;12;0;35;16
WireConnection;12;1;25;0
WireConnection;54;0;50;0
WireConnection;54;1;51;0
WireConnection;54;2;53;0
WireConnection;54;3;52;0
WireConnection;26;0;21;0
WireConnection;26;1;12;0
WireConnection;58;0;54;0
WireConnection;47;0;26;0
WireConnection;57;1;56;0
WireConnection;45;0;57;0
WireConnection;45;2;48;0
ASEEND*/
//CHKSM=8A8D304447E5888693D027CF095DF0CA2045FF38