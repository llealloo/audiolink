// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "AudioLink/AudioSpectrum"
{
    Properties
    {
		_RTARenderTexture("RTA Render Texture", 2D) = "gray" {}
		_Bands("Bands (Rows)", Float) = 4
		_Gain("Gain", Range( 0 , 2)) = 0.2724236
		_LogAttenuation("Log Attenuation", Range( 0 , 1)) = 0
		_ContrastSlope("Contrast Slope", Range( 0 , 1)) = 0
		_ContrastOffset("Contrast Offset", Range( 0 , 1)) = 0
		_FadeLength("Fade Length", Range( 0 , 1)) = 0
		_FadeExpFalloff("Fade Exp Falloff", Range( 0 , 1)) = 0.3144608
		_Bass("Bass", Range( 0 , 4)) = 1
		_Treble("Treble", Range( 0 , 4)) = 1

    }

	SubShader
	{
		LOD 0

		
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
			Name "Custom RT Update"
            CGPROGRAM
            
            #include "UnityCustomRenderTexture.cginc"
            #pragma vertex ASECustomRenderTextureVertexShader
            #pragma fragment frag
            #pragma target 3.0
			

			struct ase_appdata_customrendertexture
			{
				uint vertexID : SV_VertexID;
				
			};

			struct ase_v2f_customrendertexture
			{
				float4 vertex           : SV_POSITION;
				float3 localTexcoord    : TEXCOORD0;    // Texcoord local to the update zone (== globalTexcoord if no partial update zone is specified)
				float3 globalTexcoord   : TEXCOORD1;    // Texcoord relative to the complete custom texture
				uint primitiveID        : TEXCOORD2;    // Index of the update zone (correspond to the index in the updateZones of the Custom Texture)
				float3 direction        : TEXCOORD3;    // For cube textures, direction of the pixel being rendered in the cubemap
				
			};

			uniform sampler2D _RTARenderTexture;
			uniform float _FadeLength;
			uniform float _FadeExpFalloff;
			uniform float _Gain;
			uniform float _Bass;
			uniform float _Treble;
			uniform float _Bands;
			uniform float Lut[1023];
			uniform float Chunks[1023];
			uniform float Spectrum[1023];
			uniform float _LogAttenuation;
			uniform float _ContrastSlope;
			uniform float _ContrastOffset;
			float InvCubeRemap119( float Input )
			{
				return -1.0 * pow(Input-1.0, 3);
			}
			
			float CubicAttenuation123( float Input, float Attenuation )
			{
				return Input * (1.0 + ( pow(Input-1.0, 4.0) * Attenuation ) - Attenuation);
			}
			
			float LinearEQ139( float Gain, float BassLevel, float TrebleLevel, float Freq )
			{
				return Gain*(((1.0-Freq)*BassLevel)+(Freq*TrebleLevel));
			}
			
			float LUTCRONCH151( float Pointer, float Size, float Activate )
			{
				float total = 0;
				for( int i=Pointer; i<Pointer+Size; i++)
				{
					total += Spectrum[i] * i;
					//total = max(total, Spectrum[i]);
				}
				return total/Size;
			}
			
			float LogAttenuation94( float Input, float Attenuation )
			{
				return clamp(Input * (log(1.1)/(log(1.1+pow(Attenuation, 4)*(1.0-Input)))), 0.0, 1.0);
			}
			
			float Contrast99( float Input, float Slope, float Offset )
			{
				return clamp((Input*tan(1.57*Slope) + Input + Offset*tan(1.57*Slope) - tan(1.57*Slope)), 0, 1);
			}
			


			ase_v2f_customrendertexture ASECustomRenderTextureVertexShader(ase_appdata_customrendertexture IN  )
			{
				ase_v2f_customrendertexture OUT;
				
			#if UNITY_UV_STARTS_AT_TOP
				const float2 vertexPositions[6] =
				{
					{ -1.0f,  1.0f },
					{ -1.0f, -1.0f },
					{  1.0f, -1.0f },
					{  1.0f,  1.0f },
					{ -1.0f,  1.0f },
					{  1.0f, -1.0f }
				};

				const float2 texCoords[6] =
				{
					{ 0.0f, 0.0f },
					{ 0.0f, 1.0f },
					{ 1.0f, 1.0f },
					{ 1.0f, 0.0f },
					{ 0.0f, 0.0f },
					{ 1.0f, 1.0f }
				};
			#else
				const float2 vertexPositions[6] =
				{
					{  1.0f,  1.0f },
					{ -1.0f, -1.0f },
					{ -1.0f,  1.0f },
					{ -1.0f, -1.0f },
					{  1.0f,  1.0f },
					{  1.0f, -1.0f }
				};

				const float2 texCoords[6] =
				{
					{ 1.0f, 1.0f },
					{ 0.0f, 0.0f },
					{ 0.0f, 1.0f },
					{ 0.0f, 0.0f },
					{ 1.0f, 1.0f },
					{ 1.0f, 0.0f }
				};
			#endif

				uint primitiveID = IN.vertexID / 6;
				uint vertexID = IN.vertexID % 6;
				float3 updateZoneCenter = CustomRenderTextureCenters[primitiveID].xyz;
				float3 updateZoneSize = CustomRenderTextureSizesAndRotations[primitiveID].xyz;
				float rotation = CustomRenderTextureSizesAndRotations[primitiveID].w * UNITY_PI / 180.0f;

			#if !UNITY_UV_STARTS_AT_TOP
				rotation = -rotation;
			#endif

				// Normalize rect if needed
				if (CustomRenderTextureUpdateSpace > 0.0) // Pixel space
				{
					// Normalize xy because we need it in clip space.
					updateZoneCenter.xy /= _CustomRenderTextureInfo.xy;
					updateZoneSize.xy /= _CustomRenderTextureInfo.xy;
				}
				else // normalized space
				{
					// Un-normalize depth because we need actual slice index for culling
					updateZoneCenter.z *= _CustomRenderTextureInfo.z;
					updateZoneSize.z *= _CustomRenderTextureInfo.z;
				}

				// Compute rotation

				// Compute quad vertex position
				float2 clipSpaceCenter = updateZoneCenter.xy * 2.0 - 1.0;
				float2 pos = vertexPositions[vertexID] * updateZoneSize.xy;
				pos = CustomRenderTextureRotate2D(pos, rotation);
				pos.x += clipSpaceCenter.x;
			#if UNITY_UV_STARTS_AT_TOP
				pos.y += clipSpaceCenter.y;
			#else
				pos.y -= clipSpaceCenter.y;
			#endif

				// For 3D texture, cull quads outside of the update zone
				// This is neeeded in additional to the preliminary minSlice/maxSlice done on the CPU because update zones can be disjointed.
				// ie: slices [1..5] and [10..15] for two differents zones so we need to cull out slices 0 and [6..9]
				if (CustomRenderTextureIs3D > 0.0)
				{
					int minSlice = (int)(updateZoneCenter.z - updateZoneSize.z * 0.5);
					int maxSlice = minSlice + (int)updateZoneSize.z;
					if (_CustomRenderTexture3DSlice < minSlice || _CustomRenderTexture3DSlice >= maxSlice)
					{
						pos.xy = float2(1000.0, 1000.0); // Vertex outside of ncs
					}
				}

				OUT.vertex = float4(pos, 0.0, 1.0);
				OUT.primitiveID = asuint(CustomRenderTexturePrimitiveIDs[primitiveID]);
				OUT.localTexcoord = float3(texCoords[vertexID], CustomRenderTexture3DTexcoordW);
				OUT.globalTexcoord = float3(pos.xy * 0.5 + 0.5, CustomRenderTexture3DTexcoordW);
			#if UNITY_UV_STARTS_AT_TOP
				OUT.globalTexcoord.y = 1.0 - OUT.globalTexcoord.y;
			#endif
				OUT.direction = CustomRenderTextureComputeCubeDirection(OUT.globalTexcoord.xy);

				return OUT;
			}

            float4 frag(ase_v2f_customrendertexture IN ) : COLOR
            {
				float4 finalColor;
				float2 texCoord4 = IN.localTexcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float curU127 = texCoord4.x;
				float curV86 = texCoord4.y;
				float2 appendResult25 = (float2(( curU127 - 0.03125 ) , curV86));
				float2 texCoord132 = IN.localTexcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float Input119 = _FadeLength;
				float localInvCubeRemap119 = InvCubeRemap119( Input119 );
				float Input123 = ( tex2D( _RTARenderTexture, texCoord132 ).r - localInvCubeRemap119 );
				float Attenuation123 = _FadeExpFalloff;
				float localCubicAttenuation123 = CubicAttenuation123( Input123 , Attenuation123 );
				float clampResult125 = clamp( localCubicAttenuation123 , 0.0 , 1.0 );
				float Gain139 = _Gain;
				float BassLevel139 = _Bass;
				float TrebleLevel139 = _Treble;
				float Freq139 = curV86;
				float localLinearEQ139 = LinearEQ139( Gain139 , BassLevel139 , TrebleLevel139 , Freq139 );
				float bands176 = _Bands;
				float temp_output_81_0 = ( curV86 * bands176 );
				float Pointer151 = Lut[(int)temp_output_81_0];
				float Size151 = Chunks[(int)temp_output_81_0];
				float Activate151 = Spectrum[5];
				float localLUTCRONCH151 = LUTCRONCH151( Pointer151 , Size151 , Activate151 );
				float raw133 = localLUTCRONCH151;
				float clampResult147 = clamp( ( localLinearEQ139 * raw133 ) , 0.0 , 1.0 );
				float eq2142 = clampResult147;
				float Input94 = eq2142;
				float Attenuation94 = _LogAttenuation;
				float localLogAttenuation94 = LogAttenuation94( Input94 , Attenuation94 );
				float Input99 = localLogAttenuation94;
				float Slope99 = _ContrastSlope;
				float Offset99 = _ContrastOffset;
				float localContrast99 = Contrast99( Input99 , Slope99 , Offset99 );
				float eq3105 = localContrast99;
				float temp_output_111_0 = max( clampResult125 , eq3105 );
				float4 appendResult36 = (float4(temp_output_111_0 , temp_output_111_0 , temp_output_111_0 , 1.0));
				float4 ifLocalVar21 = 0;
				if( curU127 > 0.03125 )
				ifLocalVar21 = tex2D( _RTARenderTexture, appendResult25 );
				else if( curU127 < 0.03125 )
				ifLocalVar21 = appendResult36;
				float4 break182 = ifLocalVar21;
				float4 appendResult183 = (float4(break182.r , break182.g , break182.b , 0.0));
				
                finalColor = appendResult183;
				return finalColor;
            }
            ENDCG
		}
    }
	
	CustomEditor "ASEMaterialInspector"
	
}
/*ASEBEGIN
Version=18900
3809.6;271.2;2250;1278;3127.253;1631.323;1.55;True;False
Node;AmplifyShaderEditor.CommentaryNode;197;-1316.941,-1561.452;Inherit;False;1050.201;483.9189;Variable setup;8;4;175;86;176;189;188;127;18;;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;175;-718.7701,-1287.5;Inherit;False;Property;_Bands;Bands (Rows);1;0;Create;False;0;0;0;False;0;False;4;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;4;-1253.005,-1268.113;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RegisterLocalVarNode;176;-512.1118,-1287.5;Inherit;False;bands;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;89;-2590.922,-1520.167;Inherit;False;1232.653;415.4087;1024 Linear -> N Log LUT;8;177;151;2;68;150;133;81;129;;0.8745098,1,0.7764706,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;86;-958.1788,-1192.279;Inherit;False;curV;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;129;-2552.165,-1443.472;Inherit;False;86;curV;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;177;-2550.748,-1341.316;Inherit;False;176;bands;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;81;-2328.373,-1453.668;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;32;False;1;FLOAT;0
Node;AmplifyShaderEditor.GlobalArrayNode;2;-2126.695,-1214.831;Inherit;False;Spectrum;5;1023;0;False;False;0;1;False;Object;-1;4;0;INT;0;False;2;INT;0;False;1;INT;0;False;3;INT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GlobalArrayNode;68;-2124.841,-1469.416;Inherit;False;Lut;0;1023;0;False;False;0;1;False;Object;-1;4;0;INT;0;False;2;INT;0;False;1;INT;0;False;3;INT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GlobalArrayNode;150;-2126.831,-1348.701;Inherit;False;Chunks;0;1023;0;False;False;0;1;False;Object;-1;4;0;INT;0;False;2;INT;0;False;1;INT;0;False;3;INT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CustomExpressionNode;151;-1822.167,-1379.581;Inherit;False;float total = 0@$for( int i=Pointer@ i<Pointer+Size@ i++)${$	total += Spectrum[i] * i@$	//total = max(total, Spectrum[i])@$}$return total/Size@;1;False;3;True;Pointer;FLOAT;0;In;;Inherit;False;True;Size;FLOAT;0;In;;Inherit;False;True;Activate;FLOAT;0;In;;Inherit;False;LUT CRONCH;True;False;0;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;143;-2632.465,-1071.711;Inherit;False;1272.966;403.645;Bass / Treble EQ;9;142;147;139;141;140;138;137;51;136;;1,1,1,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;133;-1574.348,-1409.271;Inherit;False;raw;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;138;-2480.634,-752.8357;Inherit;False;86;curV;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;137;-2580.803,-840.1056;Inherit;False;Property;_Treble;Treble;10;0;Create;True;0;0;0;False;0;False;1;0;0;4;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;51;-2587.919,-1019.258;Inherit;False;Property;_Gain;Gain;3;0;Create;True;0;0;0;False;0;False;0.2724236;0;0;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;136;-2581.255,-927.2868;Inherit;False;Property;_Bass;Bass;9;0;Create;True;0;0;0;False;0;False;1;0;0;4;0;1;FLOAT;0
Node;AmplifyShaderEditor.CustomExpressionNode;139;-2228.439,-989.7296;Inherit;False;return Gain*(((1.0-Freq)*BassLevel)+(Freq*TrebleLevel))@;1;False;4;True;Gain;FLOAT;0;In;;Inherit;False;True;BassLevel;FLOAT;0;In;;Inherit;False;True;TrebleLevel;FLOAT;0;In;;Inherit;False;True;Freq;FLOAT;0;In;;Inherit;False;Linear EQ;True;False;0;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;140;-2186.398,-834.3016;Inherit;False;133;raw;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;141;-1955.711,-916.6469;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;147;-1785.516,-883.4635;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;142;-1583.205,-995.4196;Inherit;False;eq2;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;126;-2197.81,-271.7629;Inherit;False;1600.178;439.9229;Trails / Fade;11;36;107;111;106;125;123;113;121;44;119;132;;0.9152238,0.7028302,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;104;-2632.18,-645.6932;Inherit;False;1135.637;339.3584;Log Attenuation & Contrast;7;105;100;99;91;96;94;102;;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;96;-2596.282,-491.0063;Inherit;False;Property;_LogAttenuation;Log Attenuation;4;0;Create;True;0;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;107;-2082.774,-11.44797;Inherit;False;Property;_FadeLength;Fade Length;7;0;Create;True;0;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;91;-2597.26,-589.8366;Inherit;False;142;eq2;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;132;-2167.389,-177.5244;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;44;-1898.489,-215.7262;Inherit;True;Property;_TextureSample1;Texture Sample 1;0;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;gray;Auto;False;Instance;18;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.CustomExpressionNode;94;-2261.385,-597.8323;Inherit;False;return clamp(Input * (log(1.1)/(log(1.1+pow(Attenuation, 4)*(1.0-Input)))), 0.0, 1.0)@;1;False;2;True;Input;FLOAT;0;In;;Inherit;False;True;Attenuation;FLOAT;0;In;;Inherit;False;Log Attenuation;True;False;0;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;100;-2267.027,-487.4856;Inherit;False;Property;_ContrastSlope;Contrast Slope;5;0;Create;True;0;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;102;-2260.55,-397.2217;Inherit;False;Property;_ContrastOffset;Contrast Offset;6;0;Create;True;0;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.CustomExpressionNode;119;-1784.217,-7.926696;Inherit;False;return -1.0 * pow(Input-1.0, 3)@;1;False;1;True;Input;FLOAT;0;In;;Inherit;False;Inv Cube Remap;True;False;0;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;60;-1467.931,-575.8552;Inherit;False;875.6935;269.33;Shift Pixels Right;5;43;130;25;20;131;;0.3867925,0.3867925,0.3867925,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;121;-2081.895,77.43327;Inherit;False;Property;_FadeExpFalloff;Fade Exp Falloff;8;0;Create;True;0;0;0;False;0;False;0.3144608;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;113;-1556.85,-110.7092;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;127;-957.3438,-1280.079;Inherit;False;curU;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CustomExpressionNode;99;-1924.974,-541.1031;Inherit;False;return clamp((Input*tan(1.57*Slope) + Input + Offset*tan(1.57*Slope) - tan(1.57*Slope)), 0, 1)@;1;False;3;True;Input;FLOAT;0;In;;Inherit;False;True;Slope;FLOAT;0;In;;Inherit;False;True;Offset;FLOAT;0;In;;Inherit;False;Contrast;True;False;0;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CustomExpressionNode;123;-1389.932,-43.6339;Inherit;False;return Input * (1.0 + ( pow(Input-1.0, 4.0) * Attenuation ) - Attenuation)@;1;False;2;True;Input;FLOAT;0;In;;Inherit;False;True;Attenuation;FLOAT;0;In;;Inherit;False;Cubic Attenuation;True;False;0;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;131;-1438.146,-520.4774;Inherit;False;127;curU;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;105;-1712.706,-512.4838;Inherit;False;eq3;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;106;-1148.877,56.7457;Inherit;False;105;eq3;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;125;-1151.357,-89.65405;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;130;-1438.146,-429.5869;Inherit;False;86;curV;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;20;-1235.572,-515.224;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0.03125;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;111;-915.4839,-30.679;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;25;-1070.133,-453.4195;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;36;-740.9844,-66.72099;Inherit;False;COLOR;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;1;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;128;-755.5135,-661.4303;Inherit;False;127;curU;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;43;-900.0974,-514.8953;Inherit;True;Property;_TextureSample2;Texture Sample 2;0;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;gray;Auto;False;Instance;18;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ConditionalIfNode;21;-500.5497,-482.1663;Inherit;False;False;5;0;FLOAT;0;False;1;FLOAT;0.03125;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;4;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.CommentaryNode;196;-1318.251,-1044.96;Inherit;False;868.9702;357.092;Encode bands & delays data into alpha channel, 0-255;8;195;202;194;184;191;193;192;190;;1,1,1,1;0;0
Node;AmplifyShaderEditor.BreakToComponentsNode;182;-273.2939,-493.9202;Inherit;False;COLOR;1;0;COLOR;0,0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.OneMinusNode;194;-897.6984,-789.5706;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;183;56.74652,-465.028;Inherit;False;COLOR;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;188;-506.7386,-1192.133;Inherit;False;delays;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;193;-1062.169,-794.6527;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.00390625;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;195;-693.4248,-907.7753;Inherit;False;bandsNormalized;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;189;-714.6863,-1192.134;Inherit;False;Property;_Delays;Delays (Columns);2;0;Create;False;0;0;0;False;0;False;32;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;192;-1277.169,-794.6527;Inherit;False;188;delays;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;178;-432.38,-281.8013;Inherit;False;195;bandsNormalized;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;201;-434.205,-180.5404;Inherit;False;202;delaysNormalized;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;18;-1266.941,-1511.452;Inherit;True;Property;_RTARenderTexture;RTA Render Texture;0;0;Create;True;0;0;0;True;0;False;-1;None;None;True;0;False;gray;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;190;-1279.679,-894.9584;Inherit;False;176;bands;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;191;-1062.679,-905.9584;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.00390625;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;202;-693.3676,-802.0142;Inherit;False;delaysNormalized;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;184;-896.2079,-890.8766;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;199;-111.8637,-335.2644;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;200;-107.9955,-215.3533;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;35;245.4433,-488.1756;Float;False;True;-1;2;ASEMaterialInspector;0;3;AudioLink/AudioSpectrum;32120270d1b3a8746af2aca8bc749736;True;Custom RT Update;0;0;Custom RT Update;1;False;True;0;1;False;-1;0;False;-1;0;1;False;-1;0;False;-1;True;0;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;0;True;2;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;2;0;;0;0;Standard;0;0;1;True;False;;False;0
WireConnection;176;0;175;0
WireConnection;86;0;4;2
WireConnection;81;0;129;0
WireConnection;81;1;177;0
WireConnection;68;0;81;0
WireConnection;150;0;81;0
WireConnection;151;0;68;0
WireConnection;151;1;150;0
WireConnection;151;2;2;0
WireConnection;133;0;151;0
WireConnection;139;0;51;0
WireConnection;139;1;136;0
WireConnection;139;2;137;0
WireConnection;139;3;138;0
WireConnection;141;0;139;0
WireConnection;141;1;140;0
WireConnection;147;0;141;0
WireConnection;142;0;147;0
WireConnection;44;1;132;0
WireConnection;94;0;91;0
WireConnection;94;1;96;0
WireConnection;119;0;107;0
WireConnection;113;0;44;1
WireConnection;113;1;119;0
WireConnection;127;0;4;1
WireConnection;99;0;94;0
WireConnection;99;1;100;0
WireConnection;99;2;102;0
WireConnection;123;0;113;0
WireConnection;123;1;121;0
WireConnection;105;0;99;0
WireConnection;125;0;123;0
WireConnection;20;0;131;0
WireConnection;111;0;125;0
WireConnection;111;1;106;0
WireConnection;25;0;20;0
WireConnection;25;1;130;0
WireConnection;36;0;111;0
WireConnection;36;1;111;0
WireConnection;36;2;111;0
WireConnection;43;1;25;0
WireConnection;21;0;128;0
WireConnection;21;2;43;0
WireConnection;21;4;36;0
WireConnection;182;0;21;0
WireConnection;194;0;193;0
WireConnection;183;0;182;0
WireConnection;183;1;182;1
WireConnection;183;2;182;2
WireConnection;188;0;189;0
WireConnection;193;0;192;0
WireConnection;195;0;184;0
WireConnection;191;0;190;0
WireConnection;202;0;194;0
WireConnection;184;0;191;0
WireConnection;199;0;182;0
WireConnection;199;1;178;0
WireConnection;200;0;182;1
WireConnection;200;1;201;0
WireConnection;35;0;183;0
ASEEND*/
//CHKSM=DC0B67BA6B1D16B8AE6928A92BF2277223487B44