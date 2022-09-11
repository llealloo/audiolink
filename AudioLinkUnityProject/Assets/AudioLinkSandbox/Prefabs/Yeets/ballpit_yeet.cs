
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

	public class ballpit_yeet : UdonSharpBehaviour
	{
		float LastYeet;
		public float YeetIntensity = 10;
		
		public GameObject Spawn;
		void Start()
		{
			LastYeet = 0;
		}

		public override void OnPlayerTriggerStay(VRCPlayerApi player)
		{
			OnPlayerTriggerEnter( player );
		}
		
		public override void OnPlayerTriggerEnter(VRCPlayerApi player)
		{
			if( Time.timeSinceLevelLoad - LastYeet > 0.2 && Vector3.Distance( transform.position, Spawn.transform.position ) > 7 )
			{
				Vector3 yeetvector = transform.TransformDirection( Vector3.forward ) * -YeetIntensity;
				player.SetVelocity( yeetvector );
				LastYeet = Time.timeSinceLevelLoad;
			}
		}
		
		public void OnTriggerEnter(Collider collide)
		{
			Vector3 yeetvector = transform.TransformDirection( Vector3.forward ) * -YeetIntensity;
			if( Utilities.IsValid( collide ) )
			{
				GameObject go = collide.gameObject;
				if( Utilities.IsValid( go ) )
				{
					Rigidbody rb = collide.gameObject.GetComponent<Rigidbody>();
					if( Utilities.IsValid( rb ) )
					{
						rb.velocity = yeetvector;
					}
				}
			}
		}
}