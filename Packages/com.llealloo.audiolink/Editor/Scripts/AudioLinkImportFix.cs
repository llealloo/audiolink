using System.IO;
using UnityEditor;

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
                }
            }
        }

        private static void ReimportPackage()
        {
            AssetDatabase.ImportAsset(Path.Combine("Packages", "com.llealloo.audiolink"), ImportAssetOptions.ImportRecursive);
            SessionState.SetBool(audioLinkReimportedKey, true);
        }
    }
}