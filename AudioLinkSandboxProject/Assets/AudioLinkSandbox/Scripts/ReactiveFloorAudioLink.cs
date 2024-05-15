
using UdonSharp;
using UnityEngine;
// debug
using UnityEngine.UI;
using VRC.SDKBase;
using VRC.Udon;

namespace AudioLinkWorld
{
    public class ReactiveFloorAudioLink : UdonSharpBehaviour
    {
        readonly string PROP_NAME_ARRAY_LENGTH = "_ArrayLength";
        readonly string PROP_NAME_PLAYER_POSITIONS = "PlayerPositions";
        readonly string PROP_NAME_FEET_POSITIONS = "FeetPositions";

        public MeshRenderer renderer;
        public Material material;

        private Material _targetMaterial;

        private VRCPlayerApi[] _playerArray = new VRCPlayerApi[84];
        private Vector4[] _positionArray = new Vector4[100];
        private Vector4[] _footPositionArray = new Vector4[200];
        private int _numPlayers = 0;
        private int _numFeet = 0;

        private HumanBodyBones _leftFoot;
        private HumanBodyBones _rightFoot;
        private VRCPlayerApi.TrackingDataType _leftFootTrackingDataType;
        private VRCPlayerApi.TrackingDataType _rightFootTrackingDataType;

        // debug
        public Text consoleTextField;
        private string consoleText;

        private void Start()
        {
            for (int i = 0; i < renderer.sharedMaterials.Length; i++)
            {
                if (renderer.materials[i].name.StartsWith(material.name))
                {
                    _targetMaterial = renderer.materials[i];
                    break;
                }
            }

            // setup foot trackers
            _leftFoot = HumanBodyBones.LeftFoot;
            _rightFoot = HumanBodyBones.RightFoot;
        }

        private void Update()
        {

            for (int i = 0; i < _numPlayers; i++)
            {
                if (_playerArray[i].IsValid() == false)
                {
                    RemoveIndex(i);
                    break;
                }
                _positionArray[i] = _playerArray[i].GetPosition();
            }

            UpdateFootPositionArray();

            _targetMaterial.SetFloat(PROP_NAME_ARRAY_LENGTH, _numPlayers);
            _targetMaterial.SetVectorArray(PROP_NAME_PLAYER_POSITIONS, _positionArray);
            _targetMaterial.SetVectorArray(PROP_NAME_FEET_POSITIONS, _footPositionArray);

            //PrintFeetPositions();
        }

        public override void OnPlayerJoined(VRC.SDKBase.VRCPlayerApi player)
        {
            Add(player);
        }

        public override void OnPlayerLeft(VRC.SDKBase.VRCPlayerApi player)
        {
            Remove(player);
        }

        private void Add(VRCPlayerApi player)
        {
            _playerArray[_numPlayers] = player;
            _numPlayers++;
            _numFeet += 2;
        }

        private void Remove(VRCPlayerApi player)
        {
            for (int i = 0; i < _numPlayers; i++)
            {
                if (_playerArray[i] == player)
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
                _numFeet -= 2;
            }
        }

        private void UpdateFootPositionArray()
        {
            Vector3 playerPosition;
            Vector3 leftFootPosition;
            Vector3 rightFootPosition;

            for (int i = 0; i < _numPlayers; i++)
            {
                /*playerPosition = _playerArray[i].GetPosition();
                leftFootPosition = _playerArray[i].GetBonePosition(_leftFoot);
                rightFootPosition = _playerArray[i].GetBonePosition(_rightFoot);

                _footPositionArray[i * 2] = (leftFootPosition == Vector3.zero) ? playerPosition : leftFootPosition;
                _footPositionArray[i * 2 + 1] = (rightFootPosition == Vector3.zero) ? playerPosition : rightFootPosition;*/


                _footPositionArray[i * 2] = _playerArray[i].GetBonePosition(HumanBodyBones.LeftFoot);
                _footPositionArray[i * 2 + 1] = _playerArray[i].GetBonePosition(HumanBodyBones.RightFoot);
            }
        }


        private void PrintFeetPositions()
        {
            consoleText = "";

            for (int i = 0; i < _numPlayers; i++)
            {
                consoleText = consoleText + "player " + (i + 1).ToString() + " position: " + _positionArray[i].ToString("F2") + "\n";
                consoleText = consoleText + "player " + (i + 1).ToString() + " left: " + _footPositionArray[i * 2].ToString("F2") + "\n";
                consoleText = consoleText + "player " + (i + 1).ToString() + " right: " + _footPositionArray[i * 2 + 1].ToString("F2") + "\n";

                //consoleText = consoleText + "player " + (i + 1).ToString() + " left: " + _playerArray[i].GetBonePosition(HumanBodyBones.LeftFoot).ToString("F2") + "\n";
                //consoleText = consoleText + "player " + (i + 1).ToString() + " right: " + _playerArray[i].GetBonePosition(HumanBodyBones.RightFoot).ToString("F2") + "\n";
            }

            consoleTextField.text = consoleText;
        }
    }
}
