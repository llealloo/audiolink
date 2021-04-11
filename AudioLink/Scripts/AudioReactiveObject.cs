
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;
using System;
using System.Collections;

public class AudioReactiveObject : UdonSharpBehaviour
{
    public UdonBehaviour audioLink;
    public int band;
    [Range(0, 31)]
    public int delay;
    public Vector3 position;
    public Vector3 rotation;
    public Vector3 scale;


    private int _dataIndex;
    private Vector3 _initialPosition;
    private Vector3 _initialRotation;
    private Vector3 _initialScale;

    void Start()
    {
        UpdateDataIndex();
        _initialPosition = transform.localPosition;
        _initialRotation = transform.localEulerAngles;
        _initialScale = transform.localScale;

    }

    void Update()
    {
        Color[] audioData = (Color[])audioLink.GetProgramVariable("audioData");
        if (audioData.Length != 0)      // check for audioLink initialization
        {
            float amplitude = audioData[_dataIndex].grayscale;
            
            transform.localPosition = _initialPosition + (position * amplitude);
            transform.localEulerAngles = _initialRotation + (rotation * amplitude);
        
            //transform.localScale *= scale;
        }
    }

    public void UpdateDataIndex()
    {
        _dataIndex = (band * 32) + delay;
    }
}
