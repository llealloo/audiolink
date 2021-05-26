using UnityEngine;
using VRC.SDKBase;
using UnityEngine.UI;

namespace VRCAudioLink
{
    #if UDON
        using UdonSharp;
        using VRC.Udon;

        public class GlobalSlider : UdonSharpBehaviour
        {
            [UdonSynced]
            private float syncedValue;
            private float localValue;
            private bool deserializing;
            private Slider slider;
            private VRCPlayerApi localPlayer;

            private void Start()
            {
                slider = transform.GetComponent<Slider>();
                localPlayer = Networking.LocalPlayer;
                syncedValue = localValue = slider.value;
                deserializing = false;
            }

            public override void OnDeserialization()
            {
                deserializing = true;
                if(!Networking.IsOwner(gameObject))
                {
                    slider.value = syncedValue;
                }
                deserializing = false;
            }

            public override void OnPreSerialization()
            {
                syncedValue = localValue;
            }

            public void SlideUpdate()
            {
                if (!Networking.IsOwner(gameObject) && !deserializing)
                    Networking.SetOwner(localPlayer, gameObject);
                localValue = syncedValue = slider.value;
            }
        }
    #else
        public class GlobalSlider : MonoBehaviour
        {
        }
    #endif
}