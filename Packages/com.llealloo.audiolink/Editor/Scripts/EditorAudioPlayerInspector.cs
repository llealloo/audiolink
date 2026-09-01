#if UNITY_EDITOR && !COMPILER_UDONSHARP
using System;
using System.Globalization;
using System.IO;
using UnityEditor;
using UnityEngine;
using UnityEngine.Video;

namespace AudioLink.Editor
{
    [CustomEditor(typeof(EditorAudioPlayer))]
    internal class EditorAudioPlayerInspector : UnityEditor.Editor
    {
        private const string ShowVideoPreviewKey = "YTDLP-VIDEO-PREVIEW";
        private const string UseFFmpegTranscodeKey = "USE-FFMPEG-TRANSCODE";
        private const string LastDirectoryKey = "AUDIOLINK-LOCAL-FILE-LAST-DIRECTORY";

        private const long LargeFileWarningBytes = 32L * 1024L * 1024L;

        // Locating yt-dlp or ffmpeg walks every entry in PATH when they are missing, which is far
        // too much work to repeat on an inspector that repaints every frame during playback.
        private static bool _ytdlpAvailable;
        private static bool _ffmpegAvailable;
        private static double _toolsLastChecked = double.NegativeInfinity;

        private static bool _showAdvanced;

        // Same reasoning for the file probe behind the local file status line.
        private string _probedPath;
        private double _probedAt = double.NegativeInfinity;
        private bool _probedExists;
        private long _probedSize;

        // IMGUI walks this method twice per frame, once to lay out and once to paint, and both
        // passes must begin and end exactly the same layout groups. Everything that decides what
        // gets drawn is sampled once on Layout into these fields and read from here afterwards, so
        // a timer expiring or a load finishing midway through a frame cannot desynchronise them.
        private bool _layoutLocalMode;
        private bool _layoutAdvanced;
        private string _layoutPath = "";
        private bool _layoutFileExists;
        private long _layoutFileSize;
        private bool _layoutNativeFormat = true;
        private bool _layoutYtdlp;
        private bool _layoutFFmpeg;
        private EditorAudioPlayer.LoadState _layoutLoadState;

        private EditorAudioPlayer _player;

        private SerializedProperty _playbackSource;
        private SerializedProperty _audioLink;
        private SerializedProperty _loop;

        private SerializedProperty _ytdlpURL;
        private SerializedProperty _resolution;
        private SerializedProperty _videoPlayer;

        private SerializedProperty _audioFilePath;
        private SerializedProperty _audioSource;
        private SerializedProperty _playOnLoad;
        private SerializedProperty _streamFromDisk;

        private SerializedProperty _enableGlobalVideoTexture;
        private SerializedProperty _globalTextureName;
        private SerializedProperty _textureTransformMode;
        private SerializedProperty _texturePixelOrigin;
        private SerializedProperty _texturePixelSize;
        private SerializedProperty _textureTiling;
        private SerializedProperty _textureOffset;
        private SerializedProperty _showStandbyIfPaused;
        private SerializedProperty _forceStandbyTexture;
        private SerializedProperty _standbyTexture;

        private void OnEnable()
        {
            _player = (EditorAudioPlayer)target;

            _playbackSource = serializedObject.FindProperty(nameof(EditorAudioPlayer.playbackSource));
            _audioLink = serializedObject.FindProperty(nameof(EditorAudioPlayer.audioLink));
            _loop = serializedObject.FindProperty(nameof(EditorAudioPlayer.loop));

            _ytdlpURL = serializedObject.FindProperty(nameof(EditorAudioPlayer.ytdlpURL));
            _resolution = serializedObject.FindProperty(nameof(EditorAudioPlayer.resolution));
            _videoPlayer = serializedObject.FindProperty(nameof(EditorAudioPlayer.videoPlayer));

            _audioFilePath = serializedObject.FindProperty(nameof(EditorAudioPlayer.audioFilePath));
            _audioSource = serializedObject.FindProperty(nameof(EditorAudioPlayer.audioSource));
            _playOnLoad = serializedObject.FindProperty(nameof(EditorAudioPlayer.playOnLoad));
            _streamFromDisk = serializedObject.FindProperty(nameof(EditorAudioPlayer.streamFromDisk));

            _enableGlobalVideoTexture = serializedObject.FindProperty(nameof(EditorAudioPlayer.enableGlobalVideoTexture));
            _globalTextureName = serializedObject.FindProperty(nameof(EditorAudioPlayer.globalTextureName));
            _textureTransformMode = serializedObject.FindProperty(nameof(EditorAudioPlayer.textureTransformMode));
            _texturePixelOrigin = serializedObject.FindProperty(nameof(EditorAudioPlayer.texturePixelOrigin));
            _texturePixelSize = serializedObject.FindProperty(nameof(EditorAudioPlayer.texturePixelSize));
            _textureTiling = serializedObject.FindProperty(nameof(EditorAudioPlayer.textureTiling));
            _textureOffset = serializedObject.FindProperty(nameof(EditorAudioPlayer.textureOffset));
            _showStandbyIfPaused = serializedObject.FindProperty(nameof(EditorAudioPlayer.showStandbyIfPaused));
            _forceStandbyTexture = serializedObject.FindProperty(nameof(EditorAudioPlayer.forceStandbyTexture));
            _standbyTexture = serializedObject.FindProperty(nameof(EditorAudioPlayer.standbyTexture));

            // The shipped prefab keeps the VideoPlayer on this same object; wire it up so a fresh
            // component is usable without hunting for the reference.
            if (_videoPlayer.objectReferenceValue == null)
            {
                VideoPlayer local = _player.GetComponent<VideoPlayer>();
                if (local != null)
                {
                    _videoPlayer.objectReferenceValue = local;
                    serializedObject.ApplyModifiedPropertiesWithoutUndo();
                }
            }
        }

        public override bool RequiresConstantRepaint()
        {
            return _player != null && (_player.isBusy || _player.isPlaying);
        }

        public override void OnInspectorGUI()
        {
            serializedObject.Update();

            if (Event.current.type == EventType.Layout)
                CaptureLayoutState();

            // A scope, not a bare BeginVertical/EndVertical pair: if any of the Draw calls throws,
            // the scope still closes its layout group while unwinding.
            Rect dropArea;
            using (EditorGUILayout.VerticalScope scope = new EditorGUILayout.VerticalScope())
            {
                dropArea = scope.rect;

                DrawSourceSelector();

                if (_layoutLocalMode)
                {
                    DrawLocalFileSelector();
                    DrawLocalFileStatus();
                }
                else
                {
                    DrawStreamSelector();
                }

                DrawTransport();
                DrawOptions();
                DrawReferences();
                DrawVideoTextureSection();
                DrawToolWarnings();
            }

            if (_layoutLocalMode)
                HandleDragAndDrop(dropArea);

            serializedObject.ApplyModifiedProperties();
        }

        /// <summary>Samples everything that decides which controls get drawn, once per frame.</summary>
        private void CaptureLayoutState()
        {
            // intValue is the enum's numeric value; the enumValueIndex used by the toolbar below is
            // its position in the declaration order.
            _layoutLocalMode = _playbackSource.intValue == (int)EditorAudioPlayer.PlaybackSource.LocalFile;
            _layoutAdvanced = _showAdvanced;
            _layoutPath = _audioFilePath.stringValue ?? "";
            _layoutLoadState = _player.loadState;
            _layoutNativeFormat = string.IsNullOrEmpty(_layoutPath) || LocalAudioFile.IsNativelySupported(_layoutPath);

            RefreshToolAvailability(false);
            _layoutYtdlp = _ytdlpAvailable;
            _layoutFFmpeg = _ffmpegAvailable;

            ProbeFile(_layoutLocalMode ? _layoutPath : "");
            _layoutFileExists = _probedExists;
            _layoutFileSize = _probedSize;
        }

        #region Source selection

        private void DrawSourceSelector()
        {
            using (new EditorGUILayout.HorizontalScope())
            {
                EditorGUILayout.LabelField("  Source", GUILayout.Width(100));

                GUIContent[] options =
                {
                    new GUIContent(" Stream", EditorGUIUtility.IconContent("CloudConnect").image),
                    new GUIContent(" Local File", EditorGUIUtility.IconContent("d_Profiler.Audio").image)
                };

                int current = _playbackSource.enumValueIndex;
                int picked = GUILayout.Toolbar(current, options);
                if (picked != current)
                {
                    _playbackSource.enumValueIndex = picked;
                    // The panel below swaps on the next Layout pass, so ask for one right away.
                    Repaint();
                }
            }
        }

        private void DrawStreamSelector()
        {
            using (new EditorGUI.DisabledScope(!_layoutYtdlp))
            using (new EditorGUILayout.HorizontalScope())
            {
                EditorGUILayout.LabelField(new GUIContent(" Video URL", EditorGUIUtility.IconContent("CloudConnect").image), GUILayout.Width(100));
                EditorGUILayout.PropertyField(_ytdlpURL, GUIContent.none);
                EditorGUILayout.PropertyField(_resolution, GUIContent.none, GUILayout.Width(65));
            }

            if (ytdlpURLResolver.useFFmpeg && _layoutFFmpeg)
            {
                EditorGUILayout.HelpBox("Using FFmpeg to transcode test videos into a compatible format locally.\n\n" +
                                        "This may play videos that *are not* supported in VRChat / ChilloutVR,\nadditionally it does not support livestreams.\n\n" +
                                        "If you encounter any issues, specify you're using FFmpeg Transcoding when reporting issues.",
                    MessageType.Info);
            }
        }

        private void DrawLocalFileSelector()
        {
            using (new EditorGUILayout.HorizontalScope())
            {
                EditorGUILayout.LabelField(new GUIContent(" Audio File", EditorGUIUtility.IconContent("d_Profiler.Audio").image), GUILayout.Width(100));

                string fileName = string.IsNullOrEmpty(_layoutPath) ? "(no file selected)" : Path.GetFileName(_layoutPath);
                using (new EditorGUI.DisabledScope(true))
                    EditorGUILayout.TextField(fileName);

                if (GUILayout.Button("Browse...", GUILayout.Width(74)))
                    BrowseForFile();

                using (new EditorGUI.DisabledScope(string.IsNullOrEmpty(_layoutPath)))
                {
                    if (GUILayout.Button("Clear", GUILayout.Width(50)))
                        ApplyPathFromGui("");
                }
            }

            if (!string.IsNullOrEmpty(_layoutPath))
            {
                using (new EditorGUI.DisabledScope(true))
                    EditorGUILayout.LabelField(_layoutPath, EditorStyles.miniLabel);
            }
            else
            {
                EditorGUILayout.LabelField("Drop an audio file anywhere on this component, or use Browse.", EditorStyles.miniLabel);
            }
        }

        private void DrawLocalFileStatus()
        {
            if (!string.IsNullOrEmpty(_layoutPath) && !_layoutFileExists)
            {
                EditorGUILayout.HelpBox("That file no longer exists on disk.", MessageType.Error);
                return;
            }

            if (!string.IsNullOrEmpty(_layoutPath) && !_layoutNativeFormat)
            {
                if (_layoutFFmpeg)
                {
                    EditorGUILayout.HelpBox($"'{Path.GetExtension(_layoutPath)}' is not a format Unity decodes directly. " +
                                            "It will be converted to WAV with ffmpeg on load, and the result cached for this editor session.",
                        MessageType.Info);
                }
                else
                {
                    EditorGUILayout.HelpBox($"'{Path.GetExtension(_layoutPath)}' is not a format Unity decodes directly, and ffmpeg was not found to convert it.\n\n" +
                                            "Install ffmpeg and make sure it is on your PATH, or point AudioLink at it via " +
                                            "Tools/AudioLink/Select Custom FFmpeg Location.\n\n" +
                                            "Alternatively, pick a .wav, .mp3, .ogg or .aiff file instead.",
                        MessageType.Warning);
                }
            }

            switch (_layoutLoadState)
            {
                case EditorAudioPlayer.LoadState.Failed:
                    EditorGUILayout.HelpBox(_player.statusMessage, MessageType.Error);
                    break;
                case EditorAudioPlayer.LoadState.Loading:
                case EditorAudioPlayer.LoadState.Transcoding:
                    EditorGUILayout.HelpBox(_player.statusMessage, MessageType.Info);
                    break;
                case EditorAudioPlayer.LoadState.Ready:
                    using (new EditorGUI.DisabledScope(true))
                        EditorGUILayout.LabelField("Loaded", _player.statusMessage, EditorStyles.miniLabel);
                    break;
            }

            if (!EditorApplication.isPlaying)
                EditorGUILayout.HelpBox("Enter Play Mode to play the selected file. AudioLink does not run in Edit Mode.", MessageType.Info);
        }

        #endregion

        #region Transport

        private void DrawTransport()
        {
            bool hasSource = _layoutLocalMode
                ? !string.IsNullOrEmpty(_layoutPath)
                : _videoPlayer.objectReferenceValue != null;

            using (new EditorGUILayout.HorizontalScope())
            {
                EditorGUILayout.LabelField(new GUIContent(" Seek: " + _player.PlaybackTimestampFormatted(), EditorGUIUtility.IconContent("d_Slider Icon").image));

                using (new EditorGUI.DisabledScope(!EditorApplication.isPlaying || !hasSource))
                {
                    GUIContent reloadContent = new GUIContent(_layoutLocalMode ? " Reload File" : " Reload URL", EditorGUIUtility.IconContent("TreeEditor.Refresh").image);
                    if (GUILayout.Button(reloadContent, GUILayout.Width(110)))
                        _player.Reload();
                }
            }

            using (new EditorGUI.DisabledScope(!EditorApplication.isPlaying || !_player.isReady))
            {
                using (new EditorGUILayout.HorizontalScope())
                {
                    EditorGUI.BeginChangeCheck();
                    float playbackTime = GUILayout.HorizontalSlider(_player.GetPlaybackTime(), 0f, 1f);
                    if (EditorGUI.EndChangeCheck())
                        _player.SetPlaybackTime(playbackTime);

                    EditorGUI.BeginChangeCheck();
                    string currentTimestamp = _player.FormattedTimestamp(_player.playbackSeconds, _player.lengthSeconds);
                    string seekTimestamp = EditorGUILayout.DelayedTextField(currentTimestamp, GUILayout.MaxWidth(8 * currentTimestamp.Length + 16));
                    if (EditorGUI.EndChangeCheck() && TryParseTimestamp(seekTimestamp, out double seekSeconds))
                        _player.SetPlaybackSeconds(seekSeconds);
                }

                // The toggles report a click by coming back different to what went in.
                using (new EditorGUILayout.HorizontalScope())
                {
                    bool isPlaying = _player.isPlaying;
                    bool isPaused = _player.isPaused;
                    bool isStopped = !isPlaying && !isPaused;

                    bool play = GUILayout.Toggle(isPlaying, new GUIContent(" Play", EditorGUIUtility.IconContent("d_PlayButton On").image), "Button") != isPlaying;
                    bool pause = GUILayout.Toggle(isPaused, new GUIContent(" Pause", EditorGUIUtility.IconContent("d_PauseButton On").image), "Button") != isPaused;
                    bool stop = GUILayout.Toggle(isStopped, new GUIContent(" Stop", EditorGUIUtility.IconContent("d_Record Off").image), "Button") != isStopped;

                    if (play)
                        _player.Play();
                    else if (pause)
                        _player.Pause();
                    else if (stop)
                        _player.Stop();
                }
            }

            float volume;
            using (new EditorGUI.DisabledScope(!_player.GetAudioSourceVolume(out volume)))
            {
                EditorGUI.BeginChangeCheck();
                volume = EditorGUILayout.Slider(new GUIContent("  AudioSource Volume", EditorGUIUtility.IconContent("d_Profiler.Audio").image), volume, 0f, 1f);
                if (EditorGUI.EndChangeCheck())
                {
                    if (_player.audioSource != null)
                        Undo.RecordObject(_player.audioSource, "Change AudioLink input volume");
                    _player.SetAudioSourceVolume(volume);
                }
            }
        }

        #endregion

        #region Options and references

        private void DrawOptions()
        {
            EditorGUILayout.PropertyField(_loop, new GUIContent("Loop"));

            if (_layoutLocalMode)
                EditorGUILayout.PropertyField(_playOnLoad, new GUIContent("Play On Load"));

            EditorGUI.BeginChangeCheck();
            _showAdvanced = EditorGUILayout.Foldout(_showAdvanced, "Advanced", true);
            if (EditorGUI.EndChangeCheck())
                Repaint();

            if (!_layoutAdvanced)
                return;

            using (new EditorGUILayout.VerticalScope("box"))
            {
                if (_layoutLocalMode)
                {
                    EditorGUI.BeginChangeCheck();
                    EditorGUILayout.PropertyField(_streamFromDisk, new GUIContent("Stream From Disk"));
                    if (EditorGUI.EndChangeCheck() && EditorApplication.isPlaying)
                    {
                        // The mode is picked when the clip is decoded, so the change needs a fresh load.
                        serializedObject.ApplyModifiedProperties();
                        _player.Reload();
                    }

                    if (!_streamFromDisk.boolValue && _layoutFileSize > LargeFileWarningBytes)
                    {
                        EditorGUILayout.HelpBox("This file is fairly large. Decoding it in full will use a lot of memory - " +
                                                "consider turning on Stream From Disk.", MessageType.Info);
                    }
                }
                else
                {
                    bool platformDefaultUseFFmpegTranscode = false;
#if UNITY_EDITOR_LINUX
                    platformDefaultUseFFmpegTranscode = true;
#endif
                    bool wasUsingFFmpeg = EditorPrefs.GetBool(UseFFmpegTranscodeKey, platformDefaultUseFFmpegTranscode);
                    ytdlpURLResolver.useFFmpeg = EditorGUILayout.ToggleLeft(new GUIContent("Use FFmpeg Transcoding"), wasUsingFFmpeg);

                    if (wasUsingFFmpeg != ytdlpURLResolver.useFFmpeg)
                        EditorPrefs.SetBool(UseFFmpegTranscodeKey, ytdlpURLResolver.useFFmpeg);
                }

                using (new EditorGUILayout.HorizontalScope())
                {
                    string ytdlpStatus = _layoutYtdlp ? "found" : "not found";
                    string ffmpegStatus = _layoutFFmpeg ? "found" : "not found";
                    EditorGUILayout.LabelField($"yt-dlp: {ytdlpStatus}   ffmpeg: {ffmpegStatus}", EditorStyles.miniLabel);
                    if (GUILayout.Button("Re-check", EditorStyles.miniButton, GUILayout.Width(70)))
                    {
                        RefreshToolAvailability();
                        Repaint();
                    }
                }
            }
        }

        private void DrawReferences()
        {
            bool videoPlayerOnThisObject = _player.GetComponent<VideoPlayer>() != null;

            using (new EditorGUI.DisabledScope(EditorApplication.isPlaying))
            {
                using (new EditorGUI.DisabledScope(videoPlayerOnThisObject))
                    EditorGUILayout.PropertyField(_videoPlayer, new GUIContent("  VideoPlayer", EditorGUIUtility.IconContent("d_Profiler.Video").image));

                if (_layoutLocalMode)
                    EditorGUILayout.PropertyField(_audioSource, new GUIContent("  AudioSource", EditorGUIUtility.IconContent("d_Profiler.Audio").image));

                EditorGUILayout.PropertyField(_audioLink, new GUIContent("  AudioLink"));
            }

            bool missingForMode = _layoutLocalMode
                ? _audioSource.objectReferenceValue == null
                : _videoPlayer.objectReferenceValue == null;

            if (!missingForMode && _audioLink.objectReferenceValue != null)
                return;

            EditorGUILayout.HelpBox(_layoutLocalMode
                ? "Local File playback needs the AudioSource that AudioLink reads from, plus the AudioLink component to report play state to."
                : "Stream playback needs a VideoPlayer, plus the AudioLink component to report play state to.",
                MessageType.Warning);

            if (!GUILayout.Button("Find AudioLink and its AudioSource"))
                return;

            Undo.RecordObject(_player, "Assign AudioLink references");
            _player.ResolveReferences();
            EditorUtility.SetDirty(_player);
            serializedObject.Update();
        }

        private void DrawVideoTextureSection()
        {
            // The video preview only ever has something to show in Stream mode, but the global
            // texture (and its standby image) stays useful either way.
            using (new EditorGUI.DisabledScope(_videoPlayer.objectReferenceValue == null))
            {
                if (!_layoutLocalMode)
                {
                    // This lives in EditorPrefs, not on the component: it is a per-user viewing
                    // preference rather than project data. Writing the serialized field here would
                    // be undone by the ApplyModifiedProperties at the end of this pass anyway.
                    bool wasShowingPreview = EditorPrefs.GetBool(ShowVideoPreviewKey, false);
                    bool showPreview = EditorGUILayout.Toggle(new GUIContent("  Show Video Preview", EditorGUIUtility.IconContent("d_ViewToolOrbit On").image), wasShowingPreview);

                    if (showPreview != wasShowingPreview)
                    {
                        EditorPrefs.SetBool(ShowVideoPreviewKey, showPreview);
                        Repaint();
                    }

                    VideoPlayer player = (VideoPlayer)_videoPlayer.objectReferenceValue;
                    if (wasShowingPreview && player != null && player.texture != null)
                    {
                        // Draw video preview with the same aspect ratio as the video
                        Texture videoPlayerTexture = player.texture;
                        EditorGUILayout.LabelField($"Resolution: {videoPlayerTexture.width}x{videoPlayerTexture.height}");
                        float aspectRatio = (float)videoPlayerTexture.width / videoPlayerTexture.height;
                        Rect previewRect = GUILayoutUtility.GetAspectRect(aspectRatio);
                        EditorGUI.DrawPreviewTexture(previewRect, videoPlayerTexture, null, ScaleMode.ScaleToFit);
                    }
                }

                EditorGUILayout.PropertyField(_enableGlobalVideoTexture, new GUIContent("Enable Global Video Texture"));
                using (new EditorGUILayout.VerticalScope("box"))
                {
                    if (!_enableGlobalVideoTexture.boolValue)
                        return;

                    EditorGUILayout.LabelField("Global Video Texture Settings");
                    EditorGUILayout.HelpBox("Global Video Texture is NOT part of AudioLink and is only provided as a convenience for testing avatars in editor.", MessageType.Info);

                    using (new EditorGUI.DisabledScope(EditorApplication.isPlaying))
                        EditorGUILayout.PropertyField(_globalTextureName, new GUIContent("Global Texture Property Target"));

                    EditorGUILayout.PropertyField(_textureTransformMode, new GUIContent("Transform Texture (" + _globalTextureName.stringValue + "_ST)"));
                    EditorGUI.indentLevel++;
                    switch ((EditorAudioPlayer.TextureTransformMode)_textureTransformMode.enumValueIndex)
                    {
                        case EditorAudioPlayer.TextureTransformMode.Normalized:
                            EditorGUILayout.PropertyField(_textureTiling, new GUIContent("Tiling"));
                            EditorGUILayout.PropertyField(_textureOffset, new GUIContent("Offset"));
                            break;
                        case EditorAudioPlayer.TextureTransformMode.ByPixels:
                            EditorGUILayout.PropertyField(_texturePixelOrigin, new GUIContent("Pixel Origin (from Top-Left)"));
                            EditorGUILayout.PropertyField(_texturePixelSize, new GUIContent("Pixel Size (0 = Texture Source Size)"));
                            if (EditorApplication.isPlaying)
                                using (new EditorGUI.DisabledScope(true))
                                    EditorGUILayout.LabelField($"Normalized: {_player.lastGlobalST}");
                            break;
                    }

                    EditorGUI.indentLevel--;
                    EditorGUILayout.PropertyField(_showStandbyIfPaused, new GUIContent("Show Standby Texture when Paused"));
                    EditorGUILayout.PropertyField(_forceStandbyTexture, new GUIContent("Force Show Standby Texture"));
                    EditorGUILayout.PropertyField(_standbyTexture, new GUIContent("Standby Texture"), GUILayout.Height(EditorGUIUtility.singleLineHeight));
                }
            }
        }

        private void DrawToolWarnings()
        {
            if (_layoutLocalMode)
                return;

#if UNITY_EDITOR_LINUX
            bool available = _layoutYtdlp && _layoutFFmpeg;
#else
            bool available = _layoutYtdlp;
#endif
            bool ffmpegNotFound = ytdlpURLResolver.useFFmpeg && !_layoutFFmpeg;
            if (available && !ffmpegNotFound)
                return;

#if UNITY_EDITOR_LINUX
            EditorGUILayout.HelpBox("Failed to locate yt-dlp & ffmpeg executables.\n\nTo fix this, install yt-dlp and ffmpeg via your package manager,\nor make sure the portable executables are in your PATH.\n\nOnce this is done, enter play mode to retry.\n\nYou can also switch Source to Local File and play an audio file from disk instead.", MessageType.Warning);
#elif UNITY_EDITOR_WIN
            if (ffmpegNotFound)
                EditorGUILayout.HelpBox("Failed to locate ffmpeg executable.\n\nTo fix this, install ffmpeg and make sure the executable is on your PATH.\n\nOnce this is done, enter play mode to retry.", MessageType.Warning);
            if (!available)
                EditorGUILayout.HelpBox("Failed to locate yt-dlp executable.\n\nTo fix this, either install and launch VRChat once,\nor install yt-dlp and make sure the executable is on your PATH.\n\nOnce this is done, enter play mode to retry.\n\nYou can also switch Source to Local File and play an audio file from disk instead.", MessageType.Warning);
#else
            EditorGUILayout.HelpBox("Failed to locate yt-dlp & ffmpeg executables.\n\nTo fix this, install yt-dlp and ffmpeg via *homebrew*: \"brew install yt-dlp ffmpeg\", or make sure the executables are in your PATH.\n\nOnce this is done, enter play mode to retry.\n\nYou can also switch Source to Local File and play an audio file from disk instead.", MessageType.Warning);
#endif
        }

        #endregion

        #region Helpers

        private void BrowseForFile()
        {
            string startDirectory = EditorPrefs.GetString(LastDirectoryKey, "");

            if (!string.IsNullOrEmpty(_layoutPath))
            {
                try
                {
                    startDirectory = Path.GetDirectoryName(_layoutPath);
                }
                catch (Exception)
                {
                    // Keep the remembered directory if the stored path is malformed.
                }
            }

            EditorAudioPlayer player = _player;

            // OpenFilePanel spins the OS message loop, which re-enters IMGUI. Opening it from inside
            // the GUI pass abandons the pass with layout groups still on the stack, and the next
            // event then fails in EndLayoutGroup. Deferring it lets this pass finish first.
            EditorApplication.delayCall += () =>
            {
                if (player == null)
                    return;

                string picked = EditorUtility.OpenFilePanelWithFilters("Select an audio file", startDirectory, LocalAudioFile.FilePanelFilters());
                if (string.IsNullOrEmpty(picked))
                    return;

                ApplyPath(player, picked);

                if (this != null)
                    Repaint();
            };
        }

        private void HandleDragAndDrop(Rect dropArea)
        {
            Event evt = Event.current;
            if (evt.type != EventType.DragUpdated && evt.type != EventType.DragPerform)
                return;

            if (!dropArea.Contains(evt.mousePosition))
                return;

            string dropped = FirstUsablePath(DragAndDrop.paths);
            DragAndDrop.visualMode = dropped != null ? DragAndDropVisualMode.Copy : DragAndDropVisualMode.Rejected;

            if (evt.type == EventType.DragPerform && dropped != null)
            {
                DragAndDrop.AcceptDrag();
                ApplyPathFromGui(dropped);
            }

            evt.Use();
        }

        private static string FirstUsablePath(string[] paths)
        {
            if (paths == null)
                return null;

            foreach (string path in paths)
            {
                if (string.IsNullOrEmpty(path) || !LocalAudioFile.IsKnownExtension(path))
                    continue;

                // Assets dragged out of the Project window arrive as project relative paths.
                string full = Path.GetFullPath(path);
                if (File.Exists(full))
                    return full;
            }

            return null;
        }

        /// <summary>Sets the file path from inside the GUI pass, keeping the SerializedObject in step.</summary>
        private void ApplyPathFromGui(string path)
        {
            ApplyPath(_player, path);

            // The component was written directly, so refresh our cached copy - otherwise the
            // ApplyModifiedProperties at the end of OnInspectorGUI writes the old path back over it.
            serializedObject.Update();
            Repaint();
        }

        private static void ApplyPath(EditorAudioPlayer player, string path)
        {
            string full = "";
            if (!string.IsNullOrEmpty(path))
            {
                try
                {
                    full = Path.GetFullPath(path);
                }
                catch (Exception e)
                {
                    Debug.LogError($"[AudioLink:LocalFile] '{path}' is not a usable file path: {e.Message}");
                    return;
                }
            }

            Undo.RecordObject(player, "Set AudioLink test audio file");
            player.audioFilePath = full;
            EditorUtility.SetDirty(player);

            if (!string.IsNullOrEmpty(full))
                EditorPrefs.SetString(LastDirectoryKey, Path.GetDirectoryName(full));

            // In play mode the component picks the change up on its next Update, but reloading here
            // makes the swap feel immediate.
            if (EditorApplication.isPlaying)
                player.Reload();
        }

        /// <summary>Parses "ss", "mm:ss" or "hh:mm:ss" into seconds.</summary>
        private static bool TryParseTimestamp(string text, out double seconds)
        {
            seconds = 0.0;
            if (string.IsNullOrEmpty(text))
                return false;

            string[] parts = text.Trim().Split(':');
            if (parts.Length > 3)
                return false;

            double scale = 1.0;
            double total = 0.0;

            for (int i = parts.Length - 1; i >= 0; i--)
            {
                if (!double.TryParse(parts[i], NumberStyles.Float, CultureInfo.InvariantCulture, out double value))
                    return false;

                total += value * scale;
                scale *= 60.0;
            }

            seconds = total;
            return true;
        }

        private void ProbeFile(string path)
        {
            double now = EditorApplication.timeSinceStartup;
            if (path == _probedPath && now - _probedAt < 1.0)
                return;

            _probedPath = path;
            _probedAt = now;
            _probedExists = false;
            _probedSize = 0;

            if (string.IsNullOrEmpty(path))
                return;

            try
            {
                FileInfo info = new FileInfo(path);
                _probedExists = info.Exists;
                _probedSize = _probedExists ? info.Length : 0;
            }
            catch (Exception)
            {
                // An unreadable or malformed path just stays reported as missing.
            }
        }

        private static void RefreshToolAvailability(bool force = true)
        {
            double now = EditorApplication.timeSinceStartup;
            if (!force && now - _toolsLastChecked <= 3.0)
                return;

            _ytdlpAvailable = ytdlpURLResolver.IsytdlpAvailable();
            _ffmpegAvailable = ytdlpURLResolver.IsFFmpegAvailable();
            _toolsLastChecked = now;
        }

        #endregion
    }
}
#endif
