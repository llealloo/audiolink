Shader "_pi_/Aurora"
{
    Properties
    {
        _Speed ("Speed", Float) = 2.0
        _ColSpeed ("Color Speed", Float) = 2.0
        _ScaleDown ("ScaleDown", Float) = 0.25
        _ScaleUp ("ScaleUp", Float) = 4
        _Height ("Height", Float) = 10
        _OpacityMod ("Opacity Modifier", Range(0.0, 1.0)) = 1.0

        [Toggle(GEOM_TYPE_MESH)] _AudioLink ("AudioLink support", Float) = 0.0
        [ToggleUI] _Reactive ("Reactive to Audio (Animateable)", Float) = 1.0
    }
    SubShader
    {
        Tags {
            "RenderType" = "Background"
            "Queue" = "Transparent-10"
            "ForceNoShadowCasting" = "True"
            "IgnoreProjector" = "True"
        }

        ZWrite Off
        ZTest LEqual
        Cull Back
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma shader_feature GEOM_TYPE_MESH

            #pragma target 5.0
            #pragma fragmentoption ARB_precision_hint_fastest

            #include "UnityCG.cginc"
            #include "noiseSimplex.cginc"

            #ifdef GEOM_TYPE_MESH
            #define AUDIOLINK
            #endif
            #ifdef AUDIOLINK
            #include "Packages/com.llealloo.audiolink/Runtime/Shaders/AudioLink.cginc"
            #endif

            float _Speed, _ColSpeed, _ScaleDown, _OpacityMod, _Reactive, _Height;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 clipPos : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                float4 screenPos : TEXCOORD1;
                float2 uv : TEXCOORD2;
                float4 ray : TEXCOORD3;
                float4 heightBandMult : TEXCOORD4;
                float time : TEXCOORD5;
            };

            #define MAX_STEPS 18
            #define EPSILON 1.2f
            #define BOTTOM _Bottom
            #define HEIGHT _Height

            /*
             * STATICS
             */
            float3 get_camera_pos() {
                float3 worldCam;
                worldCam.x = unity_CameraToWorld[0][3];
                worldCam.y = unity_CameraToWorld[1][3];
                worldCam.z = unity_CameraToWorld[2][3];
                return worldCam;
            }
            // _WorldSpaceCameraPos is broken in VR (single pass stereo)
            static float3 camera_pos = get_camera_pos();
            // detects VRChat mirror cameras
            static bool isInMirror = UNITY_MATRIX_P._31 != 0 || UNITY_MATRIX_P._32 != 0;

            v2f vert (appdata v)
            {
                v2f o;

                float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
                v.vertex *= _ScaleDown;
                o.clipPos = UnityObjectToClipPos(v.vertex);
                o.screenPos = ComputeNonStereoScreenPos(o.clipPos);
                o.ray.xyz = worldPos.xyz - camera_pos.xyz;
                o.ray.w = o.clipPos.w;
                o.worldPos = worldPos;
                o.uv = v.uv;
                o.time = _Time.x;

                float4 bands = float4(.48, .48, .48, .48);

                #ifdef AUDIOLINK
                uint testw = 0, testh = 0;
                _AudioTexture.GetDimensions(testw, testh);
                if (testw > 16 && _Reactive > 0)
                {
                    fixed4 band0 = _AudioTexture[uint2(0, 0)] + _AudioTexture[uint2(1, 0)];
                    fixed4 band1 = _AudioTexture[uint2(0, 1)] + _AudioTexture[uint2(1, 1)];
                    fixed4 band2 = _AudioTexture[uint2(0, 2)] + _AudioTexture[uint2(1, 2)];
                    fixed4 band3 = _AudioTexture[uint2(0, 3)] + _AudioTexture[uint2(1, 3)];
                    bands = float4(band0.r, band1.r, band2.r, band3.r);
                    bands = pow(bands, 0.7);
                    bands *= 0.27f;
                    bands += 0.48f;
                    o.time = AudioLinkDecodeDataAsSeconds(ALPASS_GENERALVU_NETWORK_TIME) * 0.05;
                }
                #endif

                o.heightBandMult = bands;

                return o;
            }

            static float _Bottom;

            // Following noise function is adapted from:
            // https://www.shadertoy.com/view/XtGGRt
            /* float2x2 m2 = float2x2(0.95534, 0.29552, -0.29552, 0.95534); */
            float2x2 mm2(float a){float c = cos(a), s = sin(a);return float2x2(c,s,-s,c);}
            float tri(float x){return clamp(abs(frac(x)-.5),0.01,0.49);}
            float2 tri2(float2 p){return float2(tri(p.x)+tri(p.y),tri(p.y+tri(p.x)));}
            float triNoise2d(float2 p, float spd, float time)
            {
                float z = 1.8;
                float z2 = 2.5;
                float rz = 0.;
                /* p = mul(p, mm2(p.x*0.06)); */
                float2 bp = p;
                for (uint i=0; i<3; i++)
                {
                    float2 dg = tri2(bp*1.85)*.75;
                    dg = mul(dg, mm2(time*spd));
                    p -= dg/z2;

                    bp *= 1.2;
                    z2 *= .45;
                    z *= .42;
                    p *= 1.21 + (rz-1.0)*.02;

                    rz += tri(p.x+tri(p.y))*z;
                    /* p = mul(p, -m2); */
                }
                return clamp(1./pow(rz*29., 1.40),0.,.55);
            }

            float4 aurora(float3 pos, float bandMult, float time, float color) {
                float heightMod = saturate(HEIGHT-(pos.y-BOTTOM)) * bandMult;
                float density = saturate(triNoise2d(pos.xz*0.0087, _Speed, time)-0.030f)*heightMod;
                float3 col = lerp(float3(1, 0.08, 0), float3(0, 1.3, 0.06), color);

                /* return float4(col, density > 0.01 ? 1 : 0); */
                return float4(col, density);
            }

            float4 raymarch(float3 start, float3 dir, float screenDist, float top, float camDist, float4 bands, float distFromCenter, float time) {
                float3 cur = start;
                float4 acc = float4(0, 0, 0, 0);

                // "foveated" rendering:
                // increase EPSILON as we get closer to the edge of the screen
                float epsMod = 0.90 + pow(saturate(screenDist*1.2), 6);
                float eps = EPSILON * epsMod;
                dir *= eps * clamp(camDist * 0.0115f, 0.95f, 10000);

                top /= clamp(camDist * 0.003f, 1, 10000);

                float color = saturate(0.4+0.5*snoise(start.xz*0.0026f + time*_ColSpeed));

                for (uint j; j < MAX_STEPS; j++) {
                    float band = (cur.y - BOTTOM) * (1/HEIGHT);
                    float bandMult = band < 0.125 ?
                        bands.x : (band < 0.375 ?
                        lerp(bands.x, bands.y, (band - 0.125) * 4) : (band < 0.625 ?
                        lerp(bands.y, bands.z, (band - 0.375) * 4) : (band < 0.875 ?
                        lerp(bands.z, bands.w, (band - 0.625) * 4) : bands.w
                    )));

                    float4 next = aurora(cur, bandMult, time, color) * distFromCenter;
                    acc.rgb = lerp(acc.rgb, next.rgb, 0.5);
                    acc.a += next.a;

                    cur += dir;

                    if (cur.y > top) {
                        return acc;
                    }
                }

                // overrun
                return acc;
            }

            float3 planeIntersect(float3 rayStart, float3 ray, float3 pos, float3 norm) {
                float3 diff = rayStart - pos;
                float3 prod1 = dot(diff, norm);
                float3 prod2 = dot(ray, norm);
                float3 prod3 = prod1 / prod2;
                return rayStart - ray * prod3;
            }

            float4 frag (v2f i) : SV_Target
            {
                /* if (isInMirror) discard; */

                // not how you're supposed to do variables lol
                _Bottom = i.worldPos.y;

                float2 screenPos = i.screenPos.xy/i.screenPos.w;
                float screenDist = distance(screenPos, float2(0.5f, 0.5f));

                float3 ray = normalize((i.ray.xyz / i.ray.w).xyz);
                float3 start = planeIntersect(camera_pos, ray, i.worldPos, float3(0, -1, 0));

                float distFromCenter = distance(float2(0, 0), (i.uv - 0.5)*2);
                distFromCenter = 1.0 - distFromCenter;
                distFromCenter = pow(saturate(distFromCenter), 1.6);

                float4 result = distFromCenter < 0.01f ? float4(0, 0, 0, 0) :
                    raymarch(
                        start,
                        ray,
                        screenDist,
                        BOTTOM + HEIGHT,
                        distance(camera_pos, i.worldPos),
                        i.heightBandMult,
                        pow(distFromCenter * 0.85, 1.20),
                        i.time
                    );

                result.a = saturate(result.a * _OpacityMod)*0.9;

                return result;
            }
            ENDCG
        }
    }
}
