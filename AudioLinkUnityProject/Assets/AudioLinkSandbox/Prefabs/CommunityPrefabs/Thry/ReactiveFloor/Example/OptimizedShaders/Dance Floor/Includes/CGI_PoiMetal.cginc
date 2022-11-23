#ifndef POI_METAL
    #define POI_METAL
    samplerCUBE _CubeMap;
    float _SampleWorld;
    POI_TEXTURE_NOSAMPLER(_MetallicMask);
    POI_TEXTURE_NOSAMPLER(_SmoothnessMask);
    float _Metallic;
    float _InvertSmoothness;
    float _Smoothness;
    float _EnableMetallic;
    float3 _MetalReflectionTint;
    POI_TEXTURE_NOSAMPLER(_MetallicTintMap);
    float3 finalreflections;
    float metalicMap;
    float3 reflection;
    float roughness;
    float lighty_boy_uwu_var;
    bool shouldMetalHappenBeforeLighting()
    {
        float4 envSample = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, poiCam.reflectionDir, roughness * UNITY_SPECCUBE_LOD_STEPS);
        bool probeExists = !(unity_SpecCube0_HDR.a == 0 && envSample.a == 0);
        return probeExists && !float(0);
    }
    float3 fresnelRelflection(in float4 albedo)
    {
        half3 dotNV = 1 - abs(poiLight.nDotV);
        half f = dotNV * dotNV * dotNV * dotNV;
        return lerp(lerp(DielectricSpec.rgb, albedo.rgb, metalicMap), saturate(1 - roughness + metalicMap), f);
    }
    void calculateMetallicness()
    {
        metalicMap = POI2D_SAMPLER_PAN(_MetallicMask, _MainTex, poiMesh.uv[float(0)], float4(0,0,0,0)) * float(0);
    }
    void ApplyMetallics(inout float4 finalColor, in float4 albedo)
    {
        #ifdef FORWARD_BASE_PASS
            float smoothnessMap = (POI2D_SAMPLER_PAN(_SmoothnessMask, _MainTex, poiMesh.uv[float(0)], float4(0,0,0,0)));
            #ifdef POI_BLACKLIGHT
                if (_BlackLightMaskMetallic != 4)
                {
                    metalicMap *= blackLightMask[_BlackLightMaskMetallic];
                    smoothnessMap *= blackLightMask[_BlackLightMaskMetallic];
                }
            #endif
            if(float(0) == 1)
            {
                smoothnessMap = 1 - smoothnessMap;
            }
            smoothnessMap *= float(1);
            roughness = 1 - smoothnessMap;
            Unity_GlossyEnvironmentData envData;
            envData.roughness = roughness;
            envData.reflUVW = BoxProjection(
                poiCam.reflectionDir, poiMesh.worldPos.xyz,
                unity_SpecCube0_ProbePosition,
                unity_SpecCube0_BoxMin, unity_SpecCube0_BoxMax
            );
            float3 probe0 = Unity_GlossyEnvironment(
                UNITY_PASS_TEXCUBE(unity_SpecCube0), unity_SpecCube0_HDR, envData
            );
            envData.reflUVW = BoxProjection(
                poiCam.reflectionDir, poiMesh.worldPos.xyz,
                unity_SpecCube1_ProbePosition,
                unity_SpecCube1_BoxMin, unity_SpecCube1_BoxMax
            );
            float interpolator = unity_SpecCube0_BoxMin.w;
            
            if(interpolator < 0.99999)
            {
                float3 probe1 = Unity_GlossyEnvironment(
                    UNITY_PASS_TEXCUBE_SAMPLER(unity_SpecCube1, unity_SpecCube0),
                    unity_SpecCube0_HDR, envData
                );
                reflection = lerp(probe1, probe0, interpolator);
            }
            else
            {
                reflection = probe0;
            }
            float reflecty_lighty_boy_uwu_var_2 = 1.0 / (roughness * roughness + 1.0);
            half4 tintMap = POI2D_SAMPLER_PAN(_MetallicTintMap, _MainTex, poiMesh.uv[float(0)], float4(0,0,0,0));
            finalColor.rgb *= (1 - metalicMap * tintMap.a);
            finalColor.rgb += reflecty_lighty_boy_uwu_var_2 * reflection.rgb * fresnelRelflection(albedo) * float4(0.250646,0.250646,0.250646,1) * tintMap.rgb * tintMap.a;
        #endif
    }
    void ApplyMetallicsFake(inout float4 finalColor, in float4 albedo)
    {
        #ifdef FORWARD_BASE_PASS
            metalicMap = POI2D_SAMPLER_PAN(_MetallicMask, _MainTex, poiMesh.uv[float(0)], float4(0,0,0,0)) * float(0);
            float smoothnessMap = (POI2D_SAMPLER_PAN(_SmoothnessMask, _MainTex, poiMesh.uv[float(0)], float4(0,0,0,0)));
            #ifdef POI_BLACKLIGHT
                if(_BlackLightMaskMetallic != 4)
                {
                    metalicMap *= blackLightMask[_BlackLightMaskMetallic];
                    smoothnessMap *= blackLightMask[_BlackLightMaskMetallic];
                }
            #endif
            if(float(0) == 1)
            {
                smoothnessMap = 1 - smoothnessMap;
            }
            smoothnessMap *= float(1);
            roughness = 1 - smoothnessMap;
            reflection = texCUBElod(_CubeMap, float4(poiCam.reflectionDir, roughness * UNITY_SPECCUBE_LOD_STEPS));
            float reflecty_lighty_boy_uwu_var_2 = 1.0 / (roughness * roughness + 1.0);
            half4 tintMap = POI2D_SAMPLER_PAN(_MetallicTintMap, _MainTex, poiMesh.uv[float(0)], float4(0,0,0,0));
            finalColor.rgb *= (1 - metalicMap * tintMap.a);
            finalColor.rgb += reflecty_lighty_boy_uwu_var_2 * reflection.rgb * fresnelRelflection(albedo) * float4(0.250646,0.250646,0.250646,1) * tintMap.rgb * tintMap.a;
        #endif
    }
#endif
