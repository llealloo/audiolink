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

Shader "Smew/Audio Pulse" {
Properties {
  _EmissionGain ("Emission Gain", Range(0, 1)) = 0.5
}
    SubShader {
    Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
	Blend One One
    Cull off ZWrite off

    CGPROGRAM
    #pragma target 3.0
    #pragma surface surf StandardSpecular vertex:vert
	#pragma multi_compile __ AUDIO_REACTIVE
    #pragma multi_compile __ TBT_LINEAR_TARGET

	#include "Packages/com.llealloo.audiolink/Runtime/Shaders/AudioLink.cginc"

    struct Input {
      fixed4 color : Color;
      float2 tex : TEXCOORD0;
      float3 viewDir;
      float3 worldNormal;
      INTERNAL_DATA
    };

    fixed _EmissionGain;

	fixed4 bloomColor(fixed4 color, fixed gain) {
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

	//from brush.cginc
	fixed4 LinearToSrgb(fixed4 color) {

		fixed3 linearColor = color.rgb;
		fixed3 S1 = sqrt(linearColor);
		fixed3 S2 = sqrt(S1);
		fixed3 S3 = sqrt(S2);
		color.rgb = 0.662002687 * S1 + 0.684122060 * S2 - 0.323583601 * S3 - 0.0225411470 * linearColor;
		return color;
	}

	fixed4 TbVertToSrgb(fixed4 color) { return LinearToSrgb(color); }
	fixed4 SrgbToNative(fixed4 color) { return color; }

    void vert (inout appdata_full i, out Input o) {
      UNITY_INITIALIZE_OUTPUT(Input, o);
      o.color = TbVertToSrgb(o.color);
      o.tex = i.texcoord;
    }

	void surf (Input IN, inout SurfaceOutputStandardSpecular o) {
      o.Smoothness = .8;
      o.Specular = .05;
      fixed audioMultiplier = 1;

	  IN.tex.x -= (_Time.x) * 30 * AudioLinkGetAmplitudeAtFrequency(50.0);

      IN.tex.x = fmod(abs(IN.tex.x),3);

	  fixed neon = saturate(pow(10 * saturate(.2 - IN.tex.x), 5));
      fixed4 bloom = bloomColor(IN.color, _EmissionGain);
	  bloom *= pow(1, 5);
      o.Emission = SrgbToNative(bloom * neon);
    }
    ENDCG
    }
}
