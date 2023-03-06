// Custom shader made by Juice...
#pragma target 3.0
#include "Lighting.cginc"
#include "UnityCG.cginc"
#include "Packages/com.llealloo.audiolink/Runtime/Shaders/AudioLink.cginc"

float4 _Color__FurPrimary;
float _Emission__FurPrimary;
float _Hue__FurPrimary;
float _Sat__FurPrimary;
float _Invert__FurPrimary;
float _Specular__FurPrimary;
float _DL__FurPrimary;
float _LP__FurPrimary;
float _Gloss__FurPrimary;
sampler2D _MainTex__FurPrimary, _EmissionMask__FurPrimary, _FurMap__FurPrimary;
float4 _MainTex__FurPrimary_ST, _EmissionMask__FurPrimary_ST, _FurMap__FurPrimary_ST;
float _Length__FurPrimary;
float _Density__FurPrimary;
float _Shading__FurPrimary;
float _ALEmission__FurPrimary;
float _ALFur__FurPrimary;
float _ALRotation__FurPrimary;
float _ALLength__FurPrimary;
float _ALBass__FurPrimary;
float _ALMidLow__FurPrimary;
float _ALMidHigh__FurPrimary;
float _ALTrebel__FurPrimary;


half _Dither__FurPrimary;
float _MinDistance__FurPrimary;
float _MaxDistance__FurPrimary;

// HSV Controls
float alt(float n, float3 hsv) {
	float k=fmod(n+hsv.x/60,6);
	return (hsv.z-hsv.z*hsv.y*max(0,min(min(k,4-k),1)));
}
float3 conv(float3 clr) {
	float mx=max(clr.r,max(clr.g,clr.b));
	float mn=min(clr.r,min(clr.g,clr.b));
	float3 hsv={0,0,mx};
	float c=mx-mn;
	if(hsv.z == clr.r){
		hsv.x=60*((clr.g-clr.b)/c);
	}else{
		if(hsv.z == clr.g){
			hsv.x=60*(2+(clr.b-clr.r)/c);
		}else{
			if(hsv.z == clr.b){
				hsv.x=60*(4+(clr.r-clr.g)/c);
			}
		}
	}
	if(hsv.z!=0){
		hsv.y=c/hsv.z;
	}
	hsv.x+=_Hue__FurPrimary;
	if(hsv.x>360)hsv.x-=360;
	hsv.y*=_Sat__FurPrimary;
	return float3(alt(5,hsv),alt(3,hsv),alt(1,hsv));
}

// AudioLink
float lfrac(float Input, float MaxValue) {
    return frac(Input / MaxValue) * MaxValue;
}

float GetAudioLinkData(float2 uv3_ALTexRot, float y) {
    float pos = (frac(uv3_ALTexRot.y * _ALLength__FurPrimary * 10) * 0.5 - 0.5);
    float pos2 = (frac(uv3_ALTexRot.y * _ALLength__FurPrimary * 10) * 0.5);
    float start_fade = saturate(abs(frac((uv3_ALTexRot.y) * (_ALLength__FurPrimary * 10)) - 1));
    float AL = AudioLinkData(ALPASS_AUDIOLINK + int2(lfrac(pos * 128, 128), y)).g;
    float AL2 = AudioLinkData(ALPASS_AUDIOLINK + int2(lfrac(pos2 * 128 + 1, 128), y)).g;
    return lerp(AL2, AL, start_fade);
}

float audiolink(float2 UV) {
    float2 pivot = float2(0.5, 0.5);
    float cosAngle = cos(_ALRotation__FurPrimary);
    float sinAngle = sin(_ALRotation__FurPrimary);
    float2x2 rot = float2x2(cosAngle, -sinAngle, sinAngle, cosAngle);
    float2 RotatedUV = UV - pivot;
    float2 uv3_ALTexRot = mul(rot, RotatedUV);
    uv3_ALTexRot += pivot;
    float AL1 = GetAudioLinkData(uv3_ALTexRot, 0);
    float AL2 = GetAudioLinkData(uv3_ALTexRot, 1);
    float AL3 = GetAudioLinkData(uv3_ALTexRot, 2);
    float AL4 = GetAudioLinkData(uv3_ALTexRot, 3);
    return AudioLinkIsAvailable() ? ((AL1 * _ALBass__FurPrimary) + (AL2 * _ALMidLow__FurPrimary) + (AL3 * _ALMidHigh__FurPrimary) + (AL4 * _ALTrebel__FurPrimary)) : 0;
}

bool IsInMirror() {
    return unity_CameraProjection[2][0] != 0.f || unity_CameraProjection[2][1] != 0.f;
}

struct appdata {
    float4 vertex : POSITION;
    float3 normal : NORMAL;
    float4 pos: POSITION;
    float2 uv: TEXCOORD0;
    float2 uv2: TEXCOORD1;
    float2 uv3: TEXCOORD2;
    float2 uv4: TEXCOORD3;
};

struct v2f {
    float4 pos: SV_POSITION;
    float2 uv: TEXCOORD0;
    float2 uv2: TEXCOORD1;
    float2 uv3: TEXCOORD2;
    float2 uv4: TEXCOORD3;
    float3 worldNormal: NORMAL;
    float3 worldPos: TEXCOORD4;
};

v2f vert (appdata v) {
    v2f o;
    o.pos = UnityObjectToClipPos(v.pos);
    o.uv = TRANSFORM_TEX(v.uv, _MainTex__FurPrimary);
    o.uv2 = TRANSFORM_TEX(v.uv2, _FurMap__FurPrimary);
    o.uv3 = TRANSFORM_TEX(v.uv3, _EmissionMask__FurPrimary);
    o.uv4 = v.uv4;
    return o;
}

v2f vert_surface(appdata v) {
    v2f o;
    o.pos = UnityObjectToClipPos(v.vertex);
    o.uv = TRANSFORM_TEX(v.uv, _MainTex__FurPrimary);
    o.uv3 = TRANSFORM_TEX(v.uv3, _EmissionMask__FurPrimary);
    o.uv4 = v.uv4;
    o.worldNormal = UnityObjectToWorldNormal(v.normal);
    o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
    return o;
}

v2f vert_base(appdata v) {
    v2f o;
    float4 AL = audiolink(v.uv4);
    float3 P = v.vertex.xyz + v.normal * ((_Length__FurPrimary * (((AL * _ALFur__FurPrimary) * 2) + 1)) / 10) * FURSTEP;
    o.pos = UnityObjectToClipPos(float4(P, 1.0));
    o.uv = TRANSFORM_TEX(v.uv, _MainTex__FurPrimary );
    o.uv2 = TRANSFORM_TEX(v.uv2, _FurMap__FurPrimary);
    o.uv3 = TRANSFORM_TEX(v.uv3, _EmissionMask__FurPrimary);
    o.uv4 = v.uv4;
    o.worldNormal = UnityObjectToWorldNormal(v.normal);
    o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
    return o;
}

// Reflectivity
float3 reflection(float3 UVworldNormal, float3 UVworldPos, float Gloss) {
    float3 worldNormal = normalize(UVworldNormal);
    float3 worldLight = normalize(_WorldSpaceLightPos0.xyz);
    float3 worldView = normalize(_WorldSpaceCameraPos.xyz - UVworldPos.xyz);
    float3 worldHalf = normalize(worldView + worldLight);
    float3 worldViewDir = normalize(UnityWorldSpaceViewDir(UVworldPos));
    float3 worldRefl = reflect(-worldViewDir, UVworldNormal);
    float4 reflectionData = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, worldRefl);
    float3 reflectionColor = DecodeHDR (reflectionData, unity_SpecCube0_HDR);
    float4 r = 0;
    return reflectionColor * Gloss;
}

// Color & Texture
float3 surface(float3 UVworldNormal, float3 UVworldPos, float3 UVpos, float2 UVc, float2 UVa, float2 UVm) {
    float3 worldNormal = normalize(UVworldNormal);
    float3 worldLight = normalize(_WorldSpaceLightPos0.xyz);
    float3 worldView = normalize(_WorldSpaceCameraPos.xyz - UVworldPos.xyz);
    float3 worldHalf = normalize(worldView + worldLight);
    float3 lightprobes = (ShadeSH9(float4(UVworldNormal,1)) * _LP__FurPrimary * 3);
    float4 AL = audiolink(UVa);
    float3 albedo = abs(_Invert__FurPrimary - conv(tex2D(_MainTex__FurPrimary, UVc).rgb) * _Color__FurPrimary);
    float3 emission = (albedo * tex2D(_EmissionMask__FurPrimary, UVm).rgb) * ((_Emission__FurPrimary * 2) + (AL * _ALEmission__FurPrimary * 10) / 2);
    albedo -= (pow(1 - FURSTEP, 2)) * _Shading__FurPrimary;
    float3 ambient = emission + albedo * (UNITY_LIGHTMODEL_AMBIENT.xyz) * _DL__FurPrimary;
    float3 diffuse = _LightColor0.rgb * albedo * (saturate(dot(worldNormal, worldLight)) * _DL__FurPrimary);
    fixed3 specular = _LightColor0.rgb * diffuse * pow(saturate(dot(worldNormal, worldHalf)), clamp( (_Specular__FurPrimary * 90), .001, 90) );

    
    float distanceFromCamera = distance(UVworldPos, _WorldSpaceCameraPos);
    float fade = saturate(((distanceFromCamera - _MinDistance__FurPrimary) / _MaxDistance__FurPrimary) + IsInMirror());

    // Screen-door transparency: Discard pixel if below threshold.
    float4x4 thresholdMatrix =
    {  1.0 / 17.0,  9.0 / 17.0,  3.0 / 17.0, 11.0 / 17.0,
      13.0 / 17.0,  5.0 / 17.0, 15.0 / 17.0,  7.0 / 17.0,
       4.0 / 17.0, 12.0 / 17.0,  2.0 / 17.0, 10.0 / 17.0,
      16.0 / 17.0,  8.0 / 17.0, 14.0 / 17.0,  6.0 / 17.0
    };
    float4x4 _RowAccess = { 1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1 };
    float2 pos2 = UVpos.xy / UVpos.z;
    pos2 *= _ScreenParams.xy; // pixel position
    clip(_Dither__FurPrimary * fade - thresholdMatrix[fmod(pos2.x, 4)] * _RowAccess[fmod(pos2.y, 4)]);

    return ambient + diffuse + specular;
}

// Mesh Surface
float4 frag_surface(v2f i): SV_Target {
    float3 r = reflection(i.worldNormal, i.worldPos, _Gloss__FurPrimary);
    float3 color = surface(i.worldNormal, i.worldPos, i.pos, i.uv, i.uv4, i.uv3);
    return float4(color + r, 1);
}

// Shell Layers
float4 frag_base(v2f i): SV_Target {
    float3 r = reflection(i.worldNormal, i.worldPos, _Gloss__FurPrimary);
    float3 color = surface(i.worldNormal, i.worldPos, i.pos, i.uv, i.uv4, i.uv3);
    float3 noise = tex2D(_FurMap__FurPrimary, i.uv2).rgb;
    float alpha = clamp(noise - (FURSTEP * FURSTEP) * (_Density__FurPrimary), 0, 1);
    return float4(color + r, alpha);
}