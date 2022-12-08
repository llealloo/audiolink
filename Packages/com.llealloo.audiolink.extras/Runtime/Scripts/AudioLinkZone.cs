#if UDONSHARP
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;

namespace VRCAudioLink.Extras
{
    [RequireComponent(typeof(Collider))]
    public class AudioLinkZone : UdonSharpBehaviour
    {
        [Space(10)]
        public AudioLink audioLink;
        [Space(10)]
        public AudioSource audioSource;

        private VRCPlayerApi _localPlayer;

        void Start()
        {
            _localPlayer = Networking.LocalPlayer;        
        }

        public override void OnPlayerTriggerEnter(VRCPlayerApi player)
        {
            if (player == _localPlayer) audioLink.audioSource = audioSource;
        }
    }
}
#endif