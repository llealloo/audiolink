
using UnityEngine;
using VRC.SDKBase;
using UnityEngine.UI;
using System;

#if UDON
using UdonSharp;
using VRC.Udon;

public class AudioLinkController : UdonSharpBehaviour
{

    public UdonBehaviour audioLink;
    [Space(10)]
    public Material audioSpectrumDisplay;
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
    public Slider x1Slider;
    public Slider x2Slider;
    public Slider x3Slider;
    public Slider threshold0Slider;
    public Slider threshold1Slider;
    public Slider threshold2Slider;
    public Slider threshold3Slider;

    private float _initGain;
    private float _initTreble;
    private float _initBass;
    private float _initFadeLength;
    private float _initFadeExpFalloff;
    private float _initX1;
    private float _initX2;
    private float _initX3;
    private float _initThreshold0;
    private float _initThreshold1;
    private float _initThreshold2;
    private float _initThreshold3;

    private Vector3 _initThreshold0SliderPosition;
    private Vector3 _initThreshold1SliderPosition;
    private Vector3 _initThreshold2SliderPosition;
    private Vector3 _initThreshold3SliderPosition;
 
    #if UNITY_EDITOR
    void Update()
    {
        UpdateSettings();
    }
    #endif

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
        _initThreshold0 = threshold0Slider.value;
        _initThreshold1 = threshold1Slider.value;
        _initThreshold2 = threshold2Slider.value;
        _initThreshold3 = threshold3Slider.value;
        _initThreshold0SliderPosition = threshold0Slider.transform.localPosition;
        _initThreshold1SliderPosition = threshold1Slider.transform.localPosition;
        _initThreshold2SliderPosition = threshold2Slider.transform.localPosition;
        _initThreshold3SliderPosition = threshold3Slider.transform.localPosition;

        UpdateSettings();
    }

    public void UpdateSettings()
    {
        // Update labels
        gainLabel.text = "Gain: " + ((int)Remap( gainSlider.value, 0f, 2f, 0f, 200f )).ToString() + "%";
        trebleLabel.text = "Treble: " + ((int)Remap( trebleSlider.value, 0f, 2f, 0f, 200f )).ToString() + "%";
        bassLabel.text = "Bass: " + ((int)Remap( bassSlider.value, 0f, 2f, 0f, 200f )).ToString() + "%";

        // Update 
        threshold0Slider.transform.localPosition = new Vector3(Remap(x1Slider.value / 2f, 0f, 1f, -349f, 349f), _initThreshold0SliderPosition.y, 0f);
        threshold1Slider.transform.localPosition = new Vector3(Remap((x1Slider.value + x2Slider.value) / 2f, 0f, 1f, -349f, 349f), _initThreshold1SliderPosition.y, 0f);
        threshold2Slider.transform.localPosition = new Vector3(Remap((x2Slider.value + x3Slider.value) / 2f, 0f, 1f, -349f, 349f), _initThreshold2SliderPosition.y, 0f);
        threshold3Slider.transform.localPosition = new Vector3(Remap((x3Slider.value + 1f) / 2f, 0f, 1f, -349f, 349f), _initThreshold3SliderPosition.y, 0f);

        // General settings
        audioLink.SetProgramVariable("gain", gainSlider.value);
        audioLink.SetProgramVariable("treble", trebleSlider.value);
        audioLink.SetProgramVariable("bass", bassSlider.value);
        audioLink.SetProgramVariable("fadeLength", fadeLengthSlider.value);
        audioLink.SetProgramVariable("fadeExpFalloff", fadeExpFalloffSlider.value);
        audioLink.SetProgramVariable("fadeExpFalloff", fadeExpFalloffSlider.value);

        // Crossover settings
        audioLink.SetProgramVariable("x1", x1Slider.value);
        audioLink.SetProgramVariable("x2", x2Slider.value);
        audioLink.SetProgramVariable("x3", x3Slider.value);
        audioLink.SetProgramVariable("threshold0", threshold0Slider.value);
        audioLink.SetProgramVariable("threshold1", threshold1Slider.value);
        audioLink.SetProgramVariable("threshold2", threshold2Slider.value);
        audioLink.SetProgramVariable("threshold3", threshold3Slider.value);
        audioSpectrumDisplay.SetFloat("_X1", x1Slider.value);
        audioSpectrumDisplay.SetFloat("_X2", x2Slider.value);
        audioSpectrumDisplay.SetFloat("_X3", x3Slider.value);
        audioSpectrumDisplay.SetFloat("_Threshold0", threshold0Slider.value);
        audioSpectrumDisplay.SetFloat("_Threshold1", threshold1Slider.value);
        audioSpectrumDisplay.SetFloat("_Threshold2", threshold2Slider.value);
        audioSpectrumDisplay.SetFloat("_Threshold3", threshold3Slider.value);

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
        threshold0Slider.value = _initThreshold0;
        threshold1Slider.value = _initThreshold1;
        threshold2Slider.value = _initThreshold2;
        threshold3Slider.value = _initThreshold3;
    }


    private float Remap(float t, float a, float b, float u, float v)
    {
        return ( (t-a) / (b-a) ) * (v-u) + u;
    }
}
#else
public class AudioLinkController2 : MonoBehaviour
{
}
#endif


/*#if !COMPILER_UDONSHARP// && UNITY_EDITOR
[ExecuteInEditMode]
public class AudioLinkControllerEditUpdater : MonoBehaviour
{
    void Update()
    {
        Debug.Log("test");
    }
}
#endif

*/







// && UDON
//[CustomEditor(typeof(AudioLinkController))]

 
        //UdonSharpBehaviour thisGuy = GetUdonSharpComponent<UdonSharpBehaviour>();
        //Debug.Log(thisGuy);