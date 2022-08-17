// WARNING ONLY USE THIS IF YOU ARE ATTEMPTING TO PERFORM A RENDERDOC PERF TEST INSIDE UNITY.
// Put your editor into play mode while watchnig this, filling you screen.  It will force
// the GPU into high power mode and your perf tests will be much more accurate.


Shader "Unlit/PerfEater"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

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
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
				int t;
				float2 c = i.uv * 2. - 1.;
				float2 z = 0;
				for( t = 0; t < 10000; t++ )
				{
				  z = float2( z.x * z.x - z.y * z.y + c.x, z.x*z.y*2.+c.y );
				}
                float4 col = float4( z, 0 , 1);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
