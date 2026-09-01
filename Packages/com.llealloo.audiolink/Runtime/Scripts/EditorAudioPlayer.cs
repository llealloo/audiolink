#if UNITY_EDITOR && !COMPILER_UDONSHARP
using System;
using System.IO;
using System.Linq;
using System.Threading;
using UnityEditor;
using UnityEngine;
using UnityEngine.Networking;
using UnityEngine.Video;

// This component uses code from the following sources:
// UnityYoutubePlayer, courtesy iBicha (SPDX-License-Identifier: Unlicense) https://github.com/iBicha/UnityYoutubePlayer
// USharpVideo, Copyright (c) 2020 Merlin, (SPDX-License-Identifier: MIT) https://github.com/MerlinVR/USharpVideo/

// Editor-only test player for AudioLink. It drives the AudioSource that AudioLink samples from one
// of two sources, picked with the Source buttons at the top of the inspector:
//
//   Stream     - resolved with yt-dlp and played through a VideoPlayer.
//   Local File - decoded from a file on this machine and played through the AudioSource directly.
//
// The local file path exists because the extractors upstream of yt-dlp break regularly; a file you
// already have on disk always works. Nothing in this file ships to a player build or to Udon.

// TODO(float3): add this to the AudioLinkMiniPlayer

namespace AudioLink
{
    [AddComponentMenu("AudioLink/AudioLink Editor Audio Player")]
    public partial class EditorAudioPlayer : MonoBehaviour
    {
        public enum PlaybackSource
        {
            [InspectorName("Stream")] Stream = 0,
            [InspectorName("Local File")] LocalFile = 1
        }

        /// <summary>Progress of a local file load. Stream progress is tracked by the resolving request instead.</summary>
        public enum LoadState
        {
            Empty,
            Transcoding,
            Loading,
            Ready,
            Failed
        }

        public enum TextureTransformMode
        {
            AsIs,
            Normalized,
            ByPixels
        }

        public enum Resolution
        {
            [InspectorName("360p")] _360p = 360,
            [InspectorName("480p")] _480p = 480,
            [InspectorName("720p")] _720p = 720,
            [InspectorName("1080p")] _1080p = 1080,
            [InspectorName("1440p")] _1440p = 1440,
            [InspectorName("2160p")] _2160p = 2160,
        }

        // ---- shared ----

        [Tooltip("Where the audio comes from: a stream resolved with yt-dlp, or a file on this machine.")]
        public PlaybackSource playbackSource = PlaybackSource.Stream;

        [Tooltip("The AudioLink instance whose media state should be driven. By default, it is looked up in the Scene.")]
        public AudioLink audioLink = null;

        [Tooltip("Repeat when the end is reached. Applies to both sources.")]
        public bool loop = true;

        // ---- stream ----

        public string ytdlpURL = "https://www.youtube.com/watch?v=vGXyAKy-X6s";
        public VideoPlayer videoPlayer = null;
        public Resolution resolution = Resolution._720p;

        // ---- local file ----

        [Tooltip("Path to Audio/Video file to use. Use the Browse button, or drop a file onto the inspector.")]
        public string audioFilePath = "";

        [Tooltip("Target AudioLink Audio Source. By default this is taken from the VideoPlayer, then from the linked AudioLink component.")]
        public AudioSource audioSource = null;

        [Tooltip("Start playing as soon as the file has finished decoding.")]
        public bool playOnLoad = true;

        [Tooltip("Stream the file from disk instead of decoding all of it into memory. Uses far less memory on long files, at the cost of slightly less precise seeking.")]
        public bool streamFromDisk = true;

        // ---- global video texture ----

        public bool showVideoPreviewInComponent = false;
        public bool enableGlobalVideoTexture = false;
        public string globalTextureName = "_Udon_VideoTex";
        public TextureTransformMode textureTransformMode = TextureTransformMode.Normalized;
        public Vector2Int texturePixelOrigin = new Vector2Int(0, 0);
        public Vector2Int texturePixelSize = new Vector2Int(0, 0);
        public Vector2 textureTiling = new Vector2(1f, 1f);
        public Vector2 textureOffset = new Vector2(0f, 0f);
        public bool forceStandbyTexture = false;
        public bool showStandbyIfPaused = true;
        public Texture2D standbyTexture;

        private int _globalTextureId;
        private int _globalTextureTransformId;
        private bool _globalTextureActive = false;
        private Vector4 _lastGlobalST = Vector4.zero;

        /// <summary>Last texture transform pushed to the global video texture. Shown as a debug readout in the inspector.</summary>
        public Vector4 lastGlobalST => _lastGlobalST;

        // ---- stream state ----

        private ResolvingRequest _currentRequest = null;

        // ---- local file state ----

        private AudioClip _clip;
        private bool _ownsClip;
        private UnityWebRequest _streamingRequest;
        private TranscodeJob _transcodeJob;

        private LoadState _loadState = LoadState.Empty;
        private string _statusMessage = "";
        private string _loadedPath;
        private int _loadGeneration;
        private bool _triedTranscodeFallback;

        private bool _paused;
        private int _pendingSeekSamples;

        private AudioClip _originalClip;
        private bool _capturedOriginalClip;

        // ---- source switching ----

        private PlaybackSource _activeSource;
        private bool _parkedVideoPlayer;

        #region State

        public bool isStreaming => playbackSource == PlaybackSource.Stream;

        /// <summary>The clip decoded from audioFilePath, or null in stream mode / when nothing is loaded.</summary>
        public AudioClip clip => _clip;

        public LoadState loadState => _loadState;

        /// <summary>Human readable detail for the current local file load, shown in the inspector.</summary>
        public string statusMessage => _statusMessage;

        /// <summary>True while yt-dlp is resolving, or while a local file is being converted or decoded.</summary>
        public bool isBusy => isStreaming
            ? _currentRequest != null && !_currentRequest.isDone
            : _loadState == LoadState.Loading || _loadState == LoadState.Transcoding;

        /// <summary>True once there is something to play and transport controls make sense.</summary>
        public bool isReady => isStreaming
            ? videoPlayer != null && videoPlayer.length > 0
            : _loadState == LoadState.Ready && _clip != null && audioSource != null;

        public bool isPlaying => isStreaming
            ? videoPlayer != null && videoPlayer.isPlaying
            : isReady && audioSource.isPlaying;

        public bool isPaused => isStreaming
            ? videoPlayer != null && videoPlayer.isPaused
            : _paused;

        #endregion

        #region Lifecycle

        private void Reset()
        {
            ResolveReferences();
        }

        private void OnEnable()
        {
            ResolveReferences();

            _globalTextureId = Shader.PropertyToID(globalTextureName);
            _globalTextureTransformId = Shader.PropertyToID(globalTextureName + "_ST");

            _activeSource = playbackSource;

            if (isStreaming)
            {
                RestoreVideoPlayer();
                RequestPlay();
            }
            else if (Application.isPlaying)
            {
                ParkVideoPlayer();
                ReloadLocalFile();
            }
        }

        private void OnDisable()
        {
            CancelPendingWork();
            ReleaseClip();
            RestoreVideoPlayer();

            _loadState = LoadState.Empty;
            _statusMessage = "";
            _loadedPath = null;

            if (audioLink != null)
                audioLink.autoSetMediaState = true;
        }

        /// <summary>
        /// Fills in audioLink, videoPlayer and audioSource from the surrounding scene. The AudioSource
        /// is taken from the VideoPlayer's output first, so the shipped AudioLink prefab needs no wiring.
        /// </summary>
        public void ResolveReferences()
        {
            if (audioLink == null)
                audioLink = GetComponentInParent<AudioLink>();
            if (audioLink == null)
                audioLink = FindFirstObjectByType<AudioLink>();

            if (videoPlayer == null)
                videoPlayer = GetComponent<VideoPlayer>();

            if (audioSource == null)
                audioSource = TargetAudioSourceOf(videoPlayer);
            if (audioSource == null && audioLink != null)
                audioSource = audioLink.audioSource;
            if (audioSource == null)
                audioSource = GetComponentInParent<AudioSource>();
        }

        private static AudioSource TargetAudioSourceOf(VideoPlayer player)
        {
            if (player == null || player.audioOutputMode != VideoAudioOutputMode.AudioSource)
                return null;

            return player.controlledAudioTrackCount > 0 ? player.GetTargetAudioSource(0) : null;
        }

        private void Update()
        {
            if (_activeSource != playbackSource)
                SwitchPlaybackSource();

            if (isStreaming)
                UpdateStream();
            else
                UpdateLocalFile();

            PushMediaState();
        }

        private void LateUpdate() => ExportGlobalVideoTexture();

        private void UpdateStream()
        {
            if (_currentRequest != null && _currentRequest.isDone)
            {
                UpdateUrl(_currentRequest.resolvedURL);
                _currentRequest = null;
            }

            if (videoPlayer != null && videoPlayer.isLooping != loop)
                videoPlayer.isLooping = loop;
        }

        private void UpdateLocalFile()
        {
            PollPendingWork();

            if (isReady && audioSource.loop != loop)
                audioSource.loop = loop;
        }

        #endregion

        #region Source switching

        private void SwitchPlaybackSource()
        {
            _activeSource = playbackSource;

            if (!Application.isPlaying)
                return;

            if (isStreaming)
            {
                // Hand the AudioSource back and let the VideoPlayer drive it again.
                CancelPendingWork();
                ReleaseClip();
                _loadState = LoadState.Empty;
                _statusMessage = "";
                _loadedPath = null;

                RestoreVideoPlayer();
                RequestPlay();
            }
            else
            {
                // A VideoPlayer in AudioSource output mode writes its own clip into our AudioSource,
                // so it has to be parked before we can put ours there.
                _currentRequest = null;
                ParkVideoPlayer();
                ReloadLocalFile();
            }
        }

        private void ParkVideoPlayer()
        {
            if (videoPlayer == null || !Application.isPlaying || _parkedVideoPlayer)
                return;

            videoPlayer.Stop();
            videoPlayer.enabled = false;
            _parkedVideoPlayer = true;
        }

        private void RestoreVideoPlayer()
        {
            if (!_parkedVideoPlayer)
                return;

            _parkedVideoPlayer = false;
            if (videoPlayer != null)
                videoPlayer.enabled = true;
        }

        #endregion

        #region Stream source

        public void RequestPlay()
        {
            ytdlpURLResolver.FetchEditorPrefs();

            ytdlpURLResolver.TryResolve((bool dumpJson) => {
                ytdlpURLResolver.Resolve(ytdlpURL, (ResolvingRequest newRequest) => _currentRequest = newRequest, (int)resolution, dumpJson);
            });
        }

        public void UpdateUrl(string resolved)
        {
            if (videoPlayer == null)
                return;

            videoPlayer.prepareCompleted -= MediaReady;
            videoPlayer.prepareCompleted += MediaReady;
            videoPlayer.url = resolved;
            videoPlayer.Prepare();
        }

        private void MediaReady(VideoPlayer player)
        {
            if (player.canSetTime)
                player.time = 0.0;

            if (player.length > 0)
                player.Play();
        }

        #endregion

        #region Local file source

        /// <summary>Decode audioFilePath again from scratch. Only does anything in play mode.</summary>
        public void ReloadLocalFile()
        {
            if (!Application.isPlaying)
                return;

            _loadedPath = audioFilePath;
            _triedTranscodeFallback = false;

            CancelPendingWork();
            ReleaseClip();
            _statusMessage = "";

            if (string.IsNullOrEmpty(audioFilePath))
            {
                _loadState = LoadState.Empty;
                return;
            }

            if (!File.Exists(audioFilePath))
            {
                Fail($"File not found: {audioFilePath}");
                return;
            }

            if (IsNativelySupportedFile(audioFilePath))
                BeginClipLoad(audioFilePath);
            else
                BeginTranscode();
        }

        private void PollPendingWork()
        {
            if (_transcodeJob != null)
            {
                _transcodeJob.Poll();
                if (!_transcodeJob.isDone)
                    return;

                TranscodeJob job = _transcodeJob;
                _transcodeJob = null;

                if (job.succeeded)
                    BeginClipLoad(job.outputPath);
                else
                    Fail($"ffmpeg could not decode '{Path.GetFileName(_loadedPath)}'.\n{job.error}");

                return;
            }

            if (_loadState == LoadState.Loading)
                return;

            // Picking a different file at runtime (inspector, drag and drop, script) reloads on its own.
            if (!string.Equals(audioFilePath ?? "", _loadedPath ?? "", StringComparison.Ordinal))
                ReloadLocalFile();
        }

        private void BeginTranscode()
        {
            _triedTranscodeFallback = true;

            if (!ytdlpURLResolver.IsFFmpegAvailable())
            {
                Fail($"'{Path.GetExtension(_loadedPath)}' is not a format Unity can decode, and ffmpeg was not found to convert it.\n" +
                     "Install ffmpeg and put it on your PATH, or set a custom location via Tools/AudioLink/Select Custom FFmpeg Location.");
                return;
            }

            _loadState = LoadState.Transcoding;
            _statusMessage = $"Converting {Path.GetFileName(_loadedPath)} with ffmpeg...";
            _transcodeJob = StartTranscode(_loadedPath);
        }

        private void BeginClipLoad(string path)
        {
            AudioType audioType = AudioTypeOf(path);
            if (audioType == AudioType.UNKNOWN)
                audioType = AudioType.WAV;

            string uri;
            try
            {
                uri = new Uri(path).AbsoluteUri;
            }
            catch (Exception e)
            {
                Fail($"Could not build a file URI for '{path}': {e.Message}");
                return;
            }

            UnityWebRequest request = UnityWebRequestMultimedia.GetAudioClip(uri, audioType);
            DownloadHandlerAudioClip handler = (DownloadHandlerAudioClip)request.downloadHandler;
            handler.streamAudio = streamFromDisk;
            handler.compressed = false;

            _loadState = LoadState.Loading;
            _statusMessage = $"Decoding {Path.GetFileName(path)}...";

            int generation = ++_loadGeneration;
            request.SendWebRequest().completed += _ => OnClipLoadCompleted(request, path, generation);
        }

        private void OnClipLoadCompleted(UnityWebRequest request, string path, int generation)
        {
            // The component may have been disabled, switched to Stream, or pointed at another file
            // while this was in flight.
            if (generation != _loadGeneration)
            {
                request.Dispose();
                return;
            }

            AudioClip loaded = null;
            string error = null;

            if (request.result != UnityWebRequest.Result.Success)
            {
                error = request.error;
            }
            else
            {
                try
                {
                    loaded = DownloadHandlerAudioClip.GetContent(request);
                }
                catch (Exception e)
                {
                    error = e.Message;
                }

                if (loaded == null)
                    error = error ?? "Unity returned no audio data.";
                else if (loaded.samples <= 0)
                    error = "The decoded clip is empty.";
            }

            if (error != null)
            {
                request.Dispose();

                // A wrong container/codec guess (Opus in .ogg, ADPCM in .wav, ...) can still be
                // rescued by handing the file to ffmpeg.
                if (!_triedTranscodeFallback && ytdlpURLResolver.IsFFmpegAvailable())
                {
                    Debug.LogWarning($"[AudioLink:LocalFile] Unity could not decode '{path}' ({error}). Retrying through ffmpeg.");
                    BeginTranscode();
                    return;
                }

                Fail($"Unity could not decode '{Path.GetFileName(path)}': {error}");
                return;
            }

            loaded.name = Path.GetFileNameWithoutExtension(_loadedPath ?? path);

            _clip = loaded;
            _ownsClip = true;

            // A streamed clip keeps reading through the download handler, so the request has to
            // outlive it. A fully decoded clip does not.
            if (streamFromDisk)
                _streamingRequest = request;
            else
                request.Dispose();

            _loadState = LoadState.Ready;
            _statusMessage = $"{loaded.channels}ch - {loaded.frequency} Hz - {FormattedTimestamp(loaded.length)}";

            AttachClip();

            if (_loadState == LoadState.Ready && playOnLoad)
                Play();
        }

        private void AttachClip()
        {
            if (audioSource == null)
            {
                Fail("No AudioSource is assigned, so the decoded clip has nowhere to go.");
                return;
            }

            if (!_capturedOriginalClip)
            {
                _originalClip = audioSource.clip;
                _capturedOriginalClip = true;
            }

            audioSource.Stop();
            audioSource.clip = _clip;
            audioSource.loop = loop;

            _paused = false;
            _pendingSeekSamples = 0;
        }

        private void ReleaseClip()
        {
            // Only hand the AudioSource back if it is actually playing our clip; on a first load
            // there is nothing of ours on it yet and stopping it would be rude.
            if (_clip != null && audioSource != null && audioSource.clip == _clip)
            {
                audioSource.Stop();
                audioSource.clip = _capturedOriginalClip ? _originalClip : null;
            }

            _capturedOriginalClip = false;
            _originalClip = null;

            if (_clip != null && _ownsClip)
            {
                if (Application.isPlaying)
                    Destroy(_clip);
                else
                    DestroyImmediate(_clip);
            }

            _clip = null;
            _ownsClip = false;

            if (_streamingRequest != null)
            {
                _streamingRequest.Dispose();
                _streamingRequest = null;
            }

            _paused = false;
            _pendingSeekSamples = 0;
        }

        private void CancelPendingWork()
        {
            _loadGeneration++;

            if (_transcodeJob != null)
            {
                _transcodeJob.Cancel();
                _transcodeJob = null;
            }
        }

        private void Fail(string message)
        {
            _loadState = LoadState.Failed;
            _statusMessage = message;
            Debug.LogError($"[AudioLink:LocalFile] {message}", this);
        }

        private int CurrentSamples
        {
            get
            {
                if (_clip == null)
                    return 0;

                if (audioSource != null && (audioSource.isPlaying || _paused))
                    return Mathf.Clamp(audioSource.timeSamples, 0, Mathf.Max(0, _clip.samples - 1));

                return Mathf.Clamp(_pendingSeekSamples, 0, Mathf.Max(0, _clip.samples - 1));
            }
        }

        #endregion

        #region Transport

        /// <summary>Re-resolve the stream URL, or decode the local file again.</summary>
        public void Reload()
        {
            if (isStreaming)
                RequestPlay();
            else
                ReloadLocalFile();
        }

        public void Play()
        {
            if (isStreaming)
            {
                if (videoPlayer != null)
                    videoPlayer.Play();
                return;
            }

            if (!isReady)
                return;

            audioSource.loop = loop;

            if (_paused)
            {
                audioSource.UnPause();
                _paused = false;
                return;
            }

            if (audioSource.isPlaying)
                return;

            int start = Mathf.Clamp(_pendingSeekSamples, 0, Mathf.Max(0, _clip.samples - 1));
            audioSource.Play();
            if (start > 0)
                audioSource.timeSamples = start;
            _pendingSeekSamples = 0;
        }

        public void Pause()
        {
            if (isStreaming)
            {
                if (videoPlayer != null)
                    videoPlayer.Pause();
                return;
            }

            if (audioSource == null || !audioSource.isPlaying)
                return;

            audioSource.Pause();
            _paused = true;
        }

        public void Stop()
        {
            if (isStreaming)
            {
                if (videoPlayer != null)
                    videoPlayer.Stop();
                return;
            }

            if (audioSource == null)
                return;

            audioSource.Stop();
            _paused = false;
            _pendingSeekSamples = 0;
        }

        public void TogglePlayPause()
        {
            if (isPlaying)
                Pause();
            else
                Play();
        }

        /// <summary>Playback position as a 0..1 fraction, matching AudioLink's media time.</summary>
        public float GetPlaybackTime()
        {
            if (isStreaming)
                return videoPlayer != null && videoPlayer.length > 0 ? (float)(videoPlayer.time / videoPlayer.length) : 0f;

            if (_clip == null || _clip.samples <= 0)
                return 0f;

            return Mathf.Clamp01((float)CurrentSamples / _clip.samples);
        }

        /// <summary>Seek to a 0..1 fraction. Works while playing, paused or stopped.</summary>
        public void SetPlaybackTime(float normalizedTime)
        {
            if (isStreaming)
            {
                if (videoPlayer != null && videoPlayer.length > 0 && videoPlayer.canSetTime)
                    videoPlayer.time = videoPlayer.length * Mathf.Clamp01(normalizedTime);
                return;
            }

            if (_clip == null || audioSource == null || _clip.samples <= 0)
                return;

            int target = Mathf.Clamp(Mathf.RoundToInt(Mathf.Clamp01(normalizedTime) * _clip.samples), 0, _clip.samples - 1);

            if (audioSource.isPlaying || _paused)
            {
                audioSource.timeSamples = target;
                // Some Unity versions resume a paused source when the playhead is moved.
                if (_paused && audioSource.isPlaying)
                    audioSource.Pause();
            }
            else
            {
                // A stopped source rewinds to 0 on Play(), so remember where to jump to instead.
                _pendingSeekSamples = target;
            }
        }

        public void SetPlaybackSeconds(double seconds)
        {
            if (lengthSeconds <= 0)
                return;

            SetPlaybackTime((float)(seconds / lengthSeconds));
        }

        public double playbackSeconds => isStreaming
            ? (videoPlayer != null ? videoPlayer.time : 0.0)
            : (_clip != null && _clip.frequency > 0 ? (double)CurrentSamples / _clip.frequency : 0.0);

        public double lengthSeconds => isStreaming
            ? (videoPlayer != null ? videoPlayer.length : 0.0)
            : (_clip != null ? _clip.length : 0.0);

        public string FormattedTimestamp(double seconds, double maxSeconds = 0)
        {
            double formatValue = maxSeconds > 0 ? maxSeconds : seconds;
            string formatString = formatValue >= 3600.0 ? @"hh\:mm\:ss" : @"mm\:ss";
            return TimeSpan.FromSeconds(Math.Max(0.0, seconds)).ToString(formatString);
        }

        public string PlaybackTimestampFormatted()
        {
            if (lengthSeconds <= 0)
                return "00:00 / 00:00";

            return $"{FormattedTimestamp(playbackSeconds, lengthSeconds)} / {FormattedTimestamp(lengthSeconds)}";
        }

        public bool GetAudioSourceVolume(out float volume)
        {
            volume = 0f;
            if (audioSource == null)
                return false;

            volume = audioSource.volume;
            return true;
        }

        public void SetAudioSourceVolume(float volume)
        {
            if (audioSource != null)
                audioSource.volume = Mathf.Clamp01(volume);
        }

        #endregion

        #region AudioLink media state

        private void PushMediaState()
        {
            if (audioLink == null)
                return;

            if (isStreaming ? videoPlayer == null : audioSource == null)
                return;

            // In local file mode with nothing picked there is nothing to report, so leave AudioLink's
            // own media state handling alone rather than pinning it to "None".
            if (!isStreaming && string.IsNullOrEmpty(audioFilePath))
            {
                audioLink.autoSetMediaState = true;
                return;
            }

            audioLink.autoSetMediaState = false;

            if (isBusy)
                audioLink.SetMediaPlaying(MediaPlaying.Loading);
            else if (!isStreaming && _loadState == LoadState.Failed)
                audioLink.SetMediaPlaying(MediaPlaying.Error);
            else if (isPaused)
                audioLink.SetMediaPlaying(MediaPlaying.Paused);
            else if (isPlaying)
                audioLink.SetMediaPlaying(MediaPlaying.Playing);
            else
                audioLink.SetMediaPlaying(MediaPlaying.Stopped);

            audioLink.SetMediaTime(GetPlaybackTime());
            audioLink.SetMediaLoop(loop ? MediaLoop.LoopOne : MediaLoop.None);
            if (GetAudioSourceVolume(out float volume))
                audioLink.SetMediaVolume(volume);
        }

        #endregion

        #region Global video texture

        private void ExportGlobalVideoTexture()
        {
            Texture texture = null;
            bool showStandby = forceStandbyTexture;
            if (!showStandby && videoPlayer != null)
            {
                // enable pausing or stopping the video to make the standby texture show
                showStandby |= (!videoPlayer.isPaused || showStandbyIfPaused) && !videoPlayer.isPlaying;
                if (!showStandby) texture = videoPlayer.targetTexture != null ? videoPlayer.targetTexture : videoPlayer.texture;
            }

            showStandby |= texture == null;
            if (showStandby && standbyTexture != null)
                texture = standbyTexture;

            Vector4 st = new Vector4(1, 1, 0, 0);
            if (enableGlobalVideoTexture)
            {
                if (texture != null && !showStandby)
                {
                    switch (textureTransformMode)
                    {
                        case TextureTransformMode.Normalized:
                            st.x = textureTiling.x;
                            st.y = textureTiling.y;
                            st.z = textureOffset.x;
                            st.w = textureOffset.y;
                            break;
                        case TextureTransformMode.ByPixels:
                            // calculate offset/tiling from source texture pixel size.
                            float sourceWidth = texture.width;
                            float sourceHeight = texture.height;
                            float targetWidth = texturePixelSize.x;
                            float targetHeight = texturePixelSize.y;
                            float targetX = texturePixelOrigin.x;
                            float targetY = texturePixelOrigin.y;
                            if (targetWidth == 0) targetWidth = sourceWidth;
                            if (targetHeight == 0) targetHeight = sourceHeight;
                            st.x = targetWidth / sourceWidth;
                            st.y = targetHeight / sourceHeight;
                            st.z = targetX / sourceWidth;
                            st.w = (sourceHeight - targetHeight - targetY) / sourceHeight;
                            break;
                    }
                }

                Shader.SetGlobalVector(_globalTextureTransformId, st);
                Shader.SetGlobalTexture(_globalTextureId, texture);
                _lastGlobalST = st;
                _globalTextureActive = true;
            }
            // if globals ever get disabled, unset the custom texture global flag as well
            else if (_globalTextureActive)
            {
                _globalTextureActive = false;
                _lastGlobalST = st;
                Shader.SetGlobalVector(_globalTextureTransformId, st);
                Shader.SetGlobalTexture(_globalTextureId, null);
            }
        }

        #endregion
    }

    public class CachedEditorPrefs
    {
        public string ytdlpPath;
        public string ffmpegPath;
        public bool useFFmpeg;
    }

    public class ResolvingRequest
    {
        public bool isDone;
        public string resolvedURL;
    }

    public class VideoMeta
    {
        public string id;
        public Double duration;

        public VideoMeta(string _id = "", double _duration = 0)
        {
            id = _id; duration = _duration;
        }
    }

    public class VideoFormat
    {
        public string VideoCodec { get; }
        public string AudioCodec { get; }
        public string Container { get; }

        public VideoFormat(string videoCodec = "vp8", string audioCodec = "libvorbis", string container = "webm")
        {
            VideoCodec = videoCodec; AudioCodec = audioCodec; Container = container;
        }
    }

    public static class ytdlpURLResolver
    {
        private static int _mainThreadId;

        [InitializeOnLoadMethod]
        private static void CaptureMainThreadId_Editor()
        {
            _mainThreadId = Thread.CurrentThread.ManagedThreadId;
        }

        private static bool IsMainThread()
        {
            // If somehow not initialized yet, assume current is main (editor init order can be weird)
            if (_mainThreadId == 0) _mainThreadId = Thread.CurrentThread.ManagedThreadId;
            return Thread.CurrentThread.ManagedThreadId == _mainThreadId;
        }
        
        private static string _localytdlpPath = Application.dataPath + "\\AudioLink\\yt-dlp.exe";

        private static CachedEditorPrefs _cachedEditorPrefs = new CachedEditorPrefs();

        private static string _ytdlpPath = "";
        private static bool _ytdlpFound = false;
        private static VideoMeta _ytdlpJson;

        public static bool useFFmpeg = false;
        private static System.Diagnostics.Process _ffmpegProc;
        private static string _ffmpegError;
        private static string _ffmpegPath = "";
        private static bool _ffmpegFound = false;
        private static string _ffmpegCache = "Video Cache";

        private const string userDefinedYTDLPathKey = "YTDL-PATH-CUSTOM";
        private const string userDefinedYTDLPathMenu = "Tools/AudioLink/Select Custom YTDL Location";

        private const string userDefinedFFmpegPathKey = "MPEG-PATH-CUSTOM";
        private const string userDefinedFFmpegPathMenu = "Tools/AudioLink/Select Custom FFmpeg Location";

        public const string useFFmpegTranscodeKey = "USE-FFMPEG-TRANSCODE";

        /// <summary>Whether FFmpeg transcoding is on by default here. Linux has no other working path.</summary>
        public static bool platformDefaultUseFFmpegTranscode =>
#if UNITY_EDITOR_LINUX
            true;
#else
            false;
#endif

        private const string _ffErrorIdentifier = ", from 'http";

#if UNITY_EDITOR_WIN
        private static VideoFormat platformVideoFormat = new VideoFormat(videoCodec: "h264", audioCodec: "aac", container: "mp4");
#elif UNITY_EDITOR_LINUX
        private static VideoFormat platformVideoFormat = new VideoFormat(videoCodec: "vp8", audioCodec: "libvorbis", container: "webm");
#elif UNITY_EDITOR_OSX
        private static VideoFormat platformVideoFormat = new VideoFormat(videoCodec: "vp8", audioCodec: "libvorbis", container: "webm");
#endif

        private static void SelectToolInstall(string title, string pathMenu, string pathKey)
        {
            if (Menu.GetChecked(pathMenu))
            {
                EditorPrefs.SetString(pathKey, string.Empty);
                return;
            }

            string currentPath = EditorPrefs.GetString(pathKey, "");
            string dirPath = currentPath.Substring(0, currentPath.LastIndexOf("/", StringComparison.Ordinal) + 1);
            string path = EditorUtility.OpenFilePanel(title, dirPath, "");
            EditorPrefs.SetString(pathKey, path ?? string.Empty);
        }

        [MenuItem(userDefinedYTDLPathMenu, priority = 1)]
        private static void SelectYtdlInstall()
        {
            SelectToolInstall("Select YTDL Location", userDefinedYTDLPathMenu, userDefinedYTDLPathKey);
        }

        [MenuItem(userDefinedFFmpegPathMenu, priority = 1)]
        private static void SelectFFmpegInstall()
        {
            SelectToolInstall("Select FFmpeg Location", userDefinedFFmpegPathMenu, userDefinedFFmpegPathKey);
        }

        [MenuItem(userDefinedYTDLPathMenu, true, priority = 1)]
        private static bool ValidateSelectYtdlInstall()
        {
            Menu.SetChecked(userDefinedYTDLPathMenu, EditorPrefs.GetString(userDefinedYTDLPathKey, string.Empty) != string.Empty);
            return true;
        }

        [MenuItem(userDefinedFFmpegPathMenu, true, priority = 1)]
        private static bool ValidateSelectFFmpegInstall()
        {
            Menu.SetChecked(userDefinedFFmpegPathMenu, EditorPrefs.GetString(userDefinedFFmpegPathKey, string.Empty) != string.Empty);
            return true;
        }

        public static bool IsytdlpAvailable()
        {
            if (_ytdlpFound)
                return true;

            Locateytdlp();
            return _ytdlpFound;
        }

        public static bool IsFFmpegAvailable()
        {
            if (_ffmpegFound)
                return true;

            LocateFFmpeg();
            return _ffmpegFound;
        }

        /// <summary>
        /// Path to the ffmpeg executable found by LocateFFmpeg. Only meaningful once
        /// IsFFmpegAvailable has returned true.
        /// </summary>
        public static string FFmpegPath => _ffmpegPath;

        public static void FetchEditorPrefs()
        {
            if (!IsMainThread()) return; // Do not throw; just keep the existing cached values.
            
            try
            {
                _cachedEditorPrefs.ffmpegPath = EditorPrefs.GetString(userDefinedFFmpegPathKey, string.Empty);
                _cachedEditorPrefs.ytdlpPath = EditorPrefs.GetString(userDefinedYTDLPathKey, string.Empty);
                _cachedEditorPrefs.useFFmpeg = EditorPrefs.GetBool(useFFmpegTranscodeKey, platformDefaultUseFFmpegTranscode);
            }
            catch (Exception e)
            {
                Debug.LogException(e);
            }
        }

        public static void Locateytdlp()
        {
            _ytdlpFound = false;

            // CRITICAL: Ensure cached prefs are up-to-date. Otherwise, custom path may be ignored after reload.
            FetchEditorPrefs();

            // check for a custom install location
            string customPath = _cachedEditorPrefs.ytdlpPath;
            if (!string.IsNullOrEmpty(customPath))
            {
                if (File.Exists(customPath))
                {
                    Debug.Log($"[AudioLink:YT-dlp] Custom YTDL location found: {customPath}");
                    _ytdlpPath = customPath;
                    _ytdlpFound = true;
                    return;
                }

                Debug.LogWarning($"[AudioLink:YT-dlp] Custom YTDL location detected but does not exist: {customPath}");
                Debug.Log("[AudioLink:YT-dlp] Checking other locations...");
            }


#if UNITY_EDITOR_WIN
            string[] splitPath = Application.persistentDataPath.Split('/', '\\');
            _ytdlpPath = string.Join("\\", splitPath.Take(splitPath.Length - 2)) + "\\VRChat\\VRChat\\Tools\\yt-dlp.exe";
            if (!File.Exists(_ytdlpPath))
                _ytdlpPath = _localytdlpPath;
#else
            _ytdlpPath = "/usr/bin/yt-dlp";
#endif

            if (!File.Exists(_ytdlpPath))
            {
                string[] possibleExecutableNames = { "yt-dlp", "ytdlp", "youtube-dlp", "youtubedlp", "yt-dl", "ytdl", "youtube-dl", "youtubedl" };
                _ytdlpPath = LocateExecutable(possibleExecutableNames);
            }

            if (!File.Exists(_ytdlpPath))
                return;

            _ytdlpFound = true;
            Debug.Log($"[AudioLink:YT-dlp] Found yt-dlp at path '{_ytdlpPath}'");
        }

        public static void LocateFFmpeg()
        {
            _ffmpegFound = false;

            // CRITICAL: Ensure cached prefs are up-to-date. Otherwise, custom path may be ignored after reload.
            FetchEditorPrefs();

            // check for a custom install location
            string customPath = _cachedEditorPrefs.ffmpegPath;
            if (!string.IsNullOrEmpty(customPath))
            {
                if (File.Exists(customPath))
                {
                    Debug.Log($"[AudioLink:FFmpeg] Custom FFmpeg location found: {customPath}");
                    _ffmpegPath = customPath;
                    _ffmpegFound = true;
                    return;
                }

                Debug.LogWarning($"[AudioLink:FFmpeg] Custom FFmpeg location detected but does not exist: {customPath}");
                Debug.Log("[AudioLink:FFmpeg] Checking other locations...");

            }

#if !UNITY_EDITOR_WIN
            _ffmpegPath = "/usr/bin/ffmpeg";
#endif

            if (!File.Exists(_ffmpegPath))
            {
                string[] possibleExecutableNames = { "ffmpeg" };
                _ffmpegPath = LocateExecutable(possibleExecutableNames);
            }

            if (!File.Exists(_ffmpegPath))
                return;

            _ffmpegFound = true;
            Debug.Log($"[AudioLink:FFmpeg] Found FFmpeg at path '{_ffmpegPath}'");
        }

        public static System.Diagnostics.Process ResolvingProcess(string resolverPath, string[] args)
        {
            System.Diagnostics.Process resolver = new System.Diagnostics.Process();

            resolver.EnableRaisingEvents = true;

            resolver.StartInfo.WindowStyle = System.Diagnostics.ProcessWindowStyle.Hidden;
            resolver.StartInfo.CreateNoWindow = true;
            resolver.StartInfo.UseShellExecute = false;
            resolver.StartInfo.RedirectStandardInput = true;
            resolver.StartInfo.RedirectStandardOutput = true;
            resolver.StartInfo.RedirectStandardError = true;

            resolver.StartInfo.FileName = resolverPath;

            foreach (string argument in args)
                resolver.StartInfo.Arguments += argument + " ";

            return resolver;
        }

        public static void Transcode(string url, Action<ResolvingRequest> callback, string outPath, VideoFormat videoFormat)
        {

            ResolvingRequest transcode = new ResolvingRequest();

            string[] ffmpegArgs = new string[13] {
                "-hide_banner",

                "-y",

                "-hwaccel auto",

                "-i", $"\"{url}\"",

                "-c:a", $"{videoFormat.AudioCodec}",

                "-c:v", $"{videoFormat.VideoCodec}",

                videoFormat.VideoCodec == "vp8" ? "-cpu-used 6 -deadline realtime -qmin 0 -qmax 50 -crf 5 -minrate 1M -maxrate 1M -b:v 1M" : "",

                "-f", $"{videoFormat.Container}",

                $"\"{outPath}\""
            };

            _ffmpegError = "";

            _ffmpegProc = ResolvingProcess(_ffmpegPath, ffmpegArgs);

            _ffmpegProc.Exited += (sender, args) =>
            {

                if (File.Exists(outPath))
                {
#if UNITY_EDITOR_WIN
                    transcode.resolvedURL = outPath;
#else
                    transcode.resolvedURL = "file://" + outPath;
#endif
                    transcode.isDone = true;

                    Debug.Log($"[AudioLink:FFmpeg] Transcode completed sucessfully. ({_ytdlpJson.id})");
                }
                else
                Debug.LogError($"[AudioLink:FFmpeg] Failed to transcode Video! ({_ytdlpJson.id})\n{_ffmpegError}");

                _ytdlpJson.id = "";

                callback(transcode);

                _ffmpegProc.Dispose();
                _ffmpegProc = null;
            };

            _ffmpegProc.ErrorDataReceived += (sender, args) =>
            {
                if (args.Data != null)
                {
                    if (args.Data == "Press [q] to stop, [?] for help")
                        Debug.Log($"[AudioLink:FFmpeg] Starting transcode. ({_ytdlpJson.id})");
                    else if (args.Data.StartsWith("frame="))
                    {
                        string progressTimeString = args.Data;
                        int progressTimeIndex = progressTimeString.IndexOf("time=") + 5;
                        int progressTimeLength = progressTimeString.IndexOf("bitrate=") - progressTimeIndex;

                        string progressTime = progressTimeString.Substring(progressTimeIndex, progressTimeLength);
                        TimeSpan ffmpegProgress = TimeSpan.Parse(progressTime);

                        string progressSeconds = ffmpegProgress.ToString();
                        progressSeconds = progressSeconds.Contains('.') ? progressSeconds.Substring(0, progressSeconds.IndexOf('.')) : progressSeconds;
                        progressSeconds += "s";
                        string progressPercent = _ytdlpJson.duration == 0.0 ? "" : $"- {Mathf.FloorToInt((float)(ffmpegProgress.TotalSeconds / _ytdlpJson.duration) * 100f)}%";

                        Debug.Log($"[AudioLink:FFmpeg] Transcode progress ({_ytdlpJson.id}): {progressSeconds} {progressPercent}");
                    }
                    else
                    {
                        if (args.Data.Contains(_ffErrorIdentifier))
                        {
                            _ffmpegError += args.Data.Substring(0, args.Data.IndexOf(_ffErrorIdentifier)) + "\n";
                        }
                        else
                        {
                            _ffmpegError += args.Data + "\n";
                        }
                    }
                }
            };

            try
            {
                _ffmpegProc.Start();
                _ffmpegProc.BeginErrorReadLine();
            }
            catch (Exception e)
            {
                Debug.LogWarning($"[AudioLink:FFmpeg] Unable to transcode URL '{url}' : " + e.Message);
                callback(null);
            }
        }

        public static void TryResolve(Action<bool> callback)
        {
            if (!_ytdlpFound)
            {
                Locateytdlp();
            }

            bool dumpJson = true;

            System.Diagnostics.Process ytdlpJsonDumpCheckProc = ResolvingProcess(_ytdlpPath, new string[] { "--dump-json" });

            ytdlpJsonDumpCheckProc.Exited += (sender, args) => {
                ytdlpJsonDumpCheckProc.Dispose();
                callback(dumpJson);
                };

            ytdlpJsonDumpCheckProc.ErrorDataReceived += (sender, args) =>
            {
                if (args.Data != null)
                {
                    if (args.Data.Contains("error: no such option: --dump-json"))
                        dumpJson = false;
                }
            };

            try
            {
                ytdlpJsonDumpCheckProc.Start();
                ytdlpJsonDumpCheckProc.BeginErrorReadLine();
            }
            catch (Exception e)
            {
                Debug.LogWarning($"[AudioLink:YT-dlp] Unable to check for \"--dump-json\" : " + e.Message);
                callback(false);
            }
        }

        private static string SanitizeURL(string url, string identifier, char seperator)
        {
            if (url.StartsWith(identifier) && url.Contains(seperator))
                url = url.Substring(0, url.IndexOf(seperator));

            return url;
        }

        public static void Resolve(string url, Action<ResolvingRequest> callback, int resolution = 720, bool dumpJson = false)
        {
            if (!_ytdlpFound)
            {
                Locateytdlp();
            }

            if (!_ytdlpFound)
            {
                Debug.LogWarning($"[AudioLink:YT-dlp] Unable to resolve URL '{url}' : yt-dlp not found");
            }

            if (!_ffmpegFound)
            {
                LocateFFmpeg();
            }

            useFFmpeg = _cachedEditorPrefs.useFFmpeg;

            // Catch playlist runaway
            url = SanitizeURL(url, "https://www.youtube.com/", '&');
            url = SanitizeURL(url, "https://youtu.be/", '?');

            string tempPath = Path.GetFullPath(Path.Combine("Temp", _ffmpegCache));

#if !UNITY_EDITOR_LINUX
            if (IsFFmpegAvailable())
#endif
            if (!Directory.Exists(tempPath))
                Directory.CreateDirectory(tempPath);

            string urlHash = Hash128.Compute(url).ToString();
            string fullUrlHash = Path.Combine(tempPath, urlHash + $".{platformVideoFormat.Container}");

            ResolvingRequest request = new ResolvingRequest();

            if (File.Exists(fullUrlHash))
            {

#if UNITY_EDITOR_WIN
                request.resolvedURL = fullUrlHash;
#else
                request.resolvedURL = "file://" + fullUrlHash;
#endif
                request.isDone = true;

                callback(request);

                Debug.Log($"[AudioLink:FFmpeg] Loaded cached video ({url}).");
                return;
            }

            _ytdlpJson = new VideoMeta(_id: url);

            if (_ffmpegProc != null)
            {
                _ffmpegProc.StandardInput.Write('q');
                _ffmpegProc.StandardInput.Flush();
            }

            string[] ytdlpArgs = new string[8] {
                "--no-check-certificate",
                "--no-cache-dir",
                "--rm-cache-dir",

                dumpJson ? "--dump-json" : "",

                "-f", $"\"mp4[height<=?{resolution}][protocol^=http]/best[height<=?{resolution}][protocol^=http]\"",

                "--get-url", $"\"{url}\""
            };

            System.Diagnostics.Process ytdlpProc = ResolvingProcess(_ytdlpPath, ytdlpArgs);

            ytdlpProc.Exited += (sender, args) => { ytdlpProc.Dispose(); };

            ytdlpProc.OutputDataReceived += (sender, args) =>
            {
                if (args.Data != null)
                {
                    if (args.Data.StartsWith("{"))
                    {
                        _ytdlpJson = JsonUtility.FromJson<VideoMeta>(args.Data);
                    }
                    else
                    {
                        string debugStdout = args.Data;
                        if (args.Data.Contains("ip="))
                        {
                            int filterStart = args.Data.IndexOf("ip=");
                            int filterEnd = args.Data.Substring(filterStart).IndexOf("&");

                            debugStdout = args.Data.Replace(args.Data.Substring(filterStart + 3, filterEnd - 3), "[REDACTED]");
                        }

                        Debug.Log("[AudioLink:YT-dlp] ytdlp resolved: " + debugStdout);

                        if (useFFmpeg && IsFFmpegAvailable())
                        {
                            Transcode(args.Data, callback, fullUrlHash, platformVideoFormat);
                        }
                        else
                        {
                            if (useFFmpeg)
                                Debug.LogWarning($"[AudioLink:FFmpeg] Unable to convert URL '{url}' : FFmpeg not found");

                            request.resolvedURL = args.Data;
                            request.isDone = true;

                            callback(request);
                        }
                    }
                }
            };

            ytdlpProc.ErrorDataReceived += (sender, args) =>
            {
                if (args.Data != null)
                {
                    if (args.Data.StartsWith("WARNING: "))
                    {
                        Debug.LogWarning("[AudioLink:YT-dlp] YT-dlp " + args.Data);
                    } else {
                        Debug.LogError("[AudioLink:YT-dlp] YT-dlp " + args.Data);
                    }
                }
            };

            try
            {
                ytdlpProc.Start();
                ytdlpProc.BeginOutputReadLine();
                ytdlpProc.BeginErrorReadLine();
            }
            catch (Exception e)
            {
                Debug.LogWarning($"[AudioLink:YT-dlp] Unable to resolve URL '{url}' : " + e.Message);
                callback(null);
            }
        }

        private static string LocateExecutable(params string[] names)
        {
            string exists = names.FirstOrDefault(File.Exists);
            // check for any names being a valid exact path
            if (!string.IsNullOrEmpty(exists)) return Path.GetFullPath(exists);
            // search in path
            string path = Environment.GetEnvironmentVariable("PATH") ?? "";
#if UNITY_EDITOR_OSX
            // M-series Macs use a different location for Homebrew packages to prevent conflicts with x86_64 binaries.
            // As a result, ARM packages are found in the "/opt/homebrew/bin" location, which is not normally in PATH.
            path += Path.PathSeparator + "/opt/homebrew/bin/";
#endif
            string[] paths = path.Split(Path.PathSeparator);
            // check each possible executable name
            foreach (string n in names)
            {
                string name = n;
#if UNITY_EDITOR_WIN
                // append the windows file extension
                name += ".exe";
#endif
                // return the full name if it has a directory prefix and is part of a valid and existing full path
                if (Path.GetDirectoryName(name) != string.Empty)
                {
                    string full = Path.GetFullPath(name);
                    if (File.Exists(full)) return full;
                }

                // otherwise go through each possible PATH location to check for a valid executable.
                foreach (string dir in paths)
                {
                    string trimmed = dir.Trim();
                    if (string.IsNullOrEmpty(trimmed)) continue;
                    string combined = Path.Combine(trimmed, name);
                    if (File.Exists(combined)) return Path.GetFullPath(combined);
                }
            }

            // no executable was found...
            return string.Empty;
        }
    }
}
#endif
