
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

public class proximity : UdonSharpBehaviour
{
    public GameObject prev1;
    //public GameObject prev2;

    public override void OnPlayerTriggerEnter(VRCPlayerApi player)
    {
        if (player == Networking.LocalPlayer)
        {
            prev1.SetActive(true);
            //prev2.SetActive(true);
        }
    }
    public override void OnPlayerTriggerExit(VRCPlayerApi player)
    {
        if (player == Networking.LocalPlayer)
        {
            prev1.SetActive(false);
            //prev2.SetActive(false);
        }
    }

}
