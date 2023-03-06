#ifndef POI_VERTEX_MANIPULATION
    #define POI_VERTEX_MANIPULATION
    #include "CGI_PoiMath.cginc"
    float4 _VertexManipulationLocalTranslation;
    float4 _VertexManipulationLocalRotation;
    float4 _VertexManipulationLocalScale;
    float4 _VertexManipulationWorldTranslation;
    float _VertexManipulationHeight;
    float _VertexManipulationHeightBias;
    sampler2D _VertexManipulationHeightMask; float4 _VertexManipulationHeightMask_ST;
    float2 _VertexManipulationHeightPan;
    float _EnableVertexGlitch;
    sampler2D _VertexGlitchMap;     float4 _VertexGlitchMap_ST;
    float _VertexGlitchThreshold;
    float _VertexGlitchFrequency;
    float _VertexGlitchStrength;
    float _VertexRoundingDivision;
    float _VertexRoundingEnabled;
    void applyLocalVertexTransformation(inout float3 normal, inout float4 tangent, inout float4 vertex)
    {
        normal = rotate_with_quaternion(normal, float4(0,0,0,1));
        tangent.xyz = rotate_with_quaternion(tangent.xyz, float4(0,0,0,1));
        vertex = transform(vertex, float4(0,0,0,1), float4(0,0,0,1), float4(1,1,1,1));
    }
    void applyLocalVertexTransformation(inout float3 normal, inout float4 vertex)
    {
        normal = rotate_with_quaternion(normal, float4(0,0,0,1));
        vertex = transform(vertex, float4(0,0,0,1), float4(0,0,0,1), float4(1,1,1,1));
    }
    void applyWorldVertexTransformation(inout float4 worldPos, inout float4 localPos, inout float3 worldNormal, float2 uv)
    {
        float3 heightOffset = (tex2Dlod(_VertexManipulationHeightMask, float4(TRANSFORM_TEX(uv, _VertexManipulationHeightMask) + float4(0,0,0,0) * _Time.x, 0, 0)).r - float(0)) * float(0) * worldNormal;
        worldPos.rgb += float4(0,0,0,1).xyz * float4(0,0,0,1).w + heightOffset;
        localPos.xyz = mul(unity_WorldToObject, worldPos);
    }
    void applyWorldVertexTransformationShadow(inout float4 worldPos, inout float4 localPos, float3 worldNormal, float2 uv)
    {
        float3 heightOffset = (tex2Dlod(_VertexManipulationHeightMask, float4(TRANSFORM_TEX(uv, _VertexManipulationHeightMask) + float4(0,0,0,0) * _Time.x, 0, 0)).r - float(0)) * float(0) * worldNormal;
        worldPos.rgb += float4(0,0,0,1).xyz * float4(0,0,0,1).w + heightOffset;
        localPos.xyz = mul(unity_WorldToObject, worldPos);
    }
    void applyVertexRounding(inout float4 worldPos, inout float4 localPos)
    {
        
        if (float(0))
        {
            worldPos.xyz = (ceil(worldPos * float(500)) / float(500)) - 1 / float(500) * .5;
            localPos = mul(unity_WorldToObject, worldPos);
        }
    }
    void applyVertexGlitching(inout float4 worldPos, inout float4 localPos)
    {
        
        if(_EnableVertexGlitch)
        {
            float3 forward = getCameraPosition() - mul(unity_ObjectToWorld, float4(0, 0, 0, 1)).xyz;
            forward.y = 0;
            forward = normalize(forward);
            float3 glitchDirection = normalize(cross(float3(0, 1, 0), forward));
            float glitchAmount = frac(sin(dot(_Time.xy + worldPos.y, float2(12.9898, 78.233))) * 43758.5453123) * 2 - 1;
            float time = _Time.y * _VertexGlitchFrequency;
            float randomGlitch = (sin(time) + sin(2.2 * time + 5.52) + sin(2.9 * time + 0.93) + sin(4.6 * time + 8.94)) / 4;
            worldPos.xyz += glitchAmount * glitchDirection * (_VertexGlitchStrength * .01) * step(_VertexGlitchThreshold, randomGlitch);
            localPos = mul(unity_WorldToObject, worldPos);
        }
    }
#endif
