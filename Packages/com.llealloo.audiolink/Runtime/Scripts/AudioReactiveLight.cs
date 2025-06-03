using UnityEngine;

namespace AudioLink.Reactive
{

#if UDONSHARP
    using UdonSharp;
#endif

    [RequireComponent(typeof(Light))]
    public class AudioReactiveLight : AudioReactive

    {
        public AudioLink audioLink;
        public AudioLinkBand band;
        public bool smooth;
        [Range(0, 127)]
        public int delay;
        
        public bool affectIntensity = true;
        public float intensityMultiplier = 1f;
        public float hueShift;

        private Light _light;
        private Color _initialColor;

        void Start()
        {
            _light = transform.GetComponent<Light>();
            _initialColor = _light.color;
        }

        void Update()
        {
            if (audioLink.AudioDataIsAvailable())
            {
                float amplitude = audioLink.GetBandAsSmooth(band, delay, smooth);
                if (affectIntensity) _light.intensity = amplitude * intensityMultiplier;
                _light.color = HueShift(_initialColor, amplitude * hueShift);
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
