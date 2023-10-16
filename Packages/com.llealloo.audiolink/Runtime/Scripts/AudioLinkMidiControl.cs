#if UDONSHARP
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

namespace AudioLink
{

    [UdonBehaviourSyncMode(BehaviourSyncMode.None)]
    public class AudioLinkMidiControl : UdonSharpBehaviour
    {
        public AudioLinkController _audioLinkController;
        public int _midiChannel;
        public bool _allowMidi;

        public bool _debugMidi;

        public override void MidiNoteOn(int channel, int key, int value) {

            

            // Check On Midi
            if (_allowMidi && channel == _midiChannel && Networking.IsOwner(_audioLinkController.gameObject) && VRC.SDKBase.Utilities.IsValid(_audioLinkController)) {

                if (VRC.SDKBase.Utilities.IsValid(_audioLinkController.themeColorController)) {

                    ThemeColorController _themeColorController = _audioLinkController.themeColorController;
                
                    switch (key) {

                        case (int)MidiIds.AudioLink:
                        // Enable AudioLink
                        _audioLinkController.powerToggle.isOn = true;
                        break;

                        case (int)MidiIds.AutoGain:
                        // Enable Auto Gain
                        _audioLinkController.autoGainToggle.isOn = true;
                        break;

                        case (int)MidiIds.ColorChord:
                        // Enable Color Chord
                        _themeColorController.themeColorToggle.isOn = true;
                        break;

                        case (int)MidiIds.Reset:
                        // Trigger Controller Reset
                        _audioLinkController.ResetSettings();
                        _themeColorController.ResetThemeColors();
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
            if (_allowMidi && channel == _midiChannel && Networking.IsOwner(_audioLinkController.gameObject) && VRC.SDKBase.Utilities.IsValid(_audioLinkController)) {

                if (VRC.SDKBase.Utilities.IsValid(_audioLinkController.themeColorController)) {

                    ThemeColorController _themeColorController = _audioLinkController.themeColorController;
                    
                    switch (key) {

                        case (int)MidiIds.AudioLink:
                        // Disable AudioLink
                        _audioLinkController.powerToggle.isOn = false;
                        break;

                        case (int)MidiIds.AutoGain:
                        // Disable Auto Gain
                        _audioLinkController.autoGainToggle.isOn = false;
                        break;

                        case (int)MidiIds.ColorChord:
                        // Disable Color Chord
                        _themeColorController.themeColorToggle.isOn = false;
                        break;

                        case (int)MidiIds.Reset:
                        // Trigger Controller Reset
                        _audioLinkController.ResetSettings();
                        _themeColorController.ResetThemeColors();
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
            if (_allowMidi && channel == _midiChannel && Networking.IsOwner(_audioLinkController.gameObject) && VRC.SDKBase.Utilities.IsValid(_audioLinkController)) {

                if (VRC.SDKBase.Utilities.IsValid(_audioLinkController.themeColorController)) {

                    ThemeColorController _themeColorController = _audioLinkController.themeColorController;
                
                    float floatValue = (float)value / 127f;

                    float cutoff = floatValue / 4;
                    
                    switch (key) {

                        case (int)MidiIds.Gain: // 0
                        // Handle Gain change
                        _audioLinkController.gainSlider.value = floatValue * 2;
                        break;

                        case (int)MidiIds.Bass: // 1
                        // Handle Bass change
                        if (VRC.SDKBase.Utilities.IsValid(_audioLinkController.bassSlider)) _audioLinkController.bassSlider.value = floatValue * 2;
                        break;

                        case (int)MidiIds.Treble: // 2
                        // Handle Treble change
                        if (VRC.SDKBase.Utilities.IsValid(_audioLinkController.trebleSlider)) _audioLinkController.trebleSlider.value = floatValue * 2;
                        break;

                        case (int)MidiIds.Length: // 3
                        // Handle Length change
                        _audioLinkController.fadeLengthSlider.value = floatValue;
                        break;

                        case (int)MidiIds.Falloff: // 4 
                        // Handle Falloff change
                        _audioLinkController.fadeExpFalloffSlider.value = floatValue;
                        break;

                        // Band 0

                        case (int)MidiIds.Band0Hue: // 11
                        // Handle Band 0 Hue change
                        _themeColorController.SelectCustomColor0();
                        _themeColorController.sliderHue.value = floatValue;
                        break;

                        case (int)MidiIds.Band0Saturation: // 12
                        // Handle Band 0 Saturation change
                        _themeColorController.SelectCustomColor0();
                        _themeColorController.sliderSaturation.value = floatValue;
                        break;

                        case (int)MidiIds.Band0Value: // 13
                        // Handle Band 0 Value change
                        _themeColorController.SelectCustomColor0();
                        _themeColorController.sliderValue.value = floatValue;
                        break;

                        case (int)MidiIds.Band0Threshold: // 14
                        // Handle Band 0 Threshold change
                        _audioLinkController.threshold0Slider.value = floatValue;
                        break;

                        case (int)MidiIds.Band0: // 15
                        // Handle Band 0 change
                        _audioLinkController.x0Slider.value = cutoff;
                        break;

                        // Band 1

                        case (int)MidiIds.Band1Hue: // 21
                        // Handle Band 1 Hue change
                        _themeColorController.SelectCustomColor1();
                        _themeColorController.sliderHue.value = floatValue;
                        break;

                        case (int)MidiIds.Band1Saturation: // 22
                        // Handle Band 1 Saturation change
                        _themeColorController.SelectCustomColor1();
                        _themeColorController.sliderSaturation.value = floatValue;
                        break;

                        case (int)MidiIds.Band1Value: // 23
                        // Handle Band 1 Value change
                        _themeColorController.SelectCustomColor1();
                        _themeColorController.sliderValue.value = floatValue;
                        break;

                        case (int)MidiIds.Band1Threshold: // 24
                        // Handle Band 1 Threshold change
                        _audioLinkController.threshold1Slider.value = floatValue;
                        break;

                        case (int)MidiIds.Band1: // 25
                        // Handle Band 1 change
                        _audioLinkController.x1Slider.value = cutoff + .25f;
                        break;

                        // Band 2

                        case (int)MidiIds.Band2Hue: // 31
                        // Handle Band 2 Hue change
                        _themeColorController.SelectCustomColor2();
                        _themeColorController.sliderHue.value = floatValue;
                        break;

                        case (int)MidiIds.Band2Saturation: // 32
                        // Handle Band 2 Saturation change
                        _themeColorController.SelectCustomColor2();
                        _themeColorController.sliderSaturation.value = floatValue;
                        break;

                        case (int)MidiIds.Band2Value: // 33
                        // Handle Band 2 Value change
                        _themeColorController.SelectCustomColor2();
                        _themeColorController.sliderValue.value = floatValue;
                        break;

                        case (int)MidiIds.Band2Threshold: // 34
                        // Handle Band 2 Threshold change
                        _audioLinkController.threshold2Slider.value = floatValue;
                        break;

                        case (int)MidiIds.Band2: // 35
                        // Handle Band 2 change
                        _audioLinkController.x2Slider.value = cutoff + .5f;
                        break;

                        // Band 3

                        case (int)MidiIds.Band3Hue: // 41
                        // Handle Band 3 Hue change
                        _themeColorController.SelectCustomColor3();
                        _themeColorController.sliderHue.value = floatValue;
                        break;

                        case (int)MidiIds.Band3Saturation: // 42
                        // Handle Band 3 Saturation change
                        _themeColorController.SelectCustomColor3();
                        _themeColorController.sliderSaturation.value = floatValue;
                        break;

                        case (int)MidiIds.Band3Value: // 43
                        // Handle Band 3 Value change
                        _themeColorController.SelectCustomColor3();
                        _themeColorController.sliderValue.value = floatValue;
                        break;

                        case (int)MidiIds.Band3Threshold: // 44
                        // Handle Band 3 Threshold change
                        _audioLinkController.threshold3Slider.value = floatValue;
                        break;

                        case (int)MidiIds.Band3: // 45
                        // Handle Band 3 change
                        _audioLinkController.x3Slider.value = cutoff + .75f;
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
        AudioLink = 7,
        AutoGain = 8,

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
#endif