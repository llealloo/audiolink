using System;
using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEngine;

namespace VRCAudioLink.Editor
{
    public class AudioLinkShaderCompatabilityUtility
    {
        private const string OldPath = "Assets/AudioLink/Shaders/AudioLink.cginc";
        private const string NewPath = "Packages/com.llealloo.audiolink/Runtime/Shaders/AudioLink.cginc";
        private const string MenuItemPath = "AudioLink Menu/Run AudioLink Shader Compatibility Utility";


        [MenuItem(MenuItemPath)]
        public static void UpgradeShaders()
        {
            if (EditorUtility.DisplayDialog("AudioLink Shader Compatibility Utility",
                    "Do you want to check all shaders in this project for AudioLink 0.3.x compatibility and update them if necessary? This is useful for upgrading projects using AudioLink 0.2.x or below.?"
                    + Environment.NewLine + Environment.NewLine +
                    "If you choose 'Go Ahead', shader files in this project which include 'AudioLink.cginc' will be edited to use the new path introduced by AudioLink 0.3.x. Shaders which already use the new path will be unaffected. You should make a backup before proceeding."
                    + Environment.NewLine + Environment.NewLine +
                    "(You can always run this utility manually via the " + MenuItemPath + "menu command)"
                    ,
                    "I Made a Backup, Go Ahead! ", "No Thanks"))
            {
                UpgradeShaderFiles();
                UpgradeCgincFiles();
            }
        }

        private static void UpgradeShaderFiles()
        {
            ShaderInfo[] shaders = ShaderUtil.GetAllShaderInfo();

            foreach (ShaderInfo shaderinfo in shaders)
            {
                Shader shader = Shader.Find(shaderinfo.name);
                if (AssetDatabase.GetAssetPath(shader).StartsWith("Assets") ||
                    AssetDatabase.GetAssetPath(shader).StartsWith("Packages"))
                {
                    string path = AssetDatabase.GetAssetPath(shader);
                    ReplaceInFile(path);
                }
            }
        }

        private static void UpgradeCgincFiles()
        {
            List<string> cgincs = FindCgincFiles(Application.dataPath);
            foreach (string cginc in cgincs)
            {
                ReplaceInFile(cginc);
            }
        }

        private static List<string> FindCgincFiles(string path)
        {
            List<string> cgincList = new List<string>();

            string[] files = Directory.GetFiles(path);
            foreach (string file in files)
            {
                if (file.EndsWith(".cginc"))
                {
                    cgincList.Add(file);
                }
            }

            string[] folders = Directory.GetDirectories(path);
            foreach (string folder in folders)
            {
                List<string> cgincs = FindCgincFiles(folder);
                foreach (string cginc in cgincs)
                {
                    cgincList.Add(cginc);
                }
            }

            return cgincList;
        }

        private static void ReplaceInFile(string path)
        {
            string shaderSource = File.ReadAllText(path);
            shaderSource = shaderSource.Replace(OldPath, NewPath);
            File.WriteAllText(path, shaderSource);
        }
    }
}