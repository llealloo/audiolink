#ifndef POI_RGBMASK
    #define POI_RGBMASK
    UNITY_DECLARE_TEX2D_NOSAMPLER(_RGBMask); float4 _RGBMask_ST;
    UNITY_DECLARE_TEX2D_NOSAMPLER(_RedTexure); float4 _RedTexure_ST;
    UNITY_DECLARE_TEX2D_NOSAMPLER(_GreenTexture); float4 _GreenTexture_ST;
    UNITY_DECLARE_TEX2D_NOSAMPLER(_BlueTexture); float4 _BlueTexture_ST;
    float4 _RedColor;
    float4 _GreenColor;
    float4 _BlueColor;
    float4 _RGBMaskPanning;
    float4 _RGBRedPanning;
    float4 _RGBGreenPanning;
    float4 _RGBBluePanning;
    float _RGBBlendMultiplicative;
    float _RGBMaskUV;
    float _RGBRed_UV;
    float _RGBGreen_UV;
    float _RGBBlue_UV;
    float _RGBUseVertexColors;
    float _RGBNormalBlend;
    static float3 rgbMask;
    void calculateRGBNormals(inout half3 mainTangentSpaceNormal)
    {
    }
    float3 calculateRGBMask(float3 baseColor)
    {
        #ifndef RGB_MASK_TEXTURE
            #define RGB_MASK_TEXTURE
            
            if (float(0))
            {
                rgbMask = poiMesh.vertexColor.rgb;
            }
            else
            {
                rgbMask = POI2D_SAMPLER_PAN(_RGBMask, _MainTex, poiMesh.uv[float(0)], float4(0,0,0,0)).rgb;
            }
        #endif
        float4 red = POI2D_SAMPLER_PAN2(_RedTexure, _MainTex, float(5), float4(0,0,0,0));
        float4 green = POI2D_SAMPLER_PAN(_GreenTexture, _MainTex, poiMesh.uv[float(0)], float4(0,0,0,0));
        float4 blue = POI2D_SAMPLER_PAN(_BlueTexture, _MainTex, poiMesh.uv[float(0)], float4(0,0,0,0));
        
        if(float(0))
        {
            float3 RGBColor = 1;
            RGBColor = lerp(RGBColor, red.rgb * float4(1,1,1,0.1098039).rgb, rgbMask.r * red.a * float4(1,1,1,0.1098039).a);
            RGBColor = lerp(RGBColor, green.rgb * float4(1,1,1,0).rgb, rgbMask.g * green.a * float4(1,1,1,0).a);
            RGBColor = lerp(RGBColor, blue.rgb * float4(1,1,1,0).rgb, rgbMask.b * blue.a * float4(1,1,1,0).a);
            baseColor *= RGBColor;
        }
        else
        {
            baseColor = lerp(baseColor, red.rgb * float4(1,1,1,0.1098039).rgb, rgbMask.r * red.a * float4(1,1,1,0.1098039).a);
            baseColor = lerp(baseColor, green.rgb * float4(1,1,1,0).rgb, rgbMask.g * green.a * float4(1,1,1,0).a);
            baseColor = lerp(baseColor, blue.rgb * float4(1,1,1,0).rgb, rgbMask.b * blue.a * float4(1,1,1,0).a);
        }
        return baseColor;
    }
#endif
