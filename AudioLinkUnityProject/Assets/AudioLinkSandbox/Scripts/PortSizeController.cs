
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

[UdonBehaviourSyncMode(BehaviourSyncMode.Manual)]

public class PortSizeController : UdonSharpBehaviour
{

    [UdonSynced] public bool state;

    public GameObject[] toggleInterfacesEnabled;
    public GameObject[] toggleInterfacesDisabled;
    public UdonBehaviour[] toggleTextSliders;
    public AudioSource toggleSoundEnabled;
    public AudioSource toggleSoundDisabled;
    public Animator toggleAnimator;

    private bool _buttonAvailable;
    private Vector2 _bounds;

    public void Start()
    {
        _bounds = new Vector2(0, 0);
        SetButtonAvailable();
    }

    public void Update()
    {
        foreach (UdonBehaviour toggleTextSlider in toggleTextSliders)
        {
            _bounds.x = toggleAnimator.GetFloat("LocalBoundX");
            toggleTextSlider.SetProgramVariable("localBounds", _bounds);
        }
    }

    public override void OnDeserialization()
    {
        ApplyToggle();
    }

    public void Interact()
    {
        if (_buttonAvailable)
        {
            Networking.SetOwner(Networking.LocalPlayer, gameObject);
            state = !state;
            RequestSerialization();
            ApplyToggle();
            _buttonAvailable = false;
            // this one is for the spammers
            SendCustomEventDelayedSeconds("SetButtonAvailable", 7f);
        }
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
            toggleSoundEnabled.Play();
            toggleAnimator.SetBool("State", true);
        } else {
            toggleSoundDisabled.Play();
            toggleAnimator.SetBool("State", false);
        }
    }

    public void SetButtonAvailable()
    {
        _buttonAvailable = true;
    }
}
