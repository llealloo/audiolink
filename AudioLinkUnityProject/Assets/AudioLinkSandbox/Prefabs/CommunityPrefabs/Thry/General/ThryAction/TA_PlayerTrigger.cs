
using UdonSharp;
#if !COMPILER_UDONSHARP && UNITY_EDITOR
using UnityEditor;
#endif
using UnityEngine;
using UnityEngine.UI;
using VRC.SDKBase;
using VRC.Udon;

namespace Thry.General
{
    [UdonBehaviourSyncMode(BehaviourSyncMode.Manual)]
    public class TA_PlayerTrigger : UdonSharpBehaviour
    {
        public ThryAction action;
        public bool onlyLocalPlayer = true;
        public bool reactToTrigger = true;
        public bool reactToCollision = true;

        private void Start()
        {
            action.RegsiterAdapter(this);
        }

        [HideInInspector]
        public float local_float;
        [HideInInspector]
        public bool local_bool;

        public override void OnPlayerTriggerEnter(VRCPlayerApi player)
        {
            if(reactToTrigger && (!onlyLocalPlayer || player == Networking.LocalPlayer)) action.OnInteraction();
        }

        public override void OnPlayerCollisionEnter(VRCPlayerApi player)
        {
            Debug.Log((!onlyLocalPlayer || player == Networking.LocalPlayer));
            if (reactToCollision && (!onlyLocalPlayer || player == Networking.LocalPlayer)) action.OnInteraction();
        }

        public void SetAdapterBool(){}
        public void SetAdapterFloat(){}
    }

#if !COMPILER_UDONSHARP && UNITY_EDITOR

    [CustomEditor(typeof(TA_PlayerTrigger))]
    public class TA_PlayerTrigger_Editor : Editor
    {
        public override void OnInspectorGUI()
        {
            EditorGUILayout.LabelField("<size=20><color=#f542da>Player Collider Adapter</color></size>", new GUIStyle(EditorStyles.label) { richText = true, alignment = TextAnchor.MiddleCenter }, GUILayout.Height(50));

            serializedObject.Update();
            TA_PlayerTrigger action = (TA_PlayerTrigger)target;
            if (!ThryActionEditor.MakeSureItsAnUdonBehaviour(action)) return;

            action.action = (ThryAction)EditorGUILayout.ObjectField(new GUIContent("Thry Action"), action.action, typeof(ThryAction), true);
            action.onlyLocalPlayer = EditorGUILayout.Toggle("Only Local Player", action.onlyLocalPlayer);
            action.reactToTrigger = EditorGUILayout.Toggle("Fire on Trigger", action.reactToTrigger);
            action.reactToCollision = EditorGUILayout.Toggle("Fire on Collision", action.reactToCollision);
        }
    }
#endif
}