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
    public class YtdlpPlayer : MonoBehaviour
    {
        public string ytdlpURL = "https://www.youtube.com/watch?v=SFTcZ1GXOCQ";
        Request _currentRequest = null;

        [SerializeField]
        public bool showVideoPreviewInComponent = false;

        [SerializeReference]
        public VideoPlayer VideoPlayer = null;

        [SerializeField]
        public Resolution resolution = Resolution._720p;

        public enum Resolution
        {
            [InspectorName("360p")] _360p = 360,
            [InspectorName("480p")] _480p = 480,
            [InspectorName("720p")] _720p = 720,
            [InspectorName("1080p")] _1080p = 1080,
            [InspectorName("1440p")] _1440p = 1440,
            [InspectorName("2160p")] _2160p = 2160,
        }

        void OnEnable()
        {
            RequestPlay();
        }

        public void RequestPlay()
        {
            _currentRequest = YtdlpURLResolver.Resolve(ytdlpURL, (int)resolution);
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
            if (VideoPlayer == null)
                return;

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

        public bool GetAudioSourceVolume(out float volume)
        {
            volume = 0;

            if (VideoPlayer != null)
            {
                AudioSource AudioSourceOutput = VideoPlayer?.GetTargetAudioSource(0);
                if (AudioSourceOutput != null)
                {
                    volume = AudioSourceOutput.volume;
                    return true;
                }
            }

            return false;
        }

        public void SetAudioSourceVolume(float volume)
        {
            AudioSource AudioSourceOutput = VideoPlayer?.GetTargetAudioSource(0);
            if (AudioSourceOutput != null)
                AudioSourceOutput.volume = Mathf.Clamp01(volume);
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

        public static Request Resolve(string url, int resolution = 720)
        {
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
            // If video player is on the same gameobject, assign it automatically
            if (_ytdlpPlayer.gameObject.GetComponent<VideoPlayer>() != null)
                _ytdlpPlayer.VideoPlayer = _ytdlpPlayer.gameObject.GetComponent<VideoPlayer>();
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

            bool hasVideoPlayer = _ytdlpPlayer.VideoPlayer != null;
            float playbackTime = hasVideoPlayer ? _ytdlpPlayer.GetPlaybackTime() : 0;
            double videoLength = hasVideoPlayer ? _ytdlpPlayer.VideoPlayer.length : 0;

            using (new EditorGUI.DisabledScope(!available))
            {
                using (new EditorGUILayout.HorizontalScope())
                {
                    EditorGUILayout.LabelField(new GUIContent(" Video URL", EditorGUIUtility.IconContent("CloudConnect").image), GUILayout.Width(100));
                    _ytdlpPlayer.ytdlpURL = EditorGUILayout.TextField(_ytdlpPlayer.ytdlpURL);
                    _ytdlpPlayer.resolution = (YtdlpPlayer.Resolution)EditorGUILayout.EnumPopup(_ytdlpPlayer.resolution, GUILayout.Width(65));
                }

                using (new EditorGUI.DisabledScope(!hasVideoPlayer || !EditorApplication.isPlaying))
                {
                    using (new EditorGUILayout.HorizontalScope())
                    {
                        // Timestamp/Reload button
                        EditorGUILayout.LabelField(new GUIContent(" Seek: " + _ytdlpPlayer.PlaybackTimestampFormatted(), EditorGUIUtility.IconContent("d_Slider Icon").image));

                        GUIContent reloadButtonContent = new GUIContent(" Reload URL", EditorGUIUtility.IconContent("TreeEditor.Refresh").image);

                        bool updateURL = GUILayout.Button(reloadButtonContent);
                        if (updateURL)
                            _ytdlpPlayer.RequestPlay();
                    }

                    // Seekbar/Time input
                    using (new EditorGUI.DisabledScope(!hasVideoPlayer || videoLength == 0))
                    using (new EditorGUILayout.HorizontalScope())
                    {
                        // Seekbar input
                        EditorGUI.BeginChangeCheck();
                        playbackTime = GUILayout.HorizontalSlider(playbackTime, 0, 1);
                        if (EditorGUI.EndChangeCheck())
                            _ytdlpPlayer.SetPlaybackTime(playbackTime);

                        // Timestamp input
                        EditorGUI.BeginChangeCheck();
                        double time = hasVideoPlayer ? _ytdlpPlayer.VideoPlayer.time : 0;
                        string currentTimestamp = " " + _ytdlpPlayer.FormattedTimestamp(time);
                        string seekTimestamp = EditorGUILayout.DelayedTextField(currentTimestamp, GUILayout.MaxWidth(8 * currentTimestamp.Length));
                        if (EditorGUI.EndChangeCheck() && videoLength > 0)
                        {
                            TimeSpan inputTimestamp;
                            // Add an extra 00: to force TimeSpan to interpret 12:34 as 00:12:34 for proper mm:ss input
                            if (TimeSpan.TryParse($"00:{seekTimestamp}", out inputTimestamp))
                            {
                                playbackTime = (float)(inputTimestamp.TotalSeconds / videoLength);
                                _ytdlpPlayer.SetPlaybackTime(playbackTime);
                            }
                        }
                    }

                    // Media Controls
                    using (new EditorGUILayout.HorizontalScope())
                    {
                        bool isPlaying = hasVideoPlayer ? _ytdlpPlayer.VideoPlayer.isPlaying : false;
                        bool isPaused = hasVideoPlayer ? _ytdlpPlayer.VideoPlayer.isPaused : false;
                        bool isStopped = !isPlaying && !isPaused;

                        bool play = GUILayout.Toggle(isPlaying, new GUIContent(" Play", EditorGUIUtility.IconContent("d_PlayButton On").image), "Button") != isPlaying;
                        bool pause = GUILayout.Toggle(isPaused, new GUIContent(" Pause", EditorGUIUtility.IconContent("d_PauseButton On").image), "Button") != isPaused;
                        bool stop = GUILayout.Toggle(isStopped, new GUIContent(" Stop", EditorGUIUtility.IconContent("d_Record Off").image), "Button") != isStopped;

                        if (hasVideoPlayer)
                        {
                            if (play)
                                _ytdlpPlayer.VideoPlayer.Play();
                            else if (pause)
                                _ytdlpPlayer.VideoPlayer.Pause();
                            else if (stop)
                                _ytdlpPlayer.VideoPlayer.Stop();
                        }
                    }
                }

                float volume;
                using (new EditorGUI.DisabledScope(!_ytdlpPlayer.GetAudioSourceVolume(out volume)))
                {
                    EditorGUI.BeginChangeCheck();
                    volume = EditorGUILayout.Slider(new GUIContent("  AudioSource Gain", EditorGUIUtility.IconContent("d_Profiler.Audio").image), volume, 0.0f, 1.0f);
                    if (EditorGUI.EndChangeCheck())
                        _ytdlpPlayer.SetAudioSourceVolume(volume);
                }
            }

            bool videoPlayerOnThisObject = _ytdlpPlayer.gameObject.GetComponent<VideoPlayer>() != null;

            using (new EditorGUI.DisabledScope(EditorApplication.isPlaying || videoPlayerOnThisObject))
            {
                _ytdlpPlayer.VideoPlayer = (VideoPlayer)EditorGUILayout.ObjectField(new GUIContent("  VideoPlayer", EditorGUIUtility.IconContent("d_Profiler.Video").image), _ytdlpPlayer.VideoPlayer, typeof(VideoPlayer), allowSceneObjects: true);
            }

            // Video preview
            using (new EditorGUI.DisabledScope(!available || !hasVideoPlayer))
            {
                _ytdlpPlayer.showVideoPreviewInComponent = EditorGUILayout.Toggle(new GUIContent("  Show Video Preview", EditorGUIUtility.IconContent("d_ViewToolOrbit On").image), _ytdlpPlayer.showVideoPreviewInComponent);

                if (_ytdlpPlayer.showVideoPreviewInComponent && available && hasVideoPlayer && _ytdlpPlayer.VideoPlayer.texture != null)
                {
                    // Draw video preview with the same aspect ratio as the video
                    float aspectRatio = (float)_ytdlpPlayer.VideoPlayer.texture.width / _ytdlpPlayer.VideoPlayer.texture.height;
                    Rect previewRect = GUILayoutUtility.GetAspectRect(aspectRatio);
                    EditorGUI.DrawPreviewTexture(previewRect, _ytdlpPlayer.VideoPlayer.texture, null, ScaleMode.ScaleToFit);
                }
            }

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