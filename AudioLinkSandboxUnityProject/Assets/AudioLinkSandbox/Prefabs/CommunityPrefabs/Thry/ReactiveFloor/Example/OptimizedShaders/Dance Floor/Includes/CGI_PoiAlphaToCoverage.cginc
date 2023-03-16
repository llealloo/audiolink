#ifndef POI_ALPHA_TO_COVERAGE
    #define POI_ALPHA_TO_COVERAGE
    half _MainMipScale;
    float _MainAlphaToCoverage;
    float CalcMipLevel(float2 texture_coord)
    {
        float2 dx = ddx(texture_coord);
        float2 dy = ddy(texture_coord);
        float delta_max_sqr = max(dot(dx, dx), dot(dy, dy));
        return 0.5 * log2(delta_max_sqr);
    }
    void ApplyAlphaToCoverage(inout float4 finalColor)
    {
        
        if (float(0) == 1)
        {
            
            if(float(0))
            {
                finalColor.a *= 1 + max(0, CalcMipLevel(poiMesh.uv[0] * float4(1,1,1,1).zw)) * float(0.25);
                finalColor.a = (finalColor.a - float(0.5)) / max(fwidth(finalColor.a), 0.0001) + float(0.5);
            }
        }
    }
#endif
