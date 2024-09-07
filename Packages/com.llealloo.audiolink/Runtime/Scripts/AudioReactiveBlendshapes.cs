using UnityEngine;

namespace AudioLink
{
#if UDONSHARP
    using UdonSharp;
    using UnityEngine.Rendering.PostProcessing;

    public class AudioReactiveBlendshapes : UdonSharpBehaviour
#else
    public class AudioReactiveBlendshapes : MonoBehaviour
#endif
    {
        public AudioLink audioLink;
        public int band;
        [Range(0, 127)]
        public int delay;
        public int[] blendshapeIDs;
        public float[] blendshapeWeights;
        public float[] blendshapeMinWeights;

        private SkinnedMeshRenderer _skinnedMeshRenderer;
        private int _dataIndex;
        private int _maxBlendshapes;

        void Start()
        {
            _skinnedMeshRenderer = transform.GetComponent<SkinnedMeshRenderer>();
            _dataIndex = (band * 128) + delay;
            int[] maxBlendshapes = new int[3] { blendshapeIDs.Length, blendshapeWeights.Length, blendshapeMinWeights.Length };
            _maxBlendshapes = Mathf.Min(maxBlendshapes);

        }

        void Update()
        {
            if (audioLink.AudioDataIsAvailable())
            {
                // Convert to grayscale
                float amplitude = Vector3.Dot(audioLink.GetDataAtPixel(delay, band), new Vector3(0.299f, 0.587f, 0.114f)) * 100f;
                for (int indx = 0; indx < _maxBlendshapes; indx++)
                    _skinnedMeshRenderer.SetBlendShapeWeight(blendshapeIDs[indx], Mathf.LerpUnclamped(blendshapeMinWeights[indx], blendshapeWeights[indx], amplitude));
            }
        }

    }
}