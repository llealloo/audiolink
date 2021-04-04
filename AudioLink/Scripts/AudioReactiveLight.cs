
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;
using System;

public class AudioReactiveLight : UdonSharpBehaviour
{
	[SerializeField]
	private UdonBehaviour audioLink;
	[SerializeField]
	private int band;
	[SerializeField]
	private int delay;
	[SerializeField]
	private float intensityMultiplier = 1f;

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
