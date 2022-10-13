using System;
using System.IO;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEngine.Video;
using UnityEditor;

// This component uses code from the following sources:
// UnityYoutubePlayer, courtesy iBicha (SPDX-License-Identifier: Unlicense) https://github.com/iBicha/UnityYoutubePlayer
// USharpVideo, Copyright (c) 2020 Merlin, (SPDX-License-Identifier: MIT) https://github.com/MerlinVR/USharpVideo/

namespace VRCAudioLink
{
#if UNITY_EDITOR_WIN // Only supports windows for now
    /// <summary> Downloads and plays Youtube videos via a VideoPlayer component </summary>
    [RequireComponent(typeof(VideoPlayer))]
    public class YoutubePlayer : MonoBehaviour
    {
        /// <summary> Youtube url (e.g. https://www.youtube.com/watch?v=SFTcZ1GXOCQ) </summary>
        public string youtubeURL = "https://www.youtube.com/watch?v=SFTcZ1GXOCQ";

        /// <summary> VideoPlayer component associated with the current YoutubePlayer instance </summary>
        public VideoPlayer videoPlayer { get; private set; }

        /// <summary> Initialize and play from URL </summary>
        void OnEnable()
        {
            videoPlayer = GetComponent<VideoPlayer>();
            UpdateURL();
            if (videoPlayer.length > 0)
                videoPlayer.Play();
        }

        /// <summary> Update URL and start playing </summary>
        public void UpdateAndPlay()
        {
            UpdateURL();
            if (videoPlayer.length > 0)
                videoPlayer.Play();
        }

        /// <summary> Set time to zero, resolve, and set URL </summary>
        public void UpdateURL()
        {
            try
            {
                SetPlaybackTime(0.0f);
                YtdlpURLResolver.ResolveAndSet(youtubeURL, 720, videoPlayer);
            }
            catch
            {
                videoPlayer.Pause();
                Debug.LogWarning($"[AudioLink] Unable to play url {youtubeURL}");
            }
        }

        /// <summary> Get Video Player Playback Time (as a fraction of playback, 0-1) </summary>
        public float GetPlaybackTime()
        {
            if(videoPlayer != null && videoPlayer.length > 0)
                return (float)(videoPlayer.length > 0 ? videoPlayer.time / videoPlayer.length : 0);
            else
                return 0;
        }

        /// <summary> Set Video Player Playback Time (Seek) </summary>
        /// <param name="time">Fraction of playback (0-1) to seek to</param>
        public float SetPlaybackTime(float time)
        {
            if(videoPlayer != null && videoPlayer.length > 0)
            {
                if (!videoPlayer.canSetTime)
                    return GetPlaybackTime();

                videoPlayer.time = videoPlayer.length * (double) Mathf.Clamp(time, 0.0f, 1.0f);
                return (float)videoPlayer.time;
            }
            else
                return 0;
        }

        /// <summary> Get Video Player Playback Time formatted as current / length </summary>
        public string PlaybackTimeFormatted()
        {
            if(videoPlayer != null && videoPlayer.length > 0)
            {
                float videoLengthSeconds = (float)videoPlayer.length;
                float currentVideoTime = (float)videoPlayer.time;

                if(videoLengthSeconds >= 3600)
                    return $"{TimeSpan.FromSeconds(currentVideoTime).ToString(@"hh\:mm\:ss")} / {TimeSpan.FromSeconds(videoLengthSeconds).ToString(@"hh\:mm\:ss")}";
                else
                    return $"{TimeSpan.FromSeconds(currentVideoTime).ToString(@"mm\:ss")} / {TimeSpan.FromSeconds(videoLengthSeconds).ToString(@"mm\:ss")}";
            }
            else
                return "00:00 / 00:00";
        }
    }

    [CustomEditor(typeof(YoutubePlayer))]
    public class YoutubePlayerCleanEditor : UnityEditor.Editor 
    {
        SerializedProperty youtubeURL;
        YoutubePlayer youtubePlayer;
        bool reloadURL = false;

        void OnEnable()
        {
            youtubeURL = serializedObject.FindProperty("youtubeURL");
            youtubePlayer = (YoutubePlayer) target;
        }

        public override void OnInspectorGUI()
        {
            serializedObject.Update();
            EditorGUILayout.PropertyField(youtubeURL, new GUIContent(" YouTube URL", EditorGUIUtility.IconContent("d_BuildSettings.Web.Small").image));
            reloadURL = EditorGUILayout.Toggle("Reload URL", reloadURL);
            if(reloadURL)
            {
                youtubePlayer.UpdateAndPlay();
                reloadURL = false;
            }
            float playbackTime = 0;

            bool hasPlayer = youtubePlayer.videoPlayer != null;
            EditorGUI.BeginDisabledGroup(!hasPlayer || !Application.IsPlaying(target) || !youtubePlayer.videoPlayer.isPlaying);
            if(hasPlayer && youtubePlayer.videoPlayer.length > 0)
                playbackTime = youtubePlayer.GetPlaybackTime();

            EditorGUI.BeginChangeCheck();
            EditorGUILayout.LabelField(new GUIContent(" Seek: " + youtubePlayer.PlaybackTimeFormatted(), EditorGUIUtility.IconContent("d_Slider Icon").image));
            playbackTime = EditorGUILayout.Slider(playbackTime, 0, 1);
            if(EditorGUI.EndChangeCheck())
                youtubePlayer.SetPlaybackTime(playbackTime);

            EditorGUI.EndDisabledGroup();

            if(Application.IsPlaying(target))
                EditorUtility.SetDirty(target);
            serializedObject.ApplyModifiedProperties();
        }
    }

    [InitializeOnLoad]
    public static class YtdlpURLResolver
    {
        private static string _ytdlpDownloadURL = "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe";
        private static string _localYtdlpPath = Application.dataPath + "\\AudioLink\\yt-dlp.exe";

        private static string _ytdlpPath = "";
        private static HashSet<System.Diagnostics.Process> _runningYtdlProcesses = new HashSet<System.Diagnostics.Process>();
        private static HashSet<MonoBehaviour> _registeredBehaviours = new HashSet<MonoBehaviour>();
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
            string[] splitPath = Application.persistentDataPath.Split('/', '\\');
            
            // Check for yt-dlp in VRC application data first
            _ytdlpPath = string.Join("\\", splitPath.Take(splitPath.Length - 2)) + "\\VRChat\\VRChat\\Tools\\yt-dlp.exe";

            if (!File.Exists(_ytdlpPath)) 
            {
                // Check the local path (in the Assets folder)
                _ytdlpPath = _localYtdlpPath;
            }

            if (!File.Exists(_ytdlpPath))
            {
                // Offer to download yt-dlp to the AudioLink folder
                bool doDownload = EditorUtility.DisplayDialog("[AudioLink] Download yt-dlp?", "AudioLink could not locate yt-dlp in your VRChat folder.\nDownload to AudioLink folder instead?", "Download", "Cancel");

                if(doDownload)
                    DownloadYtdlp();

                if(!Application.isPlaying)
                    EditorApplication.ExitPlaymode();
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

            var ytdlProcess = new System.Diagnostics.Process();

            ytdlProcess.StartInfo.WindowStyle = System.Diagnostics.ProcessWindowStyle.Hidden;
            ytdlProcess.StartInfo.CreateNoWindow = true;
            ytdlProcess.StartInfo.UseShellExecute = false;
            ytdlProcess.StartInfo.RedirectStandardOutput = true;
            ytdlProcess.StartInfo.FileName = _ytdlpPath;
            ytdlProcess.StartInfo.Arguments = $"--no-check-certificate --no-cache-dir --rm-cache-dir -f \"mp4[height<=?{resolution}]/best[height<=?{resolution}]\" --get-url \"{url}\"";

            Debug.Log($"[AudioLink] Attempting to resolve URL '{url}'");

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

        /// <summary> Resolves a URL and set a videoplayer's URL to the resolved URL. </summary>
        /// <param name="url">URL to resolve for playback</param>
        /// <param name="resolution">Resolution (vertical) to request from yt-dlp</param>
        /// <param name="player">VideoPlayer component to set URL on</param>
        public static void ResolveAndSet(string url, int resolution, VideoPlayer player)
        {
            try
            {
                string resolved = Resolve(url, resolution);
                if(resolved != null)
                    player.url = resolved;
            }
            catch(Exception e)
            {
                Debug.LogWarning($"[AudioLink] Unable to play URL '{url}' : " + e.Message);
            }
        }

        /// <summary> Cleans up any remaining YTDL processes from this play, in case they don't clean up after themselves. </summary>
        private static void PlayModeChanged(PlayModeStateChange change)
        {
            if (change == PlayModeStateChange.ExitingPlayMode)
            {
                foreach (var process in _runningYtdlProcesses)
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
            var webClient = new System.Net.WebClient();
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
            webClient.Dispose();

            // Check for it again to make sure it was actually downloaded
            LocateYtdlp();
        }
    }
#endif

#if UNITY_EDITOR && !UNITY_EDITOR_WIN
    // Stubs to inform mac/linux users that it's unsupported for now
    /// <summary> Downloads and plays Youtube videos via a VideoPlayer component. </summary>
    [RequireComponent(typeof(VideoPlayer))]
    public class YoutubePlayerClean : MonoBehaviour
    {
        /// <summary> Youtube url (e.g. https://www.youtube.com/watch?v=SFTcZ1GXOCQ) </summary>
        public string youtubeURL;
    }

    [CustomEditor(typeof(YoutubePlayerClean))]
    public class YoutubePlayerCleanEditor : Editor 
    {
        SerializedProperty youtubeURL;
        YoutubePlayerClean youtubePlayer;

        void OnEnable()
        {
            Debug.LogWarning("[AudioLink] Youtube Player Component is unsupported on this platform.");
            youtubeURL = serializedObject.FindProperty("youtubeURL");
            youtubePlayer = (YoutubePlayerClean) target;
        }

        public override void OnInspectorGUI()
        {
            serializedObject.Update();
            EditorGUILayout.HelpBox("Youtube Player Component is unsupported on this platform.", MessageType.Error);
            EditorGUILayout.PropertyField(youtubeURL, new GUIContent(" YouTube URL", EditorGUIUtility.IconContent("d_BuildSettings.Web.Small").image));
            serializedObject.ApplyModifiedProperties();
        }
    }
#endif
}