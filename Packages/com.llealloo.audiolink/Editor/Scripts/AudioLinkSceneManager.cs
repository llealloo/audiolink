#if UNITY_EDITOR
using UnityEditor;
using UnityEngine;

namespace VRCAudioLink.Editor
{
    public static class SceneManager
    {
        [MenuItem("AudioLink/Add AudioLink Prefab to Scene", false)]
        [MenuItem("GameObject/AudioLink/Add AudioLink Prefab to Scene", false, 49)]
        static void AddAudioLinkToScene()
        {
#if VRC_SDK_VRCSDK3 && !UDONSHARP //VRC AVATAR
            string[] paths = new string[]
            {
                "Packages/com.llealloo.audiolink/Runtime/AudioLinkAvatar.prefab"
            };
#else  //VRC WORLD or STANDALONE
            string[] paths = new string[]
            {
#if UDONSHARP
                "Packages/com.llealloo.audiolink/Runtime/AudioLinkController.prefab",
#endif
                "Packages/com.llealloo.audiolink/Runtime/AudioLink.prefab"
            };
#endif
            foreach (string path in paths)
            {
                GameObject asset = AssetDatabase.LoadAssetAtPath<GameObject>(path);
                if (asset != null)
                {
                    GameObject instance = (GameObject)PrefabUtility.InstantiatePrefab(asset);
                    EditorGUIUtility.PingObject(instance);
                }
            }
        }
    }
}
#endif