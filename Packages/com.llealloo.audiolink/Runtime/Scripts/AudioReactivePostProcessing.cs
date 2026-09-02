#if UNITY_POST_PROCESSING_STACK_V2
using UnityEngine;
using UnityEngine.Rendering.PostProcessing;

namespace AudioLink
{

    [RequireComponent(typeof(PostProcessVolume))]
    public class AudioReactivePostProcessing : AudioReactive
    {
        public AudioLink audioLink;
        [Header("AudioLink Settings")]
        public AudioLinkBand band;
        public bool smooth;
        [Range(0, 127)]
        public int delay;

        [Header("Reactivity Settings"), Range(0.0f, 1.0f)]
        public float fromWeight = 0.0f;
        [Range(0.0f, 1.0f)]
        public float toWeight = 1.0f;
        
        private PostProcessVolume _postProcessVolume;

        void Start()
        {
            _postProcessVolume = transform.GetComponent<PostProcessVolume>();

        }

        void Update()
        {
            if (audioLink.AudioDataIsAvailable())
            {
                float amplitude = AudioLink.ToGrayscale(audioLink.GetBandAsSmooth(band, delay, smooth));
                _postProcessVolume.weight = Mathf.Lerp(fromWeight, toWeight, amplitude);
            }
        }

    }
}
#endif