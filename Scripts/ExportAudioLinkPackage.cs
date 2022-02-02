using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

#if UNITY_EDITOR
public class ExportAudioLinkPackage : MonoBehaviour
{
    [MenuItem("Tools/Export AudioLink Packages")]
    static void ExportPackageAudioLink()
    {
        var exportedPackageAssetList = new List<string>();
        exportedPackageAssetList.Add("Assets/AudioLink");
        exportedPackageAssetList.Add("Assets/Docs");
        exportedPackageAssetList.Add("Assets/AudioLink/CHANGELOG.md");

        AssetDatabase.ExportPackage(exportedPackageAssetList.ToArray(), "AudioLink-full.unitypackage",
            ExportPackageOptions.Recurse );

        var exportedMinimal = new List<string>();
        exportedMinimal.Add( "Assets/AudioLink/AudioLink.prefab" );
        exportedMinimal.Add( "Assets/AudioLink/AudioLinkController.prefab" );
        exportedMinimal.Add( "Assets/AudioLink/AudioLinkMiniPlayer.prefab" );
        exportedMinimal.Add( "Assets/AudioLink/AudioLinkAvatar.prefab" );
        exportedMinimal.Add( "Assets/AudioLink/LICENSE.txt" );
        exportedMinimal.Add( "Assets/AudioLink/README.md" );
        exportedMinimal.Add( "Assets/AudioLink/VERSION.txt" );
        exportedMinimal.Add( "Assets/AudioLink/Scripts" );
        exportedMinimal.Add( "Assets/AudioLink/RenderTextures" );
        exportedMinimal.Add( "Assets/AudioLink/Shaders" );
        exportedMinimal.Add( "Assets/AudioLink/Materials" );
        exportedMinimal.Add( "Assets/AudioLink/Resources" );
        exportedMinimal.Add( "Assets/AudioLink/CHANGELOG.md" );

        AssetDatabase.ExportPackage(exportedMinimal.ToArray(), "AudioLink-minimal.unitypackage",
            ExportPackageOptions.Recurse );
    }
}
#endif