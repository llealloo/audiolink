
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;
using System;

public class AudioReactiveLight : UdonSharpBehaviour
{
	public UdonBehaviour audioLink;
	public int band;
	[Range(0, 31)]
	public int delay;
	public float intensityMultiplier = 1f;

	private Light _light;
	private int _dataIndex;

    void Start()
    {
    	_light = transform.GetComponent<Light>();
    	_dataIndex = (band * 32) + delay;
    }

    void Update()
    {
    	Color[] audioData = (Color[])audioLink.GetProgramVariable("audioData");
    	if(audioData.Length != 0)		// check for audioLink initialization
    	{
    		_light.intensity = audioData[_dataIndex].grayscale * intensityMultiplier;
    	}
    }
}
