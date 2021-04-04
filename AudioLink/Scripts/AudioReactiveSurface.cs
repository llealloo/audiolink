
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

public class AudioReactiveSurface : UdonSharpBehaviour
{


	[SerializeField]
	private UdonBehaviour audioLink;
    [SerializeField]
	private float band;
	[SerializeField]
	private float delay;
    [SerializeField][ColorUsage(true, true)]
    private Color color;

    void Start()
    {
    	//var camera = audioLink.GetComponent<Camera>();
    	//var audioTexture = camera.targetTexture;
        var spectrumBands = (float[])audioLink.GetProgramVariable("spectrumBands");
        var block = new MaterialPropertyBlock();
        var mesh = GetComponent<MeshRenderer>();
        block.SetFloat("_Delay", delay);
        block.SetFloat("_Band", band);
        block.SetFloat("_NumBands", spectrumBands.Length);
        block.SetColor("_AudioColor", color);
        //block.SetTexture("_AudioTexture", audioTexture);
        mesh.SetPropertyBlock(block);
    }
}
