#ifndef POI_MAINTEXTURE
    #define POI_MAINTEXTURE
    
    
    
    POI_TEXTURE_NOSAMPLER(_AlphaMask);
    POI_TEXTURE_NOSAMPLER(_MainFadeTexture);
    float4 _Color;
    float _MainVertexColoring;
    float _MainUseVertexColorAlpha;
    float _Saturation;
    float2 _MainDistanceFade;
    half _MainMinAlpha;
    float _MainHueShift;
    #ifdef COLOR_GRADING_HDR
        POI_TEXTURE_NOSAMPLER(_MainHueShiftMask);
        float _MainHueShiftToggle;
        float _MainHueShiftSpeed;
        float _MainHueShiftReplace;
    #endif
    
    #ifdef FINALPASS
        POI_TEXTURE_NOSAMPLER(_DetailTex);
        half _DetailTexIntensity;
        half3 _DetailTint;
        float _DetailBrightness;
    #endif
    //globals
    float alphaMask;
    half3 diffColor;
    
    #include "CGI_PoiBackFace.cginc"
    
    float3 wireframeEmission;
    
    inline FragmentCommonData SpecularSetup(float4 i_tex, inout float4 albedo)
    {
        half4 specGloss = 0;
        half3 specColor = specGloss.rgb;
        half smoothness = specGloss.a;
        
        half oneMinusReflectivity;
        diffColor = EnergyConservationBetweenDiffuseAndSpecular(albedo, specColor, /*out*/ oneMinusReflectivity);
        
        FragmentCommonData o = (FragmentCommonData)0;
        o.diffColor = diffColor;
        o.specColor = specColor;
        o.oneMinusReflectivity = oneMinusReflectivity;
        o.smoothness = smoothness;
        return o;
    }
    
    inline FragmentCommonData FragmentSetup(float4 i_tex, half3 i_viewDirForParallax, float3 i_posWorld, inout float4 albedo)
    {
        i_tex = i_tex;
        
        FragmentCommonData o = SpecularSetup(i_tex, albedo);
        o.normalWorld = float4(0, 0, 0, 1);
        o.eyeVec = poiCam.viewDir;
        o.posWorld = i_posWorld;
        
        // NOTE: shader relies on pre-multiply alpha-blend (_SrcBlend = One, _DstBlend = OneMinusSrcAlpha)
        o.diffColor = PreMultiplyAlpha(o.diffColor, 1, o.oneMinusReflectivity, /*out*/ o.alpha);
        return o;
    }
    
    void initTextureData(inout float4 albedo, inout float4 mainTexture, inout float3 backFaceEmission, inout float3 dissolveEmission, in half3 detailMask)
    {
        dissolveEmission = 0;
        
        #if (defined(FORWARD_BASE_PASS) || defined(FORWARD_ADD_PASS))
            #ifdef POI_MIRROR
                applyMirrorTexture(mainTexture);
            #endif
        #endif
        
        alphaMask = POI2D_SAMPLER_PAN(_AlphaMask, _MainTex, poiMesh.uv[_AlphaMaskUV], _AlphaMaskPan);
        
        mainTexture.a *= alphaMask;
        
        #ifndef POI_SHADOW
            albedo = float4(lerp(mainTexture.rgb, dot(mainTexture.rgb, float3(0.3, 0.59, 0.11)), -_Saturation) * max(_Color.rgb, float3(0.000000001, 0.000000001, 0.000000001)) * lerp(1, GammaToLinearSpace(poiMesh.vertexColor.rgb), _MainVertexColoring), mainTexture.a * max(_Color.a, 0.0000001));
            
            #ifdef POI_LIGHTING
                applyShadowTexture(albedo);
            #endif
            
            albedo *= lerp(1, poiMesh.vertexColor.a, _MainUseVertexColorAlpha);
            #ifdef POI_RGBMASK
                albedo.rgb = calculateRGBMask(albedo.rgb);
            #endif
            
            albedo.a = saturate(_AlphaMod + albedo.a);
            
            wireframeEmission = 0;
            #ifdef POI_WIREFRAME
                applyWireframe(wireframeEmission, albedo);
            #endif
            float backFaceDetailIntensity = 1;
            
            float mixedHueShift = _MainHueShift;
            applyBackFaceTexture(backFaceDetailIntensity, mixedHueShift, albedo, backFaceEmission);
            
            #ifdef POI_FUR
                calculateFur();
            #endif
            
            #ifdef COLOR_GRADING_HDR
                float hueShiftAlpha = POI2D_SAMPLER_PAN(_MainHueShiftMask, _MainTex, poiMesh.uv[_MainHueShiftMaskUV], _MainHueShiftMaskPan).r;
                
                if(_MainHueShiftReplace)
                {
                    albedo.rgb = lerp(albedo.rgb, hueShift(albedo.rgb, mixedHueShift + _MainHueShiftSpeed * _Time.x), hueShiftAlpha);
                }
                else
                {
                    albedo.rgb = hueShift(albedo.rgb, frac((mixedHueShift - (1 - hueShiftAlpha) + _MainHueShiftSpeed * _Time.x)));
                }
            #endif
            #ifdef FINALPASS
                half3 detailTexture = POI2D_SAMPLER_PAN(_DetailTex, _MainTex, poiMesh.uv[_DetailTexUV], _DetailTexPan).rgb * _DetailTint.rgb;
                albedo.rgb *= LerpWhiteTo(detailTexture * _DetailBrightness * unity_ColorSpaceDouble.rgb, detailMask.r * _DetailTexIntensity * backFaceDetailIntensity);
            #endif
            albedo.rgb = saturate(albedo.rgb);
            
            #ifdef POI_HOLOGRAM
                ApplyHoloAlpha(albedo);
            #endif
            
            s = FragmentSetup(float4(poiMesh.uv[0], 1, 1), poiCam.viewDir, poiMesh.worldPos, albedo);
        #endif
        
        #ifdef DISTORT
            calculateDissolve(albedo, dissolveEmission);
        #endif
    }
    
    void distanceFade(inout float4 albedo)
    {
        half fadeMap = POI2D_SAMPLER_PAN(_MainFadeTexture, _MainTex, poiMesh.uv[_MainFadeTextureUV], _MainFadeTexturePan);
        if(fadeMap)
        {
            half fadeValue = max(smoothstep(_MainDistanceFade.x, _MainDistanceFade.y, poiCam.distanceToVert), _MainMinAlpha);
            albedo.a *= fadeValue;
        }
    }
#endif