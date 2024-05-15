using UdonSharp;
using UnityEngine;
using UnityEngine.UI;
using VRC.SDKBase;
using VRC.Udon;

public class teleport : UdonSharpBehaviour
{

    public override void OnPlayerTriggerEnter(VRCPlayerApi player)
    {
        if (player == Networking.LocalPlayer)
        {
            Networking.LocalPlayer.TeleportTo(player.GetPosition() * 1.1f, player.GetRotation());
        }

    }

}
