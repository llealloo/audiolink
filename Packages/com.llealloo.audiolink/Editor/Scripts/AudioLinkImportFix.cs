using System.IO;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;

// This define is inserted into the file in CI.
// We can't rely on regular scripting defines so early in the import process.
#if !AUDIOLINK_STANDALONE
using VRC.PackageManagement.Core.Types;
using VRC.PackageManagement.Core.Types.Packages;
#endif

namespace VRCAudioLink.Editor
{
    [InitializeOnLoad]
    public class AudioLinkImportFix
    {
        private const string audioLinkReimportedKey = "AUDIOLINK_REIMPORTED";

        static AudioLinkImportFix()
        {
            // Skip if we've already checked for the canary file during this Editor Session
            if (!SessionState.GetBool(audioLinkReimportedKey, false))
            {
                // Check for canary file in Library - package probably needs a reimport after a Library wipe
                string canaryFilePath = Path.Combine("Library", audioLinkReimportedKey);
                if (File.Exists(canaryFilePath))
                {
                    SessionState.SetBool(audioLinkReimportedKey, true);
                }
                else
                {
                    #if !AUDIOLINK_STANDALONE
                    if (IsWorldProjectWithoutUdonSharp())
                    {
                        if (EditorUtility.DisplayDialog(
                            "Install missing UdonSharp dependency",
                            "It looks like you are trying to use AudioLink in a world project, but don't have UdonSharp 1.x installed.\n" +
                            "AudioLink will not function correctly without UdonSharp 1.x. Would you like to install it now?",
                            "Yes", "No"))
                        {
                            InstallUdonSharp();
                        }
                    }
                    else
                    #endif
                    {
                        ReimportPackage();
                    }
                    File.WriteAllText(canaryFilePath, audioLinkReimportedKey);
                    AudioLinkShaderCompatabilityUtility.UpgradeShaders();
                }
            }
        }

        private static void ReimportPackage()
        {
            AssetDatabase.ImportAsset(Path.Combine("Packages", "com.llealloo.audiolink"), ImportAssetOptions.ImportRecursive);
            SessionState.SetBool(audioLinkReimportedKey, true);
        }

        #if !AUDIOLINK_STANDALONE
        [MenuItem("AudioLink/Open AudioLink Example Scene")]
        public static void OpenExampleScene()
        {
            if (EditorSceneManager.SaveCurrentModifiedScenesIfUserWantsTo())
            {
                string baseAssetsPath = "Samples/AudioLink/0.3.1";
                string packagePath = "Packages/com.llealloo.audiolink/Samples~/AudioLinkExampleScene";
                string assetsPath = Path.Combine("Assets", baseAssetsPath, "AudioLinkExampleScene");
                if (!Directory.Exists(Path.Combine(Application.dataPath, baseAssetsPath, "AudioLinkExampleScene")))
                {
                    Directory.CreateDirectory(Path.Combine(Application.dataPath, baseAssetsPath));
                    FileUtil.CopyFileOrDirectory(packagePath, assetsPath);
                    AssetDatabase.Refresh();
                }
                EditorSceneManager.OpenScene(Path.Combine(assetsPath, "AudioLink_ExampleScene.unity"));
            }
        }

        [MenuItem("AudioLink/Install UdonSharp dependency", true)]
        public static bool IsWorldProjectWithoutUdonSharp()
        {
            var path = new DirectoryInfo(Application.dataPath).Parent?.FullName;
            var project = new UnityProject(path);
            return project.VPMProvider.HasPackage(VRCPackageNames.WORLDS) && !project.VPMProvider.HasPackage(VRCAddonPackageNames.UDONSHARP);
        }

        [MenuItem("AudioLink/Install UdonSharp dependency")]
        public static void InstallUdonSharp()
        {
            var path = new DirectoryInfo(Application.dataPath).Parent?.FullName;
            var project = new UnityProject(path);
            project.AddVPMPackage(VRCAddonPackageNames.UDONSHARP, "1.x");
            ReimportPackage();
        }
        #endif
    }
}
