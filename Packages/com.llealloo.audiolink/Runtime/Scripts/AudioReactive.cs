using UnityEngine;

namespace AudioLink.Reactive
{
#if UDONSHARP
    using UdonSharp;

    [UdonBehaviourSyncMode(BehaviourSyncMode.None)]
    public abstract class AudioReactive : UdonSharpBehaviour
#else
    public abstract class AudioReactive : MonoBehaviour
#endif
    {
        public AudioLink audioLink;
        public AudioLinkBand band;
        public bool smooth;
        [Range(0, 127)]
        public int delay;
    }
}