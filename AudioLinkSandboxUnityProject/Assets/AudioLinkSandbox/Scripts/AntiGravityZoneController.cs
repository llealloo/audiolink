
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;
using VRC.Udon.Common;

public class AntiGravityZoneController : UdonSharpBehaviour
{

    private const float ZERO_GRAVITY = 0.0001f;

    public UdonBehaviour airtimePlayerController;
    public Animator deck1Animator;
    public Animator deck2Animator;
    public Animator deck3Animator;
    public Animator deck4Animator;
    public Material antiGravityVoxelCRT;
    public float floatDrag;
    public float floatMovePower;
    public float terminalHandVelocity;
    public float handVelocityCutoff;
    public float handForceMagnitude;

    private Vector3 _deck1Size;
    private Vector3 _deck2Size;
    private Vector3 _deck3Size;
    private Vector3 _deck4Size;
    private VRCPlayerApi _localPlayer;
    private float _airtimeGravitySetting;
    private int _triggerZoneCounter;
    private bool _floatZoneState;
    private float _floatForceHorizontal;
    private float _floatForceVertical;

    //private float _lookHorizontal;
    //private float _lookVertical;

    //private Vector3 _lastLeftHandLocalPosition;
    //private Vector3 _lastRightHandLocalPosition;

    private float _playerWalkSpeed;
    private float _playerRunSpeed;

    void Start()
    {
        _floatZoneState = false;
        _localPlayer = Networking.LocalPlayer;
        _deck1Size = antiGravityVoxelCRT.GetVector("_Zone2Size");
        _deck2Size = antiGravityVoxelCRT.GetVector("_Zone3Size");
        _deck3Size = antiGravityVoxelCRT.GetVector("_Zone4Size");
        _deck4Size = antiGravityVoxelCRT.GetVector("_Zone5Size");
        _triggerZoneCounter = 0;
        _airtimeGravitySetting = (float)airtimePlayerController.GetProgramVariable("gravityStrength");
        _playerWalkSpeed = _localPlayer.GetWalkSpeed();
        _playerRunSpeed = _localPlayer.GetRunSpeed();

        _floatForceHorizontal = _floatForceVertical = 0f;
    }

    void Update()
    {
        _deck1Size.x = _deck1Size.y = deck1Animator.GetFloat("AntiGravityZoneSize");
        _deck2Size.x = _deck2Size.y = deck2Animator.GetFloat("AntiGravityZoneSize");
        _deck3Size.x = _deck3Size.y = deck3Animator.GetFloat("AntiGravityZoneSize");
        _deck4Size.x = _deck4Size.y = deck4Animator.GetFloat("AntiGravityZoneSize");
        antiGravityVoxelCRT.SetVector("_Zone2Size", _deck1Size);
        antiGravityVoxelCRT.SetVector("_Zone3Size", _deck2Size);
        antiGravityVoxelCRT.SetVector("_Zone4Size", _deck3Size);
        antiGravityVoxelCRT.SetVector("_Zone5Size", _deck4Size);
        /*if (_floatZoneState)
        {
            _localPlayer.SetVelocity(_localPlayer.GetTrackingData(VRCPlayerApi.TrackingDataType.Head).rotation * new Vector3(_floatForceHorizontal, 0, _floatForceVertical) + (_localPlayer.GetVelocity() * floatDrag));
        }*/

    }

    void FixedUpdate()
    {
        if (_floatZoneState)
        {
            _localPlayer.SetVelocity(_localPlayer.GetTrackingData(VRCPlayerApi.TrackingDataType.Head).rotation * new Vector3(_floatForceHorizontal, 0, _floatForceVertical) + (_localPlayer.GetVelocity() * floatDrag)/* + totalHandForce*/);
        }
    }

    void PostLateUpdate()
    {

        //_lastLeftHandLocalPosition = _localPlayer.GetBonePosition(HumanBodyBones.LeftHand) - _localPlayer.GetPosition();
        //_lastRightHandLocalPosition = _localPlayer.GetBonePosition(HumanBodyBones.RightHand) - _localPlayer.GetPosition();
        if (_floatZoneState)
        {
            _localPlayer.SetWalkSpeed(0f);
            _localPlayer.SetRunSpeed(0f);
        }
        else
        {
            _localPlayer.SetWalkSpeed(_playerWalkSpeed);
            _localPlayer.SetRunSpeed(_playerRunSpeed);
        }
    }

    public override void InputMoveHorizontal(float value, UdonInputEventArgs args)
    {
        _floatForceHorizontal = _playerWalkSpeed * value * floatMovePower;
    }

    public override void InputMoveVertical(float value, UdonInputEventArgs args)
    {
        _floatForceVertical = _playerWalkSpeed * value * floatMovePower;

    }

    /*public override void InputLookVertical(float value, UdonInputEventArgs args)
    {
        _lookVertical = value;

    }

    public override void InputLookHorizontal(float value, UdonInputEventArgs args)
    {
        _lookHorizontal = value;

    }*/

    public override void InputJump(bool value, UdonInputEventArgs args)
    {
        if(value)
        {

        }
    }

    public void IncreaseTriggerZoneCounter()
    {
        _triggerZoneCounter++;
        UpdatePlayerGravityState();
    }

    public void DecreaseTriggerZoneCounter()
    {
        _triggerZoneCounter--;
        if (_triggerZoneCounter < 0) _triggerZoneCounter = 0;
        UpdatePlayerGravityState();
    }

    private void UpdatePlayerGravityState()
    {
        if (_triggerZoneCounter > 0)
        {
            DisablePlayerGravity();
        }
        else
        {
            EnablePlayerGravity();
        }
    }

    private void EnablePlayerGravity()
    {
        airtimePlayerController.SetProgramVariable("gravityStrength", _airtimeGravitySetting);
        _localPlayer.SetGravityStrength(_airtimeGravitySetting);
        _floatZoneState = false;
    }

    private void DisablePlayerGravity()
    {
        airtimePlayerController.SetProgramVariable("gravityStrength", ZERO_GRAVITY);
        _localPlayer.SetGravityStrength(ZERO_GRAVITY);
        _floatZoneState = true;
    }

}
