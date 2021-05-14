
using UnityEngine;
using VRC.SDKBase;

#if UDON
using UdonSharp;
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

#else
public class MirrorToggle : MonoBehaviour { }
#endif