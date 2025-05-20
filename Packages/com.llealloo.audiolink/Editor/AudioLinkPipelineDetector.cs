using UnityEngine;
using UnityEditor;
using System.Linq;
using UnityEngine.Rendering;

[InitializeOnLoad]
public static class AudioLinkPipelineDetector
{
    static AudioLinkPipelineDetector()
    {
        DetectPackages();
#if UNITY_2021_1_OR_NEWER
        RenderPipelineManager.activeRenderPipelineTypeChanged -= DetectPackages;
        RenderPipelineManager.activeRenderPipelineTypeChanged += DetectPackages;
#endif
    }

    // [MenuItem("Tools/VRSL/Check Pipeline")]
    private static void DetectPackages()
    {
        // Check for URP
        bool hasURP = DoesPackageExist("com.unity.render-pipelines.universal");
        if (hasURP) Shader.EnableKeyword("UNIVERSAL_RENDER_PIPELINE");
        else Shader.DisableKeyword("UNIVERSAL_RENDER_PIPELINE");

        // Check for other packages as needed
        // bool hasHDRP = DoesPackageExist("com.unity.render-pipelines.");
        bool hasHDRP = DoesPackageExist("com.unity.render-pipelines.high-definition");
        if (hasHDRP) Shader.EnableKeyword("HIGH_DEFINITION_RENDER_PIPELINE");
        else Shader.DisableKeyword("HIGH_DEFINITION_RENDER_PIPELINE");
    }

    private static bool DoesPackageExist(string packageName)
    {
        // For Unity 2019.3+
#if UNITY_2019_3_OR_NEWER
        var listRequest = UnityEditor.PackageManager.Client.List(true);
        while (!listRequest.IsCompleted) { }

        bool found;
        if (listRequest.Status == UnityEditor.PackageManager.StatusCode.Success)
        {
            return listRequest.Result.Any(package => package.name == packageName);
        }
#endif

        // Fallback method for earlier Unity versions: check for package directory
        string packagePath = $"Packages/{packageName}";
        return System.IO.Directory.Exists(packagePath);
    }
}
