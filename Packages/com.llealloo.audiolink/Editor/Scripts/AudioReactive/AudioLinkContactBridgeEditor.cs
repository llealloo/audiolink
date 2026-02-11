#if !COMPILER_UDONSHARP && UNITY_EDITOR
using UnityEditor;

namespace AudioLink.Editor
{
    [CustomEditor(typeof(AudioLinkContactBridge))]
    public class AudioLinkContactBridgeEditor : AudioReactiveCommon
    {
        public override void OnInspectorGUI()
        {
            StandardReactiveEditorHeader("AudioLink Contact Bridge:\nStreams the current and smoothed values of the primary 4 bands to supported Avatars using contacts,\nfor cases when custom Shaders are unavailable or incapable.");

            StandardReactiveEditor();

            EditorGUILayout.Space();
        }
    }
}
#endif