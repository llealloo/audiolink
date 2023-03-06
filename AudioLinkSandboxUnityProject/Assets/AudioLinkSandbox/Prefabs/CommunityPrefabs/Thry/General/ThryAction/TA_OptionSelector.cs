
using UdonSharp;
#if !COMPILER_UDONSHARP && UNITY_EDITOR
using UnityEditor;
using UnityEditorInternal;
#endif
using UnityEngine;
using UnityEngine.UI;
using VRC.SDKBase;
using VRC.Udon;

namespace Thry.General
{
    [UdonBehaviourSyncMode(BehaviourSyncMode.Manual)]
    public class TA_OptionSelector : UdonSharpBehaviour
    {
        public ThryAction action;

        public string[] options;
        public Text selectedText;

        public Animator _optionalAnimator;

        private void Start()
        {
            action.RegsiterAdapter(this);
        }

        [HideInInspector]
        public float local_float;
        [HideInInspector]
        public bool local_bool;

        public void SetAdapterBool()
        {

        }

        public void SetAdapterFloat()
        {
            UpdateOptionals();
        }

        private void UpdateOptionals()
        {
            if (_optionalAnimator != null)
            {
                _optionalAnimator.SetFloat("value", local_float);
            }
            selectedText.text = options[(int)local_float];
        }

        public void Next()
        {
            Networking.SetOwner(Networking.LocalPlayer, gameObject);
            local_float = (local_float + 1) % options.Length;
            UpdateOptionals();
            action.SetFloat(local_float);
        }

        public void Prev()
        {
            Networking.SetOwner(Networking.LocalPlayer, gameObject);
            local_float = (local_float - 1 + options.Length) % options.Length;
            UpdateOptionals();
            action.SetFloat(local_float);
        }
    }

#if !COMPILER_UDONSHARP && UNITY_EDITOR

    [CustomEditor(typeof(TA_OptionSelector))]
    public class TA_OptionSelector_Editor : Editor
    {

        public override void OnInspectorGUI()
        {
            EditorGUILayout.LabelField("<size=20><color=#f542da>Option Selector Adapter</color></size>", new GUIStyle(EditorStyles.label) { richText = true, alignment = TextAnchor.MiddleCenter }, GUILayout.Height(50));

            serializedObject.Update();
            TA_OptionSelector action = (TA_OptionSelector)target;
            if (!ThryActionEditor.MakeSureItsAnUdonBehaviour(action)) return;

            action.action = (ThryAction)EditorGUILayout.ObjectField(new GUIContent("Thry Action"), action.action, typeof(ThryAction), true);
            action.selectedText = (Text)EditorGUILayout.ObjectField(new GUIContent("Selected Text"), action.selectedText, typeof(Text), true);
            
            list.DoLayoutList();

            EditorGUILayout.LabelField("Optional", EditorStyles.boldLabel);

            action._optionalAnimator = (Animator)EditorGUILayout.ObjectField(new GUIContent("Animator"), action._optionalAnimator, typeof(Animator), true);

            serializedObject.ApplyModifiedProperties();
        }

        ReorderableList list;
        private void OnEnable()
        {
            list = new ReorderableList(serializedObject, serializedObject.FindProperty("options"), true, true, true, true);
            list.drawElementCallback = DrawListItems; 
            list.drawHeaderCallback = DrawHeader;
        }

        void DrawListItems(Rect rect, int index, bool isActive, bool isFocused)
        {
            SerializedProperty element = list.serializedProperty.GetArrayElementAtIndex(index);
            element.stringValue = EditorGUI.TextField(rect, element.stringValue);
        }

        //Draws the header
        void DrawHeader(Rect rect)
        {
            EditorGUI.LabelField(rect, "Options");
        }
    }
#endif
}