
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
    public bool transparency;


    private int _dataIndex;
    private Vector3 _initialPosition;
    private Vector3 _initialRotation;
    private Vector3 _initialScale;
    private Material _material;
    private Color _initialMaterialColor;

    void Start()
    {
        UpdateDataIndex();
        _initialPosition = transform.localPosition;
        _initialRotation = transform.localEulerAngles;
        _initialScale = transform.localScale;
        _material = gameObject.GetComponent<Renderer>().material;
        _initialMaterialColor = _material.color;

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

            if(transparency){
                Color c = new Color(_initialMaterialColor.r, 
                                    _initialMaterialColor.g,
                                    _initialMaterialColor.b,
                                    amplitude);
                _material.SetColor("_Color", c);
            }
        }
    }

    public void UpdateDataIndex()
    {
        _dataIndex = (band * 32) + delay;
    }
}
