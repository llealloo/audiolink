#if UDONSHARP
using VRC.SDKBase;
using UdonSharp;
#elif PVR_CCK_WORLDS
using PVR.CCK.Worlds.PSharp;
#endif

using UnityEngine;
using UnityEngine.Serialization;

namespace AudioLink
{
#if UDONSHARP
    [RequireComponent(typeof(Collider)), UdonBehaviourSyncMode(BehaviourSyncMode.None)]
    public class AudioLinkZone : UdonSharpBehaviour
#elif PVR_CCK_WORLDS
	[RequireComponent(typeof(Collider))]
	public class  AudioLinkZone : PSharpBehaviour
#else
    [RequireComponent(typeof(Collider))]
    public class AudioLinkZone : MonoBehaviour
#endif
    {
        [Header("Targets")]
        public AudioLink audioLink;
        [FormerlySerializedAs("audioSource")]
        public AudioSource targetAudioSource;

        [Header("Settings")]
        public bool disableSource = true;
        public bool enableTarget = true;

#if UDONSHARP
        public override void OnPlayerTriggerEnter(VRCPlayerApi player)
        {
            if (!player.IsValid() || !player.isLocal) return;
#elif PVR_CCK_WORLDS
		public override void OnPlayerTriggerEnter(PSharpPlayer player)
		{
            if (player.IsNull || !player.IsLocal) return;   
#else
        private void OnTriggerEnter(Collider player)
        {
            if (!player.gameObject.CompareTag("Player")) return;
#endif
            if (disableSource && audioLink.audioSource != null) audioLink.audioSource.gameObject.SetActive(false);

            audioLink.audioSource = targetAudioSource;

            if (enableTarget && audioLink.audioSource != null) audioLink.audioSource.gameObject.SetActive(true);
        }
    }
}
