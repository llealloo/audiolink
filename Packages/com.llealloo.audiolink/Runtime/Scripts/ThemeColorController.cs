using UnityEngine;
#if VRC_SDK_VRCSDK2 || VRC_SDK_VRCSDK3
using VRC.SDKBase;
#endif
using UnityEngine.UI;

namespace VRCAudioLink
{
    #if UDONSHARP
        using UdonSharp;

        [UdonBehaviourSyncMode(BehaviourSyncMode.Manual)]
        public class ThemeColorController : UdonSharpBehaviour
    #else
        public class ThemeColorController : MonoBehaviour
    #endif
        {
            #if UDONSHARP
            [UdonSynced] 
            #endif
            private int themeColorMode;

            #if UDONSHARP
            [UdonSynced] 
            #endif
            public Color[] customThemeColors = new Color[4]{
                Color.yellow,
                Color.blue,
                Color.red,
                Color.green
            };

            public AudioLink audioLink;  // Initialized by AudioLinkController.


            // Initialized from prefab.
            public Dropdown themeColorDropdown;

            private Color[] _initCustomThemeColors;
            private int _initThemeColorMode; // Initialized from themeColorDropdown.

            private bool processGUIevents = true;
            
            #if UDONSHARP
            private VRCPlayerApi localPlayer;
            #endif
            
            // A view-controller for customThemeColors
            public Transform extensionCanvas;
            public Slider slider_Hue;
            public Slider slider_Saturation;
            public Slider slider_Value;
            public Transform[] customColorLassos;
            public int customColorIndex = 0;

            private void Start()
            {
                #if UDONSHARP
                localPlayer = Networking.LocalPlayer;
                #endif
                
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
                #if UDONSHARP
                if (Networking.IsOwner(gameObject))
                    RequestSerialization();
                #endif
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
                #if UDONSHARP
                if (!Networking.IsOwner(gameObject))
                    Networking.SetOwner(localPlayer, gameObject);
                #endif
                bool modeChanged = (themeColorMode != themeColorDropdown.value);
                themeColorMode = themeColorDropdown.value;
                customThemeColors[customColorIndex] = Color.HSVToRGB(
                    slider_Hue.value,
                    slider_Saturation.value,
                    slider_Value.value
                );

                if (modeChanged) UpdateGUI();
                UpdateAudioLinkThemeColors();
                #if UDONSHARP
                RequestSerialization();
                #endif
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
                #if UDONSHARP
                RequestSerialization();
                #endif
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
                audioLink.themeColorMode = themeColorMode;
                audioLink.customThemeColor0 = customThemeColors[0];
                audioLink.customThemeColor1 = customThemeColors[1];
                audioLink.customThemeColor2 = customThemeColors[2];
                audioLink.customThemeColor3 = customThemeColors[3];
                audioLink.UpdateThemeColors();
            }
        }
}
