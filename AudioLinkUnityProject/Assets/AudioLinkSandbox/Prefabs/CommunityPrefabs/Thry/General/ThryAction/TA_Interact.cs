
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
    public class TA_Interact : UdonSharpBehaviour
    {
        public ThryAction action;

        private void Start()
        {
            action.RegsiterAdapter(this);
        }
        
        public float local_float;
        public bool local_bool;

        public override void Interact()
        {
            action.OnInteraction();
        }

        public void SetAdapterBool(){}
        public void SetAdapterFloat(){}
    }

#if !COMPILER_UDONSHARP && UNITY_EDITOR

    [CustomEditor(typeof(TA_Interact))]
    public class TA_Interact_Editor : Editor
    {
        public override void OnInspectorGUI()
        {
            EditorGUILayout.LabelField("<size=20><color=#f542da>Interact Adapter</color></size>", new GUIStyle(EditorStyles.label) { richText = true, alignment = TextAnchor.MiddleCenter }, GUILayout.Height(50));

            serializedObject.Update();
            TA_Interact action = (TA_Interact)target;
            if (!ThryActionEditor.MakeSureItsAnUdonBehaviour(action)) return;
            UdonSharpEditor.UdonSharpGUI.DrawInteractSettings(action);
            if (action.action == null)
            {
                if (action.gameObject.GetComponent<ThryAction>() != null)
                    action.action = action.gameObject.GetComponent<ThryAction>();
            }
            action.action = (ThryAction)EditorGUILayout.ObjectField(new GUIContent("Thry Action"), action.action, typeof(ThryAction), true);
        }
    }
#endif
}