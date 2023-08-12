﻿using System.IO;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;

// This define is inserted into the file in CI.
// We can't rely on regular scripting defines so early in the import process.
#if !AUDIOLINK_STANDALONE && VPM_RESOLVER
using VRC.PackageManagement.Core.Types;
using VRC.PackageManagement.Core.Types.Packages;
#endif

namespace AudioLink.Editor
{
    [InitializeOnLoad]
    public class AudioLinkAssetManager
    {
        private const string audioLinkReimportedKey = "AUDIOLINK_REIMPORTED";

        static AudioLinkAssetManager()
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
#if !AUDIOLINK_STANDALONE && VPM_RESOLVER

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

#if !AUDIOLINK_STANDALONE && VPM_RESOLVER
        [MenuItem("AudioLink/Open AudioLink Example Scene")]
        public static void OpenExampleScene()
        {
            if (EditorSceneManager.SaveCurrentModifiedScenesIfUserWantsTo())
            {
                string baseAssetsPath = "Samples/AudioLink/0.3.2";
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
            string path = new DirectoryInfo(Application.dataPath).Parent?.FullName;
            UnityProject project = new UnityProject(path);
            return project.VPMProvider.HasPackage(VRCPackageNames.WORLDS) && !project.VPMProvider.HasPackage(VRCAddonPackageNames.UDONSHARP);
        }

        [MenuItem("AudioLink/Install UdonSharp dependency")]
        public static void InstallUdonSharp()
        {
            string path = new DirectoryInfo(Application.dataPath).Parent?.FullName;
            UnityProject project = new UnityProject(path);
            project.AddVPMPackage(VRCAddonPackageNames.UDONSHARP, "1.x");
            ReimportPackage();
        }
#endif

        [MenuItem("AudioLink/Add AudioLink Prefab to Scene", false)]
        [MenuItem("GameObject/AudioLink/Add AudioLink Prefab to Scene", false, 49)]
        public static void AddAudioLinkToScene()
        {
            string[] paths = new string[]
            {

#if UDONSHARP // VRC World        
                "Packages/com.llealloo.audiolink/Runtime/AudioLink.prefab",
                "Packages/com.llealloo.audiolink/Runtime/AudioLinkController.prefab",
#elif VRC_SDK_VRCSDK3 // VRC AVATAR
                "Packages/com.llealloo.audiolink/Runtime/AudioLinkAvatar.prefab",
#elif CVR_CCK_EXISTS // CVR
                "Packages/com.llealloo.audiolink/Runtime/CVRAudioLink.prefab",
                "Packages/com.llealloo.audiolink/Runtime/CVRAudioLinkController.prefab",
#else // Standalone
                "Packages/com.llealloo.audiolink/Runtime/AudioLink.prefab",
#endif
            };
            GameObject audiolink = null;

            foreach (string path in paths)
            {
                GameObject asset = AssetDatabase.LoadAssetAtPath<GameObject>(path);
                if (asset != null)
                {
                    GameObject instance = (GameObject)PrefabUtility.InstantiatePrefab(asset);
                    if (path.EndsWith("AudioLink.prefab"))
                    {
                        audiolink = instance;
                    }
                    EditorGUIUtility.PingObject(instance);
                }
            }

            if (audiolink != null)
            {
                AudioLinkEditor.LinkAll(audiolink.GetComponent<AudioLink>());
            }
        }
    }
}
