using System;
using UnityEngine;

namespace AudioLink
{
#if UDONSHARP
    using UdonSharp;
    using VRC.SDK3.Rendering;
    using VRC.SDKBase;
    using static VRC.SDKBase.VRCShader;

    [UdonBehaviourSyncMode(BehaviourSyncMode.Manual)]
    public partial class AudioLink : UdonSharpBehaviour
#else
    using Unity.Collections;
    using UnityEngine.Rendering;
    using static Shader;

#if UNITY_WEBGL
    using System.Runtime.InteropServices;
#endif

    public partial class AudioLink : MonoBehaviour
#endif
    {
        const float AudioLinkVersionNumberMajor = 3.00f;
        const float AudioLinkVersionNumberMinor = 1.02f;

        [Header("Main Settings")]
        [Tooltip("Should be used with AudioLinkInput unless source is 2D. WARNING: if used with a custom 3D audio source (not through AudioLinkInput), audio reactivity will be attenuated by player position away from the Audio Source")]
        public AudioSource audioSource;
        [Tooltip("Optional Right Audio Source for Dual Mono setups (AVPro video players)")]
        public AudioSource optionalRightAudioSource;

        [Header("Basic EQ")]
        [Range(0.0f, 2.0f)]
        [Tooltip("Warning: this setting might be taken over by AudioLinkController")]
        public float gain = 1f;

        [Range(0.0f, 2.0f)]
        [Tooltip("Warning: this setting might be taken over by AudioLinkController")]
        public float bass = 1f;

        [Range(0.0f, 2.0f)]
        [Tooltip("Warning: this setting might be taken over by AudioLinkController")]
        public float treble = 1f;

        [Header("4 Band Crossover")]
        [Range(0.0f, 0.168f)]
        [Tooltip("Bass / low mid crossover")]
        public float x0 = 0.0f;

        [Range(0.242f, 0.387f)]
        [Tooltip("Bass / low mid crossover")]
        public float x1 = 0.25f;

        [Range(0.461f, 0.628f)]
        [Tooltip("Low mid / high mid crossover")]
        public float x2 = 0.5f;

        [Range(0.704f, 0.953f)]
        [Tooltip("High mid / treble crossover")]
        public float x3 = 0.75f;

        [Header("4 Band Threshold Points (Sensitivity)")]
        [Range(0.0f, 1.0f)]
        [Tooltip("Bass threshold level (lower is more sensitive)")]
        public float threshold0 = 0.45f;

        [Range(0.0f, 1.0f)]
        [Tooltip("Low mid threshold level (lower is more sensitive)")]
        public float threshold1 = 0.45f;

        [Range(0.0f, 1.0f)]
        [Tooltip("High mid threshold level (lower is more sensitive)")]
        public float threshold2 = 0.45f;

        [Range(0.0f, 1.0f)]
        [Tooltip("Treble threshold level (lower is more sensitive)")]
        public float threshold3 = 0.45f;

        [Header("Fade Controls")]
        [Range(0.0f, 1.0f)]
        [Tooltip("Amplitude fade amount. This creates a linear fade-off / trails effect. Warning: this setting might be taken over by AudioLinkController")]
        public float fadeLength = 0.25f;

        [Range(0.0f, 1.0f)]
        [Tooltip("Amplitude fade exponential falloff. This attenuates the above (linear) fade-off exponentially, creating more of a pulsed effect. Warning: this setting might be taken over by AudioLinkController")]
        public float fadeExpFalloff = 0.75f;

        [Header("Autogain")]
        public bool autogain = true;
        [Range(0.001f, 1.0f)]
        public float autogainDerate = 0.1f;

#if !UDONSHARP
        [Header("Auto-Director (Avatar / Editor testing only)")]
        [Tooltip("Hands-off reactivity: continuously auto-tunes the four band thresholds and crossovers from live spectrum analysis so any track fills the 0-1 range on every band. Honors the Autogain setting below. Not present in uploaded worlds.")]
        public bool autoDirectorMode = false;

        [Range(0.1f, 20f)]
        [Tooltip("How quickly the thresholds track the music. 20 is instant, real-time follow with no smoothing.")]
        public float autoDirectorSpeed = 5f;

        [Tooltip("Auto-tune the four band thresholds (per-band sensitivity).")]
        public bool autoTuneThresholds = true;

        [Tooltip("Auto-tune the four crossover frequencies. Turning this off resets X0-X3 to their defaults.")]
        public bool autoTuneCrossovers = true;

        [Tooltip("Auto-tune the fade / trail length. Turning this off resets the fade to its defaults.")]
        public bool autoTuneFade = true;

        private const float AutoDirectorMaxSpeed = 20f;
        private const float AutoDirectorReferenceFps = 60f;
        private const float AutoDirectorAgcAttack = 0.08f;
        private const float AutoDirectorAgcRelease = 2.0f;
        private const float AutoDirectorPeakDecay = 0.9f;
        private const float AutoDirectorMinThreshold = 0.2f;
        private const float AutoDirectorSilenceFloor = 0.1f;
        private const int AutoDirectorXBins = 64;
        private const float AutoDirectorHzPerBin = 23.4375f;
        private const float AutoDirectorBottomFreq = 13.75f;
        private const float AutoDirectorExpBins = 24f;
        private const float AutoDirectorBandBinFloor = 29.52f;
        private const float AutoDirectorBandBinSpan = 210.48f;
        private const int AutoDirectorFreqBinLow = 1;
        private const int AutoDirectorFreqBinHigh = 640;
        private const float AutoDirectorCrossoverSmoothing = 0.4f;
        private const float AutoDirectorCrossoverGate = 1e-5f;
        private const float AutoDirectorCrossoverStrength = 0.5f;
        private const float AutoDirectorActivitySmoothing = 0.3f;
        private const float AutoDirectorFluxMaxDecay = 4.0f;
        private const float AutoDirectorActivityFloor = 0.02f;
        private const float AutoDirectorFadeCalm = 0.45f;
        private const float AutoDirectorFadeBusy = 0.02f;
        private const float AutoDirectorFadeExpCalm = 0.5f;
        private const float AutoDirectorFadeExpBusy = 0.9f;
        private const float AutoDirectorFadeSmoothing = 0.3f;
        private const float AutoDirectorDefaultThreshold = 0.45f;
        private const float AutoDirectorDefaultX0 = 0.0f;
        private const float AutoDirectorDefaultX1 = 0.25f;
        private const float AutoDirectorDefaultX2 = 0.5f;
        private const float AutoDirectorDefaultX3 = 0.75f;
        private const float AutoDirectorDefaultFadeLength = 0.25f;
        private const float AutoDirectorDefaultFadeExp = 0.75f;

        private float[] _spectrumData = new float[1024];
        private readonly float[] _autoDirectorBandPeak = new float[4];
        private readonly float[] _autoDirectorBandLast = new float[4];
        private readonly float[] _autoDirectorSpectrumHist = new float[AutoDirectorXBins];
        private float _autoDirectorLevel;
        private float _autoDirectorActivity;
        private float _autoDirectorFluxMax;
        private bool _autoDirectorPrevThresholds = true;
        private bool _autoDirectorPrevCrossovers = true;
        private bool _autoDirectorPrevFade = true;
#endif

        [Header("Theme Colors")]
        [Tooltip("Enable for custom theme colors for Avatars to use.")]
#if UNITY_EDITOR
        [Editor.StringInList("ColorChord Colors", "Custom", "Persistent ColorChord Colors")]
#endif
        public int themeColorMode;
        public Color customThemeColor0 = new Color(1.0f, 1.0f, 0.0f, 1.0f);
        public Color customThemeColor1 = new Color(0.0f, 0.0f, 1.0f, 1.0f);
        public Color customThemeColor2 = new Color(1.0f, 0.0f, 0.0f, 1.0f);
        public Color customThemeColor3 = new Color(0.0f, 1.0f, 0.0f, 1.0f);

        [Header("Custom Global Strings")]
        [UdonSynced] public string customString1;
        [UdonSynced] public string customString2;

        [HideInInspector] public Material audioMaterial;
        [HideInInspector] public CustomRenderTexture audioRenderTexture;

        [Header("Misc")]
        [Tooltip("Automatically determines media states, such as whether audio is currently playing or not, and makes it available to AudioLink compatible shaders. Disable this if you intend to control media states via script, for example to support custom video players.")]
        public bool autoSetMediaState = true;

        [Header("Experimental (Limits performance)")]
        [Tooltip("Enable Udon audioData array. Required by AudioReactiveLight and AudioReactiveObject. Uses ReadPixels which carries a performance hit. For experimental use when performance is less of a concern")]
        [HideInInspector] public bool audioDataToggle = false;

        [NonSerialized] public Color[] audioData = new Color[AudioLinkWidth * AudioLinkHeight];
        [HideInInspector] public Texture2D audioData2D; // Texture2D reference for hacked Blit, may eventually be depreciated

        private bool _audioLinkEnabled = true;

        public bool AudioLinkEnabled
        {
            get => _audioLinkEnabled;
            set => SetAudioLinkState(value);
        }

        private float[] _audioFramesL = new float[1023 * 4];
        private float[] _audioFramesR = new float[1023 * 4];
        private float[] _samples = new float[1023];

        private string _masterName;
        // Mechanism to provide sync'd instance time to all avatars.
        [UdonSynced] private double _masterInstanceJoinTime;
        private double _elapsedTime = 0;
        private double _elapsedTimeMSW = 0;
        private int _networkTimeMS;
        private double _networkTimeMSAccumulatedError;
#if UDONSHARP
        private bool _hasInitializedTime = false;
        private VRCPlayerApi _localPlayer;
        private double GetElapsedSecondsSince2019() { return (Networking.GetNetworkDateTime() - new DateTime(2020, 1, 1)).TotalSeconds; }
        //private double GetElapsedSecondsSinceMidnightUTC() { return (Networking.GetNetworkDateTime() - DateTime.UtcNow.Date ).TotalSeconds; }
#else
        private double GetElapsedSecondsSince2019() { return (DateTime.UtcNow - new DateTime(2020, 1, 1)).TotalSeconds; }
#endif

        private double _fpsTime = 0;
        private int _fpsCount = 0;
        private int _lastUpdatedFrame = -1;

        // Fix for AVPro mono game output bug (if running the game with a mono output source like a headset)
        private int _rightChannelTestDelay = 300;
        private int _rightChannelTestCounter;
        private bool _ignoreRightChannel = false;
        private CustomRenderTextureUpdateMode initialUpdateMode = CustomRenderTextureUpdateMode.Realtime;

#if UDONSHARP || CVR_CCK_EXISTS
        [HideInInspector, SerializeField] private Transform audioTarget = null;
        [HideInInspector, SerializeField] private Component audioListenerTarget = null;
        [HideInInspector, SerializeField] private bool autoDetectAudioTarget = false;
#else
        public Transform audioTarget = null;
        public AudioListener audioListenerTarget = null;
        public bool autoDetectAudioTarget = true;
#endif

        #region PropertyIDs

        // ReSharper disable InconsistentNaming

        private int _AudioTexture;

        // AudioLink 4 Band
        private int _FadeLength;
        private int _FadeExpFalloff;
        private int _Gain;
        private int _Bass;
        private int _Treble;
        private int _X0;
        private int _X1;
        private int _X2;
        private int _X3;
        private int _Threshold0;
        private int _Threshold1;
        private int _Threshold2;
        private int _Threshold3;

        // Autogain
        private int _Autogain;
        private int _AutogainDerate;

        private int _SourceVolume;
        private int _SourceDistance;
        private int _SourceSpatialBlend;
        private int _SourcePosition;

        // Theme Colors
        private int _ThemeColorMode;
        private int _CustomThemeColor0;
        private int _CustomThemeColor1;
        private int _CustomThemeColor2;
        private int _CustomThemeColor3;

        // Global strings
        private int _StringLocalPlayer;
        private int _StringMasterPlayer;
        private int _StringCustom1;
        private int _StringCustom2;

        // Set by Udon
        private int _AdvancedTimeProps0;
        private int _AdvancedTimeProps1;
        private int _PlayerCountAndData;
        private int _VersionNumberAndFPSProperty;

        //Raw audio data.
        private int _Samples0L;
        private int _Samples1L;
        private int _Samples2L;
        private int _Samples3L;

        private int _Samples0R;
        private int _Samples1R;
        private int _Samples2R;
        private int _Samples3R;
        // ReSharper restore InconsistentNaming

#if UNITY_WEBGL

        public static WebALPeer audioLinkWebPeer { get; private set; }

        [DllImport("__Internal")]
        private static extern int SetupAnalyzerSpace();
        [DllImport("__Internal")]
        private static extern int LinkAnalyzer(int ID, float duration, int bufferSize);
        [DllImport("__Internal")]
        private static extern int UnlinkAnalyzer(int ID);
        [DllImport("__Internal")]
        private static extern int FetchAnalyzerLeft(int ID, float[] timeDomainDataLeft, int size);
        [DllImport("__Internal")]
        private static extern int FetchAnalyzerRight(int ID, float[] timeDomainDataRight, int size);

        private int WebALID = 0;

#endif

        private bool _IsInitialized = false;
        private void InitIDs()
        {
            if (_IsInitialized)
                return;

            _AudioTexture = PropertyToID("_AudioTexture");

            _FadeLength = PropertyToID("_FadeLength");
            _FadeExpFalloff = PropertyToID("_FadeExpFalloff");
            _Gain = PropertyToID("_Gain");
            _Bass = PropertyToID("_Bass");
            _Treble = PropertyToID("_Treble");
            _X0 = PropertyToID("_X0");
            _X1 = PropertyToID("_X1");
            _X2 = PropertyToID("_X2");
            _X3 = PropertyToID("_X3");
            _Threshold0 = PropertyToID("_Threshold0");
            _Threshold1 = PropertyToID("_Threshold1");
            _Threshold2 = PropertyToID("_Threshold2");
            _Threshold3 = PropertyToID("_Threshold3");

            _Autogain = PropertyToID("_Autogain");
            _AutogainDerate = PropertyToID("_AutogainDerate");

            _SourceVolume = PropertyToID("_SourceVolume");
            _SourceDistance = PropertyToID("_SourceDistance");
            _SourceSpatialBlend = PropertyToID("_SourceSpatialBlend");
            _SourcePosition = PropertyToID("_SourcePosition");

            _ThemeColorMode = PropertyToID("_ThemeColorMode");
            _CustomThemeColor0 = PropertyToID("_CustomThemeColor0");
            _CustomThemeColor1 = PropertyToID("_CustomThemeColor1");
            _CustomThemeColor2 = PropertyToID("_CustomThemeColor2");
            _CustomThemeColor3 = PropertyToID("_CustomThemeColor3");

            _StringLocalPlayer = PropertyToID("_StringLocalPlayer");
            _StringMasterPlayer = PropertyToID("_StringMasterPlayer");
            _StringCustom1 = PropertyToID("_StringCustom1");
            _StringCustom2 = PropertyToID("_StringCustom2");

            _AdvancedTimeProps0 = PropertyToID("_AdvancedTimeProps0");
            _AdvancedTimeProps1 = PropertyToID("_AdvancedTimeProps1");
            _VersionNumberAndFPSProperty = PropertyToID("_VersionNumberAndFPSProperty");
            _PlayerCountAndData = PropertyToID("_PlayerCountAndData");

            _Samples0L = PropertyToID("_Samples0L");
            _Samples1L = PropertyToID("_Samples1L");
            _Samples2L = PropertyToID("_Samples2L");
            _Samples3L = PropertyToID("_Samples3L");

            _Samples0R = PropertyToID("_Samples0R");
            _Samples1R = PropertyToID("_Samples1R");
            _Samples2R = PropertyToID("_Samples2R");
            _Samples3R = PropertyToID("_Samples3R");

            _IsInitialized = true;
        }
        #endregion

        // TODO(3): try to port this to standalone
        void Start()
        {
#if UDONSHARP
            {
                // Handle sync'd time stuff.
                // OLD NOTES
                //Originally used GetServerTimeInMilliseconds
                //Networking.GetServerTimeInMilliseconds will alias to every 49.7 days (2^32ms). GetServerTimeInSeconds also aliases.
                //We still alias, but TCL suggested using Networking.GetNetworkDateTime.
                //DateTime currentDate = Networking.GetNetworkDateTime();
                //UInt64 currentTimeTicks = (UInt64)(currentDate.Ticks/TimeSpan.TicksPerMillisecond);
                // NEW NOTES
                //We now just compute delta times per frame.

                double startTime = GetElapsedSecondsSince2019();
                _networkTimeMS = Networking.GetServerTimeInMilliseconds();
                if (Networking.IsMaster)
                {
                    _masterInstanceJoinTime = startTime;
                    RequestSerialization();
                }

                //_networkTimeOfDayUTC = GetElapsedSecondsSinceMidnightUTC();
                //Debug.Log($"[AudioLink] _networkTimeOfDayUTC = {_networkTimeOfDayUTC}" );
                //Debug.Log($"[AudioLink] _networkTimeMS = {_networkTimeMS}");
                //Debug.Log($"[AudioLink] Time Sync Debug: IsMaster: {Networking.IsMaster} startTime: {startTime}");

                _rightChannelTestCounter = _rightChannelTestDelay;

                // Set localplayer name on start
                _localPlayer = Networking.LocalPlayer;
                if (VRC.SDKBase.Utilities.IsValid(_localPlayer))
                {
                    UpdateGlobalString(_StringLocalPlayer, _localPlayer.displayName);
                }

                // Set master name once on start
                FindAndUpdateMasterName();
            }
#elif UNITY_WEBGL && !UNITY_EDITOR

            SetupAnalyzerSpace();
            audioLinkWebPeer = new WebALPeer();

            WebALID = UnityEngine.Random.Range(0, 99999);

            LinkAnalyzer(WebALID, audioSource.clip.length, 4096);

            Application.focusChanged += (focus) =>
            {
                if (_audioLinkEnabled)
                {
                    if (focus)
                    {
                        LinkAnalyzer(WebALID, audioSource.clip.length, 4096);
                    }
                    else
                        UnlinkAnalyzer(WebALID);
                }
            };

#endif

            UpdateSettings();
            UpdateThemeColors();
            UpdateCustomStrings();
            if (audioSource == null)
            {
                Debug.LogWarning("[AudioLink] No audioSource provided. AudioLink will not do anything until an audio source has been assigned.");
            }

            gameObject.SetActive(true); // client disables extra cameras, so set it true
            transform.position = new Vector3(0f, 10000000f, 0f); // keep this in a far away place
            initialUpdateMode = audioRenderTexture.updateMode;

            // Disable camera on start if user didn't ask for it
            if (!audioDataToggle)
            {
                DisableReadback();
            }

#if !UDONSHARP && !CVR_CCK_EXISTS
            if (autoDetectAudioTarget) Invoke(nameof(AutoCacheAudioTarget), 1);
#endif
        }

        void OnDestroy()
        {
            // makes sure that playmode doesn't permanently modify the update mode
            audioRenderTexture.updateMode = initialUpdateMode;
        }

        // TODO(3): try to port this to standalone
        // Only happens once per second.
        private void FPSUpdate()
        {
#if UDONSHARP
            if (!_hasInitializedTime)
            {
                if (_masterInstanceJoinTime > 0.00001)
                {
                    //We can now do our time setup.
                    double Now = GetElapsedSecondsSince2019();
                    _elapsedTime = Now - _masterInstanceJoinTime;
                    //Debug.Log($"[AudioLink] Time Sync Debug: Received instance time of {_masterInstanceJoinTime} and current time of {Now} delta of {_elapsedTime}");
                    _hasInitializedTime = true;
                    _fpsTime = _elapsedTime;
                }
                else if (_elapsedTime > 10 && Networking.IsMaster)
                {
                    //Have we gone more than 10 seconds and we're master?
                    //Debug.Log("[AudioLink] Time Sync Debug: You were master.  But no _masterInstanceJoinTime was provided for 10 seconds.  Resetting instance time.");
                    _masterInstanceJoinTime = GetElapsedSecondsSince2019();
                    RequestSerialization();
                    _hasInitializedTime = true;
                    _elapsedTime = 0;
                    _fpsTime = _elapsedTime;
                }
            }
#endif
            // The red channel should be 3.02f forever - this is the last version before the versioning change.
            audioMaterial.SetVector(_VersionNumberAndFPSProperty, new Vector4(3.02f, AudioLinkVersionNumberMajor, _fpsCount, AudioLinkVersionNumberMinor));
#if UDONSHARP
            audioMaterial.SetVector(_PlayerCountAndData, new Vector4(
                VRCPlayerApi.GetPlayerCount(),
                Networking.IsMaster ? 1.0f : 0.0f,
#if UNITY_EDITOR
                    0.0f,
#else
                    _localPlayer.isInstanceOwner ? 1.0f : 0.0f,
#endif
                0));

#else
            audioMaterial.SetVector(_PlayerCountAndData, new Vector4(
            0,
            0,
            0,
            0));
#endif
            _fpsCount = 0;
            _fpsTime++;

            // Other things to handle every second.

            // This handles wrapping of the ElapsedTime so we don't lose precision
            // onthe floating point.
            const double elapsedTimeMSWBoundary = 1024;
            if (_elapsedTime >= elapsedTimeMSWBoundary)
            {
                //For particularly long running instances, i.e. several days, the first
                //few frames will be spent federating _elapsedTime into _elapsedTimeMSW.
                //This is fine.  It just means over time, the
                _fpsTime = 0;
                _elapsedTime -= elapsedTimeMSWBoundary;
                _elapsedTimeMSW++;
            }

            // Finely adjust our network time estimate if needed.
#if UDONSHARP
            int networkTimeMSNow = Networking.GetServerTimeInMilliseconds();
#else
            int networkTimeMSNow = (int)(Time.time * 1000.0f);
#endif
            int networkTimeDelta = networkTimeMSNow - _networkTimeMS;
            if (networkTimeDelta > 3000)
            {
                //Major upset, reset.
                _networkTimeMS = networkTimeMSNow;
            }
            else if (networkTimeDelta < -3000)
            {
                //Major upset, reset.
                _networkTimeMS = networkTimeMSNow;
            }
            else
            {
                //Slowly correct the timebase.
                _networkTimeMS += networkTimeDelta / 20;
            }
            //Debug.Log( $"[AudioLink] Refinement: ${networkTimeDelta}" );
        }

        private void Update()
        {
            if (!_audioLinkEnabled)
            {
                return;
            }

            if (audioDataToggle)
            {
#if UDONSHARP
                VRCAsyncGPUReadback.Request(audioRenderTexture, 0, TextureFormat.RGBAFloat, (VRC.Udon.Common.Interfaces.IUdonEventReceiver)(Component)this);
#else
                AsyncGPUReadback.Request(audioRenderTexture, 0, TextureFormat.RGBAFloat, OnAsyncGpuReadbackComplete);
#endif
            }

            // Tested: There does not appear to be any drift updating it this way.
            _elapsedTime += Time.deltaTime;

            // Advance the current network time by a little.
            // this algorithm also takes into account sub-millisecond jitter.
            {
                double deltaTimeMS = Time.deltaTime * 1000.0;
                int advanceTimeMS = (int)(deltaTimeMS);
                _networkTimeMSAccumulatedError += deltaTimeMS - advanceTimeMS;
                if (_networkTimeMSAccumulatedError > 1)
                {
                    _networkTimeMSAccumulatedError--;
                    advanceTimeMS++;
                }
                _networkTimeMS += advanceTimeMS;
            }

            _fpsCount++;

            if (_elapsedTime >= _fpsTime)
            {
                FPSUpdate();
            }

            // use _AdvancedTimeProps0.w for Debugging
            audioMaterial.SetVector(_AdvancedTimeProps0, new Vector4(
                (float)_elapsedTime,
                (float)_elapsedTimeMSW,
                (float)DateTime.Now.TimeOfDay.TotalSeconds));

            // Jan 1, 1970 = 621355968000000000.0 ticks.
            double utcSecondsUnix = DateTime.UtcNow.Ticks / 10000000.0 - 62135596800.0;
            audioMaterial.SetVector(_AdvancedTimeProps1, new Vector4(
                (float)((_networkTimeMS) & 65535),
                (float)((_networkTimeMS) >> 16),
                (float)(Math.Floor(utcSecondsUnix / 86400)),
                (float)(utcSecondsUnix % 86400)
            ));

            // General Profiling Notes:
            //    Profiling done on 2021-05-26 on an Intel Intel Core i7-8750H CPU @ 2.20GHz
            //    Running loop 255 times (So divide all times by 255)
            //    Base load of system w/o for loop: ~420us in merlin profile land.
            //    With loop, with just summer: 1.2ms / 255
            //    Calling material.SetVeactor( ... new Vector4 ) in the loop:  2.7ms / 255
            //    Setting a float in the loop (to see if there's a difference): 1.9ms / 255
            //                             but setting 4 floats individually... is 3.0ms / 255
            //    The whole shebang with Networking.GetServerTimeInMilliseconds(); 2.3ms / 255
            //    Material.SetFloat with Networking.GetServerTimeInMilliseconds(); 2.3ms / 255
            //    Material.SetFloat with Networking.GetServerTimeInMilliseconds(), twice; 2.9ms / 255
            //    Casting and encoding as UInt32 as 2 floats, to prevent aliasing, twice: 5.1ms / 255
            //    Casting and encoding as UInt32 as 2 floats, to prevent aliasing, once: 3.2ms / 255

            if (audioSource != null)
            {
                SendAudioOutputData();

#if !UDONSHARP
                if (autoDirectorMode && audioSource.isPlaying)
                {
                    RunAutoDirector();
                }
#endif

                // Used to correct for the volume of the audio source component

                float sourceVolume = audioSource.volume;
                Vector3 sourcePosition = audioSource.transform.position;
                float sourceMax = audioSource.maxDistance;

                AnimationCurve sourceBlendCurve = audioSource.GetCustomCurve(AudioSourceCurveType.SpatialBlend);
                AnimationCurve sourceFalloffCurve = audioSource.GetCustomCurve(AudioSourceCurveType.CustomRolloff);
                var playerEars = GetHearingLocation();
                float listeningDistance = Vector3.Distance(playerEars, sourcePosition) / sourceMax;
                float sourceFalloff = sourceFalloffCurve.Evaluate(listeningDistance);
                float sourceBlend = sourceBlendCurve.Evaluate(listeningDistance);
                sourceVolume = Mathf.Lerp(sourceVolume, sourceVolume * sourceFalloff, sourceBlend);

                audioMaterial.SetFloat(_SourceVolume, sourceVolume);
                audioMaterial.SetFloat(_SourceSpatialBlend, sourceBlend);
                audioMaterial.SetVector(_SourcePosition, sourcePosition);

                if (autoSetMediaState)
                {
                    SetMediaVolume(audioSource.volume);

                    float time = 0f;
                    if (audioSource.clip != null)
                    {
                        time = audioSource.time / audioSource.clip.length;
                    }
                    SetMediaTime(time);

                    if (audioSource.isPlaying)
                    {
                        SetMediaPlaying(MediaPlaying.Playing);
                    }
                    else
                    {
                        SetMediaPlaying(MediaPlaying.Stopped);
                    }

                    if (audioSource.loop)
                    {
                        SetMediaLoop(MediaLoop.Loop);
                    }
                    else
                    {
                        SetMediaLoop(MediaLoop.None);
                    }
                }


#if UDONSHARP
                if (VRC.SDKBase.Utilities.IsValid(_localPlayer))
                {
                    float distanceToSource = Vector3.Distance(_localPlayer.GetTrackingData(VRCPlayerApi.TrackingDataType.Head).position, audioSource.transform.position);
                    audioMaterial.SetFloat(_SourceDistance, distanceToSource);
                }
#endif
            }


            // As an optimization: when in-game, require others to call these after
            // setting values on this object.
            // Since we expect changes to values on this object in editor through the GUI,
            // we do not have explicit events to when things change.
#if UNITY_EDITOR
            UpdateSettings();
            UpdateThemeColors();
            UpdateCustomStrings();

            // Handle updating the CRT when in-editor
            // mitigation for stacked CRT updates per frame when multiple views are selected.
            if (_audioLinkEnabled)
                if (audioRenderTexture.updateMode == CustomRenderTextureUpdateMode.OnDemand && _lastUpdatedFrame != Time.frameCount)
                {
                    _lastUpdatedFrame = Time.frameCount;
                    audioRenderTexture.Update();
                }
#endif
        }

        private Vector3 GetHearingLocation()
        {
#if UDONSHARP
            return _localPlayer.GetTrackingData(VRCPlayerApi.TrackingDataType.Head).position;
#elif CVR_CCK_EXISTS
            // TODO: Update with the actual logic for where the player's head is.
            return audioSource.transform.position;
#else
            // if audioTarget is unavailable, use the audioSource position to make the curves use 0 for listening distance
            return audioTarget != null ? audioTarget.position : audioSource.transform.position;
#endif
        }

#if !UDONSHARP && !CVR_CCK_EXISTS
        private void AutoCacheAudioTarget()
        {
            if (!autoDetectAudioTarget || !_audioLinkEnabled) return;
            Invoke(nameof(AutoCacheAudioTarget), audioTarget != null ? 10 : 1); // check faster until one is found
            if (!enabled) return;
            if (audioListenerTarget == null || !audioListenerTarget.isActiveAndEnabled)
                CacheAudioTarget();
        }

        private void CacheAudioTarget()
        {
#if UNITY_2022_3_OR_NEWER
            var listeners = FindObjectsByType<AudioListener>(FindObjectsInactive.Exclude, FindObjectsSortMode.None);
#else
            var listeners = FindObjectsOfType<AudioListener>(true);
#endif
            audioTarget = null;
            foreach (var l in listeners)
            {
                if (!l.enabled) continue;
                audioListenerTarget = l;
                audioTarget = l.transform;
#if UNITY_EDITOR
                // ensure texture is actually assigned. Mitigates certain edge-cases with playmode.
                // Why? No clue, but it keeps AudioLink from appearing broken when it's just the global variable that is unassigned for some reason.
                if (GetGlobalTexture(_AudioTexture) == null)
                    SetAudioLinkGlobalTexture();
#endif
                break;
            }

        }
#endif

#if UDONSHARP
        public override void OnAsyncGpuReadbackComplete(VRCAsyncGPUReadbackRequest request)
        {
            if (request.hasError || !request.done) return;

            request.TryGetData(audioData);
        }
#else
        public void OnAsyncGpuReadbackComplete(AsyncGPUReadbackRequest request)
        {
            if (request.hasError || !request.done) return;

            NativeArray<Color> data = request.GetData<Color>();
            for (int i = 0; i < data.Length; i++)
            {
                audioData[i] = data[i];
            }
        }
#endif

        private void OnEnable()
        {
            EnableAudioLink();
        }

        private void OnDisable()
        {
            DisableAudioLink();
        }

        public void UpdateSettings()
        {
            InitIDs();
            audioMaterial.SetFloat(_Gain, gain);
            audioMaterial.SetFloat(_FadeLength, fadeLength);
            audioMaterial.SetFloat(_FadeExpFalloff, fadeExpFalloff);
            audioMaterial.SetFloat(_Bass, bass);
            audioMaterial.SetFloat(_Treble, treble);
            audioMaterial.SetFloat(_X0, x0);
            audioMaterial.SetFloat(_X1, x1);
            audioMaterial.SetFloat(_X2, x2);
            audioMaterial.SetFloat(_X3, x3);
            audioMaterial.SetFloat(_Threshold0, threshold0);
            audioMaterial.SetFloat(_Threshold1, threshold1);
            audioMaterial.SetFloat(_Threshold2, threshold2);
            audioMaterial.SetFloat(_Threshold3, threshold3);
            audioMaterial.SetFloat(_Autogain, autogain ? 1 : 0);
            audioMaterial.SetFloat(_AutogainDerate, autogainDerate);
        }

        // Note: These might be changed frequently so as an optimization, they're in a different function
        // rather than bundled in with the other things in UpdateSettings().
        public void UpdateThemeColors()
        {
            InitIDs();
            audioMaterial.SetInt(_ThemeColorMode, themeColorMode);
            audioMaterial.SetColor(_CustomThemeColor0, customThemeColor0);
            audioMaterial.SetColor(_CustomThemeColor1, customThemeColor1);
            audioMaterial.SetColor(_CustomThemeColor2, customThemeColor2);
            audioMaterial.SetColor(_CustomThemeColor3, customThemeColor3);
        }

        private static float IntToFloatBits24Bit(uint value)
        {
            uint frac = value & 0x007FFFFF;
            return (frac / 8388608F) * 1.1754944e-38F;
        }

#if UDONSHARP
        public override void OnPlayerJoined(VRCPlayerApi player)
        {
            if (VRC.SDKBase.Utilities.IsValid(player) && player.isMaster)
            {
                _masterName = player.displayName;
                UpdateGlobalString(_StringMasterPlayer, player.displayName);
            }
        }

        public override void OnPlayerLeft(VRCPlayerApi player)
        {
            if (VRC.SDKBase.Utilities.IsValid(player) && (player.isMaster || player.displayName == _masterName))
            {
                FindAndUpdateMasterName();
            }
        }

        private void FindAndUpdateMasterName()
        {
            VRCPlayerApi[] players = new VRCPlayerApi[VRCPlayerApi.GetPlayerCount()];
            VRCPlayerApi.GetPlayers(players);
            foreach (VRCPlayerApi player in players)
            {
                if (player != null)
                {
                    if (VRC.SDKBase.Utilities.IsValid(player) && player.isMaster)
                    {
                        _masterName = player.displayName;
                        UpdateGlobalString(_StringMasterPlayer, player.displayName);
                        break;
                    }
                }
            }
        }
#endif

        public void UpdateCustomStrings()
        {
#if UDONSHARP
            if (!Networking.IsOwner(gameObject))
                Networking.SetOwner(_localPlayer, gameObject);
#endif

            UpdateGlobalString(_StringCustom1, customString1);
            UpdateGlobalString(_StringCustom2, customString2);

#if UDONSHARP
            RequestSerialization();
#endif
        }

#if UDONSHARP
        public override void OnDeserialization()
        {
            if (!Networking.IsOwner(gameObject))
            {
                UpdateGlobalString(_StringCustom1, customString1);
                UpdateGlobalString(_StringCustom2, customString2);
            }
        }
#endif

        private const int GlobalStringMaxLength = 32;
        private readonly int[] globalStringCodePoints = new int[GlobalStringMaxLength];
        private const int GlobalStringPackedVectorsLength = GlobalStringMaxLength / 4;
        private readonly Vector4[] globalStringPackedVectors = new Vector4[GlobalStringPackedVectorsLength];

        private void UpdateGlobalString(int nameID, string input)
        {
            InitIDs();
            int inputLength = input.Length;
            // Truncate the input if it exceeds the max length
            if (inputLength > GlobalStringMaxLength)
            {
                input = input.Substring(0, GlobalStringMaxLength);
            }
            // Get unicode codepoints, clearing previous values to prevent leftover data
            Array.Clear(globalStringCodePoints, 0, GlobalStringMaxLength);
            int codePointsLength = 0;

            for (int i = 0; i < inputLength; i++)
            {
                globalStringCodePoints[codePointsLength++] = char.ConvertToUtf32(input, i);
                if (char.IsHighSurrogate(input[i]))
                {
                    i += 1;
                }
            }

            // Pack them into vectors, clearing previous values in vecs array
            Array.Clear(globalStringPackedVectors, 0, GlobalStringPackedVectorsLength);
            int j = 0;
            for (int i = 0; i < GlobalStringPackedVectorsLength; i++)
            {
                if (j < codePointsLength) globalStringPackedVectors[i].x = IntToFloatBits24Bit((uint)globalStringCodePoints[j++]); else break;
                if (j < codePointsLength) globalStringPackedVectors[i].y = IntToFloatBits24Bit((uint)globalStringCodePoints[j++]); else break;
                if (j < codePointsLength) globalStringPackedVectors[i].z = IntToFloatBits24Bit((uint)globalStringCodePoints[j++]); else break;
                if (j < codePointsLength) globalStringPackedVectors[i].w = IntToFloatBits24Bit((uint)globalStringCodePoints[j++]); else break;
            }

            // Expose the vectors to shader without causing additional allocations
            audioMaterial.SetVectorArray(nameID, globalStringPackedVectors);
        }
        public void ToggleAudioLink()
        {
            SetAudioLinkState(!_audioLinkEnabled);
        }

        public void SetAudioLinkState(bool state)
        {
            if (!_audioLinkEnabled && state)
            {
                EnableAudioLink();
            }
            else if (_audioLinkEnabled && !state)
            {
                DisableAudioLink();
            }
        }

        public void EnableAudioLink()
        {
            InitIDs();
            _audioLinkEnabled = true;
            SetAudioLinkGlobalTexture();

#if !UDONSHARP && !CVR_CCK_EXISTS
            if (autoDetectAudioTarget) Invoke(nameof(AutoCacheAudioTarget), 1f);
#endif

#if UNITY_WEBGL && !UNITY_EDITOR
            SetupAnalyzerSpace();
            LinkAnalyzer(WebALID, audioSource.clip.length, 4096);
#endif
        }

        public void DisableAudioLink()
        {
            _audioLinkEnabled = false;
            if (audioRenderTexture != null) { audioRenderTexture.updateMode = CustomRenderTextureUpdateMode.OnDemand; }
            SetGlobalTextureWrapper(_AudioTexture, null, UnityEngine.Rendering.RenderTextureSubElement.Default);

#if UNITY_WEBGL && !UNITY_EDITOR
            UnlinkAnalyzer(WebALID);
#endif

#if !UDONSHARP && !CVR_CCK_EXISTS
            CancelInvoke(nameof(AutoCacheAudioTarget));
#endif
        }

        private void SetAudioLinkGlobalTexture()
        {
#if UNITY_EDITOR
            // When running in editor, the monobehaviour should control the render texture update cycle.
            // This mitigates the HYPERSPEED behaviour of the CRT updating multiple times per frame when more than one view camera (scene/view/whatever) is visible.
            audioRenderTexture.updateMode = CustomRenderTextureUpdateMode.OnDemand;
#else
            // In-game it will just update itself in realtime as expected.
            audioRenderTexture.updateMode = CustomRenderTextureUpdateMode.Realtime;
#endif
            SetGlobalTextureWrapper(_AudioTexture, audioRenderTexture, UnityEngine.Rendering.RenderTextureSubElement.Default);

        }

        public void SetGlobalTextureWrapper(int nameID, RenderTexture value, UnityEngine.Rendering.RenderTextureSubElement element)
        {
#if UDONSHARP
            SetGlobalTexture(nameID, value);
#else
            SetGlobalTexture(nameID, value, element);
#endif
        }

        public void EnableReadback()
        {
            audioDataToggle = true;
        }

        public void DisableReadback()
        {
            audioDataToggle = false;
        }

        public void SendAudioOutputData()
        {
            InitIDs();

#if UNITY_WEBGL && !UNITY_EDITOR

            if (audioSource.isPlaying)
            {
                FetchAnalyzerLeft(WebALID, audioLinkWebPeer.WaveformSamplesLeft, 4096);
                FetchAnalyzerRight(WebALID, audioLinkWebPeer.WaveformSamplesRight, 4096);
            }

            _audioFramesL = audioLinkWebPeer.WaveformSamplesLeft;
            _audioFramesR = audioLinkWebPeer.WaveformSamplesRight;

#else

            audioSource.GetOutputData(_audioFramesL, 0);                // left channel

#if UDONSHARP
            bool hasDualMono = VRC.SDKBase.Utilities.IsValid(optionalRightAudioSource);
#else
            bool hasDualMono = optionalRightAudioSource != null;
#endif

            if (_rightChannelTestCounter > 0)
            {
                if (_ignoreRightChannel)
                {
                    Array.Copy(_audioFramesL, 0, _audioFramesR, 0, 4092);
                }
                else
                {
                    if (hasDualMono)
                    {
                        optionalRightAudioSource.GetOutputData(_audioFramesR, 0);
                    } else audioSource.GetOutputData(_audioFramesR, 1);
                }
                _rightChannelTestCounter--;
            }
            else
            {
                _rightChannelTestCounter = _rightChannelTestDelay;                  // reset test countdown
                _audioFramesR[0] = 0f;                                              // reset tested array element to zero just in case
                if (hasDualMono)                                                    // check if dual mono is present
                {
                    optionalRightAudioSource.GetOutputData(_audioFramesR, 0);       // right channel test
                } else audioSource.GetOutputData(_audioFramesR, 1);                 // right channel test
                _ignoreRightChannel = (_audioFramesR[0] == 0f) ? true : false;
            }

#endif

            Array.Copy(_audioFramesL, 0, _samples, 0, 1023); // 4092 - 1023 * 4
            audioMaterial.SetFloatArray(_Samples0L, _samples);
            Array.Copy(_audioFramesL, 1023, _samples, 0, 1023); // 4092 - 1023 * 3
            audioMaterial.SetFloatArray(_Samples1L, _samples);
            Array.Copy(_audioFramesL, 2046, _samples, 0, 1023); // 4092 - 1023 * 2
            audioMaterial.SetFloatArray(_Samples2L, _samples);
            Array.Copy(_audioFramesL, 3069, _samples, 0, 1023); // 4092 - 1023 * 1
            audioMaterial.SetFloatArray(_Samples3L, _samples);

            Array.Copy(_audioFramesR, 0, _samples, 0, 1023); // 4092 - 1023 * 4
            audioMaterial.SetFloatArray(_Samples0R, _samples);
            Array.Copy(_audioFramesR, 1023, _samples, 0, 1023); // 4092 - 1023 * 3
            audioMaterial.SetFloatArray(_Samples1R, _samples);
            Array.Copy(_audioFramesR, 2046, _samples, 0, 1023); // 4092 - 1023 * 2
            audioMaterial.SetFloatArray(_Samples2R, _samples);
            Array.Copy(_audioFramesR, 3069, _samples, 0, 1023); // 4092 - 1023 * 1
            audioMaterial.SetFloatArray(_Samples3R, _samples);
        }

        private float Remap(float t, float a, float b, float u, float v)
        {
            return ((t - a) / (b - a)) * (v - u) + u;
        }

#if !UDONSHARP
        private void RunAutoDirector()
        {
            AutoDirectorHandleToggles();

            audioSource.GetSpectrumData(_spectrumData, 0, FFTWindow.BlackmanHarris);

            float p0 = 0f, p1 = 0f, p2 = 0f, p3 = 0f;
            for (int i = 0; i <= 10; i++) if (_spectrumData[i] > p0) p0 = _spectrumData[i];
            for (int i = 11; i <= 42; i++) if (_spectrumData[i] > p1) p1 = _spectrumData[i];
            for (int i = 43; i <= 170; i++) if (_spectrumData[i] > p2) p2 = _spectrumData[i];
            for (int i = 171; i <= 853; i++) if (_spectrumData[i] > p3) p3 = _spectrumData[i];

            float instant = Mathf.Max(Mathf.Max(p0, p1), Mathf.Max(p2, p3));
            float agcRate = instant > _autoDirectorLevel
                ? 1f - Mathf.Exp(-Time.deltaTime / AutoDirectorAgcAttack)
                : 1f - Mathf.Exp(-Time.deltaTime / AutoDirectorAgcRelease);
            _autoDirectorLevel = Mathf.Lerp(_autoDirectorLevel, instant, agcRate);

            float derate = autogain ? autogainDerate : AutoDirectorSilenceFloor;
            float norm = 1f / (_autoDirectorLevel + derate);
            float peakDecay = Mathf.Exp(-Time.deltaTime / AutoDirectorPeakDecay);
            float n = Mathf.Clamp01(autoDirectorSpeed / AutoDirectorMaxSpeed);
            float track = 1f - Mathf.Pow(1f - n, Time.deltaTime * AutoDirectorReferenceFps);

            float nb0 = p0 * norm, nb1 = p1 * norm, nb2 = p2 * norm, nb3 = p3 * norm;

            if (autoTuneThresholds)
            {
                threshold0 = AutoDirectorBandThreshold(0, nb0, threshold0, peakDecay, track);
                threshold1 = AutoDirectorBandThreshold(1, nb1, threshold1, peakDecay, track);
                threshold2 = AutoDirectorBandThreshold(2, nb2, threshold2, peakDecay, track);
                threshold3 = AutoDirectorBandThreshold(3, nb3, threshold3, peakDecay, track);
                audioMaterial.SetFloat(_Threshold0, threshold0);
                audioMaterial.SetFloat(_Threshold1, threshold1);
                audioMaterial.SetFloat(_Threshold2, threshold2);
                audioMaterial.SetFloat(_Threshold3, threshold3);
            }

            if (autoTuneCrossovers) AutoDirectorCrossovers();
            if (autoTuneFade) AutoDirectorFade(nb0, nb1, nb2, nb3);
        }

        private void AutoDirectorHandleToggles()
        {
            if (_autoDirectorPrevThresholds && !autoTuneThresholds) AutoDirectorResetThresholds();
            if (_autoDirectorPrevCrossovers && !autoTuneCrossovers) AutoDirectorResetCrossovers();
            if (_autoDirectorPrevFade && !autoTuneFade) AutoDirectorResetFade();
            _autoDirectorPrevThresholds = autoTuneThresholds;
            _autoDirectorPrevCrossovers = autoTuneCrossovers;
            _autoDirectorPrevFade = autoTuneFade;
        }

        private void AutoDirectorResetThresholds()
        {
            threshold0 = threshold1 = threshold2 = threshold3 = AutoDirectorDefaultThreshold;
            audioMaterial.SetFloat(_Threshold0, AutoDirectorDefaultThreshold);
            audioMaterial.SetFloat(_Threshold1, AutoDirectorDefaultThreshold);
            audioMaterial.SetFloat(_Threshold2, AutoDirectorDefaultThreshold);
            audioMaterial.SetFloat(_Threshold3, AutoDirectorDefaultThreshold);
        }

        private void AutoDirectorResetCrossovers()
        {
            x0 = AutoDirectorDefaultX0;
            x1 = AutoDirectorDefaultX1;
            x2 = AutoDirectorDefaultX2;
            x3 = AutoDirectorDefaultX3;
            audioMaterial.SetFloat(_X0, x0);
            audioMaterial.SetFloat(_X1, x1);
            audioMaterial.SetFloat(_X2, x2);
            audioMaterial.SetFloat(_X3, x3);
        }

        private void AutoDirectorResetFade()
        {
            fadeLength = AutoDirectorDefaultFadeLength;
            fadeExpFalloff = AutoDirectorDefaultFadeExp;
            audioMaterial.SetFloat(_FadeLength, fadeLength);
            audioMaterial.SetFloat(_FadeExpFalloff, fadeExpFalloff);
        }

        private float AutoDirectorBandThreshold(int band, float normalized, float current, float peakDecay, float track)
        {
            float peak = Mathf.Max(normalized, _autoDirectorBandPeak[band] * peakDecay);
            _autoDirectorBandPeak[band] = peak;
            float target = Mathf.Clamp(Mathf.Sqrt(peak), AutoDirectorMinThreshold, 1f);
            return Mathf.Lerp(current, target, track);
        }

        private void AutoDirectorCrossovers()
        {
            for (int i = 0; i < AutoDirectorXBins; i++) _autoDirectorSpectrumHist[i] = 0f;

            float total = 0f;
            for (int k = AutoDirectorFreqBinLow; k <= AutoDirectorFreqBinHigh; k++)
            {
                float note = AutoDirectorExpBins * Mathf.Log((k * AutoDirectorHzPerBin) / AutoDirectorBottomFreq, 2f);
                float x = (note - AutoDirectorBandBinFloor) / AutoDirectorBandBinSpan;
                if (x < 0f || x > 1f) continue;
                _autoDirectorSpectrumHist[Mathf.Clamp((int)(x * AutoDirectorXBins), 0, AutoDirectorXBins - 1)] += _spectrumData[k];
                total += _spectrumData[k];
            }

            if (total < AutoDirectorCrossoverGate) return;

            float xtrack = 1f - Mathf.Exp(-Time.deltaTime / AutoDirectorCrossoverSmoothing);
            float s = AutoDirectorCrossoverStrength;
            float q0 = Mathf.Clamp(AutoDirectorSpectrumQuantile(total * 0.05f), 0.0f, 0.168f);
            float q1 = Mathf.Clamp(AutoDirectorSpectrumQuantile(total * 0.25f), 0.242f, 0.387f);
            float q2 = Mathf.Clamp(AutoDirectorSpectrumQuantile(total * 0.50f), 0.461f, 0.628f);
            float q3 = Mathf.Clamp(AutoDirectorSpectrumQuantile(total * 0.75f), 0.704f, 0.953f);
            x0 = Mathf.Lerp(x0, Mathf.Lerp(AutoDirectorDefaultX0, q0, s), xtrack);
            x1 = Mathf.Lerp(x1, Mathf.Lerp(AutoDirectorDefaultX1, q1, s), xtrack);
            x2 = Mathf.Lerp(x2, Mathf.Lerp(AutoDirectorDefaultX2, q2, s), xtrack);
            x3 = Mathf.Lerp(x3, Mathf.Lerp(AutoDirectorDefaultX3, q3, s), xtrack);

            audioMaterial.SetFloat(_X0, x0);
            audioMaterial.SetFloat(_X1, x1);
            audioMaterial.SetFloat(_X2, x2);
            audioMaterial.SetFloat(_X3, x3);
        }

        private float AutoDirectorSpectrumQuantile(float targetEnergy)
        {
            float cumulative = 0f;
            for (int i = 0; i < AutoDirectorXBins; i++)
            {
                cumulative += _autoDirectorSpectrumHist[i];
                if (cumulative >= targetEnergy) return (i + 0.5f) / AutoDirectorXBins;
            }
            return 1f;
        }

        private void AutoDirectorFade(float nb0, float nb1, float nb2, float nb3)
        {
            float flux = Mathf.Max(0f, nb0 - _autoDirectorBandLast[0])
                       + Mathf.Max(0f, nb1 - _autoDirectorBandLast[1])
                       + Mathf.Max(0f, nb2 - _autoDirectorBandLast[2])
                       + Mathf.Max(0f, nb3 - _autoDirectorBandLast[3]);
            _autoDirectorBandLast[0] = nb0;
            _autoDirectorBandLast[1] = nb1;
            _autoDirectorBandLast[2] = nb2;
            _autoDirectorBandLast[3] = nb3;

            _autoDirectorActivity = Mathf.Lerp(_autoDirectorActivity, flux, 1f - Mathf.Exp(-Time.deltaTime / AutoDirectorActivitySmoothing));
            _autoDirectorFluxMax = Mathf.Max(_autoDirectorActivity, _autoDirectorFluxMax * Mathf.Exp(-Time.deltaTime / AutoDirectorFluxMaxDecay));
            float busy = Mathf.Clamp01(_autoDirectorActivity / (_autoDirectorFluxMax + AutoDirectorActivityFloor));

            float fadeRate = 1f - Mathf.Exp(-Time.deltaTime / AutoDirectorFadeSmoothing);
            fadeLength = Mathf.Lerp(fadeLength, Mathf.Lerp(AutoDirectorFadeCalm, AutoDirectorFadeBusy, busy), fadeRate);
            fadeExpFalloff = Mathf.Lerp(fadeExpFalloff, Mathf.Lerp(AutoDirectorFadeExpCalm, AutoDirectorFadeExpBusy, busy), fadeRate);

            audioMaterial.SetFloat(_FadeLength, fadeLength);
            audioMaterial.SetFloat(_FadeExpFalloff, fadeExpFalloff);
        }

        public void ToggleAutoDirector()
        {
            autoDirectorMode = !autoDirectorMode;
        }

        public void ToggleAutoTuneThresholds()
        {
            autoTuneThresholds = !autoTuneThresholds;
        }

        public void ToggleAutoTuneCrossovers()
        {
            autoTuneCrossovers = !autoTuneCrossovers;
        }

        public void ToggleAutoTuneFade()
        {
            autoTuneFade = !autoTuneFade;
        }
#endif
    }
}
