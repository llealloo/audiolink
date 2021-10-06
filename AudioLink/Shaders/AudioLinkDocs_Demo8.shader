Shader "AudioLink/Examples/Demo8"
{
    Properties
    {
        _AudioLinkBand("AudioLink Band", Int) = 0
    }
    SubShader
    {
        // Allow users to make this effect transparent.
        Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}

        Blend SrcAlpha OneMinusSrcAlpha

        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            #include "Assets/AudioLink/Shaders/AudioLink.cginc"


            uniform uint _AudioLinkBand;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            v2f vert (appdata v)
            {
                // This is just the template vertex shader.
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float getBandAngle(uint column)
            {
                // Implement the bottom row
                // Note: It's not performance optimal to do branching in shaders but it's quicker to develop this example.
                float v = AudioLinkData(uint2(0, _AudioLinkBand)).r;
                if (column == 0) return max(v-0.4, 0) * 2;
                if (column == 1) return v * 2 - 1;
                if (column == 2) return v > 0.4? 0 : 1;
                if (column == 3) return v > 0.4? -1 : 1;
                return 0;
            }

            float getCellAngle(uint2 grid_index)
            {
                // For the top and middle row, sample from chronotensity.
                uint2 offset = uint2(2 * grid_index.x + (grid_index.y - 1), _AudioLinkBand);
                float chronotensityAngle = (AudioLinkDecodeDataAsUInt(ALPASS_CHRONOTENSITY + offset) % 628319) / 100000.0;
                return grid_index.y == 0 ? getBandAngle(grid_index.x) : chronotensityAngle;
            }

            float4 frag (v2f i) : SV_Target
            {
                float2 grid_dimensions = float2(4,3);
                float2 uv = i.uv * grid_dimensions;
                uint2 grid_index = floor(uv);
                float2 pos = frac(uv)*2 - 1; // position relative to the circle center.
                float angle = getCellAngle(grid_index);
                float2 direction;
                sincos(angle, direction.x, direction.y);
                return float4(
                    0.7 * lerp(
                        // If pos is aligned with direction, be white.
                        // Otherwise choose a background color based on the grid_index.
                        float3(grid_index / grid_dimensions, 0),
                        float3(1,1,1),
                        smoothstep(.995, .996, dot(direction, normalize(pos)))
                    ),
                    smoothstep(.91, .90, length(pos))  // circular cutout
                );

            }
            ENDCG
        }
    }
}
