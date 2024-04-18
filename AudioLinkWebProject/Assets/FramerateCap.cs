using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using AudioLink;

public class FramerateCap : MonoBehaviour
{
    public AudioLink.AudioLink audioLink;
    public int limit = 90;
    // Start is called before the first frame update
    void Start()
    {
        Application.targetFrameRate = limit;
        if (audioLink != null) audioLink.audioRenderTexture.updatePeriod = 1 / (float)limit;
    }
}
