#ifndef POI_RGBMASK
    #define POI_RGBMASK
    
    UNITY_DECLARE_TEX2D_NOSAMPLER(_RGBMask); float4 _RGBMask_ST;
    UNITY_DECLARE_TEX2D_NOSAMPLER(_RedTexure); float4 _RedTexure_ST;
    UNITY_DECLARE_TEX2D_NOSAMPLER(_GreenTexture); float4 _GreenTexture_ST;
    UNITY_DECLARE_TEX2D_NOSAMPLER(_BlueTexture); float4 _BlueTexture_ST;
    
    #ifdef GEOM_TYPE_MESH
        POI_NORMAL_NOSAMPLER(_RgbNormalR);
        POI_NORMAL_NOSAMPLER(_RgbNormalG);
        POI_NORMAL_NOSAMPLER(_RgbNormalB);
        float _RgbNormalsEnabled;
    #endif
    
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
        #ifdef GEOM_TYPE_MESH
            #ifndef RGB_MASK_TEXTURE
                #define RGB_MASK_TEXTURE
                UNITY_BRANCH
                if (_RGBUseVertexColors)
                {
                    rgbMask = poiMesh.vertexColor.rgb;
                }
                else
                {
                    rgbMask = POI2D_SAMPLER_PAN(_RGBMask, _MainTex, poiMesh.uv[_RGBMaskUV], _RGBMaskPanning).rgb;
                }
            #endif
            
            UNITY_BRANCH
            if(_RgbNormalsEnabled)
            {
                UNITY_BRANCH
                if(_RGBNormalBlend == 0)
                {
                    UNITY_BRANCH
                    if(_RgbNormalRScale > 0)
                    {
                        half3 normalToBlendWith = UnpackScaleNormal(POI2D_SAMPLER_PAN2(_RgbNormalR, _MainTex, _RgbNormalRUV, _RgbNormalRPan), _RgbNormalRScale);
                        mainTangentSpaceNormal = lerp(mainTangentSpaceNormal, normalToBlendWith, rgbMask.r);
                    }
                    UNITY_BRANCH
                    if(_RgbNormalGScale > 0)
                    {
                        half3 normalToBlendWith = UnpackScaleNormal(POI2D_SAMPLER_PAN(_RgbNormalG, _MainTex, poiMesh.uv[_RgbNormalGUV], _RgbNormalGPan), _RgbNormalGScale);
                        mainTangentSpaceNormal = lerp(mainTangentSpaceNormal, normalToBlendWith, rgbMask.g);
                    }
                    UNITY_BRANCH
                    if(_RgbNormalBScale > 0)
                    {
                        half3 normalToBlendWith = UnpackScaleNormal(POI2D_SAMPLER_PAN(_RgbNormalB, _MainTex, poiMesh.uv[_RgbNormalBUV], _RgbNormalBPan), _RgbNormalBScale);
                        mainTangentSpaceNormal = lerp(mainTangentSpaceNormal, normalToBlendWith, rgbMask.b);
                    }
                    return;
                }
                else
                {
                    half3 newNormal = UnpackScaleNormal(POI2D_SAMPLER_PAN(_RgbNormalR, _MainTex, poiMesh.uv[_RgbNormalRUV], _RgbNormalRPan), _RgbNormalRScale * rgbMask.r);
                    half3 normalToBlendWith = UnpackScaleNormal(POI2D_SAMPLER_PAN(_RgbNormalG, _MainTex, poiMesh.uv[_RgbNormalGUV], _RgbNormalGPan), _RgbNormalGScale);
                    newNormal = lerp(newNormal, normalToBlendWith, rgbMask.g);
                    normalToBlendWith = UnpackScaleNormal(POI2D_SAMPLER_PAN(_RgbNormalB, _MainTex, poiMesh.uv[_RgbNormalBUV], _RgbNormalBPan), _RgbNormalBScale);
                    newNormal = lerp(newNormal, normalToBlendWith, rgbMask.b);
                    mainTangentSpaceNormal = BlendNormals(newNormal, mainTangentSpaceNormal);
                    return;
                }
            }
        #endif
    }
    
    float3 calculateRGBMask(float3 baseColor)
    {
        //If RGB normals are in use this data will already exist
        #ifndef RGB_MASK_TEXTURE
            #define RGB_MASK_TEXTURE
            UNITY_BRANCH
            if (_RGBUseVertexColors)
            {
                rgbMask = poiMesh.vertexColor.rgb;
            }
            else
            {
                rgbMask = POI2D_SAMPLER_PAN(_RGBMask, _MainTex, poiMesh.uv[_RGBMaskUV], _RGBMaskPanning).rgb;
            }
        #endif
        
        float4 red = POI2D_SAMPLER_PAN2(_RedTexure, _MainTex, _RGBRed_UV, _RGBRedPanning);
        float4 green = POI2D_SAMPLER_PAN(_GreenTexture, _MainTex, poiMesh.uv[_RGBGreen_UV], _RGBGreenPanning);
        float4 blue = POI2D_SAMPLER_PAN(_BlueTexture, _MainTex, poiMesh.uv[_RGBBlue_UV], _RGBBluePanning);
        
        UNITY_BRANCH
        if(_RGBBlendMultiplicative)
        {
            float3 RGBColor = 1;
            RGBColor = lerp(RGBColor, red.rgb * _RedColor.rgb, rgbMask.r * red.a * _RedColor.a);
            RGBColor = lerp(RGBColor, green.rgb * _GreenColor.rgb, rgbMask.g * green.a * _GreenColor.a);
            RGBColor = lerp(RGBColor, blue.rgb * _BlueColor.rgb, rgbMask.b * blue.a * _BlueColor.a);
            baseColor *= RGBColor;
        }
        else
        {
            baseColor = lerp(baseColor, red.rgb * _RedColor.rgb, rgbMask.r * red.a * _RedColor.a);
            baseColor = lerp(baseColor, green.rgb * _GreenColor.rgb, rgbMask.g * green.a * _GreenColor.a);
            baseColor = lerp(baseColor, blue.rgb * _BlueColor.rgb, rgbMask.b * blue.a * _BlueColor.a);
        }
        
        return baseColor;
    }
    
#endif