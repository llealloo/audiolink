
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;
using Airtime.Player.Movement;

#if !COMPILER_UDONSHARP && UNITY_EDITOR
using UnityEditor;
using UdonSharpEditor;
using Airtime;
#endif

namespace Airtime.Player.Effects
{
    // PooledPlayerController
    // requires Phasedragon's SimpleObjectPool
    [UdonBehaviourSyncMode(BehaviourSyncMode.Continuous)]
    public class PooledPlayerController : UdonSharpBehaviour
    {
        [HideInInspector] public PlayerController controller;
        private bool controllerCached = false;

        [Header("Animation")]
        public bool useAnimator;
        public Animator animator;
        public string animatorVelocityParam = "Velocity";
        public string animatorWallridingParam = "IsWallriding";
        public string animatorGrindingParam = "IsGrinding";

        [Header("Effects")]
        public Transform grindTransform;
        public Transform wallrideTransform;
        public AudioSource doubleJumpSound;
        public AudioSource wallJumpSound;
        public AudioSource grindStartSound;
        public AudioSource grindStopSound;

        // VRC Stuff
        private VRCPlayerApi owner;
        private bool ownerCached = false;
        private VRCPlayerApi localPlayer;
        private bool localPlayerCached = false;

        // Player States (we have to keep a copy here because of udon)
        public const int STATE_STOPPED = 0;
        public const int STATE_GROUNDED = 1;
        public const int STATE_AERIAL = 2;
        public const int STATE_WALLRIDE = 3;
        public const int STATE_SNAPPING = 4;
        public const int STATE_GRINDING = 5;
        public const int STATE_CUSTOM = 6;

        // Networked Effects
        [UdonSynced] private int networkPlayerState;
        [UdonSynced(UdonSyncMode.Linear)] private float networkPlayerScaledVelocity;
        [UdonSynced(UdonSyncMode.Linear)] private Quaternion networkPlayerGrindDirection;

        public void Start()
        {
            localPlayer = Networking.LocalPlayer;
            if (localPlayer != null)
            {
                localPlayerCached = true;
            }

            if (controller != null)
            {
                controllerCached = true;
            }
        }

        public void LateUpdate()
        {
            if (ownerCached && localPlayerCached && Utilities.IsValid(localPlayer))
            {
                // if owner, use synced variables to display useful information
                if (controllerCached && owner == localPlayer)
                {
                    networkPlayerState = controller.GetPlayerState();
                    networkPlayerScaledVelocity = controller.GetScaledVelocity();
                    networkPlayerGrindDirection = controller.GetGrindDirection();
                }

                transform.SetPositionAndRotation(owner.GetPosition(), owner.GetRotation());

                // set transform of grind particles
                grindTransform.rotation = networkPlayerGrindDirection;

                // animator effects
                if (useAnimator)
                {
                    animator.SetFloat(animatorVelocityParam, networkPlayerScaledVelocity);
                    animator.SetBool(animatorWallridingParam, networkPlayerState == STATE_WALLRIDE);
                    animator.SetBool(animatorGrindingParam, networkPlayerState == STATE_GRINDING);
                }
            }
        }

        public void UpdateOwner()
        {
            owner = Networking.GetOwner(gameObject);
            if (owner != null)
            {
                if (owner == localPlayer && controller != null)
                {
                    Component behaviour = GetComponent(typeof(UdonBehaviour));
                    controller.RegisterEventHandler((UdonBehaviour)behaviour);
                }

                ownerCached = true;
            }
        }

        public override void OnPlayerLeft(VRCPlayerApi player)
        {
            if (owner == player)
            {
                owner = null;
                ownerCached = false;
            }
        }

        public void _DoubleJump()
        {
            SendCustomNetworkEvent(VRC.Udon.Common.Interfaces.NetworkEventTarget.All, "NetworkedDoubleJump");
        }

        public void NetworkedDoubleJump()
        {
            doubleJumpSound.PlayOneShot(doubleJumpSound.clip);
        }

        public void _WallJump()
        {
            SendCustomNetworkEvent(VRC.Udon.Common.Interfaces.NetworkEventTarget.All, "NetworkedWallJump");
        }

        public void NetworkedWallJump()
        {
            wallJumpSound.PlayOneShot(wallJumpSound.clip);
        }

        public void _StartGrind()
        {
            SendCustomNetworkEvent(VRC.Udon.Common.Interfaces.NetworkEventTarget.All, "NetworkedStartGrind");
        }

        public void NetworkedStartGrind()
        {
            grindStartSound.PlayOneShot(grindStartSound.clip);
        }

        public void _StopGrind()
        {
            SendCustomNetworkEvent(VRC.Udon.Common.Interfaces.NetworkEventTarget.All, "NetworkedStopGrind");
        }

        public void _SwitchGrindDirection()
        {
            SendCustomNetworkEvent(VRC.Udon.Common.Interfaces.NetworkEventTarget.All, "NetworkedStopGrind");
        }

        public void NetworkedStopGrind()
        {
            grindStopSound.PlayOneShot(grindStopSound.clip);
        }
    }

#if !COMPILER_UDONSHARP && UNITY_EDITOR
    [CustomEditor(typeof(PooledPlayerController))]
    public class PooledPlayerControllerEditor : Editor
    {
        public override void OnInspectorGUI()
        {
            if (UdonSharpGUI.DrawDefaultUdonSharpBehaviourHeader(target)) return;

            PooledPlayerController player = target as PooledPlayerController;

            GUILayout.Label("Player Controller (Required)", EditorStyles.boldLabel);

            EditorGUI.BeginChangeCheck();
            PlayerController newController = (PlayerController)EditorGUILayout.ObjectField("Player Controller", player.controller, typeof(PlayerController), true);
            if (EditorGUI.EndChangeCheck())
            {
                Undo.RecordObject(player, "Change Player Controller");
                player.controller = newController;
                EditorUtility.SetDirty(player);
            }

            if (player.controller == null)
            {
                SerializedProperty controllerProp = serializedObject.FindProperty("controller");
                controllerProp.objectReferenceValue = AirtimeEditorUtility.AutoConfigurePlayerController();
                serializedObject.ApplyModifiedProperties();
            }

            GUILayout.Label("Script", EditorStyles.boldLabel);

            base.OnInspectorGUI();
        }
    }
#endif
}
