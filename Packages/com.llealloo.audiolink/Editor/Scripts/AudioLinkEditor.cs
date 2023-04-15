#if !COMPILER_UDONSHARP && UNITY_EDITOR
using System.Reflection;

#if UDONSHARP
using UdonSharp;
using UdonSharpEditor;
#endif

using UnityEditor;
using UnityEngine;

namespace VRCAudioLink.Editor
{
    [CustomEditor(typeof(AudioLink))]
    public class AudioLinkEditor : UnityEditor.Editor
    {
        public override void OnInspectorGUI()
        {
#if UDONSHARP
            if (UdonSharpGUI.DrawDefaultUdonSharpBehaviourHeader(target)) return;
#endif
            // don't use Camera.main here because the main camera might not have the main camera tag?
            if (FindObjectsOfType<Camera>().Length <= 1)
            {
                EditorGUILayout.HelpBox("The current scene is missing a main camera, this could cause issues with the AudioLink camera.", MessageType.Warning);
            }

            if (((AudioLink)target).audioSource == null)
            {
                EditorGUILayout.HelpBox("No audio source assigned. AudioLink will not work.", MessageType.Warning);
            }

            EditorGUILayout.Space();
            if (GUILayout.Button(new GUIContent("Link all sound reactive objects to this AudioLink instance",
                    "Links all scripts with 'audioLink' parameter to this object.")))
            {
                LinkAll();
            }

            EditorGUILayout.Space();
            base.OnInspectorGUI();
        }

        void LinkAll()
        {
#if UDONSHARP
            UdonSharpBehaviour[] allBehaviours = FindObjectsOfType<UdonSharpBehaviour>();
#else
            MonoBehaviour[] allBehaviours = FindObjectsOfType<MonoBehaviour>();
#endif
            foreach (var behaviour in allBehaviours)
            {
                FieldInfo fieldInfo = behaviour.GetType().GetField("audioLink");
                // in case the field isn't called "audioLink"
                if (fieldInfo == null)
                {
                    foreach (FieldInfo field in behaviour.GetType().GetFields())
                    {
                        if (field.FieldType == typeof(AudioLink))
                        {
                            fieldInfo = field;
                            break;
                        }
                    }
                }
                if (fieldInfo != null)
                {
                    fieldInfo.SetValue(behaviour, target);
                    EditorUtility.SetDirty(behaviour);

                    if (PrefabUtility.IsPartOfPrefabInstance(behaviour))
                    {
                        PrefabUtility.RecordPrefabInstancePropertyModifications(behaviour);
                    }
                }
            }
        }
    }
}
#endif