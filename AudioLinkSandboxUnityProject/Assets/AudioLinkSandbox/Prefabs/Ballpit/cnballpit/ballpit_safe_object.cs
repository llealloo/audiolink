
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

public class ballpit_safe_object : UdonSharpBehaviour
{
	private Collider thisCollider;
    void Start()
    {
        thisCollider = GetComponent<Collider>();
    }

    override public void OnPickup ()
    {
		thisCollider.enabled = false;
    }

    override public void OnDrop()
    {
		thisCollider.enabled = true;
    }
}
