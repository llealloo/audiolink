
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

namespace Thry.General
{
    [UdonBehaviourSyncMode(BehaviourSyncMode.None)]
    public class AvatarHeightTracker : UdonSharpBehaviour
    {
        VRCPlayerApi player;
        float height = 1;

        float lastUpdate = -20;

        const float UPDATE_RATE = 10;

        bool isNotInit = true;

        private void Init()
        {
            player = Networking.LocalPlayer;
            isNotInit = false;
        }

        public float GetHeight()
        {
            if (Time.time - lastUpdate < UPDATE_RATE) return height;
            if (isNotInit) Init();
            height = 0;
            Vector3 postition1 = player.GetBonePosition(HumanBodyBones.Head);
            Vector3 postition2 = player.GetBonePosition(HumanBodyBones.Neck);
            height += Vector3.Distance(postition1, postition2);
            postition1 = player.GetBonePosition(HumanBodyBones.Hips);
            height += Vector3.Distance(postition1, postition2);
            postition2 = player.GetBonePosition(HumanBodyBones.RightLowerLeg);
            height += Vector3.Distance(postition1, postition2);
            postition1 = player.GetBonePosition(HumanBodyBones.RightFoot);
            height += Vector3.Distance(postition1, postition2);
            height *= 1.15f; // Adjusting for head
            if (height == 0) height = 1; //For non humanoids
            lastUpdate = Time.time;
            return height;
        }

    }
}