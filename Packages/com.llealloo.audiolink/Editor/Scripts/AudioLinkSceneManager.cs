#if UNITY_EDITOR
using UnityEditor;
using UnityEngine;

namespace VRCAudioLink.Editor
{
    public static class SceneManager
    {
        [MenuItem("AudioLink/Add AudioLink Prefab to Scene", false)]
        [MenuItem("GameObject/Add AudioLink Prefab to Scene", false, 49)]
        static void AddAudioLinkToScene()
        {
#if VRC_SDK_VRCSDK3 && !UDONSHARP //VRC AVATAR
            string path = "Packages/com.llealloo.audiolink/Runtime/AudioLinkAvatar.prefab"; //"6e8e0ee5a3655884ea49447ae9e6e665";
#else  //VRC WORLD or STANDALONE
            string path = "Packages/com.llealloo.audiolink/Runtime/AudioLink.prefab"; //"8c1f201f848804f42aa401d0647f8902";
#endif
            GameObject asset = AssetDatabase.LoadAssetAtPath<GameObject>(path);
            if (asset != null)
            {
                GameObject instance = (GameObject)PrefabUtility.InstantiatePrefab(asset);
                EditorGUIUtility.PingObject(instance);
            }
        }
    }
}
#endif