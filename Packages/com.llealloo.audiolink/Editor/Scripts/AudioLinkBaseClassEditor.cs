#if !UDONSHARP && UNITY_EDITOR
using UnityEditor;
using UnityEditor.Experimental.SceneManagement;
using UnityEngine;

namespace AudioLink.Editor 
{
    [CustomEditor(typeof(AudioLinkBaseClass), true)]
    public class AudioLinkControllerEditor : UnityEditor.Editor
    {
        public void OnEnable()
        {
            GameObject go = ((AudioLinkBaseClass)target).gameObject;
            PrefabStage prefabStage = PrefabStageUtility.GetCurrentPrefabStage();            
            if (prefabStage == null || !prefabStage.IsPartOfPrefabContents(go))
            {
                GameObjectUtility.RemoveMonoBehavioursWithMissingScript(go);
            }
        }
    } 
}
#endif