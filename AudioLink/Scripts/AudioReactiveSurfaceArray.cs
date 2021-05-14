
using UnityEngine;
using System.Collections;
using VRC.SDKBase;

#if UDON
using UdonSharp;
using VRC.Udon;

public class AudioReactiveSurfaceArray : UdonSharpBehaviour
{
	[Header("Children should have AudioReactiveSurface shader applied")]
	[Header("AudioLink Settings")]
    public UdonBehaviour audioLink;
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

    void Start()
    {
    	UpdateChildren();
    }

    public void UpdateChildren()
    {
    	int i = 0;
		foreach (Transform child in transform)
		{
			var mesh = child.GetComponent<MeshRenderer>();
			if (mesh != null)
			{
		        var block = new MaterialPropertyBlock();
		        block.SetFloat("_Delay", (delayStep/128f) * (float)i);
		        block.SetFloat("_Band", (float)band);
		        block.SetFloat("_HueShift", hueShift);
		        block.SetColor("_EmissionColor", HueShift(color, hueStep * (float)i));
		        block.SetFloat("_Emission", intensity);
		        block.SetFloat("_Pulse", pulse);
		        block.SetFloat("_PulseRotation", pulseRotation + (pulseRotationStep * (float)i));
		        mesh.SetPropertyBlock(block);
			}
			i++;
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

#else
public class AudioReactiveSurfaceArray : MonoBehaviour { }
#endif