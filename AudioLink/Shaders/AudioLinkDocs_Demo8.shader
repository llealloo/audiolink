Shader "AudioLink/Examples/Demo7"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
    }
    SubShader
    {
        Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}
        LOD 100

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows alpha:fade

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        #include "AudioLink.cginc"

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
        };


        half _Glossiness;
        half _Metallic;
        fixed4 _Color;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        float getChronotensityAngle(uint2 grid_index) {
            // Note: I know it's not performance optimal to do branching in shaders but it's quicker to develop this way.
            uint band = 0;
            // // Calculate things off differentials in the buffer.
            // if (grid_index.y == 3) {
            //     // if (grid_index.x == 2) return (
            //     //     (AudioLinkDecodeDataAsUInt(ALPASS_CHRONOTENSITY + uint2(2*2, band)) % 628319) / 100000.0
            //     //     -(AudioLinkDecodeDataAsUInt(ALPASS_CHRONOTENSITY + uint2(2*3, band)) % 628319) / 100000.0
            //     // );
            //     float acc = 0;
            //     float v = AudioLinkData(uint2(0, band)).r;
            //     float prev = v;
            //     float total_weight = 0;
            //     for (int delay=1; delay<AUDIOLINK_WIDTH; ++delay) {
            //         v = AudioLinkData(uint2(delay, band)).r;
            //         float weight = pow(2, -1 * float(delay));
            //         total_weight += weight;
            //         float diff = v - prev;
            //         float contribution = 0;
            //         if      (grid_index.x == 0) contribution = max(0, diff);
            //         else if (grid_index.x == 1) contribution = diff;
            //         else if (grid_index.x == 2) contribution = v > .5? 0 : 1;
            //         else if (grid_index.x == 3) contribution = v > .5? -1 : 1;
            //         else                        contribution = 0;
            //         contribution *= weight;
            //         acc += contribution;
            //     }
            //     acc /= total_weight; // This could be worked out statically. (Is the compiler smart enough?)
            //     return acc;
            // }

            if (grid_index.y == 2) return (AudioLinkDecodeDataAsUInt(ALPASS_CHRONOTENSITY + uint2(2*grid_index.x+1, band)) % 628319) / 100000.0;
            if (grid_index.y == 1) return (AudioLinkDecodeDataAsUInt(ALPASS_CHRONOTENSITY + uint2(2*grid_index.x+0, band)) % 628319) / 100000.0;

            // Base things on the first value
            if (grid_index.y == 0) {
                float v = AudioLinkData(uint2(0, band)).r;
                if (grid_index.x == 0) return max(v-.4, 0) * 2;
                if (grid_index.x == 1) return v * 2 - 1;
                if (grid_index.x == 2) return v > 0.4? 0 : 1;
                if (grid_index.x == 3) return v > 0.4? -1 : 1;
                return 0;
            }
            return 0;
        }

        void surf (Input IN, inout SurfaceOutputStandard o) {
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            // o.Albedo = c.rgb;

            float2 uv = IN.uv_MainTex * float2(4,3);
            uint2 grid_index = floor(uv);
            o.Albedo.rg = grid_index / float2(4,3);

            float2 pos = (frac(uv)*2 - 1)  * 1.1;
            o.Alpha = smoothstep(1, .99, length(pos));  // circular cutout

            // float theta = atan2(pos.y, pos.x);
            float2 chronotensityDir;
            sincos(getChronotensityAngle(grid_index), chronotensityDir.x, chronotensityDir.y);
            o.Albedo.rgb = lerp(
                o.Albedo.rgb,
                float3(1,1,1),
                smoothstep(.995, .996, dot(chronotensityDir, normalize(pos)))
            );

        }
        ENDCG
    }
    FallBack "Diffuse"
}
