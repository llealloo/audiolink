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

Shader "Smew/Chromatic Audio Wave" {
Properties {
  _EmissionGain ("Emission Gain", Range(0, 1)) = 0.5
}

Category {
  Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
  Blend One One //SrcAlpha One
  BlendOp Add, Min
  AlphaTest Greater .01
  ColorMask RGBA
  Cull Off Lighting Off ZWrite Off Fog { Color (0,0,0,0) }

  SubShader {
    Pass {

      CGPROGRAM
      #pragma vertex vert
      #pragma fragment frag
      #pragma target 3.0
      #pragma multi_compile_particles
      #pragma multi_compile __ AUDIO_REACTIVE
      #pragma multi_compile __ TBT_LINEAR_TARGET
      #pragma target 3.0

      #include "UnityCG.cginc"
	  #include "Packages/com.llealloo.audiolink/Runtime/Shaders/AudioLink.cginc"

		half _EmissionGain;
		//from brush.cginc

		fixed4 bloomColor(float4 color, float gain) {
			// Guarantee that there's at least a little bit of all 3 channels.
			// This makes fully-saturated strokes (which only have 2 non-zero
			// color channels) eventually clip to white rather than to a secondary.
			fixed cmin = length(color.rgb) * .05;
			color.rgb = max(color.rgb, fixed3(cmin, cmin, cmin));
			// If we try to remove this pow() from .a, it brightens up
			// pressure-sensitive strokes; looks better as-is.
			color = pow(color, 2.2);
			color.rgb *= 2 * exp(gain * 10);
			return color;
		}

		half4 LinearToSrgb(half4 color) {

			half3 linearColor = color.rgb;
			half3 S1 = sqrt(linearColor);
			half3 S2 = sqrt(S1);
			half3 S3 = sqrt(S2);
			color.rgb = 0.662002687 * S1 + 0.684122060 * S2 - 0.323583601 * S3 - 0.0225411470 * linearColor;
			return color;
		}

		half4 TbVertToSrgb(half4 color) { return LinearToSrgb(color); }
		
		fixed4 SrgbToNative(fixed4 color) { return color; }

		struct appdata_t {
		half4 vertex : POSITION;
		fixed4 color : COLOR;
		half2 texcoord : TEXCOORD0;
		};

		struct v2f {
		half4 vertex : SV_POSITION;
		fixed4 color : COLOR;
		half2 texcoord : TEXCOORD0;
		fixed4 unbloomedColor : TEXCOORD1;
		};

		v2f vert (appdata_t v)
		{
		v.color = TbVertToSrgb(v.color);
		v2f o;
		o.vertex = UnityObjectToClipPos(v.vertex);
		o.texcoord = v.texcoord;
		o.color = bloomColor(v.color, _EmissionGain);
		o.unbloomedColor = v.color;
		return o;
		}

		// Input color is srgb
		fixed4 frag (v2f i) : SV_Target
		{
		// Envelope
		half envelope = sin(i.texcoord.x * 3.14159);
		i.texcoord.y += i.texcoord.x * 3;
		
		float al_freq = AudioLinkGetAmplitudeAtFrequency(25.0);
		
		fixed waveform_r = .15 * sin( -20 * i.unbloomedColor.r * _Time.w * al_freq * 1.2 /6 + i.texcoord.x * 100 * i.unbloomedColor.r);
		fixed waveform_g = .15 * sin( -30 * i.unbloomedColor.g * _Time.w * al_freq * 1.4 /6 + i.texcoord.x * 100 * i.unbloomedColor.g);
		fixed waveform_b = .15 * sin( -40 * i.unbloomedColor.b * _Time.w * al_freq * 1.6 /6 + i.texcoord.x * 100 * i.unbloomedColor.b);

			i.texcoord.y = fmod(i.texcoord.y + i.texcoord.x, 1);
		fixed procedural_line_r = saturate(1 - 40*abs(i.texcoord.y - .5 + waveform_r));
		fixed procedural_line_g = saturate(1 - 40*abs(i.texcoord.y - .5 + waveform_g));
		fixed procedural_line_b = saturate(1 - 40*abs(i.texcoord.y - .5 + waveform_b));
		fixed4 color = procedural_line_r * half4(1,0,0,0) + procedural_line_g * half4(0,1,0,0) + procedural_line_b * half4(0,0,1,0);
		color.w = 1;
		color = i.color * color;

		color = fixed4(color.rgb * color.a, 1.0);
		color = SrgbToNative(color);
		return color;
      }
      ENDCG
    }
  }
}
}
