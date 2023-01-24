
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

public class DoorZoneAudio : UdonSharpBehaviour
{
    // plane clamp method provided by Nestorboy

    [SerializeField] Transform audioSource;
    [SerializeField] Vector2 localBounds;

    private VRCPlayerApi localPlayer;
    private Vector4 bounds;

    private void Start()
    {
        localPlayer = Networking.LocalPlayer;
        bounds = new Vector4(-localBounds.x, localBounds.x, -localBounds.y, localBounds.y);
    }

    private void LateUpdate()
    {
        Vector3 worldHeadPos = localPlayer.GetTrackingData(VRCPlayerApi.TrackingDataType.Head).position;
        Vector3 localHeadPos = transform.InverseTransformPoint(worldHeadPos);
        audioSource.localPosition = new Vector3(Mathf.Clamp(localHeadPos.x, bounds.x, bounds.y), Mathf.Clamp(localHeadPos.y, bounds.z, bounds.w), 0);
    }
}
