
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;


// debug
using UnityEngine.UI;

public class PlayerPositionTracker : UdonSharpBehaviour
{
    readonly string PROP_NAME_ARRAY_LENGTH = "_ArrayLength";
    readonly string PROP_NAME_PLAYER_POSITIONS = "PlayerPositions";
    readonly string PROP_NAME_HEAD_POSITIONS = "HeadPositions";
    readonly string PROP_NAME_FEET_POSITIONS = "FeetPositions";
    readonly string PROP_NAME_HAND_POSITIONS = "HandPositions";

    //public MeshRenderer renderer;
    //public Material material;

    public Material[] targetMaterials;

    //private Material _targetMaterial;
    private VRCPlayerApi[] _playerArray = new VRCPlayerApi[84];
    private Vector4[] _positionArray = new Vector4[100];
    private Vector4[] _headPositionArray = new Vector4[100];
    private Vector4[] _handPositionArray = new Vector4[200];
    private Vector4[] _footPositionArray = new Vector4[200];
    private int _numPlayers = 0;
    //private int _numFeet = 0;
    //private int _numHands = 0;

    // debug
    public Text consoleTextField;
    private string consoleText;

    private void Start()
    {
        /*for(int i = 0; i < renderer.sharedMaterials.Length;i++) {
            if(renderer.materials[i].name.StartsWith(material.name))
            {
                _targetMaterial = renderer.materials[i];
                break;
            }
        }*/
    }

    private void Update()
    {

        for(int i = 0; i < _numPlayers; i++)
        {
            if(_playerArray[i].IsValid() == false)
            {
                RemoveIndex(i);
                break;
            }
            _positionArray[i] = _playerArray[i].GetPosition();

            // debug
            //PrintDebug();
        }

        UpdateHandFootPositionArrays();

        foreach (Material material in targetMaterials)
        {
            material.SetFloat(PROP_NAME_ARRAY_LENGTH, _numPlayers);
            material.SetVectorArray(PROP_NAME_PLAYER_POSITIONS, _positionArray);
            material.SetVectorArray(PROP_NAME_HEAD_POSITIONS, _headPositionArray);
            material.SetVectorArray(PROP_NAME_HAND_POSITIONS, _handPositionArray);
            material.SetVectorArray(PROP_NAME_FEET_POSITIONS, _footPositionArray);
        }

        //_targetMaterial.SetFloat(PROP_NAME_ARRAY_LENGTH, _numPlayers);
        //_targetMaterial.SetVectorArray(PROP_NAME_PLAYER_POSITIONS, _positionArray);
        //_targetMaterial.SetVectorArray(PROP_NAME_FEET_POSITIONS, _footPositionArray);
    }

    public override void OnPlayerJoined(VRC.SDKBase.VRCPlayerApi player) {
        Add(player);
    }

    public override void OnPlayerLeft(VRC.SDKBase.VRCPlayerApi player) {
        Remove(player);
    }

    private void Add(VRCPlayerApi player)
    {
        _playerArray[_numPlayers] = player;
        _numPlayers++;
        //_numFeet += 2;
    }

    private void Remove(VRCPlayerApi player)
    {
        for(int i = 0; i < _numPlayers; i++)
        {
            if(_playerArray[i] == player)
            {
                RemoveIndex(i);
                return;
            }
        }
    }

    private void RemoveIndex(int i)
    {
        if (i < _numPlayers)
        {
            _playerArray[i] = _playerArray[--_numPlayers];
            //_numFeet -= 2;
        }
    }

    private void UpdateHandFootPositionArrays()
    {
        Vector3 playerPosition;
        Vector3 leftFootPosition;
        Vector3 rightFootPosition;

        for (int i = 0; i < _numPlayers; i++)
        {
            _headPositionArray[i] = _playerArray[i].GetBonePosition(HumanBodyBones.Head);

            _handPositionArray[i * 2] = _playerArray[i].GetBonePosition(HumanBodyBones.LeftHand);
            _handPositionArray[i * 2 + 1] = _playerArray[i].GetBonePosition(HumanBodyBones.RightHand);

            _footPositionArray[i * 2] = _playerArray[i].GetBonePosition(HumanBodyBones.LeftFoot);
            _footPositionArray[i * 2 + 1] = _playerArray[i].GetBonePosition(HumanBodyBones.RightFoot);
        }
    }


    private void PrintDebug()
    {
        consoleText = "";

        for (int i = 0; i < _numPlayers; i++)
        {
            consoleText = consoleText + "player " + (i + 1).ToString() + " position: " + _positionArray[i].ToString("F2") + "\n";
            consoleText = consoleText + "player " + (i + 1).ToString() + " left: " + _handPositionArray[i * 2].ToString("F2") + "\n";
            consoleText = consoleText + "player " + (i + 1).ToString() + " right: " + _handPositionArray[i * 2 + 1].ToString("F2") + "\n";

            //consoleText = consoleText + "player " + (i + 1).ToString() + " left: " + _playerArray[i].GetBonePosition(HumanBodyBones.LeftFoot).ToString("F2") + "\n";
            //consoleText = consoleText + "player " + (i + 1).ToString() + " right: " + _playerArray[i].GetBonePosition(HumanBodyBones.RightFoot).ToString("F2") + "\n";
        }

        consoleTextField.text = consoleText;
    }
}
