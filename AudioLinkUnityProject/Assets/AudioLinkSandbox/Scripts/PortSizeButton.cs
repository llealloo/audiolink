
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

public class PortSizeButton : UdonSharpBehaviour
{

    public UdonBehaviour portSizeController;

    public override void Interact()
    {
        portSizeController.SendCustomEvent("InteractToggle");
    }
}
