
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

public class YeetResetButton : UdonSharpBehaviour
{

    public Animator portSizeController;
    public AudioSource yeetResetSound;
    public UdonBehaviour[] yeets;

    private Vector3 _startPosition;

    void Start()
    {
        _startPosition = transform.localPosition;
    }

    void Update()
    {

        transform.localPosition = new Vector3(_startPosition.x, _startPosition.y, portSizeController.GetFloat("LocalBoundX"));
    }

    public override void Interact()
    {
        foreach (UdonBehaviour yeet in yeets)
        {
            yeetResetSound.Play();
            yeet.SendCustomNetworkEvent(VRC.Udon.Common.Interfaces.NetworkEventTarget.Owner, "Respawn");
        }
    }
}
