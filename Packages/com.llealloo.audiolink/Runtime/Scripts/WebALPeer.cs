using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

#if UNITY_WEBGL
namespace AudioLink
{
    public class WebALPeer : MonoBehaviour
    {
        const int SAMPLES_COUNT = 4096;
        private float[] _waveformSamplesLeft, _waveformSamplesRight;

        public WebALPeer()
        {
            _waveformSamplesLeft = new float[SAMPLES_COUNT];
            _waveformSamplesRight = new float[SAMPLES_COUNT];
        }

        public float[] GetWaveformLeft()
        {
            return _waveformSamplesLeft;
        }

        public float[] GetWaveformRight()
        {
            return _waveformSamplesRight;
        }

        public void SyncLeft(Action<float[]> FetchSamplesLeft)
        {
            FetchSamplesLeft(_waveformSamplesLeft);
        }

        public void SyncRight(Action<float[]> FetchSamplesRight)
        {
            FetchSamplesRight(_waveformSamplesRight);
        }

    }
}
#endif
