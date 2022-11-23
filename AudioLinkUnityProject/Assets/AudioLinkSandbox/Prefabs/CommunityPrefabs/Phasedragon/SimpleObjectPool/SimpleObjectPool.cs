
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;
public class SimpleObjectPool : UdonSharpBehaviour
{
    [Header("Enable this if you do not need synced variables on the children. Refer to README for usage.")]
    public bool DoNotTransferOwnership;

    [Header("Enable this if you are running into issues and need to submit a bug report.")]
    public bool DebugLogging;

    private Component[] AllBehaviours;
    private bool[] ActiveObjects;
    private int[] ObjectsOwner;
    private VRCPlayerApi[] LastKnownOwner;
    private VRCPlayerApi[] AllPlayers = new VRCPlayerApi[81];
    private int[] PlayersObject = new int[81];
    private VRCPlayerApi LocalPlayer;
    private int NumPlayers;
    private float RebootTimer = -1;
    private float UpdatePoolTimer = -1;
    private float UpdateOwnerTimer = -1;
    private int UpdateOwnerRestarts = 0;
    private int UpdatePoolRestarts = 0;
    //Utilities
    public UdonBehaviour GetPlayersObject(VRCPlayerApi player)
    {
        if (player == null) return null;
        return (UdonBehaviour)AllBehaviours[GetPlayersIndex(player)];
    }
    public int GetPlayersIndex(VRCPlayerApi player)
    {
        for (int i = 0; i < AllBehaviours.Length; i++)
        {
            if (AllPlayers[i] == player) return i;
        }
        return 0;
    }
    //Core functions
    void Start()
    {
        LocalPlayer = Networking.LocalPlayer;
        if (DebugLogging) Debug.Log("[ObjectPool] I am " + LocalPlayer.displayName + " " + LocalPlayer.playerId);
        AllBehaviours = new Component[transform.childCount];
        ActiveObjects = new bool[transform.childCount];
        ObjectsOwner = new int[transform.childCount];
        LastKnownOwner = new VRCPlayerApi[transform.childCount];
        for (int i = 0; i < AllBehaviours.Length; i++)
        {
            Transform child = transform.GetChild(i);
            AllBehaviours[i] = child.GetComponent(typeof(UdonBehaviour));
            if (AllBehaviours[i] == null) Debug.LogError("[ObjectPool] child " + i + " does not have an udonbehaviour. This will break things!");
        }
        if (AllBehaviours.Length < 80) Debug.LogWarning("[ObjectPool] pool has " + AllBehaviours.Length + " objects. You should have double your world capacity.");
        for (int i = 0; i < PlayersObject.Length; i++)
        {
            PlayersObject[i] = -1;
        }
        for (int i = 0; i < ObjectsOwner.Length; i++)
        {
            ObjectsOwner[i] = -1;
        }
    }
    private void Update()
    {
        if (RebootTimer != -1 && RebootTimer + Mathf.Sqrt(NumPlayers) < Time.timeSinceLevelLoad) Reboot();
        if (UpdatePoolTimer != -1 && UpdatePoolTimer + Mathf.Sqrt(NumPlayers) < Time.timeSinceLevelLoad) UpdatePool();
        if (UpdateOwnerTimer != -1 && UpdateOwnerTimer + Mathf.Sqrt(NumPlayers) < Time.timeSinceLevelLoad) UpdateOwner();
    }
    public override void OnPlayerJoined(VRCPlayerApi player)
    {
        UpdatePoolTimer = Time.timeSinceLevelLoad;
        UpdatePoolRestarts = 0;
        NumPlayers++;
        //RebootTimer = Time.timeSinceLevelLoad;
        int InsertionIndex = 0;
        bool ShiftArray = true;
        for (int i = 0; i < AllPlayers.Length; i++)
        {
            if (AllPlayers[i] == null)
            {
                InsertionIndex = i;
                ShiftArray = false;
                break;
            }
            if (AllPlayers[i].playerId > player.playerId)
            {
                InsertionIndex = i;
                break;
            }
        }
        if (DebugLogging) Debug.Log("[ObjectPool] Inserting player " + player.displayName + " " + player.playerId + " at index " + InsertionIndex);
        if (ShiftArray) for (int i = AllPlayers.Length - 1; i > InsertionIndex; i--)
        {
            if (AllPlayers[i - 1] == null) continue;
            AllPlayers[i] = AllPlayers[i - 1];
            PlayersObject[i] = PlayersObject[i - 1];
            if (DebugLogging) Debug.Log("[ObjectPool] Moving " + (i-1) + " to " + i);
        }
        AllPlayers[InsertionIndex] = player;
        LogAllPlayers();
    }
    public override void OnPlayerLeft(VRCPlayerApi player)
    {
        UpdatePoolRestarts = 0;
        UpdatePoolTimer = Time.timeSinceLevelLoad;
        NumPlayers--;
        int RemovalIndex = -1;
        for (int i = 0; i < AllPlayers.Length; i++)
        {
            if (AllPlayers[i] == player)
            {
                RemovalIndex = i;
            }
        }
        for (int i = RemovalIndex; i < AllPlayers.Length - 1; i++)
        {
            AllPlayers[i] = AllPlayers[i + 1];
            PlayersObject[i] = PlayersObject[i + 1];
        }
        LogAllPlayers();
        for (int i = 0; i < PlayersObject.Length; i++)
        {
            PlayersObject[i] = -1;
        }
        for (int i = 0; i < ObjectsOwner.Length; i++)
        {
            ObjectsOwner[i] = -1;
        }
    }
    public void LogAllPlayers()
    {
        for (int i = 0; i < AllPlayers.Length; i++)
        {
            if (AllPlayers[i] == null) continue;
            if (DebugLogging) Debug.Log("[ObjectPool] Player: " + AllPlayers[i].displayName + " Index: " + i + " ID: " + AllPlayers[i].playerId);
        }
    }
    public void StartReboot()
    {
        if (DebugLogging) Debug.Log("[ObjectPool] Someone was not synced fully, reboot initiated");
        RebootTimer = Time.timeSinceLevelLoad;
    }
    public void Reboot()
    {
        RebootTimer = -1;
        UpdateOwnerTimer = -1;
        if (DebugLogging) Debug.Log("[ObjectPool] Starting Reboot");
        if (Networking.IsMaster)
        {
            for (int i = 0; i < AllBehaviours.Length; i++)
            {
                Networking.SetOwner(LocalPlayer, AllBehaviours[i].gameObject);
            }
        }
        UpdatePoolRestarts = 0;
        UpdatePoolTimer = Time.timeSinceLevelLoad;
    }
    public void UpdatePool()
    {
        FindAllObjects();
        UpdatePoolRestarts++;
        UpdatePoolTimer = -1;
        UpdateOwnerRestarts = 0;
        UpdateOwnerTimer = Time.timeSinceLevelLoad;
        if (DebugLogging) Debug.Log("[ObjectPool] Updating pool " + UpdatePoolRestarts);
        for (int i = 0; i < ActiveObjects.Length; i++)
        {
            AllBehaviours[i].gameObject.SetActive(ActiveObjects[i]);
        }

        if (DoNotTransferOwnership) return;

        for (int i = 0; i < AllPlayers.Length; i++)
        {
            if (AllPlayers[i] == null) continue;
            if (PlayersObject[i] == -1)
            {
                if (DebugLogging) Debug.Log("[ObjectPool] Player " + AllPlayers[i].playerId + " does not have a spot. They will have to wait until someone leaves.");
            }
            else if (Networking.GetOwner(AllBehaviours[PlayersObject[i]].gameObject) == AllPlayers[i])
            {
                if (DebugLogging) Debug.Log("[ObjectPool] Player " + AllPlayers[i].playerId + " already has ownership of object " + PlayersObject[i]);
            }
            else
            {
                if (DebugLogging) Debug.Log("[ObjectPool] Player " + AllPlayers[i].playerId + " does not have ownership of object " + PlayersObject[i] + ". Attempting to fix...");
                if (AllPlayers[i] == LocalPlayer || UpdatePoolRestarts > 1)
                    Networking.SetOwner(AllPlayers[i], AllBehaviours[PlayersObject[i]].gameObject);
            }
        }
    }
    public void UpdateOwner()
    {
        UpdateOwnerRestarts++;
        UpdateOwnerTimer = -1;
        if (DebugLogging) Debug.Log("[ObjectPool] Updating owners " + UpdateOwnerRestarts);
        int NumWrongOwner = 0;
        for (int i = 0; i < AllBehaviours.Length; i++)
        {
            if (AllBehaviours[i] == null) continue;
            if (!AllBehaviours[i].gameObject.activeInHierarchy) continue;
            if (ObjectsOwner[i] == -1) continue;
            if (DoNotTransferOwnership)
            {
                LastKnownOwner[i] = AllPlayers[ObjectsOwner[i]];
                if (((UdonBehaviour)AllBehaviours[i]).GetProgramVariable("Owner") != LastKnownOwner[i])
                {
                    ((UdonBehaviour)AllBehaviours[i]).SetProgramVariable("Owner", LastKnownOwner[i]);
                    ((UdonBehaviour)AllBehaviours[i]).SendCustomEvent("UpdateOwner");
                }
            }
            else
            {
                VRCPlayerApi Owner = Networking.GetOwner(AllBehaviours[i].gameObject);
                if (Owner == null) continue;
                if (DebugLogging) Debug.Log("[ObjectPool] Object " + i + " is owned by " + Owner.displayName + " " + Owner.playerId);
                if (Owner != AllPlayers[ObjectsOwner[i]]) NumWrongOwner++;
                if (i != 0 && Owner != AllPlayers[ObjectsOwner[i]]) continue;
                if (Owner != LastKnownOwner[i])
                {
                    LastKnownOwner[i] = Owner;
                    ((UdonBehaviour)AllBehaviours[i]).SendCustomEvent("UpdateOwner");
                }
            }

        }
        if (NumWrongOwner > 0)
        {
            if (DebugLogging) Debug.Log("[ObjectPool] " + NumWrongOwner + " objects have the wrong owner. Restarting UpdateOwner process " + UpdateOwnerRestarts);
            if (UpdateOwnerRestarts < 2) //2 restarts to give people a chance to take ownership
                UpdateOwnerTimer = Time.timeSinceLevelLoad;
            else if (UpdatePoolRestarts < 2)
                UpdatePoolTimer = Time.timeSinceLevelLoad;
            else
                SendCustomNetworkEvent(VRC.Udon.Common.Interfaces.NetworkEventTarget.All, "StartReboot"); //Last resort, tell everyone to restart after waiting for a bit
        }
    }
    public void FindAllObjects()
    {
        for (int i = 0; i < ActiveObjects.Length; i++)
        {
            ActiveObjects[i] = false;
        }
        for (int i = 0; i < AllPlayers.Length; i++)
        {
            if (AllPlayers[i] == null) continue;
            if (PlayersObject[i] == -1)
            {
                FindObject(i);
                if (PlayersObject[i] != -1) ActiveObjects[PlayersObject[i]] = true;
            }
            else
                ActiveObjects[PlayersObject[i]] = true;
        }
    }
    public void FindObject(int index)
    {
        int Output = AllPlayers[index].playerId % AllBehaviours.Length;
        bool ObjectTaken = true;
        int NumChecked = 0;
        while (ObjectTaken == true)
        {
            if (NumChecked > AllBehaviours.Length)
            {
                if (DebugLogging) Debug.Log("[ObjectPool] Could not find a spot for " + AllPlayers[index].playerId);
                PlayersObject[index] = -1;
                return;
            }
            if (DebugLogging) Debug.Log("[ObjectPool] Looking for a spot at " + Output);
            ObjectTaken = false;
            if (ObjectsOwner[Output] != -1)
            {
                if (DebugLogging) Debug.Log("[ObjectPool] Collision detected at " + Output);
                ObjectTaken = true;
                if (AllPlayers[index].playerId % 2 == 1)
                {
                    Output += 1;
                }
                else
                {
                    Output -= 1;
                    if (Output < 0) Output = AllBehaviours.Length - 1;
                }
                Output %= AllBehaviours.Length;
                NumChecked++;
            }
        }
        PlayersObject[index] = Output;
        ObjectsOwner[Output] = index;
        if (DebugLogging) Debug.Log("[ObjectPool] spot found at " + Output + " for player " + AllPlayers[index].playerId);
    }
}