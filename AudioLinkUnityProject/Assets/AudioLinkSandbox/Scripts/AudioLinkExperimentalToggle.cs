using UdonSharp;

namespace VRCAudioLink
{
    public class AudioLinkExperimentalToggle : UdonSharpBehaviour
    {
        public AudioLink audioLink;

        void Start()
        {
        }

        public override void Interact()
        {
            bool toggle = !audioLink.audioDataToggle;
            if (toggle)
            {
                audioLink.SendCustomEvent("EnableReadback");
            }
            else
            {
                audioLink.SendCustomEvent("DisableReadback");
            }

            InteractionText = "Experimental Readback is " + (toggle ? "ON" : "OFF") + " (local)";
        }
    }
}