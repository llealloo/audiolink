
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;


namespace AudioLinkWorld
{
    public class GameObjectArrayToggle : UdonSharpBehaviour
    {

        public GameObject[] objects;
        public GameObject toggleInterfaceEnabled;
        public GameObject toggleInterfaceDisabled;
        public AudioSource toggleSoundEnabled;
        public AudioSource toggleSoundDisabled;
        public Animator toggleButtonAnimator;
        public string toggleText;

        private bool _state;

        void Start()
        {
            _state = true;
            toggleButtonAnimator.SetBool("State", true);
        }

        public override void Interact()
        {
            _state = !_state;
            foreach (GameObject obj in objects)
            {
                obj.SetActive(!obj.activeSelf);
            }
            InteractionText = "Toggle is " + (string)((_state == true) ? "ON" : "OFF") + " (local)";
            toggleInterfaceEnabled.SetActive(_state);
            toggleInterfaceDisabled.SetActive(!_state);
            if (_state)
            {
                toggleSoundEnabled.Play();
                toggleButtonAnimator.SetBool("State", true);
            } else {
                toggleSoundDisabled.Play();
                toggleButtonAnimator.SetBool("State", false);
            }
            InteractionText = toggleText + (string)((_state == true) ? "ON" : "OFF") + " (local)";
        }

    }
}
