using UnityEngine;

namespace AudioLink
{
#if UDONSHARP
    using UdonSharp;
#endif

    public class AudioLinkContactBridge : AudioReactive
    {
        public AudioLink audioLink;
        [Header("AudioLink Settings")]
        [Range(0, 15)]
        public int smoothing;

        private bool _ready;
        // Unfortunately we can't access the name of a Enum value from Udon as Enum.GetName requires a System.Type that we can't retrieve.
        private readonly string[] _contactBandSuffix = new string[4] {
            "Bass",
            "LowMid",
            "HighMid",
            "Treble"
            };
        private Transform[] _contactTransforms = new Transform[4];
        private Transform[] _smoothContactTransforms = new Transform[4];

        void OnEnable()
        {
            _ready = false;

            transform.position = Vector3.zero;
            transform.rotation = Quaternion.identity;

            transform.localScale = Vector3.one;
            transform.localScale = new Vector3(
                1.0f / transform.lossyScale.x,
                1.0f / transform.lossyScale.y,
                1.0f / transform.lossyScale.z
            );

            for (int indx = 0; indx < 4; indx ++)
            {
                Transform contactTransform = transform.Find("AudioLink." + _contactBandSuffix[indx]);
                Transform smoothContactTransform = transform.Find("AudioLink.Smooth." + _contactBandSuffix[indx]);

#if UDONSHARP
                if (VRC.SDKBase.Utilities.IsValid(contactTransform) && VRC.SDKBase.Utilities.IsValid(smoothContactTransform))
#else
                if (contactTransform != null && smoothContactTransform != null)
#endif
                {
                    _contactTransforms[indx] = contactTransform;
                    _smoothContactTransforms[indx] = smoothContactTransform;

                    if (indx == 3)
                        _ready = true;
                }
                else
                {
                    enabled = false;
                    break;
                }
            }
        }

        void Update()
        {
            if (audioLink.AudioDataIsAvailable() && _ready) // Check for AudioLink initialization
            {
                for (int indx = 0; indx < 4; indx ++)
                {
                    _contactTransforms[indx].position = Vector3.up * ((AudioLink.ToGrayscale(audioLink.GetBandAsSmooth((AudioLinkBand)indx, 0, false)) * 0.1f) - 0.2f);
                    _smoothContactTransforms[indx].position = Vector3.up * ((AudioLink.ToGrayscale(audioLink.GetBandAsSmooth((AudioLinkBand)indx, smoothing, true)) * 0.1f) - 0.2f);
                }
            }
        }
    }
}