#ifndef POI_MACROS
    #define POI_MACROS
    #define POI_TEXTURE_NOSAMPLER(tex) Texture2D tex; float4 tex##_ST; float2 tex##Pan; uint tex##UV
    #define POI_TEXTURE(tex) UNITY_DECLARE_TEX2D(tex##); float4 tex##_ST; float2 tex##Pan; uint tex##UV
    #define POI_NORMAL_NOSAMPLER(tex) Texture2D tex; float4 tex##_ST; float2 tex##Pan; uint tex##UV; float tex##Scale
    #define POI2D_SAMPLER_PAN(tex, texSampler, uv, pan) (UNITY_SAMPLE_TEX2D_SAMPLER(tex, texSampler, TRANSFORM_TEX(uv, tex) + _Time.x * pan))
    #define POI2D_SAMPLER_PAN2(tex, texSampler, uvIndex, pan) (UNITY_SAMPLE_TEX2D_SAMPLER(tex, texSampler, uvIndex > 4 ? saturate(TRANSFORM_TEX(poiMesh.uv[uvIndex], tex)) : TRANSFORM_TEX(poiMesh.uv[uvIndex], tex) + _Time.x * pan))
    #define POI2D_SAMPLER(tex, texSampler, uv) (UNITY_SAMPLE_TEX2D_SAMPLER(tex, texSampler, TRANSFORM_TEX(uv, tex)))
    #define POI2D_PAN(tex, uv, pan) (tex2D(tex, TRANSFORM_TEX(uv, tex) + _Time.x * pan))
    #define POI2D(tex, uv) (tex2D(tex, TRANSFORM_TEX(uv, tex)))
    #define POI_SAMPLE_TEX2D(tex, uv) (UNITY_SAMPLE_TEX2D(tex, TRANSFORM_TEX(uv, tex)))
    #define POI_SAMPLE_TEX2D_PAN(tex, uv, pan) (UNITY_SAMPLE_TEX2D(tex, TRANSFORM_TEX(uv, tex) + _Time.x * pan))
    #ifdef POINT
    #   define POI_LIGHT_ATTENUATION(destName, shadow, input, worldPos) \
            unityShadowCoord3 lightCoord = mul(unity_WorldToLight, unityShadowCoord4(worldPos, 1)).xyz; \
            fixed shadow = UNITY_SHADOW_ATTENUATION(input, worldPos); \
            fixed destName = tex2D(_LightTexture0, dot(lightCoord, lightCoord).rr).r;
    #endif
    #ifdef SPOT
    #if !defined(UNITY_HALF_PRECISION_FRAGMENT_SHADER_REGISTERS)
    #define DECLARE_LIGHT_COORD(input, worldPos) unityShadowCoord4 lightCoord = mul(unity_WorldToLight, unityShadowCoord4(worldPos, 1))
    #else
    #define DECLARE_LIGHT_COORD(input, worldPos) unityShadowCoord4 lightCoord = input._LightCoord
    #endif
    #   define POI_LIGHT_ATTENUATION(destName, shadow, input, worldPos) \
            DECLARE_LIGHT_COORD(input, worldPos); \
            fixed shadow = UNITY_SHADOW_ATTENUATION(input, worldPos); \
            fixed destName = (lightCoord.z > 0) * UnitySpotCookie(lightCoord) * UnitySpotAttenuate(lightCoord.xyz);
    #endif
#endif
