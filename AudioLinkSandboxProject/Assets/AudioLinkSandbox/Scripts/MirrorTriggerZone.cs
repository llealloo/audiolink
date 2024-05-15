
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

namespace AudioLinkWorld
{
    public class MirrorTriggerZone : UdonSharpBehaviour
    {

        private VRCPlayerApi _localPlayer;

        public UdonBehaviour mirrorButton;

        void Start()
        {
            _localPlayer = Networking.LocalPlayer;
        }

        public override void OnPlayerTriggerExit(VRC.SDKBase.VRCPlayerApi player)
        {
            if (player == _localPlayer) mirrorButton.SendCustomEvent("DisableMirror");
        }

        public override void OnPlayerTriggerEnter(VRC.SDKBase.VRCPlayerApi player)
        {
            if (player == _localPlayer) mirrorButton.SendCustomEvent("SetMirrorFromState");
        }
    }
}
