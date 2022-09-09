#ifndef POI_BLENDING
    #define POI_BLENDING
    float4 poiBlend(const float sourceFactor, const  float4 sourceColor, const  float destinationFactor, const  float4 destinationColor, const float4 blendFactor)
    {
        float4 sA = 1-blendFactor;
        const float4 blendData[11] = {
            float4(0.0, 0.0, 0.0, 0.0),
            float4(1.0, 1.0, 1.0, 1.0),
            destinationColor,
            sourceColor,
            float4(1.0, 1.0, 1.0, 1.0) - destinationColor,
            sA,
            float4(1.0, 1.0, 1.0, 1.0) - sourceColor,
            sA,
            float4(1.0, 1.0, 1.0, 1.0) - sA,
            saturate(sourceColor.aaaa),
            1 - sA,
        };
        return lerp(blendData[sourceFactor] * sourceColor + blendData[destinationFactor] * destinationColor,sourceColor, sA);
    }
#endif
