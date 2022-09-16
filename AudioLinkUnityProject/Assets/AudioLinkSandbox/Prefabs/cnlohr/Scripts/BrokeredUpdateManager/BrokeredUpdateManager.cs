/*
	BrokeredUpdatManager - 2021 <>< CNLohr
	
	This file may be copied freely copied and modified under the MIT/x11
	license.
	
	How to:
		* Make sure to have the VRC SDK 3.0 and UdonSharp installed.
		* Make an empty, somewhere called "BrokeredUpdateManager"
		* Add this file as an Udon Sharp Behavior to that object.
		
	Usage:
		* Call _GetIncrementingID() to get a unique ID, just a global counter.
		* Call `_RegisterSubscription( this )` / `_UnregisterSubscription( this )`
			in order to get `_BrokeredUpdate()` called every frame during
			the period between both calls.
		* Call `_RegisterSlowUpdate( this )` / `_UnregisterSlowUpdate( this )`
			in order to get `_SlowUpdate()` called every several frames.
			(Between the two calls.) All slow updates are called round-robin.
			
	You can get a copy of a references to this object by setting the reference
	in `Start()` i.e.
	
	private BrokeredUpdateManager brokeredManager;

	void Start()
	{
		brokeredManager = GameObject.Find( "BrokeredUpdateManager" )
			.GetComponent<BrokeredUpdateManager>();
	}
*/


using System;
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

// This does not have sync'd variables yet, but if it does, they'll be manual.
namespace BrokeredUpdates
{
	[UdonBehaviourSyncMode(BehaviourSyncMode.Manual)]
	public class BrokeredUpdateManager : UdonSharpBehaviour
	{
		const int MAX_UPDATE_COMPS = 2000;
		const int MAX_SLOW_ROLL_COMPS = 2000;
		private Component [] updateObjectList;
		private int updateObjectListCount;
		private Component [] slowUpdateList;
		private int slowUpdateListCount;
		private int slowUpdatePlace;
		private Component [] slowObjectSyncUpdateList;
		private int slowObjectSyncUpdateListCount;
		private int slowObjectSyncUpdatePlace;
		private Component [] snailUpdateList;
		private int snailUpdateListCount;
		private int snailUpdatePlace;
		private bool bInitialized = false;
		private float snailUpdateTime;
		private int idIncrementer;
		
		public int _GetIncrementingID()
		{
			return idIncrementer++;
		}
		
		void DoInitialize()
		{
			bInitialized = true;
			updateObjectList = new Component[MAX_UPDATE_COMPS];
			updateObjectListCount = 0;
			
			slowObjectSyncUpdateList = new Component[MAX_SLOW_ROLL_COMPS];
			slowObjectSyncUpdateListCount = 0;
			slowObjectSyncUpdatePlace = 0;
			
			slowUpdateList = new Component[MAX_SLOW_ROLL_COMPS];
			slowUpdateListCount = 0;
			slowUpdatePlace = 0;
			
			snailUpdateList = new Component[MAX_SLOW_ROLL_COMPS];
			snailUpdateListCount = 0;
			snailUpdatePlace = 0;
			snailUpdateTime = 0;
		}

		void Start()
		{
			if( !bInitialized ) DoInitialize();
		}

		public void _RegisterSubscription( UdonSharpBehaviour go )
		{
			if( !bInitialized ) DoInitialize();
			if( updateObjectListCount < MAX_SLOW_ROLL_COMPS )
			{
				updateObjectList[updateObjectListCount] = (Component)go;
				updateObjectListCount++;
			}
		}
		
		public void _UnregisterSubscription( UdonSharpBehaviour go )
		{
			if( !bInitialized ) DoInitialize();
			int i = Array.IndexOf( updateObjectList, go );
			if( i >= 0 )
			{
				Array.Copy( updateObjectList, i + 1, updateObjectList, i, updateObjectListCount - i );
				updateObjectListCount--;
			}
		}

		public void _RegisterSlowUpdate( UdonSharpBehaviour go )
		{
			if( !bInitialized ) DoInitialize();
			if( slowUpdateListCount < MAX_UPDATE_COMPS )
			{
				slowUpdateList[slowUpdateListCount] = (Component)go;
				slowUpdateListCount++;
			}
		}

		public void _UnregisterSlowUpdate( UdonSharpBehaviour go )
		{
			if( !bInitialized ) DoInitialize();
			int i = Array.IndexOf( slowUpdateList, go );
			if( i >= 0 )
			{
				Array.Copy( slowUpdateList, i + 1, slowUpdateList, i, slowUpdateListCount - i );
				slowUpdateListCount--;
			}
		}


		public void _RegisterSlowObjectSyncUpdate( UdonSharpBehaviour go )
		{
			if( !bInitialized ) DoInitialize();
			if( slowObjectSyncUpdateListCount < MAX_UPDATE_COMPS )
			{
				slowObjectSyncUpdateList[slowObjectSyncUpdateListCount] = (Component)go;
				slowObjectSyncUpdateListCount++;
			}
		}

		public void _UnregisterSlowObjectSyncUpdate( UdonSharpBehaviour go )
		{
			if( !bInitialized ) DoInitialize();
			int i = Array.IndexOf( slowObjectSyncUpdateList, go );
			if( i >= 0 )
			{
				Array.Copy( slowObjectSyncUpdateList, i + 1, slowObjectSyncUpdateList, i, slowObjectSyncUpdateListCount - i );
				slowObjectSyncUpdateListCount--;
			}
		}

		public void _RegisterSnailUpdate( UdonSharpBehaviour go )
		{
			if( !bInitialized ) DoInitialize();
			if( snailUpdateListCount < MAX_UPDATE_COMPS )
			{
				snailUpdateList[snailUpdateListCount] = (Component)go;
				snailUpdateListCount++;
			}
		}

		public void _UnregisterSnailUpdate( UdonSharpBehaviour go )
		{
			if( !bInitialized ) DoInitialize();
			int i = Array.IndexOf( snailUpdateList, go );
			if( i >= 0 )
			{
				Array.Copy( snailUpdateList, i + 1, snailUpdateList, i, snailUpdateListCount - i );
				snailUpdateListCount--;
			}
		}

		void Update()
		{
			if( !bInitialized ) DoInitialize();
			int i;
			for( i = 0; i < updateObjectListCount; i++ )
			{
				UdonSharpBehaviour behavior = (UdonSharpBehaviour)updateObjectList[i];
				if( behavior != null )
				{
					behavior.SendCustomEvent("_BrokeredUpdate");
				}
			}
			
			if( slowUpdateListCount > 0 )
			{
				UdonSharpBehaviour behavior = (UdonSharpBehaviour)slowUpdateList[slowUpdatePlace];
				if( behavior != null )
				{
					behavior.SendCustomEvent("_SlowUpdate");
				}

				slowUpdatePlace++;

				if( slowUpdatePlace >= slowUpdateListCount )
				{
					slowUpdatePlace = 0;
				}
			}
			
			if( slowObjectSyncUpdateListCount > 0 )
			{
				UdonSharpBehaviour behavior = (UdonSharpBehaviour)slowObjectSyncUpdateList[slowObjectSyncUpdatePlace];
				if( behavior != null )
				{
					behavior.SendCustomEvent("_SlowObjectSyncUpdate");
				}

				slowObjectSyncUpdatePlace++;

				if( slowObjectSyncUpdatePlace >= slowObjectSyncUpdateListCount )
				{
					slowObjectSyncUpdatePlace = 0;
				}
			}
			
			snailUpdateTime += Time.deltaTime;
			if( snailUpdateTime > 0.05 )
			{
				snailUpdateTime = 0;
				if( snailUpdateListCount > 0 )
				{
					UdonSharpBehaviour behavior = (UdonSharpBehaviour)snailUpdateList[snailUpdatePlace];
					if( behavior != null )
					{
						behavior.SendCustomEvent("_SnailUpdate");
					}

					snailUpdatePlace++;

					if( snailUpdatePlace >= snailUpdateListCount )
					{
						snailUpdatePlace = 0;
					}
				}
			}
		}
	}
}