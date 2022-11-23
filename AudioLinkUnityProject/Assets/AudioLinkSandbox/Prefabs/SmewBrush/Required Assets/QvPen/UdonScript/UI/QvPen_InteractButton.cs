using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon.Common.Interfaces;

namespace QvPen.Udon.UI
{
    [UdonBehaviourSyncMode(BehaviourSyncMode.NoVariableSync)]
    public class QvPen_InteractButton : UdonSharpBehaviour
    {
        [SerializeField]
        private bool canUseEveryone = false;
        [SerializeField]
        private bool canUseInstanceOwner = false;
        [SerializeField]
        private bool canUseOwner = false;
        [SerializeField]
        private bool canUseMaster = false;

        [SerializeField]
        private bool isGlobalEvent = false;
        [SerializeField]
        private bool onlySendToOwner = false;
        [SerializeField]
        private UdonSharpBehaviour udonSharpBehaviour;
        [SerializeField]
        private UdonSharpBehaviour[] udonSharpBehaviours = { };
        [SerializeField]
        private string customEventName = "Unnamed";

        public AudioSource SoundFX;

        public override void Interact()
        {
            SoundFX.Play();
            if (!canUseEveryone)
            {
                if (canUseInstanceOwner && !Networking.IsInstanceOwner)
                    return;

                if (canUseMaster && !Networking.IsMaster)
                    return;

                if (canUseOwner && !Networking.IsOwner(gameObject))
                    return;
            }

            if (udonSharpBehaviour)
                if (!isGlobalEvent)
                    udonSharpBehaviour.SendCustomEvent(customEventName);
                else
                    udonSharpBehaviour.SendCustomNetworkEvent(onlySendToOwner ? NetworkEventTarget.Owner : NetworkEventTarget.All, customEventName);
            else if (udonSharpBehaviours.Length > 0)
                if (!isGlobalEvent)
                    foreach (var udonSharpBehaviour in udonSharpBehaviours)
                        udonSharpBehaviour.SendCustomEvent(customEventName);
                else
                    foreach (var udonSharpBehaviour in udonSharpBehaviours)
                        udonSharpBehaviour.SendCustomNetworkEvent(onlySendToOwner ? NetworkEventTarget.Owner : NetworkEventTarget.All, customEventName);
        }
    }
}
