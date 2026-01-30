#if UNITY_POST_PROCESSING_STACK_V2
using UnityEngine;
using UnityEngine.Rendering.PostProcessing;

namespace AudioLink
{
#if UDONSHARP
    using UdonSharp;

    [RequireComponent(typeof(PostProcessVolume))]
    public class AudioReactivePostProcessing : UdonSharpBehaviour
#else
    [RequireComponent(typeof(PostProcessVolume))]
    public class AudioReactivePostProcessing : MonoBehaviour
#endif
    {
        public AudioLink audioLink;
        public int band;
        [Range(0, 127)]
        public int delay;
        public float weight = 1;
        public float minWeight = 0;

        private PostProcessVolume _postProcessVolume;

        void Start()
        {
            _postProcessVolume = transform.GetComponent<PostProcessVolume>();

        }

        void Update()
        {
            if (audioLink.AudioDataIsAvailable())
            {
                float amplitude = audioLink.GetDataAtPixel(delay, band).x;
                _postProcessVolume.weight = Mathf.Lerp(minWeight, weight, amplitude);
            }
        }

    }
}
#endif