// Modified from: https://github.com/Lakistein/Unity-Audio-Visualizers
#if UNITY_WEBGL
using System;
using UnityEngine;
using Unity.Collections;
using UnityEngine.Rendering;

namespace AudioLink
{
    public enum BandCount
    {
        Eight = 8,
        SixtyFour = 64
    }

    public class AudioBand
    {
        readonly int BAND_COUNT;
        const int SAMPLES_COUNT = 4096;
        readonly BandCount BandCountEnum;

        private float[] _originalSamplesLeft,
                        _bandFrequency,
                        _bandFrequencyNormilized,
                        _bandFrequencyHighest,
                        _bandFrequencyBuffer,
                        _bufferDecrease,
                        _bandFrequencyBufferNormilized;

        private float _amplitudeHighest = 5,
                      _bufferDecreaseMin = 0.005f,
                      _bufferDecreaseMultiplier = 1.2f,
                      _amplitudeBuffer,
                      _amplitude,
                      _audioProfile = 1;

        public AudioBand(BandCount bandCount)
        {
            BAND_COUNT = (int)bandCount;
            BandCountEnum = bandCount;
            _originalSamplesLeft = new float[SAMPLES_COUNT];
            _bandFrequency = new float[BAND_COUNT];
            _bandFrequencyNormilized = new float[BAND_COUNT];
            _bandFrequencyHighest = new float[BAND_COUNT];
            _bandFrequencyBuffer = new float[BAND_COUNT];
            _bufferDecrease = new float[BAND_COUNT];
            _bandFrequencyBufferNormilized = new float[BAND_COUNT];
            AudioProfile();
        }

        public float GetFrequencyBand(int i, bool buffered = false)
        {
            return buffered ? _bandFrequencyBuffer[i] : _bandFrequency[i];
        }

        public float GetAudioBand(int i, bool buffered = false)
        {
            return buffered ? _bandFrequencyBufferNormilized[i] : _bandFrequencyNormilized[i];
        }

        public float GetAmplitude(bool buffered = false)
        {
            return buffered ? _amplitudeBuffer : _amplitude;
        }

        public float[] GetWaveform() {
            return _originalSamplesLeft;
        }

        public void Update(Action<float[]> GetSamples)
        {
            GetSamples(_originalSamplesLeft);
            UpdateFrequencyBands();
            UpdateBuffer();
            UpdateFrequencyBandsNormilized();
            UpdateAmplitude();
        }

        private void UpdateFrequencyBands()
        {
            switch (BandCountEnum)
            {
                case BandCount.Eight:
                    UpdateFrequencyBands8();
                    break;
                case BandCount.SixtyFour:
                    UpdateFrequencyBands64();
                    break;
                default:
                    break;
            }
        }

        private void UpdateFrequencyBands8()
        {
            int count = 0;
            for (int i = 0; i < BAND_COUNT; i++)
            {
                float average = 0;
                int sampleCount = (int)Math.Pow(2, i) * 2;
                if (i == BAND_COUNT - 1)
                {
                    sampleCount += 2;
                }
                for (int j = 0; j < sampleCount; j++)
                {
                    average += _originalSamplesLeft[count] * (count + 1);
                    count++;
                }

                average /= count;
                _bandFrequency[i] = average * 10;
            }
        }

        private void UpdateFrequencyBands64()
        {
            int count = 0;
            int sampleCount = 1;
            int power = 0;

            for (int i = 0; i < BAND_COUNT; i++)
            {
                float average = 0;
                if(i == 16 || i == 32 || i == 40 || i == 48 || i == 56)
                {
                    power++;
                    sampleCount = (int)Math.Pow(2, power);
                    if(power == 3)
                    {
                        sampleCount -= 2;
                    }
                }
                
                for (int j = 0; j < sampleCount; j++)
                {
                    average += _originalSamplesLeft[count] * (count + 1);
                    count++;
                }

                average /= count;
                _bandFrequency[i] = average * 80;
            }
        }

        private void UpdateFrequencyBandsNormilized()
        {
            for (int i = 0; i < BAND_COUNT; i++)
            {
                if (_bandFrequency[i] > _bandFrequencyHighest[i])
                {
                    _bandFrequencyHighest[i] = _bandFrequency[i];
                }
                _bandFrequencyNormilized[i] = _bandFrequency[i] / _bandFrequencyHighest[i];
                _bandFrequencyBufferNormilized[i] = _bandFrequencyBuffer[i] / _bandFrequencyHighest[i];
            }
        }

        private void AudioProfile()
        {
            for (int i = 0; i < BAND_COUNT; i++)
            {
                _bandFrequencyHighest[i] = _audioProfile;
            }
        }

        private void UpdateAmplitude()
        {
            float currAmplitude = 0;
            float currAmplitudeBuffer = 0;
            for (int i = 0; i < BAND_COUNT; i++)
            {
                currAmplitude += _bandFrequencyNormilized[i];
                currAmplitudeBuffer += _bandFrequencyBufferNormilized[i];
            }
            if (currAmplitude > _amplitudeHighest)
            {
                _amplitudeHighest = currAmplitude;
            }
            _amplitude = currAmplitude / _amplitudeHighest;
            _amplitudeBuffer = currAmplitudeBuffer / _amplitudeHighest;
        }

        private void UpdateBuffer()
        {
            for (int i = 0; i < BAND_COUNT; i++)
            {
                if (_bandFrequency[i] > _bandFrequencyBuffer[i])
                {
                    _bandFrequencyBuffer[i] = _bandFrequency[i];
                    _bufferDecrease[i] = _bufferDecreaseMin;
                }
                if (_bandFrequency[i] < _bandFrequencyBuffer[i])
                {
                    _bandFrequencyBuffer[i] -= _bufferDecrease[i];
                    _bufferDecrease[i] *= _bufferDecreaseMultiplier;
                }
            }
        }
    }
}
#endif