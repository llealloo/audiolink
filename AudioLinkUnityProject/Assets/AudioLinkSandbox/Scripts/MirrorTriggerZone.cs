
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

namespace AudioLinkWorld
{
    public class MirrorTriggerZone : UdonSharpBehaviour
    {

        public UdonBehaviour mirrorButton;

        void Start()
        {
            
        }

        public override void OnPlayerTriggerExit(VRC.SDKBase.VRCPlayerApi player)
        {
            mirrorButton.SendCustomEvent("DisableMirror");
        }

        public override void OnPlayerTriggerEnter(VRC.SDKBase.VRCPlayerApi player)
        {
            mirrorButton.SendCustomEvent("SetMirrorFromState");
        }
    }
}
