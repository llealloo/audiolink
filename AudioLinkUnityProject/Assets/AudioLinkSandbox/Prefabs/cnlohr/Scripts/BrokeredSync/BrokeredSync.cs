// Brokered object sync for fast object sync over a ton of objects.
// (C) 2021 CNLohr feel free to distribute under the MIT/x11 license.

using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;
using VRC.Udon.Common;
using VRC.Udon.Common.Interfaces;
using System;


#if !COMPILER_UDONSHARP && UNITY_EDITOR
using VRC.SDKBase.Editor.BuildPipeline;
using UnityEditor;
using UdonSharpEditor;
using System.Collections.Immutable;
#endif

namespace BrokeredUpdates
{
	[UdonBehaviourSyncMode(BehaviourSyncMode.Manual)]
	public class BrokeredSync : UdonSharpBehaviour
	{
		[UdonSynced] private Vector3	syncPosition = new Vector3( 0, 0, 0 );
		[UdonSynced] private bool	   syncMoving;
		[UdonSynced] private Quaternion syncRotation;

		private Vector3				 lastSyncPosition;
		private Quaternion			  lastSyncRotation;

		private float fTimeStill;

		public bool bDebug;
		public bool bHeld;
		public bool bDisableColliderOnGrab = true;
		public float fResetWhenHittingY = -1000;
		public float UpdateEveryPeriod = 0.05f;
		public float Snappyness = 0.001f;
		
		private bool wasMoving;
		private Collider thisCollider;
		private Rigidbody thisRigidBody;
		public BrokeredUpdateManager brokeredUpdateManager;
		private bool masterMoving;
		private bool firstUpdateSlave;
		private float fDeltaMasterSendUpdateTime;
		
		[HideInInspector]
		public bool bUseGravityOnRelease;
		[HideInInspector]
		public bool bKinematicOnRelease;
		
		private Vector3			   resetPosition;
		private Quaternion			resetQuaternion;

		public void _LogBlockState()
		{
			Debug.Log( $"SYNCMARK\t{gameObject.name}\t{transform.localPosition.x:F3},{transform.localPosition.y:F3},{transform.localPosition.z:F3}\t{transform.localRotation.x:F3},{transform.localRotation.y:F3},{transform.localRotation.z:F3},{transform.localRotation.w:F3}" );
		}


		void Start()
		{
			brokeredUpdateManager._RegisterSlowObjectSyncUpdate( this );
			brokeredUpdateManager._RegisterSnailUpdate( this );

			thisRigidBody = GetComponent<Rigidbody>();
			thisCollider = GetComponent<Collider>();

			resetPosition = transform.localPosition;
			resetQuaternion = transform.localRotation;
			
			if( Networking.IsMaster )
			{
				// We previously would do this but it would freeze the master from messing with stuff.
				// XXX TODO: See if you can cycle through players and prevent them from losing sync and reverting locations.
				
				//Let's try ownerless to begin
				//Networking.SetOwner( Networking.LocalPlayer, gameObject );
				//syncPosition = transform.localPosition;
				//syncRotation = transform.localRotation;
				//syncMoving = false;
				
				// This makes things more stable, by initializting everything
				// but, this also makes it so the master can't touch anything for a bit.
				// RequestSerialization();
			}
			else
			{
				firstUpdateSlave = true;
				
				// For whatever reason, we've checked but the sync'd variables are not
				// here populated on Start.  Don't trust their data.
			}

			if( Utilities.IsValid( thisRigidBody ) )
			{
				bUseGravityOnRelease = thisRigidBody.useGravity;
				bKinematicOnRelease = thisRigidBody.isKinematic;
			}
			else
			{
				Debug.Log( $"CNL WARNING: Rigid Body Invalid for object {gameObject.name}" );
				bUseGravityOnRelease = false;
				bKinematicOnRelease = true;
			}
			wasMoving = false;
			masterMoving = false;
			bHeld = false;
		}

		private void SendUpdateSystemAsMaster()
		{
			syncPosition = transform.localPosition;
			syncRotation = transform.localRotation;
			RequestSerialization();
		}

		private void _CheckReset()
		{
			if( transform.localPosition.y < fResetWhenHittingY )
			{
				if( Networking.GetOwner( gameObject ) == Networking.LocalPlayer )
				{
					transform.localPosition = resetPosition;
					transform.localRotation = resetQuaternion;

					if( Utilities.IsValid( thisRigidBody ) )
					{
						thisRigidBody.velocity = new Vector3( 0, 0, 0 );
						thisRigidBody.angularVelocity = new Vector3( 0, 0, 0 );
					}
					SendUpdateSystemAsMaster();
				}
			}
		}
		
		public void _SnailUpdate()
		{
			_CheckReset();
			//SLOWLY, over the course of many seconds get clients to resend
			//all their objects if they're master.  **THIS SHOULD NOT BE REQUIRED**
			//but something with photon is just broken.
			if( !masterMoving )
			{
				if( Networking.GetOwner( gameObject ) == Networking.LocalPlayer )
				{
					SendUpdateSystemAsMaster();
				}
			}
		}

		public void _SlowObjectSyncUpdate()
		{
			// In Udon, when loading, sometimes later joining clients miss OnDeserialization().
			// This function will force all of the client's blocks to eventually line up to where
			// they're supposed to be.
			
			// It seems buggy when you cause motion to happen but Unity is unaware of it.
			
			// But, don't accidentally move it.  (note: syncPosition.magnitude > 0 is a not great way...
			if( !masterMoving )
			{
				if( Networking.GetOwner( gameObject ) == Networking.LocalPlayer )
				{
					// If we are the last owner, update the sync positions.
					// XXX TODO: This is not well tested XXX TEST MORE.
					// The syncPosition.magnitude clause is to make sure we don'tested
					// do this on start.
					if( ( ( syncPosition - transform.localPosition ).magnitude > 0.001 || 
						Quaternion.Angle( syncRotation, transform.localRotation) > .1 ) &&
						syncPosition.magnitude > 0 )
					{
						SendUpdateSystemAsMaster();
						
						//Also pause object.
						//if( Utilities.IsValid( thisRigidBody ) )
						//{
						//	thisRigidBody.velocity = new Vector3( 0, 0, 0 );
						//	thisRigidBody.Sleep();
						//}
					}
				}
				else
				{
					if( syncPosition.magnitude > 0 ) OnDeserialization();
				}

				if( !syncMoving )
				{
					_ReturnToQuescentState();
				}
			}
		}
		
		private void _ReturnToQuescentState()
		{
			// Make sure eventually, things become how the quescent state is.
			// XXX TODO: This needs to happen when someone steals your ball
			// then they release it.  The stealer then does not normally hit this
			// code through the normal path. ->> Once that is resolved, try removing
			// this code.
			if( Utilities.IsValid( thisRigidBody ) )
			{
				thisRigidBody.useGravity = bUseGravityOnRelease;
				thisRigidBody.isKinematic = bKinematicOnRelease;
				if( bKinematicOnRelease )
				{
					thisRigidBody.velocity = new Vector3( 0, 0, 0 );
					thisRigidBody.Sleep();
				}
			}
		}

		public void _SendMasterMove()
		{
			syncPosition = transform.localPosition;
			syncRotation = transform.localRotation;
			
			// If moving less than 1mm or .1 degree over a second (or less if no rigid body), freeze.
			if( ( syncPosition - lastSyncPosition ).magnitude < 0.001 && 
				 Quaternion.Angle( syncRotation, lastSyncRotation) < .1 &&
				 !bHeld )
			{
				fTimeStill += Time.deltaTime;
				
				// Make sure we're still for a while before we actually disable the object.
				if( fTimeStill > 1 || !Utilities.IsValid( thisRigidBody ) || thisRigidBody.isKinematic )
				{
					// Stop Updating
					brokeredUpdateManager._UnregisterSubscription( this );
					
					// Do this so if we were moving SUPER slowly, we actually stop.
					if( Utilities.IsValid( thisRigidBody ) )
					{
						thisRigidBody.velocity = new Vector3( 0, 0, 0 );
						thisRigidBody.Sleep();
					}

					syncMoving = false;
					if( bDisableColliderOnGrab ) thisCollider.enabled = true;
					masterMoving = false;
				}
			}
			else
			{
				fTimeStill = 0;
			}
		
			lastSyncPosition = syncPosition;
			lastSyncRotation = syncRotation;
		
			//We are being moved.
			RequestSerialization();
		}

		override public void OnPickup ()
		{
			if( bDisableColliderOnGrab ) thisCollider.enabled = false;
			brokeredUpdateManager._UnregisterSubscription( this ); // In case it was already subscribed.
			brokeredUpdateManager._RegisterSubscription( this );
			Networking.SetOwner( Networking.LocalPlayer, gameObject );
			fDeltaMasterSendUpdateTime = 10;
			syncMoving = true;
			masterMoving = true;
			bHeld = true;
		}

		// We don't use Drop here. We want to see if the object has actually stopped moving.
		// But, even if it's paused and it's being held, don't stop.
		override public void OnDrop()
		{
			bHeld = false;
			if( bDisableColliderOnGrab ) thisCollider.enabled = true;
		}
		
		public override void OnDeserialization()
		{
			// This happens if it was stolen.  We should release it.
			if( masterMoving && Networking.GetOwner( gameObject ) != Networking.LocalPlayer )
			{
				Debug.Log( $"Received OnDeserialization() after master masterMoving on {gameObject.name}" );
				masterMoving = false;
				brokeredUpdateManager._UnregisterSubscription( this );
				syncMoving = false;
				if( bDisableColliderOnGrab ) thisCollider.enabled = true;
				OnDrop();
				_ReturnToQuescentState();
				return;
			}

			if( firstUpdateSlave )
			{
				transform.localPosition = syncPosition;
				transform.localRotation = syncRotation; 
				firstUpdateSlave = false;
			}
			
			if( bDebug )
			{
				MeshRenderer mr = GetComponent<MeshRenderer>();
				Vector4 col = mr.material.GetVector( "_Color" );
				col.z = ( col.z + 0.01f ) % 1;
				mr.material.SetVector( "_Color", col );
			}
			
			if( !syncMoving )
			{
				//We were released before we got the update.
				transform.localPosition = syncPosition;
				transform.localRotation = syncRotation;
				wasMoving = false;
				brokeredUpdateManager._UnregisterSubscription( this );
				_ReturnToQuescentState();
			}

			if( !masterMoving )
			{
				if( !wasMoving && syncMoving )
				{
					// If we start being moved by the master, then disable gravity.
					if( Utilities.IsValid( thisRigidBody ) )
					{
						//XXX XXX TODO This is temporarily commented out because sometimes this breaks.
						//KNOWN ISSUE: But it appears like it's with VRC.  So, we compromise.  We can't
						//change the gravity or kinematic after we start, without changing this.
						//bUseGravityOnRelease = thisRigidBody.useGravity;
						//bKinematicOnRelease =  thisRigidBody.isKinematic;
						thisRigidBody.useGravity = false;
						thisRigidBody.isKinematic = true;
					}
					brokeredUpdateManager._RegisterSubscription( this );
					wasMoving = true;
				}
			}
			else
			{
				if( Networking.GetOwner( gameObject ) != Networking.LocalPlayer )
				{
					//Master is moving AND another player has it.
					((VRC_Pickup)(gameObject.GetComponent(typeof(VRC_Pickup)))).Drop();
				}
			}
		}
		
		public void _BrokeredUpdate()
		{
			_CheckReset();

			if( masterMoving )
			{
				if( bDebug )
				{
					MeshRenderer mr = GetComponent<MeshRenderer>();
					Vector4 col = mr.material.GetVector( "_Color" );
					col.x = ( col.x + 0.01f ) % 1;
					mr.material.SetVector( "_Color", col );
				}
				fDeltaMasterSendUpdateTime += Time.deltaTime;
				
				// Don't send location more than configurable FPS.
				if( fDeltaMasterSendUpdateTime > UpdateEveryPeriod )
				{
					_SendMasterMove();
					fDeltaMasterSendUpdateTime = 0.0f;
				}
			}
			else
			{
				//Still moving, make motion slacky.
				
				if( syncMoving )
				{

					if( bDebug )
					{
						MeshRenderer mr = GetComponent<MeshRenderer>();
						Vector4 col = mr.material.GetVector( "_Color" );
						col.y = ( col.y + 0.01f ) % 1;
						mr.material.SetVector( "_Color", col );
					}

					float iir = Mathf.Pow( Snappyness, Time.deltaTime );
					float inviir = 1.0f - iir;
					transform.localPosition = transform.localPosition * iir + syncPosition * inviir;
					transform.localRotation = Quaternion.Slerp( transform.localRotation, syncRotation, inviir ); 
					
					wasMoving = true;
				}
				else if( wasMoving )
				{
					if( !syncMoving )
					{
						//We were released.
						transform.localPosition = syncPosition;
						transform.localRotation = syncRotation;
						wasMoving = false;
						_ReturnToQuescentState();
						brokeredUpdateManager._UnregisterSubscription( this );
					}
				}
			}
		}
	}
}


#if !COMPILER_UDONSHARP && UNITY_EDITOR
namespace UdonSharp
{
	public class UdonSharpBuildChecks_BrokeredSync : IVRCSDKBuildRequestedCallback
	{
		public int callbackOrder => -1;

		public bool OnBuildRequested(VRCSDKRequestedBuildType requestedBuildType)
		{
			if (requestedBuildType == VRCSDKRequestedBuildType.Avatar) return true;
			foreach( UnityEngine.GameObject go in GameObject.FindObjectsOfType(typeof(GameObject)) as UnityEngine.GameObject[] )
			{
				foreach( BrokeredUpdates.BrokeredSync b in go.GetUdonSharpComponentsInChildren< BrokeredUpdates.BrokeredSync >() )
				{
					b.UpdateProxy();
					if( b.brokeredUpdateManager == null )
					{
						Debug.LogError($"[<color=#FF00FF>BrokeredSync</color>] Missing brokeredUpdateManager reference on {b.gameObject.name}");
						typeof(UnityEditor.SceneView).GetMethod("ShowNotification", System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Static).Invoke(null, new object[] { $"BrokeredSync missing brokeredUpdateManager reference on {b.gameObject.name}" });
						return false;				
					}
				}
			}
			return true;
		}
	}
}

namespace BrokeredUpdates
{
	[CustomEditor(typeof(BrokeredUpdates.BrokeredSync))]
	public class BrokeredUpdatesBrokeredSyncEditor : Editor
	{
		public override void OnInspectorGUI()
		{
			if (UdonSharpGUI.DrawDefaultUdonSharpBehaviourHeader(target)) return;
			EditorGUILayout.Space();
			int ct = 0;
			if (GUILayout.Button(new GUIContent("Attach brokeredUpdateManager to all Brokered Sync objects.", "Automatically finds all Brokered Sync objects and attaches the manager.")))
			{
				UnityEngine.Object [] gos = GameObject.FindObjectsOfType(typeof(GameObject)); 

				BrokeredUpdateManager manager = null;
				foreach( UnityEngine.GameObject go in GameObject.FindObjectsOfType(typeof(GameObject)) as UnityEngine.GameObject[] )
				{
					foreach( BrokeredUpdateManager b in go.GetUdonSharpComponentsInChildren<BrokeredUpdateManager>() )
					{
						manager = b;
					}
				}
				if( manager == null )
				{
					Debug.LogError($"[<color=#FF00FF>UdonSharp</color>] Could not find a BrokeredUpdateManager. Did you add the prefab to your scene?");
					return;
				}

				foreach( UnityEngine.GameObject go in GameObject.FindObjectsOfType(typeof(GameObject)) as UnityEngine.GameObject[] )
				{
					foreach( BrokeredSync b in go.GetUdonSharpComponentsInChildren< BrokeredSync >() )
					{
						b.UpdateProxy();
						if( b.brokeredUpdateManager == null )
						{
							Debug.Log( $"Attaching to {b.gameObject.name}" );
							//https://github.com/MerlinVR/UdonSharp/wiki/Editor-Scripting#non-inspector-editor-scripts
							b.brokeredUpdateManager = manager;
							b.ApplyProxyModifications();
							ct++;
						}
					}
				}
			}
			if( ct > 0 )
				Debug.Log( $"Attached {ct} manager references." );
			EditorGUILayout.Space();
			base.OnInspectorGUI();
		}

		//IUdonVariable CreateUdonVariable(string symbolName, object value, System.Type type)
		//{
		//	Debug.Log( "CreateUdonVariable()" );
		//	System.Type udonVariableType = typeof(UdonVariable<>).MakeGenericType(type);
		//	return (IUdonVariable)Activator.CreateInstance(udonVariableType, symbolName, value);
		//}
	}
}
#endif
