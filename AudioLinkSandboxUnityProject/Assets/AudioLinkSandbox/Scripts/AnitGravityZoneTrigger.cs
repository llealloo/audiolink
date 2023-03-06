
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

public class AnitGravityZoneTrigger : UdonSharpBehaviour
{
    public UdonBehaviour antiGravityZoneController;

    private VRCPlayerApi _localPlayer;

    void Start()
    {
        _localPlayer = Networking.LocalPlayer;        
    }

    public override void OnPlayerTriggerExit(VRC.SDKBase.VRCPlayerApi player)
    {
        if (player == _localPlayer) antiGravityZoneController.SendCustomEvent("DecreaseTriggerZoneCounter");
    }

    public override void OnPlayerTriggerEnter(VRC.SDKBase.VRCPlayerApi player)
    {
        if (player == _localPlayer) antiGravityZoneController.SendCustomEvent("IncreaseTriggerZoneCounter");
    }
}
