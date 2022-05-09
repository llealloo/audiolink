using UnityEngine;
#if VRC_SDK_VRCSDK2 || VRC_SDK_VRCSDK3
using VRC.SDKBase;
#endif
using UnityEngine.UI;

namespace VRCAudioLink
{
    #if UDON
        using UdonSharp;
        using VRC.Udon;

        [UdonBehaviourSyncMode(BehaviourSyncMode.Manual)]
        public class ThemeColorController : UdonSharpBehaviour
        {
            [UdonSynced] private int themeColorMode;

            [UdonSynced] public Color customThemeColor0 = Color.yellow;
            [UdonSynced] public Color customThemeColor1 = Color.blue;
            [UdonSynced] public Color customThemeColor2 = Color.red;
            [UdonSynced] public Color customThemeColor3 = Color.green;

            public UdonBehaviour audioLink;  // Initialized by AudioLinkController.


            // Initialized from prefab.
            public Dropdown themeColorDropdown;
            private Color _initCustomThemeColor0;
            private Color _initCustomThemeColor1;
            private Color _initCustomThemeColor2;
            private Color _initCustomThemeColor3;

            private int _initThemeColorMode; // Initialized from themeColorDropdown.

            private bool ignoreGUIevents = false;
            private VRCPlayerApi localPlayer;


            private Slider slider;


            private void Start()
            {
                localPlayer = Networking.LocalPlayer;
                _initCustomThemeColor0 = customThemeColor0;
                _initCustomThemeColor1 = customThemeColor1;
                _initCustomThemeColor2 = customThemeColor2;
                _initCustomThemeColor3 = customThemeColor3;
                _initThemeColorMode = themeColorDropdown.value;
                themeColorMode = _initThemeColorMode;

                UpdateGUI();
                UpdateAudioLinkThemeColors();
                if (Networking.IsOwner(gameObject))
                    RequestSerialization();
            }

            public override void OnDeserialization()
            {
                UpdateGUI();
                UpdateAudioLinkThemeColors();
            }

            public void SelectCustomColor0() { Debug.Log("SelectCustomColor0"); }
            public void SelectCustomColor1() { Debug.Log("SelectCustomColor1"); }
            public void SelectCustomColor2() { Debug.Log("SelectCustomColor2"); }
            public void SelectCustomColor3() { Debug.Log("SelectCustomColor3"); }

            public void OnGUIchange()
            {
                Debug.Log("OnGUIchange");
                if (ignoreGUIevents)
                    return;
                if (!Networking.IsOwner(gameObject))
                    Networking.SetOwner(localPlayer, gameObject);
                themeColorMode = themeColorDropdown.value;

                // TODO: Update colors from HSV sliders
                UpdateAudioLinkThemeColors();
                RequestSerialization();
            }

            public void ResetThemeColors() {
                themeColorMode = _initThemeColorMode;
                customThemeColor0 = _initCustomThemeColor0;
                customThemeColor1 = _initCustomThemeColor1;
                customThemeColor2 = _initCustomThemeColor2;
                customThemeColor3 = _initCustomThemeColor3;
                UpdateGUI();
                UpdateAudioLinkThemeColors();
                RequestSerialization();
            }

            public void UpdateGUI() {
                ignoreGUIevents = false;
                themeColorDropdown.value = themeColorMode;
                // TODO: update HSV sliders
                ignoreGUIevents = true;
            }

            public void UpdateAudioLinkThemeColors() {
                if (audioLink == null) return;
                audioLink.SetProgramVariable("themeColorMode", themeColorMode);
                audioLink.SetProgramVariable("customThemeColor0", customThemeColor0);
                audioLink.SetProgramVariable("customThemeColor1", customThemeColor1);
                audioLink.SetProgramVariable("customThemeColor2", customThemeColor2);
                audioLink.SetProgramVariable("customThemeColor3", customThemeColor3);
                audioLink.SendCustomEvent("UpdateThemeColors");
            }
        }
    #else
        public class ThemeColorController : MonoBehaviour
        {
        }
    #endif
}
