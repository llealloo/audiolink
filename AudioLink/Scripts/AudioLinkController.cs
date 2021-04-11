
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;
using UnityEngine.UI;
using System;

public class AudioLinkController : UdonSharpBehaviour
{

	public UdonBehaviour audioLink;
	[Space(10)]
	public Text gainLabel;
	public Slider gainSlider;
	public Text trebleLabel;
	public Slider trebleSlider;
	public Text bassLabel;
	public Slider bassSlider;
	public Text fadeLengthLabel;
	public Slider fadeLengthSlider;
	public Text fadeExpFalloffLabel;
	public Slider fadeExpFalloffSlider;
	public Text x1Label;
	public Slider x1Slider;
	public Text x2Label;
	public Slider x2Slider;
	public Text x3Label;
	public Slider x3Slider;

    private float _initGain;
    private float _initTreble;
    private float _initBass;
    private float _initFadeLength;
    private float _initFadeExpFalloff;
    private float _initX1;
    private float _initX2;
    private float _initX3;

    void Start()
    {
        _initGain = gainSlider.value;
        _initTreble = trebleSlider.value;
        _initBass = bassSlider.value;
        _initFadeLength = fadeLengthSlider.value;
        _initFadeExpFalloff = fadeExpFalloffSlider.value;
        _initX1 = x1Slider.value;
        _initX2 = x2Slider.value;
        _initX3 = x3Slider.value;
		UpdateSettings();
    }

    public void UpdateSettings()
    {
    	gainLabel.text = "Gain: " + ((int)Remap( gainSlider.value, 0f, 2f, 0f, 200f )).ToString() + "%";
    	trebleLabel.text = "Treble: " + ((int)Remap( trebleSlider.value, 0f, 2f, 0f, 200f )).ToString() + "%";
    	bassLabel.text = "Bass: " + ((int)Remap( bassSlider.value, 0f, 2f, 0f, 200f )).ToString() + "%";
    	x1Label.text = "X1: " + ((int)x1Slider.value).ToString() + "hz";
    	x2Label.text = "X2: " + ((int)x2Slider.value).ToString() + "hz";
    	x3Label.text = "X3: " + ((int)x3Slider.value).ToString() + "hz";

    	audioLink.SetProgramVariable("gain", gainSlider.value);
    	audioLink.SetProgramVariable("treble", trebleSlider.value);
    	audioLink.SetProgramVariable("bass", bassSlider.value);
    	audioLink.SetProgramVariable("fadeLength", fadeLengthSlider.value);
    	audioLink.SetProgramVariable("fadeExpFalloff", fadeExpFalloffSlider.value);
    	audioLink.SetProgramVariable("fadeExpFalloff", fadeExpFalloffSlider.value);

    	float[] spectrumBands = (float[])audioLink.GetProgramVariable("spectrumBands");
    	spectrumBands[1] = x1Slider.value;
    	spectrumBands[2] = x2Slider.value;
    	spectrumBands[3] = x3Slider.value;
    	audioLink.SetProgramVariable("spectrumBands", spectrumBands);
    	audioLink.SendCustomEvent("UpdateSettings");
    }

    public void ResetSettings()
    {
        gainSlider.value = _initGain;
        trebleSlider.value = _initTreble;
        bassSlider.value = _initBass;
        fadeLengthSlider.value = _initFadeLength;
        fadeExpFalloffSlider.value = _initFadeExpFalloff;
        x1Slider.value = _initX1;
        x2Slider.value = _initX2;
        x3Slider.value = _initX3;
    }


    private float Remap(float t, float a, float b, float u, float v)
    {
    	return ( (t-a) / (b-a) ) * (v-u) + u;
    }
}
