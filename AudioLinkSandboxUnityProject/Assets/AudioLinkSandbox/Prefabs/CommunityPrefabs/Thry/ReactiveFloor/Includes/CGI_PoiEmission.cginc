#ifndef POI_EMISSION
    #define POI_EMISSION
    
    float4 _EmissionColor;
    POI_TEXTURE_NOSAMPLER(_EmissionMap);
    POI_TEXTURE_NOSAMPLER(_EmissionMask);
    UNITY_DECLARE_TEX2D_NOSAMPLER(_EmissionScrollingCurve); float4 _EmissionScrollingCurve_ST;
    float _EmissionBaseColorAsMap;
    float _EmissionStrength;
    float _EnableEmission;
    float _EmissionHueShift;
    float4 _EmissiveScroll_Direction;
    float _EmissiveScroll_Width;
    float _EmissiveScroll_Velocity;
    float _EmissiveScroll_Interval;
    float _EmissionBlinkingEnabled;
    float _EmissiveBlink_Min;
    float _EmissiveBlink_Max;
    float _EmissiveBlink_Velocity;
    float _ScrollingEmission;
    float _EnableGITDEmission;
    float _GITDEMinEmissionMultiplier;
    float _GITDEMaxEmissionMultiplier;
    float _GITDEMinLight;
    float _GITDEMaxLight;
    float _GITDEWorldOrMesh;
    float _EmissionCenterOutEnabled;
    float _EmissionCenterOutSpeed;
    float _EmissionHueShiftEnabled;
    float _EmissionBlinkingOffset;
    float _EmissionScrollingOffset;
    
    float4 _EmissionColor1;
    #ifdef EFFECT_HUE_VARIATION
        POI_TEXTURE_NOSAMPLER(_EmissionMap1);
        POI_TEXTURE_NOSAMPLER(_EmissionMask1);
        UNITY_DECLARE_TEX2D_NOSAMPLER(_EmissionScrollingCurve1); float4 _EmissionScrollingCurve1_ST;
    #endif
    float _EmissionBaseColorAsMap1;
    float _EmissionStrength1;
    float _EnableEmission1;
    float _EmissionHueShift1;
    float4 _EmissiveScroll_Direction1;
    float _EmissiveScroll_Width1;
    float _EmissiveScroll_Velocity1;
    float _EmissiveScroll_Interval1;
    float _EmissionBlinkingEnabled1;
    float _EmissiveBlink_Min1;
    float _EmissiveBlink_Max1;
    float _EmissiveBlink_Velocity1;
    float _ScrollingEmission1;
    float _EnableGITDEmission1;
    float _GITDEMinEmissionMultiplier1;
    float _GITDEMaxEmissionMultiplier1;
    float _GITDEMinLight1;
    float _GITDEMaxLight1;
    float _GITDEWorldOrMesh1;
    float _EmissionCenterOutEnabled1;
    float _EmissionCenterOutSpeed1;
    float _EmissionHueShiftEnabled1;
    float _EmissionBlinkingOffset1;
    float _EmissionScrollingOffset1;
    
    float _EmissionReplace;
    
    float _EmissionScrollingVertexColor;
    float _EmissionScrollingVertexColor1;
    
    float _EmissionScrollingUseCurve;
    float _EmissionScrollingUseCurve1;

	POI_TEXTURE_NOSAMPLER(_RF_Ramp);
	POI_TEXTURE_NOSAMPLER(_RF_Mask);
	float4 _ReactivePositions[100];
	float _RF_Min_Distance;
	float _RF_Max_Distance;
	float _RF_ArrayLength;
	float _RF_Ramp_Pan;

	float4 _RF_Color0;
	float4 _RF_Color1;
	float4 _RF_Color2;
    
    float calculateGlowInTheDark(in float minLight, in float maxLight, in float minEmissionMultiplier, in float maxEmissionMultiplier, in float enabled)
    {
        float glowInTheDarkMultiplier = 1;
        UNITY_BRANCH
        if (enabled)
        {
            #ifdef POI_LIGHTING
                float3 lightValue = _GITDEWorldOrMesh ? poiLight.finalLighting.rgb: poiLight.directLighting.rgb;
                float gitdeAlpha = (clamp(poiMax(lightValue), minLight, maxLight) - minLight) / (maxLight - minLight);
                glowInTheDarkMultiplier = lerp(minEmissionMultiplier, maxEmissionMultiplier, gitdeAlpha);
            #endif
        }
        return glowInTheDarkMultiplier;
    }
    
    float calculateScrollingEmission(in float3 direction, in float velocity, in float interval, in float scrollWidth, float offset, float3 position)
    {
        float phase = 0;
        phase = dot(position, direction);
        phase -= (_Time.y + offset) * velocity;
        phase /= interval;
        phase -= floor(phase);
        phase = saturate(phase);
        return(pow(phase, scrollWidth) + pow(1 - phase, scrollWidth * 4)) * 0.5;
    }
    
    float calculateBlinkingEmission(in float blinkMin, in float blinkMax, in float blinkVelocity, float offset)
    {
        float amplitude = (blinkMax - blinkMin) * 0.5f;
        float base = blinkMin + amplitude;
        return sin((_Time.y + offset) * blinkVelocity) * amplitude + base;
    }
    
    float3 calculateEmissionNew(in float4 baseColor, inout float4 finalColor)
    {
        // First Emission
        float3 emission0 = 0;
        float emissionStrength0 = _EmissionStrength;
        float3 emissionColor0 = 0;

		/*_RF_ArrayLength = 3;
		_ReactivePositions[0] = float4(0, 0, -100, 0);
		_ReactivePositions[1] = float4(0, 0, -101, 0);
		_ReactivePositions[2] = float4(-1, 0, -100.5, 0);*/

		float maxV = 0;

		float3 rfColor = (float3)0;

		float strength = 0;
		for (int i = 0; i < _RF_ArrayLength; i++) {
			if (length(_ReactivePositions[i].xyz) > 0) {
				float v = 1 - saturate((distance(poiMesh.worldPos, _ReactivePositions[i].xyz) - _RF_Min_Distance) / (_RF_Max_Distance - _RF_Min_Distance));
				if (v > 0.0001) {
					float mask = UNITY_SAMPLE_TEX2D_SAMPLER(_RF_Mask, _MainTex, float2(v, 0.5f)).a + 0.0001f;
					maxV = max(maxV, mask * UNITY_SAMPLE_TEX2D_SAMPLER(_RF_Ramp, _MainTex, float2(v + _RF_Ramp_Pan * _Time.x, 0.5f)).a);

					float3 circlecolor;
					int colorI = (i % 3);
					if (colorI == 0) circlecolor = _RF_Color0.xyz * _RF_Color0.a * 2;
					else if (colorI == 1) circlecolor = _RF_Color1.xyz * _RF_Color1.a * 2;
					else if (colorI == 2) circlecolor = _RF_Color2.xyz * _RF_Color2.a * 2;

					float h = float(i) / _RF_ArrayLength;
					float lerpV = saturate(strength / mask);
					rfColor = lerp(rfColor, circlecolor, 1-lerpV);
					strength += mask;
				}
			}
		}
		emissionStrength0 += saturate(maxV);
        
        float glowInTheDarkMultiplier0 = calculateGlowInTheDark(_GITDEMinLight, _GITDEMaxLight, _GITDEMinEmissionMultiplier, _GITDEMaxEmissionMultiplier, _EnableGITDEmission);
        
        UNITY_BRANCH
        if (!_EmissionCenterOutEnabled)
        {
            emissionColor0 = POI2D_SAMPLER_PAN(_EmissionMap, _MainTex, poiMesh.uv[_EmissionMapUV], _EmissionMapPan) * lerp(1, baseColor, _EmissionBaseColorAsMap).rgb * _EmissionColor.rgb;
        }
        else
        {
            emissionColor0 = UNITY_SAMPLE_TEX2D_SAMPLER(_EmissionMap, _MainTex, ((.5 + poiLight.nDotV * .5) * _EmissionMap_ST.xy) + _Time.x * _EmissionCenterOutSpeed) * lerp(1, baseColor, _EmissionBaseColorAsMap).rgb * _EmissionColor.rgb;
        }
		
		emissionColor0 = rfColor;
        
        UNITY_BRANCH
        if(_ScrollingEmission)
        {
            float3 pos = poiMesh.localPos;
            UNITY_BRANCH
            if(_EmissionScrollingVertexColor)
            {
                pos = poiMesh.vertexColor.rgb;
            }
            
            UNITY_BRANCH
            if(_EmissionScrollingUseCurve)
            {
                emissionStrength0 *= UNITY_SAMPLE_TEX2D_SAMPLER(_EmissionScrollingCurve, _MainTex, TRANSFORM_TEX(poiMesh.uv[_EmissionMapUV], _EmissionScrollingCurve) + (dot(pos, _EmissiveScroll_Direction) * _EmissiveScroll_Interval) + _Time.x * _EmissiveScroll_Velocity);
            }
            else
            {
                emissionStrength0 *= calculateScrollingEmission(_EmissiveScroll_Direction, _EmissiveScroll_Velocity, _EmissiveScroll_Interval, _EmissiveScroll_Width, _EmissionScrollingOffset, pos);
            }
        }
        
        UNITY_BRANCH
        if(_EmissionBlinkingEnabled)
        {
            emissionStrength0 *= calculateBlinkingEmission(_EmissiveBlink_Min, _EmissiveBlink_Max, _EmissiveBlink_Velocity, _EmissionBlinkingOffset);
        }
        
        emissionColor0 = hueShift(emissionColor0, (_EmissionHueShift) * _EmissionHueShiftEnabled);
        float emissionMask0 = UNITY_SAMPLE_TEX2D_SAMPLER(_EmissionMask, _MainTex, TRANSFORM_TEX(poiMesh.uv[_EmissionMaskUV], _EmissionMask) + _Time.x * _EmissionMaskPan);
        
        #ifdef POI_BLACKLIGHT
            if(_BlackLightMaskEmission != 4)
            {
                emissionMask0 *= blackLightMask[_BlackLightMaskEmission];
            }
        #endif
        
        emissionStrength0 *= glowInTheDarkMultiplier0 * emissionMask0;
        emission0 = emissionStrength0 * emissionColor0;
        
        #ifdef POI_DISSOLVE
            UNITY_BRANCH
            if(_DissolveEmissionSide != 2)
            {
                emission0 *= lerp(1 - dissolveAlpha, dissolveAlpha, _DissolveEmissionSide);
            }
        #endif
        
        // Second Emission
        float3 emission1 = 0;
        float emissionStrength1 = 0;
        float3 emissionColor1 = 0;
        
        #ifdef EFFECT_HUE_VARIATION
            emissionStrength1 = _EmissionStrength1;
            float glowInTheDarkMultiplier1 = calculateGlowInTheDark(_GITDEMinLight1, _GITDEMaxLight1, _GITDEMinEmissionMultiplier1, _GITDEMaxEmissionMultiplier1, _EnableGITDEmission1);
            
            UNITY_BRANCH
            if (!_EmissionCenterOutEnabled1)
            {
                emissionColor1 = POI2D_SAMPLER_PAN(_EmissionMap1, _MainTex, poiMesh.uv[_EmissionMap1UV], _EmissionMap1Pan) * lerp(1, baseColor, _EmissionBaseColorAsMap1).rgb * _EmissionColor1.rgb;
            }
            else
            {
                emissionColor1 = UNITY_SAMPLE_TEX2D_SAMPLER(_EmissionMap1, _MainTex, ((.5 + poiLight.nDotV * .5) * _EmissionMap_ST.xy) + _Time.x * _EmissionCenterOutSpeed1).rgb * lerp(1, baseColor, _EmissionBaseColorAsMap1).rgb * _EmissionColor1.rgb;
            }
            
            UNITY_BRANCH
            if(_ScrollingEmission1)
            {
                float3 pos1 = poiMesh.localPos;
                UNITY_BRANCH
                if(_EmissionScrollingVertexColor1)
                {
                    pos1 = poiMesh.vertexColor.rgb;
                }
                
                UNITY_BRANCH
                if(_EmissionScrollingUseCurve1)
                {
                    emissionStrength1 *= UNITY_SAMPLE_TEX2D_SAMPLER(_EmissionScrollingCurve1, _MainTex, TRANSFORM_TEX(poiMesh.uv[_EmissionMap1UV], _EmissionScrollingCurve1) + (dot(pos1, _EmissiveScroll_Direction1) * _EmissiveScroll_Interval1) + _Time.x * _EmissiveScroll_Velocity1);
                }
                else
                {
                    emissionStrength1 *= calculateScrollingEmission(_EmissiveScroll_Direction1, _EmissiveScroll_Velocity1, _EmissiveScroll_Interval1, _EmissiveScroll_Width1, _EmissionScrollingOffset1, pos1);
                }
            }
            UNITY_BRANCH
            if(_EmissionBlinkingEnabled1)
            {
                emissionStrength1 *= calculateBlinkingEmission(_EmissiveBlink_Min1, _EmissiveBlink_Max1, _EmissiveBlink_Velocity1, _EmissionBlinkingOffset1);
            }
            
            emissionColor1 = hueShift(emissionColor1, _EmissionHueShift1 * _EmissionHueShiftEnabled1);
            float emissionMask1 = UNITY_SAMPLE_TEX2D_SAMPLER(_EmissionMask1, _MainTex, TRANSFORM_TEX(poiMesh.uv[_EmissionMask1UV], _EmissionMask1) + _Time.x * _EmissionMask1Pan);
            #ifdef POI_BLACKLIGHT
                if(_BlackLightMaskEmission2 != 4)
                {
                    emissionMask1 *= blackLightMask[_BlackLightMaskEmission2];
                }
            #endif
            emissionStrength1 *= glowInTheDarkMultiplier1 * emissionMask1;
            emission1 = emissionStrength1 * emissionColor1;
            
            #ifdef POI_DISSOLVE
                if(_DissolveEmission1Side != 2)
                {
                    emission1 *= lerp(1 - dissolveAlpha, dissolveAlpha, _DissolveEmission1Side);
                }
            #endif
        #endif
        finalColor.rgb = lerp(finalColor.rgb, saturate(emissionColor0 + emissionColor1), saturate(emissionStrength0 + emissionStrength1) * _EmissionReplace * poiMax(emission0 + emission1));

        return emission0 + emission1;
    }
    
#endif