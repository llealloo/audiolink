using UdonSharp;
using UnityEngine;
using VRC.SDKBase;

namespace QvPen.UdonScript.World
{
    [UdonBehaviourSyncMode(BehaviourSyncMode.NoVariableSync)]
    public class QvPen_PlayerMods : UdonSharpBehaviour
    {
        [SerializeField]
        private float walkSpeed = 2f;
        [SerializeField]
        private float runSpeed = 4f;
        [SerializeField]
        private float strafeSpeed = 2f;
        [SerializeField]
        private float jumpImpulse = 3f;
        [SerializeField]
        private float gravityStrength = 1f;
        [SerializeField]
        private bool useLegacyLocomotion = false;

        public override void OnPlayerJoined(VRCPlayerApi player)
        {
            if (player.isLocal)
            {
                player.SetRunSpeed(runSpeed);
                player.SetWalkSpeed(walkSpeed);
                player.SetStrafeSpeed(strafeSpeed);
                player.SetJumpImpulse(jumpImpulse);
                player.SetGravityStrength(gravityStrength);
                if (useLegacyLocomotion)
                    player.UseLegacyLocomotion();
            }
        }
    }
}
