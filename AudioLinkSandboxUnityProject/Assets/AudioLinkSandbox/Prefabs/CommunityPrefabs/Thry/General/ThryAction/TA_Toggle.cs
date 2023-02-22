
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
    public class TA_Toggle : UdonSharpBehaviour
    {
        public ThryAction action;
        public Toggle _uiToggle;
        public Animator _optionalAnimator;

        private void Start()
        {
            if (action) action.RegsiterAdapter(this);
        }

        [HideInInspector]
        public float local_float;
        [HideInInspector]
        public bool local_bool;

        bool _block;

        public void OnInteraction()
        {
            if (_block) return;
            local_bool = _uiToggle.isOn;
            UpdateOptionals();
            if (action) action.SetBool(local_bool);
        }

        public void SetAdapterBool()
        {
            _block = true;
            _uiToggle.isOn = local_bool;
            UpdateOptionals();
            _block = false;
        }

        public void SetAdapterFloat()
        {

        }

        private void UpdateOptionals()
        {
            if (_optionalAnimator != null)
            {
                _optionalAnimator.SetBool("isOn", local_bool);
            }
        }
    }

#if !COMPILER_UDONSHARP && UNITY_EDITOR

    [CustomEditor(typeof(TA_Toggle))]
    public class UI_Slider_Toggle_Editor : Editor
    {
        public override void OnInspectorGUI()
        {
            EditorGUILayout.LabelField("<size=20><color=#f542da>Toggle Adapter</color></size>", new GUIStyle(EditorStyles.label) { richText = true, alignment = TextAnchor.MiddleCenter }, GUILayout.Height(50));

            serializedObject.Update();
            TA_Toggle action = (TA_Toggle)target;
            if (!ThryActionEditor.MakeSureItsAnUdonBehaviour(action)) return;

            action.action = (ThryAction)EditorGUILayout.ObjectField(new GUIContent("Thry Action"), action.action, typeof(ThryAction), true);
            action._uiToggle = (Toggle)EditorGUILayout.ObjectField(new GUIContent("Toggle"), action._uiToggle, typeof(Toggle), true);

            EditorGUILayout.LabelField("Optional", EditorStyles.boldLabel);

            action._optionalAnimator = (Animator)EditorGUILayout.ObjectField(new GUIContent("Animator"), action._optionalAnimator, typeof(Animator), true);
        }
    }
#endif
}