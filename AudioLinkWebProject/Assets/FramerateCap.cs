#if !UDONSHARP
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
#if AUDIOLINK_V1
using AudioLink;
#endif

public class FramerateCap : MonoBehaviour
{
    #if AUDIOLINK_V1
    public AudioLink.AudioLink audioLink;
    #endif
    public int limit = 60;
    
    void Start()
    {
        Application.targetFrameRate = limit;
        #if AUDIOLINK_V1
        if (audioLink != null) audioLink.audioRenderTexture.updatePeriod = 1 / (float)limit;
        #endif
    }
}
#endif