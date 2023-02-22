
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

public class TrackPlayerWithinPlane : UdonSharpBehaviour
{
    // plane clamp mechanic provided by Nestorboy
    // lazy follow added by llealloo

    [SerializeField] Transform trackedObject;
    [SerializeField] Vector2 localBounds;
    [SerializeField][Range(0.0f, 1.0f)] float laziness;

    private VRCPlayerApi _localPlayer;
    private Vector3 _lazyPosition;

    private void Start()
    {
        _localPlayer = Networking.LocalPlayer;
        _lazyPosition = _localPlayer.GetPosition();
    }

    private void LateUpdate()
    {
        _lazyPosition = Vector3.Lerp(_localPlayer.GetPosition(), _lazyPosition, laziness);
        Vector3 localPlayerPos = transform.InverseTransformPoint(_lazyPosition);
        trackedObject.localPosition = new Vector3(Mathf.Clamp(localPlayerPos.x, -localBounds.x, localBounds.x), Mathf.Clamp(localPlayerPos.y, -localBounds.y, localBounds.y), 0);
    }
}
