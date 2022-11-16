using System.IO;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;

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
                    ReimportPackage();
                    File.WriteAllText(canaryFilePath, audioLinkReimportedKey);
                    if (IsUsingPackageSetup())
                    {
                        AudioLinkShaderCompatabilityUtility.UpgradeShaders();
                    }
                }
            }
        }

        // Are we using AudioLink as a package, or the old Assets setup?
        public static bool IsUsingPackageSetup()
        {
            return AssetDatabase.IsValidFolder(Path.Combine("Packages", "com.llealloo.audiolink"));
        }

        private static void ReimportPackage()
        {
            if (IsUsingPackageSetup())
            {
                AssetDatabase.ImportAsset(Path.Combine("Packages", "com.llealloo.audiolink"), ImportAssetOptions.ImportRecursive);
            }

            SessionState.SetBool(audioLinkReimportedKey, true);
        }

        [MenuItem("AudioLink/Open AudioLink Example Scene")]
        public static void OpenExampleScene()
        {
            if (!IsUsingPackageSetup())
            {
                Debug.LogWarning("Couldn't not open AudioLink example scene. It is not included in your distribution of AudioLink.");
                return;
            }
            
            string baseAssetsPath = "Samples/AudioLink/0.3.0";
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
}
