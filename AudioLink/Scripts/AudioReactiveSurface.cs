
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

public class AudioReactiveSurface : UdonSharpBehaviour
{


    public UdonBehaviour audioLink;
    public int band;
    [Range(0, 31)]
    public int delay;
    [ColorUsage(true, true)]
    public Color color;
    public float hueShift;

    void Start()
    {
        //var camera = audioLink.GetComponent<Camera>();
        //var audioTexture = camera.targetTexture;
        var spectrumBands = (float[])audioLink.GetProgramVariable("spectrumBands");
        var block = new MaterialPropertyBlock();
        var mesh = GetComponent<MeshRenderer>();
        block.SetFloat("_Delay", (float)delay);
        block.SetFloat("_Band", (float)band);
        block.SetFloat("_NumBands", spectrumBands.Length);
        block.SetFloat("_AudioHueShift", hueShift);
        block.SetColor("_AudioColor", color);
        //block.SetTexture("_AudioTexture", audioTexture);
        mesh.SetPropertyBlock(block);
    }
}
