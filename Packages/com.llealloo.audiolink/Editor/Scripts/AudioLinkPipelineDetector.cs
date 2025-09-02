using UnityEngine;
using UnityEditor;
using UnityEditor.Build;
using UnityEditor.Build.Reporting;

namespace AudioLink.Editor
{
    public class AudioLinkPipelineDetector : IPreprocessBuildWithReport
    {
        public int callbackOrder => 0;

        private static readonly string[] s_shaderPrefixes = {
            "AudioLink/StandardLit",
            "AudioLink/Surface"
        };

        [InitializeOnLoadMethod]
        private static void InitializeOnLoad()
        {
            EditorApplication.delayCall += SetShaderKeywords;
        }

        public void OnPreprocessBuild(BuildReport report)
        {
            SetShaderKeywords();
        }

        private static void SetShaderKeywords()
        {
            string[] materialGuids = AssetDatabase.FindAssets("t:Material");
            int count = 0;

            foreach (string guid in materialGuids)
            {
                string path = AssetDatabase.GUIDToAssetPath(guid);
                Material material = AssetDatabase.LoadAssetAtPath<Material>(path);

                if (material != null && IsTargetShader(material.shader))
                {
#if URP_AVAILABLE
                    material.EnableKeyword("_UNIVERSAL_RENDER_PIPELINE");
                    material.DisableKeyword("_HIGH_DEFINITION_RENDER_PIPELINE");
#elif HDRP_AVAILABLE
                    material.EnableKeyword("_HIGH_DEFINITION_RENDER_PIPELINE");
                    material.DisableKeyword("_UNIVERSAL_RENDER_PIPELINE");
#else
                    material.DisableKeyword("_UNIVERSAL_RENDER_PIPELINE");
                    material.DisableKeyword("_HIGH_DEFINITION_RENDER_PIPELINE");
#endif
                    EditorUtility.SetDirty(material);
                    count++;
                }
            }

            AssetDatabase.SaveAssets();
            Debug.Log($"AudioLinkPipelineDetector: Applied shader keywords to {count} materials.");
        }

        private static bool IsTargetShader(Shader shader)
        {
            if (shader == null) return false;

            foreach (string targetShader in s_shaderPrefixes)
            {
                if (shader.name.StartsWith(targetShader))
                    return true;
            }

            return false;
        }
    }
}
