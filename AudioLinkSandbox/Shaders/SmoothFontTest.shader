Shader "Unlit/SmoothFontTest"
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
			uniform float4               _MainTex_TexelSize;


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
				float2 iuvt = i.uv * _MainTex_TexelSize.zw;
				float2 ipt = ( floor( iuvt ) ) * _MainTex_TexelSize.xy;
				
                float4 colUL = tex2D(_MainTex, ipt+float2(0,0)*_MainTex_TexelSize.xy);
                float4 colUR = tex2D(_MainTex, ipt+float2(1,0)*_MainTex_TexelSize.xy);
                float4 colLL = tex2D(_MainTex, ipt+float2(0,1)*_MainTex_TexelSize.xy);
                float4 colLR = tex2D(_MainTex, ipt+float2(1,1)*_MainTex_TexelSize.xy);

				float2 shift = smoothstep( 0, 1, iuvt - floor( iuvt ) );
				float4 ov = lerp(
					lerp( colUL, colUR, shift.x ),
					lerp( colLL, colLR, shift.x ), shift.y );

				
                float softness = 4*length( 2./pow( length( float2( ddx( iuvt.x ), ddy( iuvt.y ) ) ), 0.5 ));
				float4 col = saturate( ov * softness - softness/2 );


                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
