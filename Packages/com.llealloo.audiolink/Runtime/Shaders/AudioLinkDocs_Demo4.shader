Shader "AudioLink/Examples/Demo4"
{
    Properties
    {
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            #include "Packages/com.llealloo.audiolink/Runtime/Shaders/AudioLink.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float3 vpOrig : TEXCOORD0;
                float3 vpXform : TEXCOORD1;
                float4 vertex : SV_POSITION;
                float  corrmax : TEXCOORD2;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            v2f vert(appdata v)
            {
                v2f o;

                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                float3 vp = v.vertex;

                o.vpOrig = vp;

                // Generate a value for how far around the circle you are.
                // atan2 generates a number from -pi to pi.  We want to map
                // this from -1..1.  Tricky: add 0.001 to x otherwise
                // we lose a vertex at the poll because atan2 is undefined.
                float phi = atan2(vp.x + 0.001, vp.z) / 3.14159;

                // We want to mirror the -1..1 so that it's actually 0..1 but
                // mirrored.
                float placeinautocorrelator = abs(phi);

                // Note: We don't need lerp multiline because the autocorrelator
                // is only a single line.
                float autocorrvalue = AudioLinkLerp(ALPASS_AUTOCORRELATOR +
                    float2(placeinautocorrelator * AUDIOLINK_WIDTH, 0.));

                // Squish in the sides, and make it so it only perterbs
                // the surface.
                autocorrvalue = autocorrvalue * (.5 - abs(vp.y)) * 0.4 + .6;

                // Perform same operation to find max.  The 0th bin on the
                // autocorrelator will almost always be the max
                o.corrmax = AudioLinkLerp(ALPASS_AUTOCORRELATOR) * 0.2 + .6;

                // Modify the original vertices by this amount.
                vp *= autocorrvalue;

                o.vpXform = vp;
                o.vertex = UnityObjectToClipPos(vp);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // Decide how we want to color from colorchord.
                float ccplace = length(i.vpXform.xz) * 2. / i.corrmax;

                // Get a color from ColorChord
                float4 colorchordcolor = AudioLinkData(ALPASS_CCSTRIP +
                    float2( AUDIOLINK_WIDTH * ccplace, 0. )) + 0.01;

                // Shade the color a little.
                colorchordcolor *= length(i.vpXform.xyz) * 15. - 2.0;
                return colorchordcolor;
            }
            ENDCG
        }

        // DepthOnly pass
        Pass
        {
            Name "DepthOnly"
            Tags
            {
                "LightMode" = "DepthOnly"
            }

            ZWrite On
            ColorMask 0

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Packages/com.llealloo.audiolink/Runtime/Shaders/AudioLink.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            v2f vert(appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                float3 vp = v.vertex;

                // Generate a value for how far around the circle you are.
                float phi = atan2(vp.x + 0.001, vp.z) / 3.14159;

                // Mirror -1..1 to 0..1 mirrored
                float placeinautocorrelator = abs(phi);

                // Get autocorrelator value
                float autocorrvalue = AudioLinkLerp(ALPASS_AUTOCORRELATOR +
                    float2(placeinautocorrelator * AUDIOLINK_WIDTH, 0.));

                // Apply deformation
                autocorrvalue = autocorrvalue * (.5 - abs(vp.y)) * 0.4 + .6;

                // Apply to vertex position
                vp *= autocorrvalue;

                o.vertex = UnityObjectToClipPos(vp);
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                return 0;
            }
            ENDCG
        }

        // DepthNormals pass
        Pass
        {
            Name "DepthNormals"
            Tags
            {
                "LightMode" = "DepthNormals"
            }

            ZWrite On

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Packages/com.llealloo.audiolink/Runtime/Shaders/AudioLink.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 normal : TEXCOORD0;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            v2f vert(appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                float3 vp = v.vertex;

                // Generate a value for how far around the circle you are.
                float phi = atan2(vp.x + 0.001, vp.z) / 3.14159;

                // Mirror -1..1 to 0..1 mirrored
                float placeinautocorrelator = abs(phi);

                // Get autocorrelator value
                float autocorrvalue = AudioLinkLerp(ALPASS_AUTOCORRELATOR +
                    float2(placeinautocorrelator * AUDIOLINK_WIDTH, 0.));

                // Apply deformation
                autocorrvalue = autocorrvalue * (.5 - abs(vp.y)) * 0.4 + .6;

                // Apply to vertex position
                vp *= autocorrvalue;

                // For a proper normal calculation, we need to adjust the normal based on the deformation
                // This is a simplified approach - for a more accurate normal, you'd use a derivative-based approach
                float3 normal = UnityObjectToWorldNormal(v.normal);

                // Scale normal inverse to how the vertex was scaled to approximate the surface normal change
                normal /= autocorrvalue;
                normal = normalize(normal);

                o.normal = normal;
                o.vertex = UnityObjectToClipPos(vp);
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                float3 normalWS = normalize(i.normal);
                float3 normalEncoded = normalWS * 0.5 + 0.5;
                return float4(normalEncoded, 1.0);
            }
            ENDCG
        }
    }
}
