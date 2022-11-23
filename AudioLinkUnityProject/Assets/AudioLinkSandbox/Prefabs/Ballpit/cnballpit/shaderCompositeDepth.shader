Shader "cnballpit/shaderCompositeDepth"
{
    Properties
    {
        _DepthTop ("DepthTop", 2D) = "white" {}
        _DepthBottom ("DepthBottom", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque"  "Compute" = "Compute" }
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
                float4 vertex : SV_POSITION;
            };

            texture2D<float> _DepthTop;
            texture2D<float> _DepthBottom;
            float4 _DepthTop_TexelSize;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float2 frag (v2f i) : SV_Target
            {
				uint2 coordloc = i.uv.xy * _DepthTop_TexelSize.zw;
				uint2 coordlocB = coordloc;
				coordlocB.y = _DepthTop_TexelSize.w - coordlocB.y - 2;
				float2 ret = 0.;
				ret = float2( _DepthTop[coordloc+uint2(0,0)], _DepthBottom[coordlocB+uint2(0,0)] );
				ret = max( ret, float2( _DepthTop[coordloc+uint2(1,0)], _DepthBottom[coordlocB+uint2(1,0)] ) );
				ret = max( ret, float2( _DepthTop[coordloc+uint2(0,1)], _DepthBottom[coordlocB+uint2(0,1)] ) );
				ret = max( ret, float2( _DepthTop[coordloc+uint2(1,1)], _DepthBottom[coordlocB+uint2(1,1)] ) );
                return ret;
            }
            ENDCG
        }
    }
}
