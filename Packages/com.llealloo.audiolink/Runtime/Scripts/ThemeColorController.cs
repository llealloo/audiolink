using UnityEngine;
using UnityEngine.UI;

namespace AudioLink
{
#if UDONSHARP
    using UdonSharp;

    using VRC.SDKBase;

    [UdonBehaviourSyncMode(BehaviourSyncMode.Manual)]
    public class ThemeColorController : UdonSharpBehaviour
#else
    public class ThemeColorController : MonoBehaviour
#endif
    {
        [UdonSynced] private int _themeColorMode;

        [UdonSynced]
        public Color[] customThemeColors = {
                Color.yellow,
                Color.blue,
                Color.red,
                Color.green
            };

        public AudioLink audioLink; // Initialized by AudioLinkController.

        public Material audioLinkUI; // Initialized by AudioLinkController.

        private Color[] _initCustomThemeColors;
        private int _initThemeColorMode;

        private bool _processGUIEvents = true;

#if UDONSHARP
        private VRCPlayerApi localPlayer;
#endif

        // A view-controller for customThemeColors
        public Slider sliderHue;
        public Slider sliderSaturation;
        public Slider sliderValue;
        public Toggle themeColorToggle;
        public int customColorIndex = 0;

        private void Start()
        {
#if UDONSHARP
            localPlayer = Networking.LocalPlayer;
#endif

            _initCustomThemeColors = new[] {
                customThemeColors[0],
                customThemeColors[1],
                customThemeColors[2],
                customThemeColors[3],
            };
        }

#if UDONSHARP
        public override void OnDeserialization()
        {
            UpdateGUI();
            UpdateAudioLinkThemeColors();
        }
#endif

        public void SelectCustomColor0() { SelectCustomColorN(0); }
        public void SelectCustomColor1() { SelectCustomColorN(1); }
        public void SelectCustomColor2() { SelectCustomColorN(2); }
        public void SelectCustomColor3() { SelectCustomColorN(3); }
        public void SelectCustomColorN(int n)
        {
            customColorIndex = n;
            UpdateGUI();
        }

        public void ToggleThemeColorMode()
        {
            _themeColorMode = themeColorToggle.isOn ? 0 : 1;
            UpdateGUI();
            UpdateAudioLinkThemeColors();
#if UDONSHARP
            RequestSerialization();
#endif
        }

        public void ForceThemeColorMode()
        {
            if (!_processGUIEvents)
            {
                return;
            }

            themeColorToggle.isOn = false;
        }

        public void OnGUIchange()
        {
            if (!_processGUIEvents)
            {
                return;
            }
#if UDONSHARP
            if (!Networking.IsOwner(gameObject))
                Networking.SetOwner(localPlayer, gameObject);
#endif
            customThemeColors[customColorIndex] = Color.HSVToRGB(
                sliderHue.value,
                sliderSaturation.value,
                sliderValue.value
            );

            UpdateGUI();
            UpdateAudioLinkThemeColors();
#if UDONSHARP
            RequestSerialization();
#endif
        }

        public void ResetThemeColors()
        {
            _themeColorMode = _initThemeColorMode;
            for (int i = 0; i < 4; ++i)
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
            _processGUIEvents = false;

            bool isCustom = _themeColorMode == 1;

            // update HSV sliders
            float h, s, v;
            Color.RGBToHSV(customThemeColors[customColorIndex], out h, out s, out v);
            sliderHue.value = h;
            sliderSaturation.value = s;
            sliderValue.value = v;

            // update toggle
            themeColorToggle.isOn = _themeColorMode == 0;

            if (audioLinkUI != null)
            {
                audioLinkUI.SetInt("_ThemeColorMode", _themeColorMode);
                audioLinkUI.SetInt("_SelectedColor", customColorIndex);
                audioLinkUI.SetFloat("_Hue", h);
                audioLinkUI.SetFloat("_Saturation", s);
                audioLinkUI.SetFloat("_Value", v);

                audioLinkUI.SetColor("_CustomColor0", customThemeColors[0]);
                audioLinkUI.SetColor("_CustomColor1", customThemeColors[1]);
                audioLinkUI.SetColor("_CustomColor2", customThemeColors[2]);
                audioLinkUI.SetColor("_CustomColor3", customThemeColors[3]);
            }

            _processGUIEvents = true;
        }

        public void InitializeAudioLinkThemeColors()
        {
            if (audioLink == null) return;

            customThemeColors[0] = audioLink.customThemeColor0;
            customThemeColors[1] = audioLink.customThemeColor1;
            customThemeColors[2] = audioLink.customThemeColor2;
            customThemeColors[3] = audioLink.customThemeColor3;

            _initCustomThemeColors = new[] {
                customThemeColors[0],
                customThemeColors[1],
                customThemeColors[2],
                customThemeColors[3],
            };

            _initThemeColorMode = audioLink.themeColorMode;
            _themeColorMode = _initThemeColorMode;

            UpdateGUI();
            UpdateAudioLinkThemeColors();
#if UDONSHARP
            if (Networking.IsOwner(gameObject))
                RequestSerialization();
#endif
        }

        public void UpdateAudioLinkThemeColors()
        {
            if (audioLink == null) return;
            audioLink.themeColorMode = _themeColorMode;
            audioLink.customThemeColor0 = customThemeColors[0];
            audioLink.customThemeColor1 = customThemeColors[1];
            audioLink.customThemeColor2 = customThemeColors[2];
            audioLink.customThemeColor3 = customThemeColors[3];
            audioLink.UpdateThemeColors();
        }
    }
}
