
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
    public class TA_Slider : UdonSharpBehaviour
    {
        public ThryAction action;
        public Slider _uiSlider;
        [Header("Optional Handle Text")]
        public Text _uiSliderHandleText;
        public string _uiSliderHandlePrefix;
        public string _uiSliderHandlePostfix;

        public Animator _optionalAnimator;

        private void Start()
        {
            action.RegsiterAdapter(this);
        }

        [HideInInspector]
        public float local_float;
        [HideInInspector]
        public bool local_bool;

        bool _block;        

        public void OnInteraction()
        {
            if (_block) return;
            local_float = _uiSlider.value;
            local_bool = local_float == 1;
            UpdateOptionals();
            action.SetFloat(local_float);
        }

        public void SetAdapterBool()
        {
            
        }

        public void SetAdapterFloat()
        {
            _block = true;
            _uiSlider.value = local_float;
            UpdateOptionals();
            _block = false;
        }

        private void UpdateOptionals()
        {
            if (_uiSliderHandleText != null) _uiSliderHandleText.text = _uiSliderHandlePrefix + local_float + _uiSliderHandlePostfix;
            if (_optionalAnimator != null)
            {
                _optionalAnimator.SetFloat("value", local_float);
            }
        }
    }

#if !COMPILER_UDONSHARP && UNITY_EDITOR

    [CustomEditor(typeof(TA_Slider))]
    public class UI_Slider_Adapter_Editor : Editor
    {
        public override void OnInspectorGUI()
        {
            EditorGUILayout.LabelField("<size=20><color=#f542da>Slider Adapter</color></size>", new GUIStyle(EditorStyles.label) { richText = true, alignment = TextAnchor.MiddleCenter }, GUILayout.Height(50));

            serializedObject.Update();
            TA_Slider action = (TA_Slider)target;
            if (!ThryActionEditor.MakeSureItsAnUdonBehaviour(action)) return;

            action.action = (ThryAction)EditorGUILayout.ObjectField(new GUIContent("Thry Action"), action.action, typeof(ThryAction), true);
            action._uiSlider = (Slider)EditorGUILayout.ObjectField(new GUIContent("Slider"), action._uiSlider, typeof(Slider), true);

            EditorGUILayout.LabelField("Optional", EditorStyles.boldLabel);

            action._optionalAnimator = (Animator)EditorGUILayout.ObjectField(new GUIContent("Animator"), action._optionalAnimator, typeof(Animator), true);
            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.LabelField("Handle:");
            action._uiSliderHandlePrefix = EditorGUILayout.TextField(action._uiSliderHandlePrefix);
            action._uiSliderHandleText = (Text)EditorGUILayout.ObjectField(action._uiSliderHandleText, typeof(Text), true);
            action._uiSliderHandlePostfix = EditorGUILayout.TextField(action._uiSliderHandlePostfix);
            EditorGUILayout.EndHorizontal();

            /*Really neat code, which is why i am leaving it in, but not really needed anymore
            action._useCurve = EditorGUILayout.Toggle("Use Curve", action._useCurve);
            if (action._useCurve)
            {
                if (action._curve == null)
                {
                    action._curve = AnimationCurve.Linear(0, 0, 1, 1);
                    action._reverseCurve = ReverseCurve(action._curve);
                }
                EditorGUI.BeginChangeCheck();
                action._curve = EditorGUILayout.CurveField("Float Transformation Curve", action._curve);
                if (EditorGUI.EndChangeCheck()) action._reverseCurve = ReverseCurve(action._curve);
                //EditorGUILayout.CurveField("Reverse Curve", action._reverseCurve);
            }*/
        }

        /*Really neat code, which is why i am leaving it in, but not really needed anymore
        static AnimationCurve ReverseCurve(AnimationCurve c)
        {
            AnimationCurve rev = new AnimationCurve();
            for (int k = 0; k < c.keys.Length; k++)
            {
                Keyframe tan = c.keys[c.keys.Length - k - 1];
                Keyframe newKey = new Keyframe(c.keys[k].value, c.keys[k].time);
                newKey.weightedMode = tan.weightedMode;
                newKey.outTangent = tan.inTangent;
                newKey.outWeight = tan.inWeight;
                newKey.inTangent = tan.outTangent;
                newKey.inWeight = tan.outWeight;
                rev.AddKey(newKey);
            }
            return rev;
        }*/
    }
#endif
}