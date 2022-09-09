
using UdonSharp;
using UnityEngine;
using UnityEngine.UI;
using VRC.SDKBase;
using VRC.Udon;

public class HudHandler : UdonSharpBehaviour
{
    [Header("Notification Settings")]
    public bool ShowJoinNotifications = true;
    public bool ShowLeaveNotifications = true;
    [Space(30)]
    [Header("Icon Settings")]
    public Sprite JoinSprite;
    public Sprite LeaveSprite;
    [Header("Audio Settings")]
    public AudioClip JoinAudio;
    public AudioClip LeaveAudio;
    [Space(30)]

    //Don't touch these.
    [HideInInspector] public Text HUDJoinMessageText;
    [HideInInspector] public Text HUDInfoText;
    [HideInInspector] public Animator LocalAnimator;
    [HideInInspector] public AudioSource NotificationJoinAudio;
    [HideInInspector] public AudioSource NotificationLeaveAudio;
    [HideInInspector] public Image MainImage;
    [HideInInspector] public Image Background;
    [HideInInspector] public VRCPlayerApi.TrackingDataType trackingTarget;

    VRCPlayerApi playerApi;
    bool isInEditor;

    private void LateUpdate()
    {
        if (isInEditor)
            return;

        VRCPlayerApi.TrackingData trackingData = playerApi.GetTrackingData(trackingTarget);
        transform.SetPositionAndRotation(trackingData.position, trackingData.rotation);
    }

    public void Start()
    {
        //Check for EditorMode
        playerApi = Networking.LocalPlayer;
        isInEditor = playerApi == null;

        //Set up Audio
        NotificationJoinAudio.clip = JoinAudio;
        NotificationLeaveAudio.clip = LeaveAudio;
    }

    public void SetLeave()
    {
        MainImage.sprite = LeaveSprite;
        Background.sprite = LeaveSprite;
        HUDInfoText.text = "Player Left";
    }

    public void SetJoin()
    {
        MainImage.sprite = JoinSprite;
        Background.sprite = JoinSprite;
        HUDInfoText.text = "Player Joined";
    }

    public override void OnPlayerJoined(VRCPlayerApi player)
    {
        if ((!player.isLocal) && ShowJoinNotifications)
        {
            SetJoin();
            HUDJoinMessageText.text = player.displayName + " Joined";
            LocalAnimator.SetTrigger("PlayJoinMessage");
            NotificationJoinAudio.Play();
        }
    }

    public override void OnPlayerLeft(VRCPlayerApi player)
    {
        if (ShowLeaveNotifications)
        {
            SetLeave();
            HUDJoinMessageText.text = player.displayName + " Left";
            LocalAnimator.SetTrigger("PlayJoinMessage");
            NotificationLeaveAudio.Play();
        }
    }
}
