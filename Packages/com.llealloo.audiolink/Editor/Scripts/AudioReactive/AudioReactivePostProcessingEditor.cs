#if !COMPILER_UDONSHARP && UNITY_EDITOR
using UnityEditor;
using UnityEngine;

namespace AudioLink.Editor
{
    [CustomEditor(typeof(AudioReactivePostProcessing))]
    public class AudioReactivePostProcessingEditor : AudioReactiveCommon
    {
        public override void OnInspectorGUI()
        {
            StandardReactiveEditorHeader("AudioLink Reactive Post Processing:\nAffect the Weight of a PostProcessingVolume.\nCan be used to affect Bloom, Chromatic Abberation, Ambient Occusion, Depth of Field, etc.");

            StandardReactiveEditor("Weight");

            EditorGUILayout.Space();
            EditorGUILayout.LabelField("Reactivity Settings", EditorStyles.boldLabel);

            serializedObject.Update();

            SerializedProperty fromWeightProperty = serializedObject.FindProperty(nameof(AudioReactivePostProcessing.fromWeight));
            SerializedProperty toWeightProperty = serializedObject.FindProperty(nameof(AudioReactivePostProcessing.toWeight));

            float fromWeight = fromWeightProperty.floatValue;
            float toWeight = toWeightProperty.floatValue;

            Rect rangeSliderHorizontal = EditorGUILayout.BeginHorizontal();
            
                Rect rangeSliderLabel = EditorGUI.PrefixLabel(rangeSliderHorizontal, new GUIContent("Weight Range"));
                rangeSliderLabel.height += 18;

                Rect floatRect = rangeSliderLabel;
                Rect sliderRect = rangeSliderLabel;

                floatRect.width = 40;

                sliderRect.width -= 45 * 2;
                sliderRect.x += 45;

                fromWeight = EditorGUI.FloatField(floatRect, fromWeight);

                EditorGUI.MinMaxSlider(sliderRect, ref fromWeight, ref toWeight, 0.0f, 1.0f);
                
                floatRect.x += sliderRect.width + 50;
                toWeight = EditorGUI.FloatField(floatRect, toWeight);

            EditorGUILayout.EndHorizontal();

            fromWeightProperty.floatValue = fromWeight;
            toWeightProperty.floatValue = toWeight;

            serializedObject.ApplyModifiedProperties();

            EditorGUILayout.Space(20);
        }
    }
}
#endif