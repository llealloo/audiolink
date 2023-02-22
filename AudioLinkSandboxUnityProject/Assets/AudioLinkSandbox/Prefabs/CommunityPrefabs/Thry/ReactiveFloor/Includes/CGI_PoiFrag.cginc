#ifndef POIFRAG
// Upgrade NOTE: excluded shader from DX11, OpenGL ES 2.0 because it uses unsized arrays
#pragma exclude_renderers d3d11 gles
    #define POIFRAG
    
    float _MainEmissionStrength;
    float _IgnoreFog;
    half _GIEmissionMultiplier;
    float _IridescenceTime;
    float _AlphaToMask;
    float _ForceOpaque;
    float _commentIfZero_EnableGrabpass;
    float _AlphaPremultiply;
    float2 _MainTexPan;
    float _MainTextureUV;
    float _commentIfZero_LightingAdditiveEnable;
    
    float4 frag(v2f i, uint facing: SV_IsFrontFace): SV_Target
    {
        #ifdef FORWARD_ADD_PASS
            #if !defined(POI_LIGHTING)
                return 0;
            #endif
            #if defined(_SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A) && defined(DIRECTIONAL)
                return 0;
            #endif
        #endif
        #ifdef FORWARD_ADD_PASS
            UNITY_BRANCH
            if (_commentIfZero_LightingAdditiveEnable == 0)
            {
                return 0;
            }
        #endif
        UNITY_SETUP_INSTANCE_ID(i);
        // Color
        float4 albedo = 1;
        float4 finalColor = 1;
        
        // Lighting
        float bakedCubemap = 0; // Whether or not metallic should run before or after lighting multiplication
        float3 finalSpecular0 = 0;
        float3 finalSpecular1 = 0;
        float3 finalSSS = 0;
        fixed lightingAlpha = 1;
        float3 finalEnvironmentalRim = 0;
        
        // Emissions
        float3 finalEmission = 0;
        float3 finalLighting = 1;
        float3 IridescenceEmission = 0;
        float3 spawnInEmission = 0;
        float3 voronoiEmission = 0;
        float3 matcapEmission = 0;
        float3 depthTouchEmission = 0;
        float3 decalEmission = 0;
        float3 glitterEmission = 0;
        float3 panosphereEmission = 0;
        float3 backFaceEmission = 0;
        float3 dissolveEmission = 0;
        float3 rimLightEmission = 0;
        float3 flipbookEmission = 0;
        float3 textOverlayEmission = 0;
        float3 videoEmission = 0;
        /**********************************************************************
        Initialize the base data that's needed everywhere else in the shader
        **********************************************************************/
        calculateAttenuation(i);
        InitializeMeshData(i, facing);
        initializeCamera(i);
        calculateTangentData();
        
        
        #ifdef POI_BLACKLIGHT
            createBlackLightMask();
            UNITY_BRANCH
            if (_BlackLightMaskDebug)
            {
                return float4(blackLightMask.rgb, 1);
            }
        #endif
        
        // This has to happen in the initializbecause it alters UV data globally
        #ifdef POI_PARALLAX
            calculateandApplyParallax();
        #endif
        
        // Basically every texture relies on the maintex sampler to function and that's why this is here.
        float4 mainTexture = UNITY_SAMPLE_TEX2D(_MainTex, TRANSFORM_TEX(poiMesh.uv[_MainTextureUV], _MainTex) + _Time.x * _MainTexPan);
        half3 detailMask = 1;
        calculateNormals(detailMask);
        calculateVertexLightingData(i);
        /**********************************************************************
        Calculate Light Maps
        **********************************************************************/
        #ifdef POI_DATA
            calculateLightingData(i);
        #endif
        #ifdef POI_LIGHTING
            calculateBasePassLightMaps();
        #endif
        
        /**********************************************************************
        Calculate Color Data
        **********************************************************************/
        
        initTextureData(albedo, mainTexture, backFaceEmission, dissolveEmission, detailMask);
        
        #ifdef POI_DECAL
            applyDecal(albedo, decalEmission);
        #endif
        
        
        #ifdef POI_IRIDESCENCE
            UNITY_BRANCH
            if (_IridescenceTime == 0)
            {
                applyIridescence(albedo, IridescenceEmission);
            }
        #endif
        
        #ifdef POI_VORONOI
            applyVoronoi(albedo, voronoiEmission);
        #endif
        
        #ifdef POI_MSDF
            ApplyTextOverlayColor(albedo, textOverlayEmission);
        #endif
        
        #ifdef POI_ENVIRONMENTAL_RIM
            finalEnvironmentalRim = calculateEnvironmentalRimLighting(albedo);
        #endif
        
        #if defined(POI_METAL) || defined(POI_CLEARCOAT)
            CalculateReflectionData();
        #endif
        
        #ifdef POI_DATA
            distanceFade(albedo);
        #endif
        
        #ifdef POI_RANDOM
            albedo.a *= i.angleAlpha;
        #endif
        
        #ifdef MATCAP
            applyMatcap(albedo, matcapEmission);
        #endif
        
        #ifdef PANOSPHERE
            applyPanosphereColor(albedo, panosphereEmission);
        #endif
        
        #ifdef POI_FLIPBOOK
            applyFlipbook(albedo, flipbookEmission);
        #endif
        
        #ifdef POI_GLITTER
            applyGlitter(albedo, glitterEmission);
        #endif
        
        #ifdef POI_RIM
            applyRimLighting(albedo, rimLightEmission);
        #endif
        
        #ifdef POI_DEPTH_COLOR
            applyDepthColor(albedo, depthTouchEmission, finalEmission, i.worldDirection);
        #endif
        
        #ifdef POI_IRIDESCENCE
            UNITY_BRANCH
            if(_IridescenceTime == 1)
            {
                applyIridescence(albedo, IridescenceEmission);
            }
        #endif
        
        #ifdef POI_VIDEO
            applyScreenEffect(albedo, videoEmission);
        #endif
        
        applySpawnIn(albedo, spawnInEmission, poiMesh.uv[0], poiMesh.localPos);
        
        /**********************************************************************
        Handle a few alpha options
        **********************************************************************/
        UNITY_BRANCH
        if (_Mode == 1)
        {
            UNITY_BRANCH
            if(_AlphaToMask == 0)
            {
                applyDithering(albedo);
            }
        }
        
        albedo.a = max(_ForceOpaque, albedo.a);
        
        UNITY_BRANCH
        if(_Mode >= 1)
        {
            clip(albedo.a - _Cutoff);
        }
        
        UNITY_BRANCH
        if(_AlphaPremultiply)
        {
            albedo.rgb *= saturate(albedo.a + 0.0000000001);
        }
        
        /**********************************************************************
        Lighting Time :)
        **********************************************************************/
        
        #ifdef POI_LIGHTING
            finalLighting = calculateFinalLighting(albedo.rgb, finalColor);
            
            #ifdef SUBSURFACE
                finalSSS = calculateSubsurfaceScattering();
            #endif
        #endif
        
        float4 finalColorBeforeLighting = albedo;
        finalColor = finalColorBeforeLighting;
        
        #ifdef POI_SPECULAR
            finalSpecular0 = calculateSpecular(finalColorBeforeLighting);
        #endif
        #ifdef POI_PARALLAX
            calculateAndApplyInternalParallax(finalColor);
        #endif
        
        #ifdef POI_ALPHA_TO_COVERAGE
            ApplyAlphaToCoverage(finalColor);
        #endif
        
        UNITY_BRANCH
        if (_Mode == 1)
        {
            UNITY_BRANCH
            if(_AlphaToMask == 1)
            {
                applyDithering(finalColor);
            }
        }
        
        #ifdef POI_METAL
            calculateMetallicness();
            bool probeExists = shouldMetalHappenBeforeLighting();
            UNITY_BRANCH
            if(!probeExists)
            {
                ApplyMetallicsFake(finalColor, albedo);
            }
        #endif
        
        #ifdef POI_LIGHTING
            #if defined(FORWARD_ADD_PASS) && defined(POI_METAL)
                finalLighting *= 1 - metalicMap;
            #endif
        #endif
        
        #ifdef VERTEXLIGHT_ON
            finalColor.rgb *= finalLighting + poiLight.vFinalLighting;
        #else
            finalColor.rgb *= finalLighting;
        #endif
        
        #ifdef POI_METAL
            UNITY_BRANCH
            if(probeExists)
            {
                ApplyMetallics(finalColor, albedo);
            }
        #endif
        
        finalColor.rgb += finalSpecular0 + finalEnvironmentalRim + finalSSS;
        
        #ifdef FORWARD_BASE_PASS
            #ifdef POI_CLEARCOAT
                calculateAndApplyClearCoat(finalColor);
            #endif
        #endif
        
        finalColor.a = saturate(finalColor.a);
        
        /**********************************************************************
        Add Up all the emission values :D
        **********************************************************************/
        #if defined(FORWARD_BASE_PASS) || defined(POI_META_PASS)
            finalEmission += finalColorBeforeLighting.rgb * _MainEmissionStrength * albedo.a;
            finalEmission += wireframeEmission;
            finalEmission += IridescenceEmission;
            finalEmission += spawnInEmission;
            finalEmission += voronoiEmission;
            finalEmission += matcapEmission;
            finalEmission += depthTouchEmission;
            finalEmission += decalEmission;
            finalEmission += glitterEmission;
            finalEmission += panosphereEmission;
            finalEmission += backFaceEmission;
            finalEmission += rimLightEmission;
            finalEmission += flipbookEmission;
            finalEmission += videoEmission;
            finalEmission += textOverlayEmission;
            finalEmission += dissolveEmission;
            #ifdef POI_EMISSION
                finalEmission += calculateEmissionNew(finalColorBeforeLighting, finalColor);
            #endif
        #endif
        
        /**********************************************************************
        Meta Pass Hype :D
        **********************************************************************/
        #ifdef POI_META_PASS
            UnityMetaInput meta;
            UNITY_INITIALIZE_OUTPUT(UnityMetaInput, meta);
            meta.Emission = finalEmission * _GIEmissionMultiplier;
            meta.Albedo = saturate(finalColor.rgb);
            #ifdef POI_SPECULAR
                meta.SpecularColor = poiLight.color.rgb * _SpecularTint.rgb * lerp(1, albedo.rgb, _SpecularMetallic) * _SpecularTint.a;
            #else
                meta.SpecularColor = poiLight.color.rgb * albedo.rgb;
            #endif
            return UnityMetaFragment(meta);
        #endif
        
        /**********************************************************************
        Apply Emission to finalColor
        **********************************************************************/
        finalColor.rgb += finalEmission;
        
        /**********************************************************************
        Grabpass features
        **********************************************************************/
        
        UNITY_BRANCH
        if (_commentIfZero_EnableGrabpass)
        {
            applyGrabEffects(finalColor);
        }
        
        /**********************************************************************
        Unity Fog
        **********************************************************************/
        #ifdef FORWARD_BASE_PASS
            UNITY_BRANCH
            if (_IgnoreFog == 0)
            {
                UNITY_APPLY_FOG(i.fogCoord, finalColor);
            }
        #endif
        
        #ifdef FORWARD_ADD_PASS
            if(_Mode > 0)
            {
                finalColor.rgb *= finalColor.a;
            }
        #endif
        
        UNITY_BRANCH
        if(_Mode == 0)
        {
            finalColor.a = 1;
        }
        
        #ifdef FORWARD_ADD_PASS
            //finalColor.rgb = smoothstep(_LightingAdditiveGradientStart, _LightingAdditiveGradientEnd, 1 - (.5 * poiLight.nDotL + .5));
        #endif
        
        #ifdef POI_DEBUG
            displayDebugInfo(finalColor);
        #endif
        
        //finalColor.rgb = frac(finalColor.rgb);
        return finalColor;
    }
#endif