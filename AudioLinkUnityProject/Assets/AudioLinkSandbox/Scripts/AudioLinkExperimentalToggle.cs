
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
            audioLink.SetProgramVariable("audioDataToggle", toggle);
            InteractionText = "Experimental Readback is " + (string)((toggle == true) ? "ON" : "OFF");
        }
    }
}
