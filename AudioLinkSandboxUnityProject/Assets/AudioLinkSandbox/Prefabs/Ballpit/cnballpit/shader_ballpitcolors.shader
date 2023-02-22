Shader "cnballpit/ballpitcolors"
{
	Properties
	{
		_VideoTexture("Video", 2D) = "white" {}
		_PositionsIn("Positions In", 2D) = "black" {}
		_ShouldUpdate( "Should Update", float ) = 1
		_IsAVProInput("IsAVProInput", float) = 0
	}

	SubShader
	{
		Lighting Off
		Blend One Zero

		Pass
		{
			CGPROGRAM
			#include "UnityCustomRenderTexture.cginc"
			#include "cnballpit.cginc"

			#pragma vertex CustomRenderTextureVertexShader
			#pragma fragment frag
			#pragma target 3.0

			sampler2D   _VideoTexture;

			float _ShouldUpdate;
			float _IsAVProInput;
			
			//Currently, not doing anything with _IsAVProInput.  Potentially handle flip/inversion.

			float4 frag(v2f_customrendertexture IN) : COLOR
			{
				clip( _ShouldUpdate < 0.5 ? -1 : 1 );
				int ballid = IN.localTexcoord.x * _PositionsIn_TexelSize.z + ((uint)( IN.localTexcoord.y * _PositionsIn_TexelSize.w )) * _PositionsIn_TexelSize.z;
				float4 DataPos = GetPosition(ballid);
				float3 PositionRelativeToCenterOfBallpit = DataPos;
				float2 uvpit = saturate( PositionRelativeToCenterOfBallpit.xz * float2( 0.05, 0.08 )*.95 + 0.5 );
				return tex2D(_VideoTexture, uvpit);
			}
			ENDCG
		}
	}
}