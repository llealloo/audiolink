
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
    [UdonBehaviourSyncMode(BehaviourSyncMode.None)]
    public class UnpooledPlayerController : UdonSharpBehaviour
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

        // Effects
        private int playerState;
        private float playerScaledVelocity;

        public void Start()
        {
            localPlayer = Networking.LocalPlayer;
            if (localPlayer != null)
            {
                localPlayerCached = true;
            }

            if (controller != null)
            {
                Component behaviour = GetComponent(typeof(UdonBehaviour));
                controller.RegisterEventHandler((UdonBehaviour)behaviour);

                controllerCached = true;
            }
        }

        public void LateUpdate()
        {
            if (localPlayerCached && Utilities.IsValid(localPlayer))
            {
                if (controllerCached)
                {
                    playerState = controller.GetPlayerState();
                    playerScaledVelocity = controller.GetScaledVelocity();
                }

                transform.SetPositionAndRotation(localPlayer.GetPosition(), localPlayer.GetRotation());

                // set transform of grind particles
                grindTransform.rotation = controller.GetGrindDirection();

                // animator effects
                if (useAnimator)
                {
                    animator.SetFloat(animatorVelocityParam, playerScaledVelocity);
                    animator.SetBool(animatorWallridingParam, playerState == STATE_WALLRIDE);
                    animator.SetBool(animatorGrindingParam, playerState == STATE_GRINDING);
                }
            }
        }

        public void _DoubleJump()
        {
            doubleJumpSound.PlayOneShot(doubleJumpSound.clip);
        }

        public void _WallJump()
        {
            wallJumpSound.PlayOneShot(wallJumpSound.clip);
        }

        public void _StartGrind()
        {
            grindStartSound.PlayOneShot(grindStartSound.clip);
        }

        public void _StopGrind()
        {
            grindStopSound.PlayOneShot(grindStopSound.clip);
        }

        public void _SwitchGrindDirection()
        {
            grindStopSound.PlayOneShot(grindStopSound.clip);
        }
    }

#if !COMPILER_UDONSHARP && UNITY_EDITOR
    [CustomEditor(typeof(UnpooledPlayerController))]
    public class UnpooledPlayerControllerEditor : Editor
    {
        public override void OnInspectorGUI()
        {
            if (UdonSharpGUI.DrawDefaultUdonSharpBehaviourHeader(target)) return;

            UnpooledPlayerController player = target as UnpooledPlayerController;

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
