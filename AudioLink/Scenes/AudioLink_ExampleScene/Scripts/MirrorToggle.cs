
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

    public override void Interact()
    {
        mirror.SetActive(!mirror.activeSelf);
    }

}

#else
public class MirrorToggle : MonoBehaviour { }
#endif