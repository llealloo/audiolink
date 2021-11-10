Shader "AudioLink/AudioLinkSandbox/BrazierParticleEffect"
{
    Properties
    {
        [HideInInspector] _TANoiseTex ("TANoise", 2D) = "white" {}
        _FlameSpeed ("Flame Speed", float ) = 8.0
    }
    SubShader
    {
        //Tags { "RenderType"="Opaque" }
        Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}
        Blend SrcAlpha One
        //ZWrite Off
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "/Assets/AudioLink/Shaders/AudioLink.cginc"
            #include "/Assets/cnlohr/Shaders/tanoise/tanoise.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float4 base_color: TEXCOORD1;
            };

            float _FlameSpeed;

            v2f vert (appdata v)
            {
                v2f o;
                float4 vp = v.vertex;
                o.uv = v.uv;
                uint lightid = floor( v.uv.x );
                
                float3 localOffset = 0.;
                float _FlySpeed = 1.;
                float SyncTime = AudioLinkDecodeDataAsSeconds( ALPASS_GENERALVU_NETWORK_TIME );
                float4 ThisNote = AudioLinkData(ALPASS_CCINTERNAL + uint2( lightid/8, 0 ) );
                float ThisScale = AudioLinkData(ALPASS_AUDIOLINK + uint2( 0, lightid%4 ) );
                
                float height = glsl_mod( lightid * 423 + SyncTime*_FlameSpeed, 16. )/16.;
                float3 FlyMux = .05;
                float noisex = lightid*100. + floor( v.vertex.x + 0.5 ) + unity_ObjectToWorld[0][3]*2;
                float3 positional_offset = (tanoise2_hq( float2( noisex, SyncTime*_FlySpeed + floor( v.vertex.y + 0.5 ) + unity_ObjectToWorld[2][3]*2 ) )-0.5)*FlyMux;
                float3 positional_offset_future = (tanoise2_hq( float2( noisex, SyncTime*_FlySpeed+0.2 ) )-0.5)*FlyMux;
                float3 direction = positional_offset_future - positional_offset;
                
                localOffset = positional_offset * (height*3.+.5);
                localOffset.z += height*.2;
    
                vp.z -= lightid * .025;
                vp.xyz *= ThisScale-0.1+(1.-height);
                vp.xyz += localOffset;

                o.base_color = float4( AudioLinkCCtoRGB( ThisNote.x, 1, 0 ), 1. );
                o.vertex = UnityObjectToClipPos(vp);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = i.base_color;
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
