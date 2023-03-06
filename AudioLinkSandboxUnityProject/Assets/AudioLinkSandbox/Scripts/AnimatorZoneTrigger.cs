
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

namespace AudioLinkWorld
{
    public class AnimatorZoneTrigger : UdonSharpBehaviour
    {
        public Animator animator;
        private VRCPlayerApi _localPlayer;

        void Start()
        {
            _localPlayer = Networking.LocalPlayer;
        }

        public override void OnPlayerTriggerExit(VRC.SDKBase.VRCPlayerApi player)
        {
            if (player == _localPlayer) animator.SetBool("State", false);
        }

        public override void OnPlayerTriggerEnter(VRC.SDKBase.VRCPlayerApi player)
        {
            if (player == _localPlayer) animator.SetBool("State", true);
        }
    }
}
