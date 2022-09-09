
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

public class ReactiveFloor : UdonSharpBehaviour
{
    readonly string PROP_NAME_ARRAY_LENTH = "_RF_ArrayLength";
    readonly string PROP_NAME_ARRAY = "_ReactivePositions";

    private VRCPlayerApi[] playerList = new VRCPlayerApi[84];
    private Vector4[] positionList = new Vector4[100];
    private int length = 0;

    public MeshRenderer _renderer;
    public Material _material;

    private Material targetMaterial;

    private void Start()
    {
        for(int i = 0; i < _renderer.sharedMaterials.Length;i++) {
            if(_renderer.materials[i].name.StartsWith(_material.name))
            {
                targetMaterial = _renderer.materials[i];
                break;
            }
        }
    }

    private void Update()
    {
        for(int i = 0; i < length; i++)
        {
            if(playerList[i].IsValid() == false)
            {
                RemoveIndex(i);
                break;
            }
            positionList[i] = playerList[i].GetPosition();
        }
        targetMaterial.SetFloat(PROP_NAME_ARRAY_LENTH, length);
        targetMaterial.SetVectorArray(PROP_NAME_ARRAY, positionList);
    }

    public override void OnPlayerTriggerEnter(VRC.SDKBase.VRCPlayerApi player) {
        Add(player);
    }
    public override void OnPlayerTriggerExit(VRC.SDKBase.VRCPlayerApi player) {
        Remove(player);
    }

    public override void OnPlayerLeft(VRC.SDKBase.VRCPlayerApi player) {
        Remove(player);
    }

    private void Add(VRCPlayerApi player)
    {
        playerList[length] = player;
        length++;
    }

    private void Remove(VRCPlayerApi player)
    {
        for(int i = 0; i < length; i++)
        {
            if(playerList[i] == player)
            {
                RemoveIndex(i);
                return;
            }
        }
    }

    private void RemoveIndex(int i)
    {
        if (i < length)
        {
            playerList[i] = playerList[--length];
        }
    }
}
