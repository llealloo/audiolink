#if UDONSHARP || PVR_CCK_WORLDS
using UnityEngine.UI;
#if UDONSHARP
using UdonSharp;
using VRC.SDKBase;
#elif PVR_CCK_WORLDS
using PVR.CCK.Worlds.PSharp;
#endif

namespace AudioLink
{
#if UDONSHARP
    [UdonBehaviourSyncMode(BehaviourSyncMode.Manual)]
    public class GlobalToggle : UdonSharpBehaviour
    {
        [UdonSynced]
#elif PVR_CCK_WORLDS
    public class GlobalToggle : PSharpBehaviour
    {
        [PSharpSynced]
#endif
        private bool syncedValue;
        private bool deserializing;
        private Toggle toggle;
#if UDONSHARP
        private VRCPlayerApi localPlayer;
#elif PVR_CCK_WORLDS
        private PSharpPlayer localPlayer;
#endif
        private void Start()
        {
            toggle = transform.GetComponent<Toggle>();
#if UDONSHARP
            localPlayer = Networking.LocalPlayer;
#endif
            syncedValue = toggle.isOn;
            deserializing = false;

#if UDONSHARP
            if (Networking.IsOwner(gameObject))
                RequestSerialization();
#endif
        }

#if PVR_CCK_WORLDS // Use OnNetworkReady on PVR to get local player since its null in start
		public override void OnNetworkReady()
		{
			localPlayer = PSharpPlayer.LocalPlayer;
		}
#endif

		public override void OnDeserialization()
        {
            if (!enabled) return;

            deserializing = true;
            toggle.isOn = syncedValue;
            deserializing = false;
        }

        public void ToggleUpdate()
        {
            if (!enabled) return;
            
            if (toggle == null)
                return;
            if (deserializing)
                return;
#if UDONSHARP
            if (!Networking.IsOwner(gameObject))
                Networking.SetOwner(localPlayer, gameObject);
#elif PVR_CCK_WORLDS
            if (!IsOwner)
                PSharpNetworking.SetOwner(localPlayer, gameObject);
#endif
            syncedValue = toggle.isOn;
#if UDONSHARP
            RequestSerialization();
#endif
        }
    }
}
#endif
