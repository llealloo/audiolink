
Shader "Custom/ControllableReveal"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
		_EmissionQty( "Emission Qty", float ) = 0.0
		_AllowRotation( "Allow Rotation", float ) = 0.0
		[HideInInspector] _InputBasisQuaternion( "_InputBasisQuaternion", Vector) = (0,0,0,1)
		[HideInInspector] _InputBasisVertex( "_InputBasisVertex", Vector) = (0,0,0,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

		#include "/Assets/AudioLink/Shaders/AudioLink.cginc"
		#include "/Assets/AudioLink/Shaders/SmoothPixelFont.cginc"

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
			float3 worldPos;
			float3 worldNormal;
        };

        half _Glossiness;
        half _Metallic;
		float _EmissionQty;
        fixed4 _Color;
		float3 _InputBasisVertex;
		float _AllowRotation;
		float4 _InputBasisQuaternion;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

		// Thanks, @axlecrusher for this gem.
		float3 vector_quat_rotate( float3 v, float4 q )
		{ 
			return v + 2.0 * cross(q.xyz, cross(q.xyz, v) + q.w * v);
		}

		float3 vector_quat_unrotate( float3 v, float4 q )
		{ 
			return v + 2.0 * cross(q.xyz, cross(q.xyz, v) - q.w * v);
		}


        void surf (Input IN, inout SurfaceOutputStandard o)
        {
			float4 c = float4( 0, 0, 0, 0);
			float3 gnorm = vector_quat_rotate( float3(-1, 0, 0 ), _InputBasisQuaternion );
			float3 gdirection = vector_quat_rotate( float3(0, 0, 1 ), _InputBasisQuaternion );
			float3 relpos = IN.worldPos-_InputBasisVertex;
			
			float denom = dot( IN.worldNormal, gdirection );
			float2 uvpoint = -1;
			float3 whpt = -10000;
			if( denom > .0001 )
			{
				float t = dot( relpos, IN.worldNormal ) / denom;
				whpt = _InputBasisVertex + gdirection * t;
				float3 local = whpt + float3( 7.61, -1, 12.73 );
				uvpoint = -local.xy/float2(3,1.5)+0.5;
				uvpoint.y = 1.-uvpoint.y;
			}
			
			float2 uvox = float2( ( uvpoint.x > 0.5 )?.16:-.01, ( uvpoint.y > 0.5 )?.16:.01 );
			float2 panuv = (IN.uv_MainTex - uvpoint + uvox ) * float2( 6.5, 7 );
			if( !any(abs(panuv-.5)>.5) && !any(abs(uvpoint-.5)>.5))
			{
				float4 AudioLinkValueAtCell = AudioLinkData( uvpoint * int2( 128,64 ) );
				float2 pos = panuv * float2(13,5);
				pos.y = 5.-pos.y;
				uint2 dig = (uint2)(pos);
				float2 fmxy = float2( 4, 6 ) - (glsl_mod(pos,1.)*float2(4.,6.));
				int xoffset = 3;
				int points_after_decimal = 3;
				int max_decimals = 4;
				int leadingzero = 0;
				float value = 0;
				const float2 dropshadow = float2(0.3,0.3);
				if( dig.x >= 10 )
				{
					if( dig.x <= 10 || dig.y >= 4 )
					{
						uint char = 'I';
						if( dig.y < 4 )
						{
							if( dig.y == 0 ) char = 'R';
							else if( dig.y == 1 ) char = 'G';
							else if( dig.y == 2 ) char = 'B';
							else char = 'A';
						}
						else
						{
							if( dig.x == 10 ) char = 'I';
							else if( dig.x == 11 ) char = 'n';
							else char = 't';
						}
					
						float pfv = PrintChar(char, fmxy, 10, 0);
						float pfv1 = PrintChar(char, fmxy+dropshadow, 10, 0);
						c.a = saturate(pfv*10+pfv1*10);
						c.rgb = (pfv)*10;
					}
					else
					{
						c.rgb = AudioLinkValueAtCell.rgb;
						c.a = 1;
					}
				}
				else
				{
					if( dig.y == 0 )
					{
						value = AudioLinkValueAtCell.r;
					}
					else if( dig.y == 1 )
					{
						value = AudioLinkValueAtCell.g;
					}
					else if( dig.y == 2 )
					{
						value = AudioLinkValueAtCell.b;
					}
					else if( dig.y == 3 )
					{
						value = AudioLinkValueAtCell.a;
					}
					if( dig.y == 4 )
					{
						uint aval = AudioLinkDecodeDataAsUInt( uvpoint * int2( 128,64 ) );
						if( dig.x >= 5 )
						{
							points_after_decimal = 7;
							max_decimals = 0;
							value = aval%100000;
							leadingzero = aval>100000;
						}
						else
						{
							points_after_decimal = 2;
							max_decimals = 0;
							value = aval/100000;
							if( value == 0 ) points_after_decimal = 3; // Hide digit if too small.
						}
					}
					float pfv = PrintNumberOnLine( value, fmxy, 1, dig.x - xoffset, points_after_decimal, max_decimals, leadingzero, 0 );

					float pfv1 = PrintNumberOnLine( value, fmxy+dropshadow, 1, dig.x - xoffset, points_after_decimal, max_decimals, leadingzero, 0 );
					c.a = saturate(pfv*10+pfv1*10);
					c.rgb = (pfv)*10;
				}
			}
			
			if( length( (IN.uv_MainTex - uvpoint) * float2( 1, .5 ) ) < .002 )
			{
				c.a += 1;
				c.rgb += (1.4-length( (IN.uv_MainTex - uvpoint) * float2( 1, .5 ) )*1000)*5;
			}
			else
			{
				c.rgb = lerp( tex2D (_MainTex, IN.uv_MainTex) * _Color, c.rgb, c.a );
				float opacity_rotate = saturate(dot( relpos, gnorm )*6+.2); // Allow rotation
				float opacity_straightup = saturate((IN.uv_MainTex.x - uvpoint.x)*19);
				float opacity = lerp( opacity_straightup, opacity_rotate, _AllowRotation );
				c.a = saturate(opacity + c.a);
			}
			
			c.rgb = lerp( AudioLinkData( IN.uv_MainTex * int2( 128,64 ) ).rgb, c.rgb, c.a );

            o.Albedo = c.rgb;
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
			o.Emission = c.rgb * _EmissionQty;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
