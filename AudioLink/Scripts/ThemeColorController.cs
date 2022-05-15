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

            [UdonSynced] public Color[] customThemeColors = new Color[4]{
                Color.yellow,
                Color.blue,
                Color.red,
                Color.green
            };

            public UdonBehaviour audioLink;  // Initialized by AudioLinkController.


            // Initialized from prefab.
            public Dropdown themeColorDropdown;

            private Color[] _initCustomThemeColors;
            private int _initThemeColorMode; // Initialized from themeColorDropdown.

            private bool processGUIevents = true;
            private VRCPlayerApi localPlayer;

            // A view-controller for customThemeColors
            public Transform extensionCanvas;
            public Slider slider_Hue;
            public Slider slider_Saturation;
            public Slider slider_Value;
            public Transform[] customColorLassos;
            public int customColorIndex = 0;

            private void Start()
            {
                localPlayer = Networking.LocalPlayer;
                _initCustomThemeColors = new Color[4] {
                    customThemeColors[0],
                    customThemeColors[1],
                    customThemeColors[2],
                    customThemeColors[3],
                };

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

            public void SelectCustomColor0() { SelectCustomColorN(0); }
            public void SelectCustomColor1() { SelectCustomColorN(1); }
            public void SelectCustomColor2() { SelectCustomColorN(2); }
            public void SelectCustomColor3() { SelectCustomColorN(3); }
            public void SelectCustomColorN(int n)
            {
                customColorIndex = n;
                UpdateGUI();
            }

            public void OnGUIchange()
            {
                if (!processGUIevents)
                {
                    return;
                }
                if (!Networking.IsOwner(gameObject))
                    Networking.SetOwner(localPlayer, gameObject);

                bool modeChanged = (themeColorMode != themeColorDropdown.value);
                themeColorMode = themeColorDropdown.value;
                customThemeColors[customColorIndex] = Color.HSVToRGB(
                    slider_Hue.value,
                    slider_Saturation.value,
                    slider_Value.value
                );

                if (modeChanged) UpdateGUI();
                UpdateAudioLinkThemeColors();
                RequestSerialization();
            }

            public void ResetThemeColors()
            {
                themeColorMode = _initThemeColorMode;
                for (int i=0; i < 4; ++i)
                {
                    customThemeColors[i] = _initCustomThemeColors[i];
                }
                UpdateGUI();
                UpdateAudioLinkThemeColors();
                RequestSerialization();
            }

            public void UpdateGUI()
            {
                processGUIevents = false;
                themeColorDropdown.value = themeColorMode;

                bool isCustom = themeColorMode == 1;
                extensionCanvas.gameObject.SetActive(isCustom);
                for (int i=0; i < 4; ++i)
                {
                    customColorLassos[i].gameObject.SetActive(
                        i == customColorIndex
                    );
                }

                // update HSV sliders
                float H,S,V;
                Color.RGBToHSV(customThemeColors[customColorIndex], out H, out S, out V);
                slider_Hue.value = H;
                slider_Saturation.value = S;
                slider_Value.value = V;

                processGUIevents = true;
            }

            public void UpdateAudioLinkThemeColors()
            {
                if (audioLink == null) return;
                audioLink.SetProgramVariable("themeColorMode", themeColorMode);
                audioLink.SetProgramVariable("customThemeColor0", customThemeColors[0]);
                audioLink.SetProgramVariable("customThemeColor1", customThemeColors[1]);
                audioLink.SetProgramVariable("customThemeColor2", customThemeColors[2]);
                audioLink.SetProgramVariable("customThemeColor3", customThemeColors[3]);
                audioLink.SendCustomEvent("UpdateThemeColors");
            }
        }
    #else
        public class ThemeColorController : MonoBehaviour
        {
        }
    #endif
}
