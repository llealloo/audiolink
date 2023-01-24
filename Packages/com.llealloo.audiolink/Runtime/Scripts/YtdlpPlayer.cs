#if UNITY_EDITOR && !COMPILER_UDONSHARP
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Net;
using UnityEditor;
using UnityEngine;
using UnityEngine.Video;
using Debug = UnityEngine.Debug;

// This component uses code from the following sources:
// UnityYoutubePlayer, courtesy iBicha (SPDX-License-Identifier: Unlicense) https://github.com/iBicha/UnityYoutubePlayer
// USharpVideo, Copyright (c) 2020 Merlin, (SPDX-License-Identifier: MIT) https://github.com/MerlinVR/USharpVideo/

namespace VRCAudioLink
{
    /// <summary> Downloads and plays videos via a VideoPlayer component </summary>
    [RequireComponent(typeof(VideoPlayer))]
    public class YtdlpPlayer : MonoBehaviour
    {
        /// <summary> Ytdlp url (e.g. https://www.youtube.com/watch?v=SFTcZ1GXOCQ) </summary>
        public string ytdlpURL = "https://www.youtube.com/watch?v=SFTcZ1GXOCQ";

        /// <summary> VideoPlayer component associated with the current YtdlpPlayer instance </summary>
        public VideoPlayer VideoPlayer { get; private set; }

        /// <summary> Initialize and play from URL </summary>
        void OnEnable()
        {
            VideoPlayer = GetComponent<VideoPlayer>();
            UpdateURL();
            if (VideoPlayer.length > 0)
                VideoPlayer.Play();
        }

        /// <summary> Update URL and start playing </summary>
        public void UpdateAndPlay()
        {
            UpdateURL();
            if (VideoPlayer.length > 0)
                VideoPlayer.Play();
        }

        /// <summary> Set time to zero, resolve, and set URL </summary>
        public void UpdateURL()
        {
            string resolved = YtdlpURLResolver.Resolve(ytdlpURL, 720);
            if(resolved != null)
            {
                VideoPlayer.url = resolved;
                SetPlaybackTime(0.0f);
            }
        }

        /// <summary> Get Video Player Playback Time (as a fraction of playback, 0-1) </summary>
        public float GetPlaybackTime()
        {
            if(VideoPlayer != null && VideoPlayer.length > 0)
                return (float)(VideoPlayer.length > 0 ? VideoPlayer.time / VideoPlayer.length : 0);
            else
                return 0;
        }

        /// <summary> Set Video Player Playback Time (Seek) </summary>
        /// <param name="time">Fraction of playback (0-1) to seek to</param>
        public void SetPlaybackTime(float time)
        {
            if(VideoPlayer != null && VideoPlayer.length > 0 && VideoPlayer.canSetTime)
                VideoPlayer.time = VideoPlayer.length * Mathf.Clamp(time, 0.0f, 1.0f);
        }

        /// <summary> Format seconds as hh:mm:ss or mm:ss </summary>
        public string FormattedTimestamp(double seconds, double maxSeconds=0)
        {
            double formatValue = maxSeconds > 0 ? maxSeconds : seconds;
            string formatString = formatValue >= 3600.0 ? @"hh\:mm\:ss" : @"mm\:ss";
            return TimeSpan.FromSeconds(seconds).ToString(formatString);
        }

        /// <summary> Get Video Player Playback Time formatted as current / length </summary>
        public string PlaybackTimestampFormatted()
        {
            if(VideoPlayer != null && VideoPlayer.length > 0)
            {
                return $"{FormattedTimestamp(VideoPlayer.time, VideoPlayer.length)} / {FormattedTimestamp(VideoPlayer.length)}";
            }
            else
                return "00:00 / 00:00";
        }
    }

    [CustomEditor(typeof(YtdlpPlayer))]
    public class YtdlpPlayerEditor : UnityEditor.Editor 
    {
        YtdlpPlayer _ytdlpPlayer;

        void OnEnable()
        {
            _ytdlpPlayer = (YtdlpPlayer) target;
        }

        // Force constant updates when playing, so playback time is not behind
        public override bool RequiresConstantRepaint()
        {
            if(_ytdlpPlayer.VideoPlayer != null)
                return _ytdlpPlayer.VideoPlayer.isPlaying;
            else
                return false;
        }

        //TODO: add a warning on Linux that only some filetypes are supported?
        public override void OnInspectorGUI()
        {
            base.OnInspectorGUI();
            float playbackTime = 0;
            bool hasPlayer = _ytdlpPlayer.VideoPlayer != null;
            if(hasPlayer && _ytdlpPlayer.VideoPlayer.length > 0)
                playbackTime = _ytdlpPlayer.GetPlaybackTime();
            
            EditorGUI.BeginDisabledGroup(!hasPlayer || !Application.IsPlaying(target) || !_ytdlpPlayer.VideoPlayer.isPlaying);
            using (new EditorGUILayout.HorizontalScope())
            {
                // Timestamp/Reload button
                EditorGUILayout.LabelField(new GUIContent(" Seek: " + _ytdlpPlayer.PlaybackTimestampFormatted(), EditorGUIUtility.IconContent("d_Slider Icon").image));
                bool updateURL = GUILayout.Button(new GUIContent(" Reload", EditorGUIUtility.IconContent("TreeEditor.Refresh").image));
                if(updateURL)
                    _ytdlpPlayer.UpdateAndPlay();
            }

            EditorGUI.BeginChangeCheck();
            playbackTime = EditorGUILayout.Slider(playbackTime, 0, 1);
            if(EditorGUI.EndChangeCheck())
                _ytdlpPlayer.SetPlaybackTime(playbackTime);

            EditorGUI.EndDisabledGroup();
            
        }
    }

    [InitializeOnLoad]
    public static class YtdlpURLResolver
    {
        private static string _ytdlpDownloadURL = "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe";
        private static string _localYtdlpPath = Application.dataPath + "\\AudioLink\\yt-dlp.exe";

        private static string _ytdlpPath = "";
        private static HashSet<Process> _runningYtdlProcesses = new HashSet<Process>();
        private static bool _ytdlFound = false;

        /// <summary> Initialize URL Resolver </summary>
        static YtdlpURLResolver()
        {
            EditorApplication.playModeStateChanged += PlayModeChanged;
            LocateYtdlp();
        }

        /// <summary> Locate yt-dlp executible, either in VRC application data or locally (offer to download) </summary>
        public static void LocateYtdlp()
        {
            _ytdlFound = false;
            #if UNITY_EDITOR_WIN
            string[] splitPath = Application.persistentDataPath.Split('/', '\\');
            
            // Check for yt-dlp in VRC application data first
            _ytdlpPath = string.Join("\\", splitPath.Take(splitPath.Length - 2)) + "\\VRChat\\VRChat\\Tools\\yt-dlp.exe";
            #elif UNITY_EDITOR_LINUX
            _ytdlpPath = "/usr/bin/yt-dlp";
            #endif
            if (!File.Exists(_ytdlpPath)) 
            {
                // Check the local path (in the Assets folder)
                _ytdlpPath = _localYtdlpPath;
            }

            if (!File.Exists(_ytdlpPath))
            {
                if(Application.isPlaying)
                    EditorApplication.ExitPlaymode();

                #if UNITY_EDITOR_WIN
                // Offer to download yt-dlp to the AudioLink folder
                bool doDownload = EditorUtility.DisplayDialog("[AudioLink] Download yt-dlp?", "AudioLink could not locate yt-dlp in your VRChat folder.\nDownload to AudioLink folder instead?", "Download", "Cancel");
                if(doDownload)
                    DownloadYtdlp();
                
                #elif UNITY_EDITOR_LINUX
                    EditorUtility.DisplayDialog("[AudioLink] Missing yt-dlp", "Ensure yt-dlp is available in your PATH", "Ok");
                #endif
            }

            if (!File.Exists(_ytdlpPath)) 
            {
                // Still don't have it, no dice
                Debug.LogWarning("[AudioLink] Unable to find yt-dlp");
                return;
            }
            else
            {
                // Found it
                _ytdlFound = true;
                Debug.Log($"[AudioLink] Found yt-dlp at path '{_ytdlpPath}'");
            }
        }

        /// <summary> Resolves a URL to one usable in a VideoPlayer. </summary>
        /// <param name="url">URL to resolve for playback</param>
        /// <param name="resolution">Resolution (vertical) to request from yt-dlp</param>
        public static string Resolve(string url, int resolution)
        {
            if(!_ytdlFound)
            {
                Debug.LogWarning($"[AudioLink] Unable to resolve URL '{url}' : yt-dlp not found");
                return null;
            }

            Process ytdlProcess = new Process();

            ytdlProcess.StartInfo.WindowStyle = ProcessWindowStyle.Hidden;
            ytdlProcess.StartInfo.CreateNoWindow = true;
            ytdlProcess.StartInfo.UseShellExecute = false;
            ytdlProcess.StartInfo.RedirectStandardOutput = true;
            ytdlProcess.StartInfo.FileName = _ytdlpPath;
            ytdlProcess.StartInfo.Arguments = $"--no-check-certificate --no-cache-dir --rm-cache-dir -f \"mp4[height<=?{resolution}]/best[height<=?{resolution}]\" --get-url \"{url}\"";

            try
            {
                ytdlProcess.Start();
                _runningYtdlProcesses.Add(ytdlProcess);

                while (!ytdlProcess.HasExited)
                    new WaitForSeconds(0.1f);

                _runningYtdlProcesses.Remove(ytdlProcess);

                return ytdlProcess.StandardOutput.ReadLine();
            }
            catch(Exception e)
            {
                Debug.LogWarning($"[AudioLink] Unable to resolve URL '{url}' : " + e.Message);
                return null;
            }
        }

        /// <summary> Cleans up any remaining YTDL processes from this play, in case they don't clean up after themselves. </summary>
        private static void PlayModeChanged(PlayModeStateChange change)
        {
            if (change == PlayModeStateChange.ExitingPlayMode)
            {
                foreach (Process process in _runningYtdlProcesses)
                {
                    if (!process.HasExited)
                    {
                        process.Close();
                    }
                }

                _runningYtdlProcesses.Clear();
            }
        }

        /// <summary> Download yt-dlp to the AudioLink folder. </summary>
        private static void DownloadYtdlp()
        {
            using (var webClient = new WebClient())
            {
                try
                {
                    webClient.DownloadFile(new Uri(_ytdlpDownloadURL), _localYtdlpPath);
                    Debug.Log($"[AudioLink] yt-dlp downloaded to '{_ytdlpPath}'");
                    AssetDatabase.Refresh();
                }
                catch(Exception e)
                {
                    Debug.LogWarning($"[AudioLink] Failed to download yt-dlp from '{_ytdlpDownloadURL}' : " + e.Message);
                }

                // Check for it again to make sure it was actually downloaded
                LocateYtdlp();
            }
        }
    }
}
#endif