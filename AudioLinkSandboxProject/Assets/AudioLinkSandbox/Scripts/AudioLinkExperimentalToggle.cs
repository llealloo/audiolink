#if UDONSHARP
using UdonSharp;

namespace AudioLink
{
    public class AudioLinkExperimentalToggle : UdonSharpBehaviour
    {
        public AudioLink audioLink;

        public override void Interact()
        {
            bool toggle = !audioLink.audioDataToggle;
            if (toggle)
            {
                audioLink.EnableReadback();
            }
            else
            {
                audioLink.DisableReadback();
            }

            InteractionText = "Experimental Readback is " + (toggle ? "ON" : "OFF") + " (local)";
        }
    }
}
#endif
