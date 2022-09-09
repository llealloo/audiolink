
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

namespace Airtime.Player.Attachment
{
    [UdonBehaviourSyncMode(BehaviourSyncMode.None)]
    public class LocalTrackingAttachment : UdonSharpBehaviour
    {
        public bool attached = false;
        public VRCPlayerApi.TrackingDataType point;

        private VRCPlayerApi localPlayer;
        private bool localPlayerCached = false;

        public void Start()
        {
            localPlayer = Networking.LocalPlayer;
            if (localPlayer != null)
            {
                localPlayerCached = true;
            }
        }

        public void Update()
        {
            if (localPlayerCached && Utilities.IsValid(localPlayer))
            {
                if (attached)
                {
                    VRCPlayerApi.TrackingData data = localPlayer.GetTrackingData(point);
                    transform.position = data.position;
                    transform.rotation = data.rotation;
                }
            }
        }
    }
}
