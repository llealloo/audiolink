
using UdonSharp;
using UnityEngine;
using UnityEngine.UI;
using VRC.SDKBase;
using VRC.Udon;

public class ObjectPoolChild : UdonSharpBehaviour
{
    [UdonSynced]
    public float SyncedFloat = 0;
    public Text Display;
    private SimpleObjectPool Pool;
    private VRCPlayerApi Owner;
    private VRCPlayerApi LocalPlayer;
    private Vector3 Offset = new Vector3(0, 1.5f, 0);
    private string OwnerInfo = string.Empty;

    private void Start()
    {
        Pool = transform.parent.GetComponent<SimpleObjectPool>();
        LocalPlayer = Networking.LocalPlayer;
        if (!Display)
            Display = GetComponentInChildren<Text>();
    }
    public override void OnPreSerialization()
    {
        if (LocalPlayer != Owner)
        {
            SyncedFloat = 0;
            return;
        }
        //synced variables should never store data. They should always pull from some other ground truth.
        SyncedFloat = LocalPlayer.GetTrackingData(VRCPlayerApi.TrackingDataType.Head).rotation.eulerAngles.x;
        Display.text = OwnerInfo + "\nSynced float: " + SyncedFloat;
    }
    public override void OnDeserialization()
    {
        if (OwnerInfo == string.Empty)
        {
            Display.text = string.Empty;
            return;
        }
        Display.text = OwnerInfo + "\nSynced float: " + SyncedFloat;
    }
    public void LateUpdate() //This is an example of one possible way to use the pool
    {
        if (Owner == null) return;
        if (LocalPlayer == null) return;
        Vector3 position = Owner.GetTrackingData(VRCPlayerApi.TrackingDataType.Head).position;
        if (position == Vector3.zero) position = Owner.GetPosition() + Offset;
        transform.position = position + Offset;
        transform.LookAt(LocalPlayer.GetTrackingData(VRCPlayerApi.TrackingDataType.Head).position);
        transform.rotation = transform.rotation * Quaternion.Euler(0, 180, 0);
    }
    public void UpdateOwner() 
    {
        Owner = Networking.GetOwner(gameObject); //Setting the owner is important in order to keep track of the correct player. This can be removed if you use DoNotTransferOwnership
        if (Owner == null) return;
        OwnerInfo = "Name: " + Owner.displayName + "\nID: " + Owner.playerId + "\nPlayer Index: " + Pool.GetPlayersIndex(Owner) + "\nObject Index: " + transform.GetSiblingIndex();
        Display.text = OwnerInfo;
    }
    public override void OnPlayerLeft(VRCPlayerApi player) //Setting owner to null is important in order to prevent script crashing from an invalid playerapi
    {
        if (Owner == player)
        {
            Owner = null;
            OwnerInfo = string.Empty;
        }
    }
}
