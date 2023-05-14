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

namespace AudioLink
{
    public class YtdlpPlayer : MonoBehaviour
    {
        public string YtdlpURL = "https://www.youtube.com/watch?v=SFTcZ1GXOCQ";
        YtdlpRequest _currentRequest = null;

        [SerializeField]
        public bool showVideoPreviewInComponent = false;

        public VideoPlayer videoPlayer = null;

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
            _currentRequest = YtdlpURLResolver.Resolve(YtdlpURL, (int)resolution);
        }

        void Update()
        {
            if (_currentRequest != null && _currentRequest.isDone)
            {
                UpdateUrl(_currentRequest.resolvedURL);
                _currentRequest = null;
            }
        }

        public void UpdateUrl(string resolved)
        {
            if (videoPlayer == null)
                return;

            videoPlayer.url = resolved;
            SetPlaybackTime(0.0f);
            if (videoPlayer.length > 0)
            {
                videoPlayer.Play();
            }
        }

        public float GetPlaybackTime()
        {
            if (videoPlayer != null && videoPlayer.length > 0)
                return (float)(videoPlayer.length > 0 ? videoPlayer.time / videoPlayer.length : 0);
            else
                return 0;
        }

        public void SetPlaybackTime(float time)
        {
            if (videoPlayer != null && videoPlayer.length > 0 && videoPlayer.canSetTime)
                videoPlayer.time = videoPlayer.length * Mathf.Clamp(time, 0.0f, 1.0f);
        }

        public string FormattedTimestamp(double seconds, double maxSeconds = 0)
        {
            double formatValue = maxSeconds > 0 ? maxSeconds : seconds;
            string formatString = formatValue >= 3600.0 ? @"hh\:mm\:ss" : @"mm\:ss";
            return TimeSpan.FromSeconds(seconds).ToString(formatString);
        }

        public string PlaybackTimestampFormatted()
        {
            if (videoPlayer != null && videoPlayer.length > 0)
            {
                return $"{FormattedTimestamp(videoPlayer.time, videoPlayer.length)} / {FormattedTimestamp(videoPlayer.length)}";
            }
            else
            {
                return "00:00 / 00:00";
            }
        }

        public bool GetAudioSourceVolume(out float volume)
        {
            volume = 0;

            if (videoPlayer != null)
            {
                AudioSource audioSourceOutput = videoPlayer.GetTargetAudioSource(0);
                if (audioSourceOutput != null)
                {
                    volume = audioSourceOutput.volume;
                    return true;
                }
            }

            return false;
        }

        public void SetAudioSourceVolume(float volume)
        {
            if (videoPlayer != null)
            {
                AudioSource audioSourceOutput = videoPlayer.GetTargetAudioSource(0);
                if (audioSourceOutput != null)
                    audioSourceOutput.volume = Mathf.Clamp01(volume);
            }
        }
    }

    public class YtdlpRequest
    {
        public bool isDone;
        public string resolvedURL;
    }

    public static class YtdlpURLResolver
    {
        private static string _localYtdlpPath = Application.dataPath + "\\AudioLink\\yt-dlp.exe";

        private static string _YtdlpPath = "";
        private static bool _YtdlpFound = false;

        public static bool IsYtdlpAvailable()
        {
            if (_YtdlpFound)
                return true;

            LocateYtdlp();
            return _YtdlpFound;
        }

        public static void LocateYtdlp()
        {
            _YtdlpFound = false;
#if UNITY_EDITOR_WIN
            string[] splitPath = Application.persistentDataPath.Split('/', '\\');

            _YtdlpPath = string.Join("\\", splitPath.Take(splitPath.Length - 2)) + "\\VRChat\\VRChat\\Tools\\yt-dlp.exe";
#else
            _YtdlpPath = "/usr/bin/yt-dlp";
#endif
            if (!File.Exists(_YtdlpPath))
            {
                _YtdlpPath = _localYtdlpPath;
            }

            if (!File.Exists(_YtdlpPath))
            {
#if UNITY_EDITOR_WIN
                _YtdlpPath = LocateExecutable("yt-dlp.exe");
#else
                _YtdlpPath = LocateExecutable("yt-dlp");
#endif
            }

            if (!File.Exists(_YtdlpPath))
            {
                return;
            }
            else
            {
                _YtdlpFound = true;
                Debug.Log($"[AudioLink] Found yt-dlp at path '{_YtdlpPath}'");
            }
        }

        public static YtdlpRequest Resolve(string url, int resolution = 720)
        {
            if (!_YtdlpFound)
            {
                LocateYtdlp();
            }

            if (!_YtdlpFound)
            {
                Debug.LogWarning($"[AudioLink] Unable to resolve URL '{url}' : yt-dlp not found");
            }

            System.Diagnostics.Process proc = new System.Diagnostics.Process();
           YtdlpRequest request = new YtdlpRequest();

            proc.EnableRaisingEvents = false;

            proc.StartInfo.WindowStyle = System.Diagnostics.ProcessWindowStyle.Hidden;
            proc.StartInfo.CreateNoWindow = true;
            proc.StartInfo.UseShellExecute = false;
            proc.StartInfo.RedirectStandardOutput = true;
            proc.StartInfo.FileName = _YtdlpPath;
            proc.StartInfo.Arguments = $"--no-check-certificate --no-cache-dir --rm-cache-dir -f \"mp4[height<=?{resolution}]/best[height<=?{resolution}]\" --get-url \"{url}\"";

            proc.Exited += (sender, args) =>
            {
                proc.Dispose();
            };

            proc.OutputDataReceived += (sender, args) =>
            {
                if (args.Data != null)
                {
                    request.resolvedURL = args.Data;
                    request.isDone = true;
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
    public class YtdlpPlayerEditor : UnityEditor.Editor
    {
        YtdlpPlayer _YtdlpPlayer;

        void OnEnable()
        {
            _YtdlpPlayer = (YtdlpPlayer)target;
            // If video player is on the same gameobject, assign it automatically
            if (_YtdlpPlayer.gameObject.GetComponent<VideoPlayer>() != null)
                _YtdlpPlayer.videoPlayer = _YtdlpPlayer.gameObject.GetComponent<VideoPlayer>();
        }

        public override bool RequiresConstantRepaint()
        {
            if (_YtdlpPlayer.videoPlayer != null)
                return _YtdlpPlayer.videoPlayer.isPlaying;
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

            bool hasVideoPlayer = _YtdlpPlayer.videoPlayer != null;
            float playbackTime = hasVideoPlayer ? _YtdlpPlayer.GetPlaybackTime() : 0;
            double videoLength = hasVideoPlayer ? _YtdlpPlayer.videoPlayer.length : 0;

            using (new EditorGUI.DisabledScope(!available))
            {
                using (new EditorGUILayout.HorizontalScope())
                {
                    EditorGUILayout.LabelField(new GUIContent(" Video URL", EditorGUIUtility.IconContent("CloudConnect").image), GUILayout.Width(100));
                    _YtdlpPlayer.YtdlpURL = EditorGUILayout.TextField(_YtdlpPlayer.YtdlpURL);
                    _YtdlpPlayer.resolution = (YtdlpPlayer.Resolution)EditorGUILayout.EnumPopup(_YtdlpPlayer.resolution, GUILayout.Width(65));
                }

                using (new EditorGUI.DisabledScope(!hasVideoPlayer || !EditorApplication.isPlaying))
                {
                    using (new EditorGUILayout.HorizontalScope())
                    {
                        // Timestamp/Reload button
                        EditorGUILayout.LabelField(new GUIContent(" Seek: " + _YtdlpPlayer.PlaybackTimestampFormatted(), EditorGUIUtility.IconContent("d_Slider Icon").image));

                        GUIContent reloadButtonContent = new GUIContent(" Reload URL", EditorGUIUtility.IconContent("TreeEditor.Refresh").image);

                        bool updateURL = GUILayout.Button(reloadButtonContent);
                        if (updateURL)
                            _YtdlpPlayer.RequestPlay();
                    }

                    // Seekbar/Time input
                    using (new EditorGUI.DisabledScope(!hasVideoPlayer || videoLength == 0))
                    using (new EditorGUILayout.HorizontalScope())
                    {
                        // Seekbar input
                        EditorGUI.BeginChangeCheck();
                        playbackTime = GUILayout.HorizontalSlider(playbackTime, 0, 1);
                        if (EditorGUI.EndChangeCheck())
                            _YtdlpPlayer.SetPlaybackTime(playbackTime);

                        // Timestamp input
                        EditorGUI.BeginChangeCheck();
                        double time = hasVideoPlayer ? _YtdlpPlayer.videoPlayer.time : 0;
                        string currentTimestamp = _YtdlpPlayer.FormattedTimestamp(time, videoLength);
                        string seekTimestamp = EditorGUILayout.DelayedTextField(currentTimestamp, GUILayout.MaxWidth(8 * currentTimestamp.Length));
                        if (EditorGUI.EndChangeCheck() && videoLength > 0)
                        {
                            TimeSpan inputTimestamp;
                            // Add extra 00:'s to force TimeSpan.TryParse to interpret times properly
                            // 22 -> 00:00:22, 2:22 -> 00:02:22, 2:22:22 -> 00:2:22:22
                            if (seekTimestamp.Length < 5)
                                seekTimestamp = "00:" + seekTimestamp;
                            if (TimeSpan.TryParse($"00:{seekTimestamp}", out inputTimestamp))
                            {
                                playbackTime = (float)(inputTimestamp.TotalSeconds / videoLength);
                                _YtdlpPlayer.SetPlaybackTime(playbackTime);
                            }
                        }
                    }

                    // Media Controls
                    using (new EditorGUILayout.HorizontalScope())
                    {
                        bool isPlaying = hasVideoPlayer ? _YtdlpPlayer.videoPlayer.isPlaying : false;
                        bool isPaused = hasVideoPlayer ? _YtdlpPlayer.videoPlayer.isPaused : false;
                        bool isStopped = !isPlaying && !isPaused;

                        bool play = GUILayout.Toggle(isPlaying, new GUIContent(" Play", EditorGUIUtility.IconContent("d_PlayButton On").image), "Button") != isPlaying;
                        bool pause = GUILayout.Toggle(isPaused, new GUIContent(" Pause", EditorGUIUtility.IconContent("d_PauseButton On").image), "Button") != isPaused;
                        bool stop = GUILayout.Toggle(isStopped, new GUIContent(" Stop", EditorGUIUtility.IconContent("d_Record Off").image), "Button") != isStopped;

                        if (hasVideoPlayer)
                        {
                            if (play)
                                _YtdlpPlayer.videoPlayer.Play();
                            else if (pause)
                                _YtdlpPlayer.videoPlayer.Pause();
                            else if (stop)
                                _YtdlpPlayer.videoPlayer.Stop();
                        }
                    }
                }

                float volume;
                using (new EditorGUI.DisabledScope(!_YtdlpPlayer.GetAudioSourceVolume(out volume)))
                {
                    EditorGUI.BeginChangeCheck();
                    volume = EditorGUILayout.Slider(new GUIContent("  AudioSource Volume", EditorGUIUtility.IconContent("d_Profiler.Audio").image), volume, 0.0f, 1.0f);
                    if (EditorGUI.EndChangeCheck())
                        _YtdlpPlayer.SetAudioSourceVolume(volume);
                }
            }

            bool videoPlayerOnThisObject = _YtdlpPlayer.gameObject.GetComponent<VideoPlayer>() != null;

            using (new EditorGUI.DisabledScope(EditorApplication.isPlaying || videoPlayerOnThisObject))
            {
                _YtdlpPlayer.videoPlayer = (VideoPlayer)EditorGUILayout.ObjectField(new GUIContent("  VideoPlayer", EditorGUIUtility.IconContent("d_Profiler.Video").image), _YtdlpPlayer.videoPlayer, typeof(VideoPlayer), allowSceneObjects: true);
            }

            // Video preview
            using (new EditorGUI.DisabledScope(!available || !hasVideoPlayer))
            {
                _YtdlpPlayer.showVideoPreviewInComponent = EditorGUILayout.Toggle(new GUIContent("  Show Video Preview", EditorGUIUtility.IconContent("d_ViewToolOrbit On").image), _YtdlpPlayer.showVideoPreviewInComponent);

                if (_YtdlpPlayer.showVideoPreviewInComponent && available && hasVideoPlayer && _YtdlpPlayer.videoPlayer.texture != null)
                {
                    // Draw video preview with the same aspect ratio as the video
                    Texture videoPlayerTexture = _YtdlpPlayer.videoPlayer.texture;
                    float aspectRatio = (float)videoPlayerTexture.width / videoPlayerTexture.height;
                    Rect previewRect = GUILayoutUtility.GetAspectRect(aspectRatio);
                    EditorGUI.DrawPreviewTexture(previewRect, videoPlayerTexture, null, ScaleMode.ScaleToFit);
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