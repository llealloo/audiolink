#if UDONSHARP
using UdonSharp;

using UnityEngine;

using VRC.SDKBase;
using VRC.Udon;
namespace VRCAudioLink.Extras
{
    public class AudioLinkDisableCRT : UdonSharpBehaviour
    {
        public AudioLink audioLink;
        private RenderTexture originalRenderTexture;
        private int _AudioTexture;

        void Start()
        {
            _AudioTexture = VRCShader.PropertyToID("_AudioTexture");
        }

        public void _DisableCRT() 
        {
            VRCShader.SetGlobalTexture(_AudioTexture, null);
        }

        public void _EnableCRT()
        {
            VRCShader.SetGlobalTexture(_AudioTexture, audioLink.audioRenderTexture);
        }
    }
}
#endif