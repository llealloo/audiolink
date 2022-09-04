
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

namespace VRCAudioLink
{
    public class AudioLinkExperimentalToggle : UdonSharpBehaviour
    {

        public UdonBehaviour audioLink;

        void Start()
        {
            
        }

        public override void Interact()
        {
            bool toggle = !(bool)audioLink.GetProgramVariable("audioDataToggle");
            if (toggle)
            {
                audioLink.SendCustomEvent("EnableReadback");
            } else {
                audioLink.SendCustomEvent("DisableReadback");
            }
            InteractionText = "Experimental Readback is " + (string)((toggle == true) ? "ON" : "OFF") + " (local)";
        }
    }
}
