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
    public class GlobalSlider : UdonSharpBehaviour
    {
        [UdonSynced]
#elif PVR_CCK_WORLDS
    public class GlobalSlider : PSharpBehaviour
    {
        [PSharpSynced]
#endif
        private float syncedValue;
        private bool deserializing;
        private Slider slider;
#if UDONSHARP
        private VRCPlayerApi localPlayer;
#elif PVR_CCK_WORLDS
        private PSharpPlayer localPlayer;
#endif
        private void Start()
        {
            slider = transform.GetComponent<Slider>();
#if UDONSHARP
            localPlayer = Networking.LocalPlayer;
#endif
            syncedValue = slider.value;
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
            slider.value = syncedValue;
            deserializing = false;
        }

        public void SlideUpdate()
        {
            if (!enabled) return;

            if (slider == null)
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
            syncedValue = slider.value;
#if UDONSHARP
            RequestSerialization();
#endif
        }
    }
}
#endif
