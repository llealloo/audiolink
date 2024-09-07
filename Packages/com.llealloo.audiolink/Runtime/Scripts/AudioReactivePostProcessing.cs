using UnityEngine;

namespace AudioLink
{
#if UDONSHARP
    using UdonSharp;
    using UnityEngine.Rendering.PostProcessing;

    public class AudioReactivePostProcessing : UdonSharpBehaviour
#else
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
        private int _dataIndex;

        void Start()
        {
            _postProcessVolume = transform.GetComponent<PostProcessVolume>();
            _dataIndex = (band * 128) + delay;

        }

        void Update()
        {
            if (audioLink.AudioDataIsAvailable())
            {
                // Convert to grayscale
                float amplitude = Vector3.Dot(audioLink.GetDataAtPixel(delay, band), new Vector3(0.299f, 0.587f, 0.114f));
                _postProcessVolume.weight = Mathf.Lerp(minWeight, weight, amplitude);
            }
        }

    }
}