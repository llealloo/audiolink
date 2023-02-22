
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

namespace AudioLinkWorld
{
    public class BetterMirrorToggle : UdonSharpBehaviour
    {

        public GameObject mirror;
        public GameObject mirrorInterfaceEnabled;
        public GameObject mirrorInterfaceDisabled;
        public AudioSource mirrorSoundEnabled;
        public AudioSource mirrorSoundDisabled;
        public Animator mirrorButtonAnimator;

        private bool _state;

        void Start()
        {
            _state = mirror.activeSelf;
        }

        public override void Interact()
        {
            _state = !_state;
            mirrorInterfaceEnabled.SetActive(_state);
            mirrorInterfaceDisabled.SetActive(!_state);
            if (_state)
            {
                mirrorSoundEnabled.Play();
                mirrorButtonAnimator.SetBool("State", true);
            } else {
                mirrorSoundDisabled.Play();
                mirrorButtonAnimator.SetBool("State", false);
            }
            SetMirrorFromState();
            SetInteractionText();
        }

        public void EnableMirror()
        {
            mirror.SetActive(true);
        }

        public void DisableMirror()
        {
            mirror.SetActive(false);
        }

        private void SetInteractionText()
        {
            InteractionText = "Mirror is " + (string)((_state == true) ? "ON" : "OFF") + " (local)";
        }

        public void SetMirrorFromState()
        {
            mirror.SetActive(_state);
        }

    }
}