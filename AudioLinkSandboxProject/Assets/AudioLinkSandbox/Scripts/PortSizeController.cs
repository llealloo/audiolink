
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

[UdonBehaviourSyncMode(BehaviourSyncMode.Manual)]

public class PortSizeController : UdonSharpBehaviour
{

    [UdonSynced] public bool state;

    [UdonSynced]
    [HideInInspector]
    public long eventTime = 0;

    public GameObject[] toggleInterfacesEnabled;
    public GameObject[] toggleInterfacesDisabled;
    public UdonBehaviour[] toggleTextSliders;
    public AudioSource toggleSoundEnabled;
    public AudioSource toggleSoundDisabled;
    public Animator toggleAnimator;

    private bool _buttonAvailable;
    private Vector2 _bounds;
    private VRCPlayerApi _localPlayer;

    public void OnEnable()
    {
        _bounds = new Vector2(0, 0);
        _localPlayer = Networking.LocalPlayer;
    }

    public void Update()
    {
        foreach (UdonBehaviour toggleTextSlider in toggleTextSliders)
        {
            _bounds.x = toggleAnimator.GetFloat("LocalBoundX");
            toggleTextSlider.SetProgramVariable("localBounds", _bounds);
        }
    }

    public void Interact()
    {
        //creates a timestamp 5 seconds in the future to check that
        //the event is not stale
        eventTime = Networking.GetNetworkDateTime().AddSeconds(5).Ticks;

        //networking events do not occur if you are in an instance alone
        if (VRCPlayerApi.GetPlayerCount() > 1)
        {
            //Checks to see the local player is the owner of the gameObject and
            //if not attempts to take ownership of the gameObject.
            if (Networking.IsOwner(gameObject))
            {
                RequestSerialization();
            }
            else
            {
                Networking.SetOwner(_localPlayer, gameObject);
            }
        }
        else
        {
            state = !state;
            PlaySounds();
            ApplyToggle();
        }

        // this one is for the spammers
        DisableInteractive = true;
        SendCustomEventDelayedSeconds("_SetButtonAvailable", 5.0f);
    }

    //when ownership is transferred checks to see if the local player is the
    //owner of the gameObject and if so request serialization
    public override void OnOwnershipTransferred(VRCPlayerApi player)
    {
        if (player == _localPlayer)
        {
            RequestSerialization();
        }
    }

    //run by the owner of the gameObject before it serializes data
    //checks that they are the owner of the gameObject just in case
    //and checks that the event is not stale
    public override void OnPreSerialization()
    {
        if (Networking.GetNetworkDateTime().Ticks < eventTime)
        {
            state = !state;
            PlaySounds();
            ApplyToggle();
        }
    }


    public void OnDeserialization()
    {
        if (Networking.GetNetworkDateTime().Ticks < eventTime)
        {
            PlaySounds();
        }

        ApplyToggle();
    }


    private void ApplyToggle()
    {
        foreach (GameObject toggleInterface in toggleInterfacesEnabled)
        {
            toggleInterface.SetActive(state);
        }
        foreach (GameObject toggleInterface in toggleInterfacesDisabled)
        {
            toggleInterface.SetActive(!state);
        }
        if (state)
        {
            toggleAnimator.SetBool("State", true);
        }
        else
        {
            toggleAnimator.SetBool("State", false);
        }
    }

    // the audio is split into a seperate method so the audio does not play
    // when serializing on player join
    private void PlaySounds()
    {
        if (state)
        {
            toggleSoundEnabled.Play();
        }
        else
        {
            toggleSoundDisabled.Play();
        }
    }

    public void _SetButtonAvailable()
    {
        DisableInteractive = false;
    }
}
