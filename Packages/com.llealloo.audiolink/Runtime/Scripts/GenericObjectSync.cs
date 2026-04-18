#if PVR_CCK_WORLDS // A Stripped down version of the Object Sync sample from the PVR Worlds CCK
using PVR.CCK.Worlds.Components;
using PVR.CCK.Worlds.PSharp;
using PVR.Core;
using System;
using UnityEngine;

namespace AudioLink
{
	public class GenericObjectSync : PSharpBehaviour
	{

		[PSharpSynced(SyncType.Automatic, nameof(OnTransformSync))]
		private Vector3 _networkPosition;

		[PSharpSynced(SyncType.Automatic, nameof(OnTransformSync))]
		private Quaternion _networkRotation;

		private Vector3 _previousPosition;
		private Quaternion _previousRotation;
		private float _timeSinceLastPacket;

		private void Update()
		{
			if (!PSharpNetworking.isNetworkReady)
				return;

			if (IsOwner)
			{

				_networkPosition = transform.position;
				_networkRotation = transform.rotation;
			}
			else
			{
				_timeSinceLastPacket += Time.deltaTime;
				float time = Mathf.Clamp01(_timeSinceLastPacket / 0.1f);

				transform.SetPositionAndRotation
				(
					Vector3.Lerp(_previousPosition, _networkPosition, time),
					Quaternion.Slerp(_previousRotation, _networkRotation, time)
				);
			}
		}

		public override void OnNetworkReady()
		{
			if (IsOwner)
			{
				_networkPosition = transform.position;
				_networkRotation = transform.rotation;
			}

			_previousPosition = transform.position;
			_previousRotation = transform.rotation;
		}

		private void OnTransformSync()
		{
			_previousPosition = transform.position;
			_previousRotation = transform.rotation;

			_timeSinceLastPacket = 0f;
		}
	}
}
#endif