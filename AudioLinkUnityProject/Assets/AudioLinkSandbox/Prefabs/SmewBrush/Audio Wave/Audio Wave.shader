// Copyright 2017 Google Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

Shader "Smew/Audio Wave" {
Properties {
  _MainTex ("Particle Texture", 2D) = "white" {}
  _EmissionGain ("Emission Gain", Range(0, 1)) = 0.5
}

Category {
  Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
  Blend One One // SrcAlpha One
  BlendOp Add, Min
  AlphaTest Greater .01
  ColorMask RGBA
  Cull Off Lighting Off ZWrite Off

  SubShader {
    Pass {

      CGPROGRAM
      #pragma vertex vert
      #pragma fragment frag
      #pragma target 3.0
      #pragma multi_compile_particles
      #pragma multi_compile __ AUDIO_REACTIVE
      #pragma multi_compile __ TBT_LINEAR_TARGET

      #include "UnityCG.cginc"
	  #include "Packages/com.llealloo.audiolink/Runtime/Shaders/AudioLink.cginc"

	  sampler2D _MainTex;
      float4 _MainTex_ST;
      float _EmissionGain;

      struct appdata_t {
        float4 vertex : POSITION;
        fixed4 color : COLOR;
        float2 texcoord : TEXCOORD0;
      };

      struct v2f {
        float4 vertex : SV_POSITION;
        float4 color : COLOR;
        float2 texcoord : TEXCOORD0;
        float4 unbloomedColor : TEXCOORD1;
      };
	  
	  float4 LinearToSrgb(float4 color) {
		  // Approximation http://chilliant.blogspot.com/2012/08/srgb-approximations-for-hlsl.html
		  float3 linearColor = color.rgb;
		  float3 S1 = sqrt(linearColor);
		  float3 S2 = sqrt(S1);
		  float3 S3 = sqrt(S2);
		  color.rgb = 0.662002687 * S1 + 0.684122060 * S2 - 0.323583601 * S3 - 0.0225411470 * linearColor;
		  return color;
	  }
	  // TB mesh colors are sRGB. TBT mesh colors are linear.
	  float4 TbVertToSrgb(float4 color) { return LinearToSrgb(color); }

	  // Unity only guarantees signed 2.8 for fixed4.
	// In practice, 2*exp(_EmissionGain * 10) = 180, so we need to use float4
	  float4 bloomColor(float4 color, float gain) {
		  // Guarantee that there's at least a little bit of all 3 channels.
		  // This makes fully-saturated strokes (which only have 2 non-zero
		  // color channels) eventually clip to white rather than to a secondary.
		  float cmin = length(color.rgb) * .05;
		  color.rgb = max(color.rgb, float3(cmin, cmin, cmin));
		  // If we try to remove this pow() from .a, it brightens up
		  // pressure-sensitive strokes; looks better as-is.
		  color = pow(color, 2.2);
		  color.rgb *= 2 * exp(gain * 10);
		  return color;
	  }


      v2f vert (appdata_t v)
      {
        v.color = TbVertToSrgb(v.color);

        v2f o;
        o.vertex = UnityObjectToClipPos(v.vertex);
        o.texcoord = TRANSFORM_TEX(v.texcoord,_MainTex);
        o.color = bloomColor(v.color, _EmissionGain);
        o.unbloomedColor = v.color;
        return o;
      }

	  float4 SrgbToLinear(float4 color) {
		  // Approximation http://chilliant.blogspot.com/2012/08/srgb-approximations-for-hlsl.html
		  float3 sRGB = color.rgb;
		  color.rgb = sRGB * (sRGB * (sRGB * 0.305306011 + 0.682171111) + 0.012522878);
		  return color;
	  }
	  float4 SrgbToLinear_Large(float4 color) {
		  float4 linearColor = SrgbToLinear(color);
		  color.r = color.r < 1.0 ? linearColor.r : color.r;
		  color.g = color.g < 1.0 ? linearColor.g : color.g;
		  color.b = color.b < 1.0 ? linearColor.b : color.b;
		  return color;
	  }


	  float4 SrgbToNative(float4 color) { return SrgbToLinear_Large(color); }

      // Input colors are srgb
      fixed4 frag (v2f i) : SV_Target
      {
        // Envelope
        float envelope = sin(i.texcoord.x * 3.14159);

		// SMEW: 4/21/2022

		float waveform = .15 * sin(-30 * i.unbloomedColor.r * AudioLinkGetAmplitudeAtNote(4.0, AUDIOLINK_ROOTNOTE) +i.texcoord.x * 100 * i.unbloomedColor.r);

        float pinch = (1 - envelope) * 40 + 20;
        float procedural_line = saturate(1 - pinch*abs(i.texcoord.y - .5 -waveform * envelope));
        float4 color = 1;
        color.rgb *= envelope * procedural_line;
        color = i.color * color;
        color = float4(color.rgb * color.a, 1.0);
        color = SrgbToNative(color);
        return color;
      }
      ENDCG
    }
  }
}
}
