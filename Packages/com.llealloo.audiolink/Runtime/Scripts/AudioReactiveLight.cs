using UnityEngine;

#if UDONSHARP
using UdonSharp;
#endif

namespace AudioLink
{
    [RequireComponent(typeof(Light))]
#if UDONSHARP
    [UdonBehaviourSyncMode(BehaviourSyncMode.NoVariableSync)]
    public class AudioReactiveLight : UdonSharpBehaviour
#else
    public class AudioReactiveLight : MonoBehaviour
#endif
    {
        public AudioLink audioLink;
        public AudioLinkBand band;
        public AudioReactiveLightColorMode colorMode = AudioReactiveLightColorMode.STATIC;
        [Range(0, 127)] public int delay;
        public bool affectIntensity = true;
        public float intensityMultiplier = 1f;
        public float hueShift;

        private Light _light;
        private int _dataIndex;
        private Color _initialColor;

        void Start()
        {
            _light = GetComponent<Light>();
            _initialColor = _light.color;
            _dataIndex = ((int)band * 128) + delay;
        }

        void Update()
        {
            if (audioLink.AudioDataIsAvailable())
            {
                // Convert to grayscale
                float amplitude = Vector3.Dot(audioLink.GetDataAtPixel(delay, (int)band), new Vector3(0.299f, 0.587f, 0.114f));
                if (affectIntensity) _light.intensity = amplitude * intensityMultiplier;
                if (colorMode == AudioReactiveLightColorMode.STATIC)
                    _light.color = HueShift(_initialColor, amplitude * hueShift);
                else
                {
                    Vector2 themePixel = Vector2.zero;
                    switch (colorMode)
                    {
                        case AudioReactiveLightColorMode.THEME0: themePixel = AudioLink.GetALPassThemeColor0(); break;
                        case AudioReactiveLightColorMode.THEME1: themePixel = AudioLink.GetALPassThemeColor1(); break;
                        case AudioReactiveLightColorMode.THEME2: themePixel = AudioLink.GetALPassThemeColor2(); break;
                        case AudioReactiveLightColorMode.THEME3: themePixel = AudioLink.GetALPassThemeColor3(); break;
                    }
                    _light.color = HueShift(audioLink.GetDataAtPixel(themePixel), amplitude * hueShift);
                }
            }
        }

        private Color HueShift(Color color, float hueShiftAmount)
        {
            float h, s, v;
            Color.RGBToHSV(color, out h, out s, out v);
            h += hueShiftAmount;
            return Color.HSVToRGB(h, s, v);
        }
    }
}
