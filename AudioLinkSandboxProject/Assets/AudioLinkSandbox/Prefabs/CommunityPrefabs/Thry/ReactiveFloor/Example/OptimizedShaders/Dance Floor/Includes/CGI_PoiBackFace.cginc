#ifndef POI_BACKFACE
    #define POI_BACKFACE
    float _BackFaceEnabled;
    float _BackFaceTextureUV;
    float _BackFaceDetailIntensity;
    float _BackFaceEmissionStrength;
    float2 _BackFacePanning;
    float _BackFaceHueShift;
    float4 _BackFaceColor;
    UNITY_DECLARE_TEX2D_NOSAMPLER(_BackFaceTexture); float4 _BackFaceTexture_ST;
    float3 BackFaceColor;
    void applyBackFaceTexture(inout float backFaceDetailIntensity, inout float mixedHueShift, inout float4 albedo, inout float3 backFaceEmission)
    {
        backFaceEmission = 0;
        BackFaceColor = 0;
        
        if (float(0))
        {
            if(!poiMesh.isFrontFace)
            {
                albedo = POI2D_SAMPLER_PAN(_BackFaceTexture, _MainTex, poiMesh.uv[float(0)], float4(0,0,0,0)) * float4(1,1,1,1);
                backFaceDetailIntensity = float(1);
                BackFaceColor = albedo.rgb;
                mixedHueShift = float(0);
                backFaceEmission = BackFaceColor * float(0);
            }
        }
    }
#endif
