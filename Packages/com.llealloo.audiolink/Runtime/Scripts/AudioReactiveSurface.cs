using UnityEngine;

namespace VRCAudioLink
{
    #if UDONSHARP
        using UdonSharp;

        public class AudioReactiveSurface : UdonSharpBehaviour
    #else
        public class AudioReactiveSurface : MonoBehaviour
    #endif
        {
            [Header("To use custom mesh, swap mesh in Mesh Filter component above")]
            [Header("AudioLink Settings")]
            public int band;
            [Range(0, 127)]
            public int delay;

            [Header("Reactivity Settings")]
            [Tooltip("Emission driven by amplitude")]
            [ColorUsage(true, true)]
            public Color color;
            [Tooltip("Emission multiplier")]
            public float intensity = 1f;
            [Tooltip("Hue shift driven by amplitude")]
            public float hueShift = 0f;
            [Tooltip("Pulse")]
            public float pulse = 0f;
            [Tooltip("Pulse rotation")]
            public float pulseRotation = 0f;

            #region PropertyIDs

            // ReSharper disable InconsistentNaming
            private int _Delay;
            private int _Band;
            private int _HueShift;
            private int _EmissionColor;
            private int _Emission;
            private int _Pulse;
            private int _PulseRotation;
            // ReSharper restore InconsistentNaming
            
            private void InitIDs()
            {
                _Delay = Shader.PropertyToID("_Delay");
                _Band = Shader.PropertyToID("_Band");
                _HueShift = Shader.PropertyToID("_HueShift");
                _EmissionColor = Shader.PropertyToID("_EmissionColor");
                _Emission = Shader.PropertyToID("_Emission");
                _Pulse = Shader.PropertyToID("_Pulse");
                _PulseRotation = Shader.PropertyToID("_PulseRotation");
            }

            #endregion
            void Start()
            {
                InitIDs();
                UpdateMaterial();
            }

            public void UpdateMaterial()
            {
                var block = new MaterialPropertyBlock();
                var mesh = GetComponent<MeshRenderer>();
                block.SetFloat(_Delay, (float)delay/128f);
                block.SetFloat(_Band, (float)band);
                block.SetFloat(_HueShift, hueShift);
                block.SetColor(_EmissionColor, color);
                block.SetFloat(_Emission, intensity);
                block.SetFloat(_Pulse, pulse);
                block.SetFloat(_PulseRotation, pulseRotation);
                mesh.SetPropertyBlock(block);
            }
        }
}