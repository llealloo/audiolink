
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

public class FanBlowPlayer : UdonSharpBehaviour
{
	public float BlowIntensity = 3.0f;
	//public GameObject Spawn;
	
	private Vector3 GetYeetVector()
	{
		return transform.TransformDirection( Vector3.up ) * -.5f;
	}
	
	public override void OnPlayerTriggerStay(VRCPlayerApi player)
	{
		OnPlayerTriggerEnter( player );
	}
	
	public override void OnPlayerTriggerEnter(VRCPlayerApi player)
	{
		//if( Vector3.Distance( transform.position, Spawn.transform.position ) > 7 )
		if( Utilities.IsValid( player ) )
		{
			player.SetVelocity( player.GetVelocity()*.996f + (GetYeetVector() + ( transform.position - player.GetPosition() ) * .1f) * BlowIntensity*8.0f*Time.deltaTime ); // Apply correction
		}
	}
	
		public void OnTriggerStay(Collider collide )
		{
			OnTriggerEnter( collide );
		}
	
		public void OnTriggerEnter(Collider collide)
		{
			if( Utilities.IsValid( collide ) )
			{
				GameObject go = collide.gameObject;
				if( Utilities.IsValid( go ) )
				{
					Rigidbody rb = collide.gameObject.GetComponent<Rigidbody>();
					if( Utilities.IsValid( rb ) )
					{
						rb.velocity += ((GetYeetVector()*.996f + ( transform.position - rb.position ) * .1f)) * BlowIntensity*6.0f*Time.deltaTime; // Apply correction
					}
				}
			}
		}
}
