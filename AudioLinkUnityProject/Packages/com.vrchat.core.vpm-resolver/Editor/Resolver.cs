using System;
using System.Collections;
using System.IO;
using System.Reflection;
using Serilog;
using UnityEditor;
using UnityEngine;
using VRC.PackageManagement.Core.Types.Packages;
using Serilog.Sinks.Unity3D;
using UnityEditor.SceneManagement;

namespace VRC.PackageManagement.Resolver
{
    
    [InitializeOnLoad]
    public class Resolver
    {
        private const string _projectLoadedKey = "PROJECT_LOADED";
        
        private static string _projectDir;
        public static string ProjectDir
        {
            get
            {
                if (_projectDir != null)
                {
                    return _projectDir;
                }

                try
                {
                    _projectDir = new DirectoryInfo(Assembly.GetExecutingAssembly().Location).Parent.Parent.Parent
                        .FullName;
                    return _projectDir;
                }
                catch (Exception)
                {
                    return "";
                }
            }
        }

        static Resolver()
        {
            SetupLogging();
            if (!SessionState.GetBool(_projectLoadedKey, false))
            {
                EditorCoroutine.Start(CheckResolveNeeded());
            }
        }

        private static void SetupLogging()
        {
            VRCLibLogger.SetLoggerDirectly(
                new LoggerConfiguration()
                    .MinimumLevel.Information()
                    .WriteTo.Unity3D()
                    .CreateLogger()
            );
        }

        [MenuItem("VRC/Reload")]
        public static void ReloadCurrentScene()
        {
            var activeScene = EditorSceneManager.GetActiveScene();
            if (!string.IsNullOrWhiteSpace(activeScene.path))
            {
                if (activeScene.isDirty)
                {
                    var result = EditorUtility.DisplayDialog("Reload SDK",
                        $"This will reload the SDK and your scene, discarding any changes (probably what you want if something is broken). Is that OK?",
                        "Yes", "No, I want to save the scene first.");
                    if (result)
                    {
                        EditorSceneManager.OpenScene(activeScene.path);
                    }
                }
            }
            
        }

        private static IEnumerator CheckResolveNeeded()
        {
            SessionState.SetBool(_projectLoadedKey, true);
            
            //Wait for project to finish compiling
            while (EditorApplication.isCompiling || EditorApplication.isUpdating)
            {
                yield return null;
            }

            try
            {

                if (string.IsNullOrWhiteSpace(ProjectDir))
                {
                    yield break;
                }
                
                if (VPMProjectManifest.ResolveIsNeeded(ProjectDir))
                {
                    Debug.Log($"Resolve needed.");
                    var result = EditorUtility.DisplayDialog("VRChat Package Management",
                        $"This project requires some VRChat Packages which are not in the project yet.\n\nPress OK to download and install them.",
                        "OK", "Show Me What's Missing");
                    if (result)
                    {
                        ResolveStatic(ProjectDir);
                    }
                    else
                    {
                        ResolverWindow.ShowWindow();
                    }
                }
            }
            catch (Exception)
            {
                // Unity says we can't open windows from this function so it throws an exception but also works fine.
            }
        }
        
        public static bool VPMManifestExists()
        {
            return VPMProjectManifest.Exists(ProjectDir, out _);
        }

        public static void CreateManifest()
        {
            VPMProjectManifest.Load(ProjectDir);
            ResolverWindow.Refresh();
        }
        
        public static void ResolveManifest()
        {
            ResolveStatic(ProjectDir);
        }

        public static void ResolveStatic(string dir)
        {
            // Todo: calculate and show actual progress
            EditorUtility.DisplayProgressBar($"Getting all VRChat Packages", "Downloading and Installing...", 0.5f);
            VPMProjectManifest.Resolve(ProjectDir);
            EditorUtility.ClearProgressBar();
            AssetDatabase.Refresh(ImportAssetOptions.ForceUpdate | ImportAssetOptions.ForceSynchronousImport);
        }
    }
}