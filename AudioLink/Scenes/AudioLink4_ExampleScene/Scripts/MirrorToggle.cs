
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

public class MirrorToggle : UdonSharpBehaviour
{

    public GameObject mirror;

    void Start()
    {
        
    }

    void Interact()
    {
        mirror.SetActive(!mirror.activeSelf);
    }

}
