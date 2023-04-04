#if !COMPILER_UDONSHARP && UNITY_EDITOR && UDONSHARP
using UdonSharp;
using UdonSharpEditor;
using UnityEditor;
using UnityEngine;
using VRCAudioLink;

[CustomEditor(typeof(AudioLink))]
public class AudioLinkEditor : Editor
{
    public override void OnInspectorGUI()
    {
        if (UdonSharpGUI.DrawDefaultUdonSharpBehaviourHeader(target)) return;
        EditorGUILayout.Space();
        if (GUILayout.Button(new GUIContent("Link all sound reactive objects to this AudioLink", "Links all UdonBehaviours with 'audioLink' parameter to this object."))) { LinkAll(); }
        EditorGUILayout.Space();
        base.OnInspectorGUI();
    }

    void LinkAll()
    {
        UdonSharpBehaviour[] allUdonSharpBehaviours = FindObjectsOfType<UdonSharpBehaviour>();
        foreach (var behaviour in allUdonSharpBehaviours)
        {
            if (behaviour.GetType().GetField("audioLink") != null)
            {
                behaviour.GetType().GetField("audioLink").SetValue(behaviour, target);
                EditorUtility.SetDirty(behaviour);

                if (PrefabUtility.IsPartOfPrefabInstance(behaviour))
                {
                    behaviour.GetType().GetField("audioLink").SetValue(behaviour, target);
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