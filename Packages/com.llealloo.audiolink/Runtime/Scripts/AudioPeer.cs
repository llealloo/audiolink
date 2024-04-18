// Modified from: https://github.com/Lakistein/Unity-Audio-Visualizers
#if UNITY_WEBGL
using System.Runtime.InteropServices;
using System;
using UnityEngine;
using Unity.Collections;
using UnityEngine.Rendering;

namespace AudioLink
{

    [RequireComponent(typeof(AudioSource))]
    public class AudioPeer : MonoBehaviour
    {
        const int BAND_8 = 8;
        AudioSource _audioSource;
        public static AudioBand AudioFrequencyBand8 { get; private set; }

        [DllImport("__Internal")]
        private static extern int StartSampling(string name, float duration, int bufferSize);

        [DllImport("__Internal")]
        private static extern bool CloseSampling(string name);

        [DllImport("__Internal")]
        private static extern int GetSamples(string name, float[] freqData, int size);

        void Start()
        {
            _audioSource = GetComponent<AudioSource>();
            AudioFrequencyBand8 = new AudioBand(BandCount.Eight);
            //if starting
            #if UNITY_WEBGL && !UNITY_EDITOR
            StartSampling(name, _audioSource.clip.length, 4096);
            #endif

        }

        void Update()
        {
            if (_audioSource.isPlaying)
            {
                AudioFrequencyBand8.Update((sample) =>
                {
#if UNITY_WEBGL && !UNITY_EDITOR

                StartSampling(name, _audioSource.clip.length, 4096);
                GetSamples(name, sample, sample.Length);

#endif
                });
            }
        }
    }
}
#endif