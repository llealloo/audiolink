
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

public class ClapperEffect : UdonSharpBehaviour
{
    ParticleSystem _particleSystem;
    AudioSource _audioSource;
    bool isNotInit = true;
    float lastAvatarHeightUpdate = 0;
    float avatarHeight = 1;

    private void Start()
    {
        _particleSystem = transform.GetComponent<ParticleSystem>();
        _audioSource = transform.GetComponent<AudioSource>();
        isNotInit = false;
    }

    public void NetworkPlay()
    {
        SendCustomNetworkEvent(VRC.Udon.Common.Interfaces.NetworkEventTarget.All, nameof(Play));
    }

    public void Play()
    {
        if (isNotInit) return;
        VRCPlayerApi player = Networking.GetOwner(gameObject);
        //Update avatar height
        if(Time.time - lastAvatarHeightUpdate > 10)
        {
            avatarHeight = GetAvatarHeight(player);
            lastAvatarHeightUpdate = Time.time;
            transform.localScale = Vector3.one * avatarHeight;
            float pitch = -Mathf.Log(avatarHeight * 0.1f) * 0.4f + 0.2f;
            pitch = Mathf.Clamp(pitch, 0.2f, 3f);
            float volume = avatarHeight * 0.3f + 0.5f;
            volume = Mathf.Clamp(volume, 0.5f, 1f);
            float distance = avatarHeight * 2;
            distance = Mathf.Clamp(distance, 1, 10);
            _audioSource.pitch = pitch;
            _audioSource.maxDistance = distance;
            _audioSource.volume = volume;
            Debug.Log($"[Clapper] Height: {avatarHeight} => pitch: {pitch} => volume: {volume} => distance: {distance}");
        }
        //Set position
        if (player.IsUserInVR())
            transform.position = Vector3.Lerp(player.GetTrackingData(VRCPlayerApi.TrackingDataType.LeftHand).position,
                player.GetTrackingData(VRCPlayerApi.TrackingDataType.RightHand).position, 0.5f);
        else
            transform.position = isHumanoid ? player.GetBonePosition(HumanBodyBones.Chest) :
                Vector3.Lerp(player.GetPosition(), player.GetTrackingData(VRCPlayerApi.TrackingDataType.Head).position, 0.7f);
        transform.rotation = player.GetRotation();
        //Play particle and audio source
        _particleSystem.Emit(1);
        _audioSource.Play();
    }

    bool isHumanoid;
    public float GetAvatarHeight(VRCPlayerApi player)
    {
        float height = 0;
        Vector3 postition1 = player.GetBonePosition(HumanBodyBones.Head);
        Vector3 postition2 = player.GetBonePosition(HumanBodyBones.Neck);
        height += Vector3.Distance(postition1,postition2);
        postition1 = player.GetBonePosition(HumanBodyBones.Hips);
        height += Vector3.Distance(postition1, postition2);
        isHumanoid = height > 0;
        if (!isHumanoid) return Vector3.Distance(player.GetPosition(), player.GetTrackingData(VRCPlayerApi.TrackingDataType.Head).position) * 1.15f; //For non humanoids
        postition2 = player.GetBonePosition(HumanBodyBones.RightLowerLeg);
        height += Vector3.Distance(postition1, postition2);
        postition1 = player.GetBonePosition(HumanBodyBones.RightFoot);
        height += Vector3.Distance(postition1, postition2);
        height *= 1.15f; // Adjusting for head
        return height;
    }
}
