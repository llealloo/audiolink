
using UnityEngine;
#if VRC_SDK_VRCSDK2 || VRC_SDK_VRCSDK3
using VRC.SDKBase;
#endif

#if UDON
using UdonSharp;
using VRC.Udon;

public class MirrorToggle : UdonSharpBehaviour
{

    public GameObject mirror;

    void Start()
    {
        
    }

#pragma warning disable 108,114 ///hides inherited member
    void Interact()
#pragma warning restore 108,114
    {
        mirror.SetActive(!mirror.activeSelf);
    }

}

#else
public class MirrorToggle : MonoBehaviour { }
#endif