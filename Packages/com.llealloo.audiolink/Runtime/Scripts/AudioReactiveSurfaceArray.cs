﻿using UnityEngine;

namespace VRCAudioLink
{
    #if UDONSHARP
        using UdonSharp;
        public class AudioReactiveSurfaceArray : UdonSharpBehaviour
    #else
        public class AudioReactiveSurfaceArray : MonoBehaviour
    #endif
        {
            [Header("Children should have AudioReactiveSurface shader applied")]
            [Header("AudioLink Settings")]
            public int band;

            [Header("Group Settings (Applied equally to all children)")]
            [Tooltip("Applied equally to all children: Emission driven by amplitude")]
            [ColorUsage(true, true)]
            public Color color;
            [Tooltip("Applied equally to all children: Emission multiplier")]
            public float intensity = 1f;
            [Tooltip("Applied equally to all children: Hue shift driven by amplitude")]
            public float hueShift = 0f;
            [Tooltip("Applied equally to all children: Pulse")]
            public float pulse = 0f;
            [Tooltip("Applied equally to all children: Pulse rotation")]
            public float pulseRotation = 0f;

            [Header("Stepper Settings (Applied incrementally to all children)")]
            [Tooltip("Incrementally applied to children: Delay based on 128 delay values. First child's delay will be 0.")]
            public float delayStep = 1f;
            [Tooltip("Incrementally applied to children: Hue step based on 0-1 hue values. Very small values recommended: 0.01 or less.")]
            public float hueStep = 0f;
            [Tooltip("Incrementally applied to children: Pulse rotation based on 360 degree turn")]
            public float pulseRotationStep = 0f;
            [Tooltip("If enabled, recursively step for children of children like a tree with branches. Otherwise only step for 1st level children")]
            public bool childrenOfChildren = false;

            private Renderer[] _childRenderers;

            void Start()
            {
                _childRenderers = transform.GetComponentsInChildren<Renderer>(true);
                UpdateChildren();
            }

            public void UpdateChildren()
            {
                
                foreach (Renderer renderer in _childRenderers)
                {
                    Transform child = renderer.transform;
                    int index = child.GetSiblingIndex();

                    // Recursively apply step to children of children like a tree with branches, otherwise ignore
                    if(childrenOfChildren)
                    {
                        Transform pointer = child.parent;
                        while (!pointer.Equals(transform))
                        {
                            index += pointer.GetSiblingIndex() + 1;
                            pointer = pointer.parent;
                        }
                    } else {
                        if (!child.parent.Equals(transform)) continue;
                    }
                    var block = new MaterialPropertyBlock();
                    block.SetFloat("_Delay", (delayStep/128f) * (float)index);
                    block.SetFloat("_Band", (float)band);
                    block.SetFloat("_HueShift", hueShift);
                    block.SetColor("_EmissionColor", HueShift(color, hueStep * (float)index));
                    block.SetFloat("_Emission", intensity);
                    block.SetFloat("_Pulse", pulse);
                    block.SetFloat("_PulseRotation", pulseRotation + (pulseRotationStep * (float)index));
                    renderer.SetPropertyBlock(block);
                }
            }

            private Color HueShift(Color color, float hueShiftAmount)
            {
                float h, s, v;
                Color.RGBToHSV(color, out h, out s, out v);
                h = (h + hueShiftAmount) - Mathf.Floor(h + hueShiftAmount);
                return Color.HSVToRGB(h, s, v);
            }
        }
}