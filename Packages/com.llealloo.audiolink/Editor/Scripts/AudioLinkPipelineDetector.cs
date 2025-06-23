using UnityEngine;
using UnityEditor;

public static class AudioLinkPipelineDetector
{
    [InitializeOnLoadMethod]
    private static void DetectPackages()
    {
#if URP_AVAILABLE
        Shader.EnableKeyword("UNIVERSAL_RENDER_PIPELINE");
#else
        Shader.DisableKeyword("UNIVERSAL_RENDER_PIPELINE");
#endif

#if HDRP_AVAILABLE
        Shader.EnableKeyword("HIGH_DEFINITION_RENDER_PIPELINE");
#else
        Shader.DisableKeyword("HIGH_DEFINITION_RENDER_PIPELINE");
#endif
    }
}
