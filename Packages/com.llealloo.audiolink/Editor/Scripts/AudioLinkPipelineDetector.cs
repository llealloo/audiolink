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

        const string URP = "_UNIVERSAL_RENDER_PIPELINE";
        const string HDRP = "_HIGH_DEFINITION_RENDER_PIPELINE";

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
                    bool shouldURP = true, shouldHDRP = false;
#elif HDRP_AVAILABLE
                    bool shouldURP = false, shouldHDRP = true;
#else
                    bool shouldURP = false, shouldHDRP = false;
#endif
                    // compare current with expected
                    shouldURP = material.IsKeywordEnabled(URP) != shouldURP;
                    shouldHDRP = material.IsKeywordEnabled(HDRP) != shouldHDRP;

                    // update keywords when mismatch is detected
                    if (shouldURP || shouldHDRP)
                    {
                        if (shouldURP) material.EnableKeyword(URP);
                        else material.DisableKeyword(URP);

                        if (shouldHDRP) material.EnableKeyword(HDRP);
                        else material.DisableKeyword(HDRP);

                        EditorUtility.SetDirty(material);
                        count++;
                    }
                }
            }

            // If any changed, save asset changes and log the count
            if (count > 0)
            {
                AssetDatabase.SaveAssets();
                Debug.Log($"AudioLinkPipelineDetector: Updated render pipeline shader keywords on {count} materials.");
            }
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
