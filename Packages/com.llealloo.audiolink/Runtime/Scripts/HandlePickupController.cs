
#if UDONSHARP
using UdonSharp;
using UnityEngine;
using UnityEngine.Animations;
using VRC.SDKBase;
using VRC.Udon;

namespace AudioLink
{
    public class HandlePickupController : UdonSharpBehaviour
    {

        public AudioLinkControllerHandle leftHandle;
        public AudioLinkControllerHandle rightHandle;
        public BoxCollider leftHandleZone;
        public BoxCollider rightHandleZone;

        private VRCPlayerApi localPlayer;
        private bool inVR;
        private bool inRange;
        private Vector3 leftHandPosition;
        private Vector3 rightHandPosition;
        private Vector3 leftHandPositionLocal;
        private Vector3 rightHandPositionLocal;
        private bool leftHandleActive;
        private bool rightHandleActive;
        private bool leftHandleZoneHit;
        private bool rightHandleZoneHit;

        void Start()
        {
            localPlayer = Networking.LocalPlayer;
            inVR = localPlayer.IsUserInVR();
            inRange = false;
            leftHandleActive = false;
            rightHandleActive = false;

            if (inVR)
            {
                leftHandle.EnableHandle();
                rightHandle.EnableHandle();
            }
            else
            {
                leftHandle.DisableHandle();
                rightHandle.DisableHandle();
            }
        }

        private void PostLateUpdate()
        {
            if (inVR && inRange)
            {
                leftHandPosition = localPlayer.GetBonePosition(HumanBodyBones.LeftHand);
                rightHandPosition = localPlayer.GetBonePosition(HumanBodyBones.RightHand);

                leftHandPositionLocal = transform.InverseTransformPoint(leftHandPosition);
                rightHandPositionLocal = transform.InverseTransformPoint(rightHandPosition);

                leftHandleZoneHit = IsPointInsideBox(leftHandPositionLocal, leftHandleZone.center, leftHandleZone.size) || IsPointInsideBox(rightHandPositionLocal, leftHandleZone.center, leftHandleZone.size);
                rightHandleZoneHit = IsPointInsideBox(leftHandPositionLocal, rightHandleZone.center, rightHandleZone.size) || IsPointInsideBox(rightHandPositionLocal, rightHandleZone.center, rightHandleZone.size);

                if (leftHandleZoneHit) 
                {
                    leftHandle.EnableHandle();
                }
                else
                {
                    leftHandle.DisableHandle();
                }
                if (rightHandleZoneHit) 
                {
                    rightHandle.EnableHandle();
                }
                else
                {
                    rightHandle.DisableHandle();
                }

                // something is busted with this optimization
                /*if (leftHandleZoneHit)
                {
                    if(!leftHandleActive)
                    {
                        leftHandle.EnableHandle();
                        leftHandleActive = true;
                    }
                }
                else
                {
                    if(leftHandleActive)
                    {
                        leftHandle.DisableHandle();
                        leftHandleActive = false;
                    }
                }

                if (rightHandleZoneHit)
                {
                    if(!rightHandleActive)
                    {
                        rightHandle.EnableHandle();
                        rightHandleActive = true;
                    }
                }
                else
                {
                    if(rightHandleActive)
                    {
                        rightHandle.DisableHandle();
                        rightHandleActive = false;
                    }
                }*/

            }
        }

        public override void OnPlayerTriggerEnter(VRCPlayerApi player)
        {
            if (localPlayer == player && inVR)
            {
                inRange = true;
            }
        }

        public override void OnPlayerTriggerExit(VRCPlayerApi player)
        {
            if (localPlayer == player && inVR)
            {
                inRange = false;
                leftHandle.DisableHandle();
                rightHandle.DisableHandle();
            }
        }

        private bool IsPointInsideBox(Vector3 point, Vector3 boxCenter, Vector3 boxSize)
        {
            Vector3 halfSize = boxSize * 0.5f;
            return 
                (point.x >= boxCenter.x - halfSize.x && point.x <= boxCenter.x + halfSize.x) &&
                (point.y >= boxCenter.y - halfSize.y && point.y <= boxCenter.y + halfSize.y) &&
                (point.z >= boxCenter.z - halfSize.z && point.z <= boxCenter.z + halfSize.z);
        }

    }
}
#endif
