#if !COMPILER_UDONSHARP && UNITY_EDITOR
using Airtime.Player.Movement;
using UdonSharp;
using UdonSharpEditor;
using UnityEditor;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

namespace Airtime
{
    public class AirtimeEditorUtility
    {
        public static PlayerController AutoConfigurePlayerController()
        {
            GUIStyle warning = new GUIStyle(EditorStyles.wordWrappedLabel);

            if (UnityEditor.SceneManagement.PrefabStageUtility.GetCurrentPrefabStage() != null)
            {
                warning.normal.textColor = Color.yellow;
                GUILayout.Label("You are in prefab editing mode: please assign a PlayerController UdonBehaviour manually.", warning);

                return null;
            }

            UdonBehaviour[] behaviours = GameObject.FindObjectsOfType<UdonBehaviour>();

            PlayerController controller = null;
            int controllers = 0;

            for (int i = 0; i < behaviours.Length; i++)
            {
                if (UdonSharpEditorUtility.GetUdonSharpBehaviourType(behaviours[i]) == typeof(PlayerController))
                {
                    controller = (PlayerController)UdonSharpEditorUtility.GetProxyBehaviour(behaviours[i]);
                    controllers++;

                    if (controllers > 1)
                    {
                        warning.normal.textColor = Color.red;
                        GUILayout.Label("More than one PlayerController UdonBehaviour was found in the scene! Please only use one.", warning);

                        return null;
                    }
                }
            }

            if (controllers == 0)
            {
                warning.normal.textColor = Color.yellow;
                GUILayout.Label("No PlayerController UdonBehaviour was found in the scene. Please add one.", warning);
            }

            return controller;
        }
    }
}
#endif
