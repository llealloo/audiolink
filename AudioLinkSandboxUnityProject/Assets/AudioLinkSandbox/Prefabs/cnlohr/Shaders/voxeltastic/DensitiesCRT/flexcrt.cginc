/*
	CNLohr's "compute" CRT Header.  For doing comput-y stuff with CRTs.

	Noted differences:
	 * Switched to Texture <float4> for textures.
	 * Removed all rotation functionality.
	 * Removed 3D Texture functionality (Original implementation was bad.  Trust me.)
*/

#ifndef FLEXCRT_INCLUDED
#define FLEXCRT_INCLUDED

#ifdef DATA_FROM_UNITY_CUSTOM_TEXTURE_INCLUDED
#error Error: Cannot include both the unity custom render texture system and FLEXCRT.
#endif

#include "UnityCG.cginc"
#include "UnityStandardConfig.cginc"

// Keep in sync with CustomRenderTexture.h
#define kCustomTextureBatchSize 16

struct appdata_customrendertexture
{
	uint	vertexID	: SV_VertexID;
};

// User facing vertex to fragment shader structure
struct v2f_customrendertexture
{
	float4 vertex		   : SV_POSITION;
	float2 localTexcoord	: TEXCOORD0;	// Texcoord local to the update zone (== globalTexcoord if no partial update zone is specified)
	float2 globalTexcoord   : TEXCOORD1;	// Texcoord relative to the complete custom texture
	uint primitiveID		: TEXCOORD2;	// Index of the update zone (correspond to the index in the updateZones of the Custom Texture)
};

// Internal
float4	  CustomRenderTextureCenters[kCustomTextureBatchSize];
float4	  CustomRenderTextureSizesAndRotations[kCustomTextureBatchSize];
float	   CustomRenderTexturePrimitiveIDs[kCustomTextureBatchSize];

float4	  CustomRenderTextureParameters;
#define	 CustomRenderTextureUpdateSpace  CustomRenderTextureParameters.x // Normalized(0)/PixelSpace(1)

// User facing uniform variables
float4	  _CustomRenderTextureInfo; // x = width, y = height, z = depth, w = face/3DSlice

#define FlexCRTSize (_CustomRenderTextureInfo.xy)

// Helpers
#define _CustomRenderTextureWidth   _CustomRenderTextureInfo.x
#define _CustomRenderTextureHeight  _CustomRenderTextureInfo.y

#ifndef CRTTEXTURETYPE
#define CRTTEXTURETYPE uint4
#endif

Texture2D<CRTTEXTURETYPE>	_SelfTexture2D;
float4 _SelfTexture2D_TexelSize;

// standard custom texture vertex shader that should always be used
v2f_customrendertexture DefaultCustomRenderTextureVertexShader(appdata_customrendertexture IN)
{
	v2f_customrendertexture OUT;

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

	// Compute quad vertex position
	float2 clipSpaceCenter = updateZoneCenter.xy * 2.0 - 1.0;
	float2 pos = vertexPositions[vertexID] * updateZoneSize.xy;

	pos.x += clipSpaceCenter.x;
#if UNITY_UV_STARTS_AT_TOP
	pos.y += clipSpaceCenter.y;
#else
	pos.y -= clipSpaceCenter.y;
#endif

	OUT.vertex = float4(pos, 0.0, 1.0);
	OUT.primitiveID = asuint(CustomRenderTexturePrimitiveIDs[primitiveID]);
	OUT.localTexcoord = float2(texCoords[vertexID]);
	OUT.globalTexcoord = float2(pos.xy * 0.5 + 0.5);
#if UNITY_UV_STARTS_AT_TOP
	OUT.globalTexcoord.y = 1.0 - OUT.globalTexcoord.y;
#endif

	return OUT;
}

struct appdata_init_customrendertexture
{
	float4 vertex : POSITION;
	float2 texcoord : TEXCOORD0;
};

// User facing vertex to fragment structure for initialization materials
struct v2f_init_customrendertexture
{
	float4 vertex : SV_POSITION;
	float2 texcoord : TEXCOORD0;
};

// standard custom texture vertex shader that should always be used for initialization shaders
v2f_init_customrendertexture DefaultInitCustomRenderTextureVertexShader (appdata_init_customrendertexture v)
{
	v2f_init_customrendertexture o;
	o.vertex = UnityObjectToClipPos(v.vertex);
	o.texcoord = float2(v.texcoord.xy);
	return o;
}

float4 FlexCRTCoordinateOut( uint2 coordOut )
{
	return float4((coordOut.xy*2-FlexCRTSize+1)/FlexCRTSize, 0.5, 1 );
}

#endif
