
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

namespace AudioLink
{

    [UdonBehaviourSyncMode(BehaviourSyncMode.None)]
    public class AudioLinkMidiControl : UdonSharpBehaviour
    {
        public AudioLinkController _AudioLinkController;
        public bool allowMidi;
        public int midiChannel;

        public bool _debugMidi;

        void Start()
        {
            
        }

        public override void MidiNoteOn(int channel, int key, int value) {

            

            // Check On Midi
            if (allowMidi && channel == midiChannel && Networking.IsOwner(_AudioLinkController.gameObject) && VRC.SDKBase.Utilities.IsValid(_AudioLinkController)) {

                if (VRC.SDKBase.Utilities.IsValid(_AudioLinkController.themeColorController)) {

                    ThemeColorController _ThemeColorController = _AudioLinkController.themeColorController;
                
                    switch (key) {

                        case (int)MidiIds.ColorChord:
                        // Enable Color Chord
                        _ThemeColorController.themeColorDropdown.value = 0;
                        break;

                        case (int)MidiIds.Reset:
                        // Trigger Controller Reset
                        _AudioLinkController.ResetSettings();
                        _ThemeColorController.ResetThemeColors();
                        break;

                        default:
                        // No-op
                        break;

                    }

                }

            }

            if (_debugMidi) {

                //Debug.Log(channel);
                Debug.Log(key);
                Debug.Log(value);

            }

        }

        public override void MidiNoteOff(int channel, int key, int value) {

            // Check Off Midi
            if (allowMidi && channel == midiChannel && Networking.IsOwner(_AudioLinkController.gameObject) && VRC.SDKBase.Utilities.IsValid(_AudioLinkController)) {

                if (VRC.SDKBase.Utilities.IsValid(_AudioLinkController.themeColorController)) {

                    ThemeColorController _ThemeColorController = _AudioLinkController.themeColorController;
                    
                    switch (key) {

                        case (int)MidiIds.ColorChord:
                        // Disable Color Chord
                        _ThemeColorController.themeColorDropdown.value = 1;
                        break;

                        case (int)MidiIds.Reset:
                        // Trigger Controller Reset
                        _AudioLinkController.ResetSettings();
                        _ThemeColorController.ResetThemeColors();
                        break;

                        default:
                        // No-op
                        break;

                    }

                }

            }
            
            if (_debugMidi) {

                //Debug.Log(channel);
                Debug.Log(key);
                Debug.Log(value);

            }

        }

        public override void MidiControlChange(int channel, int key, int value) {

            // Check Change Midi
            if (allowMidi && channel == midiChannel && Networking.IsOwner(_AudioLinkController.gameObject) && VRC.SDKBase.Utilities.IsValid(_AudioLinkController)) {

                if (VRC.SDKBase.Utilities.IsValid(_AudioLinkController.themeColorController)) {

                    ThemeColorController _ThemeColorController = _AudioLinkController.themeColorController;
                
                    float floatValue = (float)value / 127f;

                    float cutoff = floatValue / 4;
                    
                    switch (key) {

                        case (int)MidiIds.Gain: // 0
                        // Handle Gain change
                        _AudioLinkController.gainSlider.value = floatValue * 2;
                        break;

                        case (int)MidiIds.Bass: // 1
                        // Handle Bass change
                        _AudioLinkController.bassSlider.value = floatValue * 2;
                        break;

                        case (int)MidiIds.Treble: // 2
                        // Handle Treble change
                        _AudioLinkController.trebleSlider.value = floatValue * 2;
                        break;

                        case (int)MidiIds.Length: // 3
                        // Handle Length change
                        _AudioLinkController.fadeLengthSlider.value = floatValue;
                        break;

                        case (int)MidiIds.Falloff: // 4 
                        // Handle Falloff change
                        _AudioLinkController.fadeExpFalloffSlider.value = floatValue;
                        break;

                        // Band 0

                        case (int)MidiIds.Band0Hue: // 11
                        // Handle Band 0 Hue change
                        _ThemeColorController.themeColorDropdown.value = 1;
                        _ThemeColorController.SelectCustomColor0();
                        _ThemeColorController.sliderHue.value = floatValue;
                        break;

                        case (int)MidiIds.Band0Saturation: // 12
                        // Handle Band 0 Saturation change
                        _ThemeColorController.themeColorDropdown.value = 1;
                        _ThemeColorController.SelectCustomColor0();
                        _ThemeColorController.sliderSaturation.value = floatValue;
                        break;

                        case (int)MidiIds.Band0Value: // 13
                        // Handle Band 0 Value change
                        _ThemeColorController.themeColorDropdown.value = 1;
                        _ThemeColorController.SelectCustomColor0();
                        _ThemeColorController.sliderValue.value = floatValue;
                        break;

                        case (int)MidiIds.Band0Threshold: // 14
                        // Handle Band 0 Threshold change
                        _AudioLinkController.threshold0Slider.value = floatValue;
                        break;

                        case (int)MidiIds.Band0: // 15
                        // Handle Band 0 change
                        _AudioLinkController.x0Slider.value = cutoff;
                        break;

                        // Band 1

                        case (int)MidiIds.Band1Hue: // 21
                        // Handle Band 1 Hue change
                        _ThemeColorController.themeColorDropdown.value = 1;
                        _ThemeColorController.SelectCustomColor1();
                        _ThemeColorController.sliderHue.value = floatValue;
                        break;

                        case (int)MidiIds.Band1Saturation: // 22
                        // Handle Band 1 Saturation change
                        _ThemeColorController.themeColorDropdown.value = 1;
                        _ThemeColorController.SelectCustomColor1();
                        _ThemeColorController.sliderSaturation.value = floatValue;
                        break;

                        case (int)MidiIds.Band1Value: // 23
                        // Handle Band 1 Value change
                        _ThemeColorController.themeColorDropdown.value = 1;
                        _ThemeColorController.SelectCustomColor1();
                        _ThemeColorController.sliderValue.value = floatValue;
                        break;

                        case (int)MidiIds.Band1Threshold: // 24
                        // Handle Band 1 Threshold change
                        _AudioLinkController.threshold1Slider.value = floatValue;
                        break;

                        case (int)MidiIds.Band1: // 25
                        // Handle Band 1 change
                        _AudioLinkController.x1Slider.value = cutoff + .25f;
                        break;

                        // Band 2

                        case (int)MidiIds.Band2Hue: // 31
                        // Handle Band 2 Hue change
                        _ThemeColorController.themeColorDropdown.value = 1;
                        _ThemeColorController.SelectCustomColor2();
                        _ThemeColorController.sliderHue.value = floatValue;
                        break;

                        case (int)MidiIds.Band2Saturation: // 32
                        // Handle Band 2 Saturation change
                        _ThemeColorController.themeColorDropdown.value = 1;
                        _ThemeColorController.SelectCustomColor2();
                        _ThemeColorController.sliderSaturation.value = floatValue;
                        break;

                        case (int)MidiIds.Band2Value: // 33
                        // Handle Band 2 Value change
                        _ThemeColorController.themeColorDropdown.value = 1;
                        _ThemeColorController.SelectCustomColor2();
                        _ThemeColorController.sliderValue.value = floatValue;
                        break;

                        case (int)MidiIds.Band2Threshold: // 34
                        // Handle Band 2 Threshold change
                        _AudioLinkController.threshold2Slider.value = floatValue;
                        break;

                        case (int)MidiIds.Band2: // 35
                        // Handle Band 2 change
                        _AudioLinkController.x2Slider.value = cutoff + .5f;
                        break;

                        // Band 3

                        case (int)MidiIds.Band3Hue: // 41
                        // Handle Band 3 Hue change
                        _ThemeColorController.themeColorDropdown.value = 1;
                        _ThemeColorController.SelectCustomColor3();
                        _ThemeColorController.sliderHue.value = floatValue;
                        break;

                        case (int)MidiIds.Band3Saturation: // 42
                        // Handle Band 3 Saturation change
                        _ThemeColorController.themeColorDropdown.value = 1;
                        _ThemeColorController.SelectCustomColor3();
                        _ThemeColorController.sliderSaturation.value = floatValue;
                        break;

                        case (int)MidiIds.Band3Value: // 43
                        // Handle Band 3 Value change
                        _ThemeColorController.themeColorDropdown.value = 1;
                        _ThemeColorController.SelectCustomColor3();
                        _ThemeColorController.sliderValue.value = floatValue;
                        break;

                        case (int)MidiIds.Band3Threshold: // 44
                        // Handle Band 3 Threshold change
                        _AudioLinkController.threshold3Slider.value = floatValue;
                        break;

                        case (int)MidiIds.Band3: // 45
                        // Handle Band 3 change
                        _AudioLinkController.x3Slider.value = cutoff + .75f;
                        break;

                        default:
                        // No-op
                        break;

                    }

                }

            }
            
            if (_debugMidi) {

                //Debug.Log(channel);
                Debug.Log(key);
                Debug.Log(value);

            }

        }
    }

    enum MidiIds {
        Gain = 0,
        Bass = 1,
        Treble = 2,
        Length = 3,
        Falloff = 4,
        ColorChord = 5,
        Reset = 6,

        Band0Hue = 11,
        Band0Saturation = 12,
        Band0Value = 13,
        Band0Threshold = 14,
        Band0 = 15,

        Band1Hue = 21,
        Band1Saturation = 22,
        Band1Value = 23,
        Band1Threshold = 24,
        Band1 = 25,

        Band2Hue = 31,
        Band2Saturation = 32,
        Band2Value = 33,
        Band2Threshold = 34,
        Band2 = 35,

        Band3Hue = 41,
        Band3Saturation = 42,
        Band3Value = 43,
        Band3Threshold = 44,
        Band3 = 45

    }
}