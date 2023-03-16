#ifndef POI_GLITTER
    #define POI_GLITTER
    half3 _GlitterColor;
    POI_TEXTURE_NOSAMPLER(_GlitterMask);
    float2 _GlitterPan;
    POI_TEXTURE_NOSAMPLER(_GlitterColorMap);
    POI_TEXTURE_NOSAMPLER(_GlitterTexture);
    half _GlitterSpeed;
    half _GlitterBrightness;
    float _GlitterFrequency;
    float _GlitterJitter;
    half _GlitterSize;
    half _GlitterContrast;
    half _GlitterAngleRange;
    half _GlitterMinBrightness;
    half _GlitterBias;
    float _GlitterRandomColors;
    float2 _GlitterMinMaxSaturation;
    float2 _GlitterMinMaxBrightness;
    fixed _GlitterUseSurfaceColor;
    float _GlitterBlendType;
    float _GlitterMode;
    float _GlitterShape;
    float _GlitterCenterSize;
    float _glitterFrequencyLinearEmissive;
    float _GlitterJaggyFix;
    float _GlitterRandomRotation;
    float _GlitterTextureRotation;
    float4 _GlitterMinMaxSize;
    float _GlitterRandomSize;
    float3 randomFloat3(float2 Seed, float maximum)
    {
        return(.5 + float3(
            frac(sin(dot(Seed.xy, float2(12.9898, 78.233))) * 43758.5453),
            frac(sin(dot(Seed.yx, float2(12.9898, 78.233))) * 43758.5453),
            frac(sin(dot(float2(Seed), float2(12.9898, 78.233))) * 43758.5453)
        ) * .5) * (maximum);
    }
    float3 randomFloat3Range(float2 Seed, float Range)
    {
        return(float3(
            frac(sin(dot(Seed.xy, float2(12.9898, 78.233))) * 43758.5453),
            frac(sin(dot(Seed.yx, float2(12.9898, 78.233))) * 43758.5453),
            frac(sin(dot(float2(Seed.x * Seed.y, Seed.y + Seed.x), float2(12.9898, 78.233))) * 43758.5453)
        ) * 2 - 1) * Range;
    }
    float3 randomFloat3WiggleRange(float2 Seed, float Range)
    {
        float3 rando = (float3(
            frac(sin(dot(Seed.xy, float2(12.9898, 78.233))) * 43758.5453),
            frac(sin(dot(Seed.yx, float2(12.9898, 78.233))) * 43758.5453),
            frac(sin(dot(float2(Seed.x * Seed.y, Seed.y + Seed.x), float2(12.9898, 78.233))) * 43758.5453)
        ) * 2 - 1);
        float speed = 1 + float(10);
        return float3(sin((_Time.x + rando.x * pi) * speed), sin((_Time.x + rando.y * pi) * speed), sin((_Time.x + rando.z * pi) * speed)) * Range;
    }
    void Unity_RandomRange_float(float2 Seed, float Min, float Max, out float Out)
    {
        float randomno = frac(sin(dot(Seed, float2(12.9898, 78.233))) * 43758.5453);
        Out = lerp(Min, Max, randomno);
    }
    float3 RandomColorFromPoint(float2 rando)
    {
        fixed hue = random2(rando.x + rando.y).x;
        fixed saturation = lerp(float4(0.8,1,0,1).x, float4(0.8,1,0,1).y, rando.x);
        fixed value = lerp(float4(0.8,1,0,1).x, float4(0.8,1,0,1).y, rando.y);
        float3 hsv = float3(hue, saturation, value);
        return HSVtoRGB(hsv);
    }
    void applyGlitter(inout float4 albedo, inout float3 glitterEmission)
    {
        float2 st = poiMesh.uv[0] * float(3000);
        float2 i_st = floor(st);
        float2 f_st = frac(st);
        float m_dist = 10.;  // minimun distance
        float2 m_point = 0;        // minimum point
        float2 randoPoint = 0;
        float2 dank;
        for (int j = -1; j <= 1; j ++)
        {
            for (int i = -1; i <= 1; i ++)
            {
                float2 neighbor = float2(i, j);
                float2 pos = random2(i_st + neighbor);
                float2 rando = pos;
                pos = 0.5 + 0.5 * sin(float(1) * 6.2831 * pos);
                float2 diff = neighbor + pos - f_st;
                float dist = length(diff);
                if (dist < m_dist)
                {
                    dank = diff;
                    m_dist = dist;
                    m_point = pos;
                    randoPoint = rando;
                }
            }
        }
        float randomFromPoint = random(randoPoint);
        float size = float(0.3);
        
        if(float(0))
        {
            size = remapClamped(randomFromPoint, 0, 1, float4(0.1,0.5,0,1).x, float4(0.1,0.5,0,1).y);
        }
        half glitterAlpha = 1;
        switch(float(0))
        {
            case 0: //circle
            glitterAlpha = (1. - step(size, m_dist));
            break;
            case 1: //sqaure
            float jaggyFix = pow(poiCam.distanceToVert, 2) * float(0);
            
            if (float(0))
            {
                float2 center = float2(0, 0);
                float theta = radians((random(randoPoint) + _Time.x * float(0)) * 360);
                float cs = cos(theta);
                float sn = sin(theta);
                dank = float2((dank.x - center.x) * cs - (dank.y - center.y) * sn + center.x, (dank.x - center.x) * sn + (dank.y - center.y) * cs + center.y);
                glitterAlpha = (1. - smoothstep(size - .1 * jaggyFix, size, abs(dank.x))) * (1. - smoothstep(size - .1 * jaggyFix, size, abs(dank.y)));
            }
            else
            {
                glitterAlpha = (1. - smoothstep(size - .1 * jaggyFix, size, abs(dank.x))) * (1. - smoothstep(size - .1 * jaggyFix, size, abs(dank.y)));
            }
            break;
        }
        float3 finalGlitter = 0;
        switch(float(0))
        {
            case 0:
            float3 randomRotation = 0;
            
            if(float(10) > 0)
            {
                randomRotation = randomFloat3WiggleRange(randoPoint, float(90));
            }
            else
            {
                randomRotation = randomFloat3Range(randoPoint, float(90));
            }
            float3 norm = poiMesh.normals[0];
            float3 glitterReflectionDirection = normalize(mul(poiRotationMatrixFromAngles(randomRotation), norm));
            finalGlitter = lerp(0, float(0) * glitterAlpha, glitterAlpha) + max(pow(saturate(dot(lerp(glitterReflectionDirection, poiCam.viewDir, float(0.8)), poiCam.viewDir)), float(300)), 0);
            finalGlitter *= glitterAlpha;
            break;
            case 1:
            float offset = random(randoPoint);
            float brightness = sin((_Time.x + offset) * float(10)) * float(20) - (float(20) - 1);
            finalGlitter = max(float(0) * glitterAlpha, brightness * glitterAlpha * smoothstep(0, 1, 1 - m_dist * float(0.08) * 10));
            break;
        }
        half3 glitterColor = float4(1,1,1,1);
        glitterColor *= lerp(1, albedo, float(0));
        glitterColor *= POI2D_SAMPLER_PAN(_GlitterColorMap, _MainTex, poiMesh.uv[float(0)], float4(0,0,0,0)).rgb;
        float2 uv = remapClamped(dank, -size, size, 0, 1);
        
        if(float(0) && !float(0))
        {
            float2 fakeUVCenter = float2(.5, .5);
            float theta = radians((random(randoPoint) + _Time.x * float(0)) * 360);
            float cs = cos(theta);
            float sn = sin(theta);
            uv = float2((uv.x - fakeUVCenter.x) * cs - (uv.y - fakeUVCenter.y) * sn + fakeUVCenter.x, (uv.x - fakeUVCenter.x) * sn + (uv.y - fakeUVCenter.y) * cs + fakeUVCenter.y);
        }
        float4 glitterTexture = POI2D_SAMPLER_PAN(_GlitterTexture, _MainTex, uv, float4(0,0,0,0));
        glitterColor *= glitterTexture.rgb;
        float glitterMask = POI2D_SAMPLER_PAN(_GlitterMask, _MainTex, poiMesh.uv[float(0)], float4(0,0,0,0));
        #ifdef POI_BLACKLIGHT
            if (_BlackLightMaskGlitter != 4)
            {
                glitterMask *= blackLightMask[_BlackLightMaskGlitter];
            }
        #endif
        if(float(0))
        {
            glitterColor *= RandomColorFromPoint(random2(randoPoint.x + randoPoint.y));
        }
        
        if(float(0) == 1)
        {
            albedo.rgb = lerp(albedo.rgb, finalGlitter * glitterColor * float(3), finalGlitter * glitterTexture.a * glitterMask);
            glitterEmission = finalGlitter * glitterColor * max(0, (float(3) - 1) * glitterTexture.a) * glitterMask;
        }
        else
        {
            glitterEmission = finalGlitter * glitterColor * float(3) * glitterTexture.a * glitterMask;
        }
    }
#endif
