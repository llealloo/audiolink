
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

namespace AudioLinkWorld
{
    public class ZoneEnabler : UdonSharpBehaviour
    {
        public GameObject[] gameObjects;
        public bool startingState;
        private VRCPlayerApi _localPlayer;

        void Start()
        {
            _localPlayer = Networking.LocalPlayer;
            if (startingState)
            {
                EnableObjects();
            }
            else
            {
                // protect for Udon initialization
                SendCustomEventDelayedSeconds("DisableObjects", 3.0f);
            }
        }

        public override void OnPlayerTriggerExit(VRC.SDKBase.VRCPlayerApi player)
        {
            if (player == _localPlayer) DisableObjects();
        }

        public override void OnPlayerTriggerEnter(VRC.SDKBase.VRCPlayerApi player)
        {
            if (player == _localPlayer) EnableObjects();
        }

        public void EnableObjects()
        {
            foreach (GameObject obj in gameObjects)
            {
                obj.SetActive(true);
            }
        }

        public void DisableObjects()
        {
            foreach (GameObject obj in gameObjects)
            {
                obj.SetActive(false);
            }
        }
    }
}
