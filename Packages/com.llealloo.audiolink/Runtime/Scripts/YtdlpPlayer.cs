#if UNITY_EDITOR && !COMPILER_UDONSHARP
using System;
using System.IO;
using System.Linq;
using UnityEditor;
using UnityEngine;
using UnityEngine.Video;

// This component uses code from the following sources:
// UnityYoutubePlayer, courtesy iBicha (SPDX-License-Identifier: Unlicense) https://github.com/iBicha/UnityYoutubePlayer
// USharpVideo, Copyright (c) 2020 Merlin, (SPDX-License-Identifier: MIT) https://github.com/MerlinVR/USharpVideo/

// TODO(float3): add this to the AudioLinkMiniPlayer
// TODO(float3): use SessionState to cache the resolved URL
// TODO(float3): add volume bar

namespace AudioLink
{
    [RequireComponent(typeof(VideoPlayer))]
    public class YtdlpPlayer : MonoBehaviour
    {
        public string ytdlpURL = "https://www.youtube.com/watch?v=SFTcZ1GXOCQ";
        public VideoPlayer VideoPlayer { get; private set; }
        Request _currentRequest = null;

        void OnEnable()
        {
            VideoPlayer = GetComponent<VideoPlayer>();
            RequestPlay();
        }

        public void RequestPlay()
        {
            _currentRequest = YtdlpURLResolver.Resolve(ytdlpURL);
        }

        void Update()
        {
            if (_currentRequest != null && _currentRequest.IsDone)
            {
                UpdateUrl(_currentRequest.ResolvedURL);
                _currentRequest = null;
            }
        }

        public void UpdateUrl(string resolved)
        {
            VideoPlayer.url = resolved;
            SetPlaybackTime(0.0f);
            if (VideoPlayer.length > 0)
            {
                VideoPlayer.Play();
            }
        }

        public float GetPlaybackTime()
        {
            if (VideoPlayer != null && VideoPlayer.length > 0)
                return (float)(VideoPlayer.length > 0 ? VideoPlayer.time / VideoPlayer.length : 0);
            else
                return 0;
        }

        public void SetPlaybackTime(float time)
        {
            if (VideoPlayer != null && VideoPlayer.length > 0 && VideoPlayer.canSetTime)
                VideoPlayer.time = VideoPlayer.length * Mathf.Clamp(time, 0.0f, 1.0f);
        }

        public string FormattedTimestamp(double seconds, double maxSeconds = 0)
        {
            double formatValue = maxSeconds > 0 ? maxSeconds : seconds;
            string formatString = formatValue >= 3600.0 ? @"hh\:mm\:ss" : @"mm\:ss";
            return TimeSpan.FromSeconds(seconds).ToString(formatString);
        }

        public string PlaybackTimestampFormatted()
        {
            if (VideoPlayer != null && VideoPlayer.length > 0)
            {
                return $"{FormattedTimestamp(VideoPlayer.time, VideoPlayer.length)} / {FormattedTimestamp(VideoPlayer.length)}";
            }
            else
            {
                return "00:00 / 00:00";
            }
        }
    }

    public class Request
    {
        public bool IsDone;
        public string ResolvedURL;
    }

    public static class YtdlpURLResolver
    {
        private static string _localYtdlpPath = Application.dataPath + "\\AudioLink\\yt-dlp.exe";

        private static string _ytdlpPath = "";
        private static bool _ytdlpFound = false;

        public static bool IsYtdlpAvailable()
        {
            if (_ytdlpFound)
                return true;

            LocateYtdlp();
            return _ytdlpFound;
        }

        public static void LocateYtdlp()
        {
            _ytdlpFound = false;
#if UNITY_EDITOR_WIN
            string[] splitPath = Application.persistentDataPath.Split('/', '\\');

            _ytdlpPath = string.Join("\\", splitPath.Take(splitPath.Length - 2)) + "\\VRChat\\VRChat\\Tools\\yt-dlp.exe";
#else
            _ytdlpPath = "/usr/bin/yt-dlp";
#endif
            if (!File.Exists(_ytdlpPath))
            {
                _ytdlpPath = _localYtdlpPath;
            }

            if (!File.Exists(_ytdlpPath))
            {
#if UNITY_EDITOR_WIN
                _ytdlpPath = LocateExecutable("yt-dlp.exe");
#else
                _ytdlpPath = LocateExecutable("yt-dlp");
#endif
            }

            if (!File.Exists(_ytdlpPath))
            {
                return;
            }
            else
            {
                _ytdlpFound = true;
                Debug.Log($"[AudioLink] Found yt-dlp at path '{_ytdlpPath}'");
            }
        }

        public static Request Resolve(string url)
        {
            const int resolution = 720;
            if (!_ytdlpFound)
            {
                LocateYtdlp();
            }

            if (!_ytdlpFound)
            {
                Debug.LogWarning($"[AudioLink] Unable to resolve URL '{url}' : yt-dlp not found");
            }

            System.Diagnostics.Process proc = new System.Diagnostics.Process();
            Request request = new Request();

            proc.EnableRaisingEvents = false;

            proc.StartInfo.WindowStyle = System.Diagnostics.ProcessWindowStyle.Hidden;
            proc.StartInfo.CreateNoWindow = true;
            proc.StartInfo.UseShellExecute = false;
            proc.StartInfo.RedirectStandardOutput = true;
            proc.StartInfo.FileName = _ytdlpPath;
            proc.StartInfo.Arguments = $"--no-check-certificate --no-cache-dir --rm-cache-dir -f \"mp4[height<=?{resolution}]/best[height<=?{resolution}]\" --get-url \"{url}\"";

            proc.Exited += (sender, args) =>
            {
                proc.Dispose();
            };

            proc.OutputDataReceived += (sender, args) =>
            {
                if (args.Data != null)
                {
                    request.ResolvedURL = args.Data;
                    request.IsDone = true;
                }
            };

            try
            {
                proc.Start();
                proc.BeginOutputReadLine();

                return request;
            }
            catch (Exception e)
            {
                Debug.Log(e.Message);
                return null;
            }
        }

        private static string LocateExecutable(string name)
        {
            if (!File.Exists(name))
            {
                if (Path.GetDirectoryName(name) == string.Empty)
                {
                    string[] path = (Environment.GetEnvironmentVariable("PATH") ?? "").Split(Path.PathSeparator);
                    foreach (string dir in path)
                    {
                        string trimmed = dir.Trim();
                        if (!string.IsNullOrEmpty(trimmed) && File.Exists(Path.Combine(trimmed, name)))
                            return Path.GetFullPath(Path.Combine(trimmed, name));
                    }
                }
            }
            return Path.GetFullPath(name);
        }
    }

    [CustomEditor(typeof(YtdlpPlayer))]
    public class ytdlpPlayerEditor : UnityEditor.Editor
    {
        YtdlpPlayer _ytdlpPlayer;

        void OnEnable()
        {
            _ytdlpPlayer = (YtdlpPlayer)target;
        }

        public override bool RequiresConstantRepaint()
        {
            if (_ytdlpPlayer.VideoPlayer != null)
                return _ytdlpPlayer.VideoPlayer.isPlaying;
            else
                return false;
        }

        public override void OnInspectorGUI()
        {
#if UNITY_EDITOR_LINUX
            bool available = false;
#else
            bool available = YtdlpURLResolver.IsYtdlpAvailable();
#endif

            EditorGUI.BeginDisabledGroup(!available);
            base.OnInspectorGUI();
            float playbackTime = 0;
            bool hasPlayer = _ytdlpPlayer.VideoPlayer != null;
            if (hasPlayer && _ytdlpPlayer.VideoPlayer.length > 0)
                playbackTime = _ytdlpPlayer.GetPlaybackTime();

            EditorGUI.BeginDisabledGroup(!hasPlayer || !Application.IsPlaying(target) || !_ytdlpPlayer.VideoPlayer.isPlaying);
            using (new EditorGUILayout.HorizontalScope())
            {
                EditorGUILayout.LabelField(new GUIContent(" Seek: " + _ytdlpPlayer.PlaybackTimestampFormatted(), EditorGUIUtility.IconContent("d_Slider Icon").image));
                bool updateURL = GUILayout.Button(new GUIContent(" Reload", EditorGUIUtility.IconContent("TreeEditor.Refresh").image));
                if (updateURL)
                    _ytdlpPlayer.RequestPlay();
            }

            EditorGUI.BeginChangeCheck();
            playbackTime = EditorGUILayout.Slider(playbackTime, 0, 1);
            if (EditorGUI.EndChangeCheck())
                _ytdlpPlayer.SetPlaybackTime(playbackTime);

            EditorGUI.EndDisabledGroup();
            EditorGUI.EndDisabledGroup();

            if (!available)
            {
#if UNITY_EDITOR_LINUX
                EditorGUILayout.HelpBox("The yt-dlp Player is currently not supported on Linux, as Unity on Linux cannot play the required file formats.", MessageType.Warning);
#elif UNITY_EDITOR_WIN
                EditorGUILayout.HelpBox("Failed to locate yt-dlp executable. To fix this, either install and launch VRChat once, or install yt-dlp and make sure the executable is on your PATH. Once this is done, enter play mode to retry.", MessageType.Warning);
#else
                EditorGUILayout.HelpBox("Failed to locate yt-dlp executable. To fix this, install yt-dlp and make sure the executable is on your PATH. Once this is done, enter play mode to retry.", MessageType.Warning);
#endif
            }
        }
    }

}
#endif