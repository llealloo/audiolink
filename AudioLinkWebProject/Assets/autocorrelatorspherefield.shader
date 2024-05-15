Shader "autocorrelatorspherefield"
{
	SubShader
	{
		Pass
		{
			ZTest Always
			ZWrite Off
			Cull Off

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"
			#include "Packages/com.llealloo.audiolink/Runtime/Shaders/AudioLink.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float4 posWorld : TEXCOORD0;
				float4 grabPos : TEXCOORD1;
				float3 ray : TEXCOORD2;
			};

			struct fragOut
			{
				float4 color : SV_Target;
				// float depth : SV_Depth;
			};

			sampler2D_float _CameraDepthTexture;
			float4 _CameraDepthTexture_TexelSize;


float4x4 inverse(float4x4 input)
{
	#define minor(a,b,c) determinant(float3x3(input.a, input.b, input.c))
	//determinant(float3x3(input._22_23_23, input._32_33_34, input._42_43_44))

	const float4x4 cofactors = float4x4(
		minor(_22_23_24, _32_33_34, _42_43_44),
		-minor(_21_23_24, _31_33_34, _41_43_44),
		minor(_21_22_24, _31_32_34, _41_42_44),
		-minor(_21_22_23, _31_32_33, _41_42_43),

		-minor(_12_13_14, _32_33_34, _42_43_44),
		minor(_11_13_14, _31_33_34, _41_43_44),
		-minor(_11_12_14, _31_32_34, _41_42_44),
		minor(_11_12_13, _31_32_33, _41_42_43),

		minor(_12_13_14, _22_23_24, _42_43_44),
		-minor(_11_13_14, _21_23_24, _41_43_44),
		minor(_11_12_14, _21_22_24, _41_42_44),
		-minor(_11_12_13, _21_22_23, _41_42_43),

		-minor(_12_13_14, _22_23_24, _32_33_34),
		minor(_11_13_14, _21_23_24, _31_33_34),
		-minor(_11_12_14, _21_22_24, _31_32_34),
		minor(_11_12_13, _21_22_23, _31_32_33)
	);
	#undef minor
	return transpose(cofactors) / determinant(input);
}

float4x4 clipToWorldMatrix()
{
	return inverse(UNITY_MATRIX_VP);
}


float2x2 rot(float angle)
{
	return float2x2(cos(angle), -sin(angle), sin(angle), cos(angle));
}

			v2f vert(appdata v)
			{
				v2f o;
				// o.pos = float4(float2(1, -1) * (v.uv * 2 - 1), 0, 1);
				o.pos = UnityObjectToClipPos(v.vertex);
				float4 objectspace = mul(clipToWorldMatrix(), o.pos);
				objectspace = mul(unity_WorldToObject, objectspace);


				o.posWorld = mul(unity_ObjectToWorld, objectspace);
				o.grabPos = ComputeScreenPos(o.pos);


				o.ray = mul(UNITY_MATRIX_MV, objectspace).xyz * float3(-1, -1, 1);
				return o;
			}


			struct raymarchout
			{
				float3 vpOrig;
				float3 vpXform;
				float corrmax;
				float4 vertex;
				float4 color;
				float clipDepth;
			};

			float signedDistanceField(float3 pos, inout raymarchout o)
			{
				pos += 100;
				#define SPHERE_RADIUS 0.3
				#define SPHERE_REPETITION 2
				pos = fmod(pos, SPHERE_REPETITION) - 0.5 * SPHERE_REPETITION;
				pos.yz = mul(rot(0.5 * UNITY_PI), pos.yz);
				float3 vp = pos;
				o.vpOrig = vp;
				float phi = atan2(vp.x + 0.001, vp.z) / 3.14159;
				float placeinautocorrelator = abs(phi);
				float autocorrvalue = AudioLinkLerp(ALPASS_AUTOCORRELATOR +
					float2(placeinautocorrelator * AUDIOLINK_WIDTH, 0.)).r;
				autocorrvalue = autocorrvalue * (.5 - abs(vp.y)) * 0.4 + .6;
				vp *= autocorrvalue;


				o.vpXform = vp;

				return length(vp) - SPHERE_RADIUS;
			}

			void raymarch(float3 rayStart, float3 rayDir, out raymarchout o)
			{
				o = (raymarchout)0;
				o.color = float4(0, 0, 0, 0);
				int maxSteps = 40;
				float minDistance = 0.001;
				float3 currentPos = rayStart;


				for (int i = 0; i < maxSteps; i++)
				{
					float distance = signedDistanceField(currentPos, o);
					currentPos += rayDir * distance;
					if (distance < minDistance)
					{
						o.color = float4((maxSteps - i) * 0.025, (maxSteps - i) * 0.025, (maxSteps - i) * 0.025, 1);
						break;
					}
				}
				o.vertex = UnityObjectToClipPos(float4(currentPos, 1.0));


				o.clipDepth = o.vertex.z / o.vertex.w;
			}

			#define NONE_ITEM_EPS 0.99

			fragOut frag(v2f i)
			{
				float rawDepth = DecodeFloatRG(tex2Dproj(_CameraDepthTexture, i.grabPos).xy);
				float linearDepth = Linear01Depth(rawDepth);
				i.ray = i.ray * (_ProjectionParams.z / i.ray.z);
				float4 vpos = float4(i.ray * linearDepth, 1);
				float3 wpos = mul(unity_CameraToWorld, vpos).xyz;

				float3 rayStart = wpos.xyz;;
				float3 rayDir = normalize(rayStart - _WorldSpaceCameraPos);


				raymarchout raymarchData = (raymarchout)0;
				raymarch(rayStart, rayDir, raymarchData);

				raymarchData.corrmax = AudioLinkLerp(ALPASS_AUTOCORRELATOR) * 0.2 + .6;

				float ccplace = length(raymarchData.vpXform.xz) * 2. / raymarchData.corrmax;

				float4 colorchordcolor = AudioLinkData(ALPASS_CCSTRIP +
					float2( AUDIOLINK_WIDTH * ccplace, 0. )) + 0.01;

				colorchordcolor *= length(raymarchData.vpXform.xyz) * 15. - 2.0;

				raymarchData.color *= colorchordcolor;

				fragOut f;
				// f.depth = raymarchData.clipDepth;
				f.color = saturate(raymarchData.color);


				return f;
			}
			ENDCG
		}
	}
}
