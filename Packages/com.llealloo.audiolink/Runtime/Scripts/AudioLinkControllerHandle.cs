
#if UDONSHARP
using UdonSharp;
using UnityEngine;
using UnityEngine.Animations;
using VRC.SDKBase;
using VRC.Udon;

namespace AudioLink
{
    public class AudioLinkControllerHandle : UdonSharpBehaviour
    {
        public ParentConstraint parentConstraint;
        public AudioLinkControllerHandle otherHandle;
    
        private ParentConstraint selfConstraint;
        private VRC_Pickup thisHandlePickup;
        private VRC_Pickup otherHandlePickup;
        private VRCPlayerApi localPlayer;
        private bool handleEnabled;
    
        public void Start()
        {
            selfConstraint = GetComponent<ParentConstraint>();
            thisHandlePickup = GetComponent<VRC_Pickup>();
            otherHandlePickup = otherHandle.GetComponent<VRC_Pickup>();
            localPlayer = Networking.LocalPlayer;
        }
    
        public override void OnPickup()
        {
            Networking.SetOwner(localPlayer, parentConstraint.gameObject);
    
            selfConstraint.enabled = false;
    
            parentConstraint.enabled = true;

            otherHandlePickup.pickupable = false;
    
            int me = -1, other = -1;
            for (int i = 0; i < 2; i++)
            {
                if (parentConstraint.GetSource(i).sourceTransform == transform)
                {
                    me = i;
                }
                else
                {
                    other = i;
                }
            }
            
            if (parentConstraint.GetSource(other).weight > 0)
            {
                var otherSource = parentConstraint.GetSource(other);
                otherSource.weight = 0.5f;
                var meSource = parentConstraint.GetSource(me);
                meSource.weight = 0.5f;
                parentConstraint.SetSource(me, meSource);
                parentConstraint.SetSource(other, otherSource);
            }
            else
            {
                var meSource = parentConstraint.GetSource(me);
                meSource.weight = 1;
                parentConstraint.SetSource(me, meSource);
            }
        }
    
        public override void OnDrop()
        {
            selfConstraint.enabled = true;

            otherHandle.UpdateHandleState();
    
            int me = -1, other = -1;
            for (int i = 0; i < 2; i++)
            {
                if (parentConstraint.GetSource(i).sourceTransform == transform)
                {
                    me = i;
                }
                else
                {
                    other = i;
                }
            }
    
            var meSource = parentConstraint.GetSource(me);
            meSource.weight = 0;
            parentConstraint.SetSource(me, meSource);
            if (parentConstraint.GetSource(other).weight > 0)
            {
                var otherSource = parentConstraint.GetSource(other);
                otherSource.weight = 1f;
                parentConstraint.SetSource(other, otherSource);
            }
            else
            {
                parentConstraint.enabled = false;
            }
        }

        public void EnableHandle()
        {
            handleEnabled = true;
            //if (!otherHandlePickup.IsHeld) UpdateHandleState();
            UpdateHandleState();
        }

        public void DisableHandle()
        {
            handleEnabled = false;
            UpdateHandleState();
        }

        public void UpdateHandleState()
        {
            thisHandlePickup.pickupable = handleEnabled;
        }
    }
}
#endif
