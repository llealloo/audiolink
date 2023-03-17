﻿using UnityEngine;
using System;
using VRCAudioLink.Editor;

namespace VRCAudioLink
{
#if UDONSHARP
    using UdonSharp;
    using VRC.SDKBase;
    using static VRC.SDKBase.VRCShader;

    [UdonBehaviourSyncMode(BehaviourSyncMode.Manual)]
    public class AudioLink : UdonSharpBehaviour
#else
    using static UnityEngine.Shader;
    using UnityEngine.Rendering;

    public class AudioLink : MonoBehaviour
#endif
    {
        const float AUDIOLINK_VERSION_NUMBER = 3.02f;

        [Header("Main Settings")] [Tooltip("Should be used with AudioLinkInput unless source is 2D. WARNING: if used with a custom 3D audio source (not through AudioLinkInput), audio reactivity will be attenuated by player position away from the Audio Source")]
        public AudioSource audioSource;

        [Header("Basic EQ")] [Range(0.0f, 2.0f)] [Tooltip("Warning: this setting might be taken over by AudioLinkController")]
        public float gain = 1f;

        [Range(0.0f, 2.0f)] [Tooltip("Warning: this setting might be taken over by AudioLinkController")]
        public float bass = 1f;

        [Range(0.0f, 2.0f)] [Tooltip("Warning: this setting might be taken over by AudioLinkController")]
        public float treble = 1f;

        [Header("4 Band Crossover")] [Range(0.0f, 0.168f)] [Tooltip("Bass / low mid crossover")]
        public float x0 = 0.0f;

        [Range(0.242f, 0.387f)] [Tooltip("Bass / low mid crossover")]
        public float x1 = 0.25f;

        [Range(0.461f, 0.628f)] [Tooltip("Low mid / high mid crossover")]
        public float x2 = 0.5f;

        [Range(0.704f, 0.953f)] [Tooltip("High mid / treble crossover")]
        public float x3 = 0.75f;

        [Header("4 Band Threshold Points (Sensitivity)")] [Range(0.0f, 1.0f)] [Tooltip("Bass threshold level (lower is more sensitive)")]
        public float threshold0 = 0.45f;

        [Range(0.0f, 1.0f)] [Tooltip("Low mid threshold level (lower is more sensitive)")]
        public float threshold1 = 0.45f;

        [Range(0.0f, 1.0f)] [Tooltip("High mid threshold level (lower is more sensitive)")]
        public float threshold2 = 0.45f;

        [Range(0.0f, 1.0f)] [Tooltip("Treble threshold level (lower is more sensitive)")]
        public float threshold3 = 0.45f;

        [Header("Fade Controls")] [Range(0.0f, 1.0f)] [Tooltip("Amplitude fade amount. This creates a linear fade-off / trails effect. Warning: this setting might be taken over by AudioLinkController")]
        public float fadeLength = 0.25f;

        [Range(0.0f, 1.0f)] [Tooltip("Amplitude fade exponential falloff. This attenuates the above (linear) fade-off exponentially, creating more of a pulsed effect. Warning: this setting might be taken over by AudioLinkController")]
        public float fadeExpFalloff = 0.75f;

        [Header("Theme Colors")] [Tooltip("Enable for custom theme colors for Avatars to use.")]
        [StringInList("ColorChord Colors", "Custom")]
        public int themeColorMode;
        public Color customThemeColor0 = new Vector4(1.0f, 1.0f, 0.0f, 1.0f);
        public Color customThemeColor1 = new Vector4(0.0f, 0.0f, 1.0f, 1.0f);
        public Color customThemeColor2 = new Vector4(1.0f, 0.0f, 0.0f, 1.0f);
        public Color customThemeColor3 = new Vector4(0.0f, 1.0f, 0.0f, 1.0f);

        [Header("Custom Global Strings")]
        #if UDONSHARP
        [UdonSynced]
        #endif
        public string customString1;
        #if UDONSHARP
        [UdonSynced]
        #endif
        public string customString2;

        [Header("Internal (Do not modify)")] public Material audioMaterial;
        public CustomRenderTexture audioRenderTexture;

        [Header("Experimental (Limits performance)")] [Tooltip("Enable Udon audioData array. Required by AudioReactiveLight and AudioReactiveObject. Uses ReadPixels which carries a performance hit. For experimental use when performance is less of a concern")]
        public bool audioDataToggle = false;

        public Color[] audioData;
        public Texture2D audioData2D; // Texture2D reference for hacked Blit, may eventually be depreciated

        private float[] _spectrumValues = new float[1024];
        private float[] _spectrumValuesTrim = new float[1023];
        private float[] _audioFramesL = new float[1023 * 4];
        private float[] _audioFramesR = new float[1023 * 4];
        private float[] _samples = new float[1023];

        private string masterName;
        // Mechanism to provide sync'd instance time to all avatars.
#if UDONSHARP
    [UdonSynced]
#endif
        private double _masterInstanceJoinTime;
        private double _elapsedTime = 0;
        private double _elapsedTimeMSW = 0;
        private int    _networkTimeMS;
        private double _networkTimeMSAccumulatedError;
#pragma warning disable 414 ///The private field is assigned but its value is never used
        private bool   _hasInitializedTime = false;
#pragma warning restore 414
        private double _FPSTime = 0;
        private int    _FPSCount = 0;

#if UDONSHARP
        private double GetElapsedSecondsSince2019() { return (Networking.GetNetworkDateTime() - new DateTime(2020, 1, 1) ).TotalSeconds; }
        //private double GetElapsedSecondsSinceMidnightUTC() { return (Networking.GetNetworkDateTime() - DateTime.UtcNow.Date ).TotalSeconds; }
#else
        private double GetElapsedSecondsSince2019() { return (DateTime.UtcNow - new DateTime(2020, 1, 1) ).TotalSeconds; }
#endif

        // Fix for AVPro mono game output bug (if running the game with a mono output source like a headset)
        private int _rightChannelTestDelay = 300;
        private int _rightChannelTestCounter;
        private bool _ignoreRightChannel = false;
        
        #region PropertyIDs

        // ReSharper disable InconsistentNaming
        
        private int _AudioTexture;

        private bool _idsInitialized = false;
        
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
        private int _SourceVolume;
        private int _SourceDistance;
        private int _SourceSpatialBlend;
        private int _SourcePosition;
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
        
        // Extra Properties
        // private int _EnableAutogain;
        // private int _AutogainDerate;
        
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


        private void InitIDs()
        {
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
            
            // _EnableAutogain = PropertyToID("_EnableAutogain");
            // _AutogainDerate = PropertyToID("_AutogainDerate");
            
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

            _idsInitialized = true;
        }
        #endregion

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
                //Debug.Log($"AudioLink _networkTimeOfDayUTC = {_networkTimeOfDayUTC}" );
                Debug.Log($"AudioLink _networkTimeMS = {_networkTimeMS}" );
                Debug.Log($"AudioLink Time Sync Debug: IsMaster: {Networking.IsMaster} startTime: {startTime}");

                _rightChannelTestCounter = _rightChannelTestDelay; 

                // Set localplayer name on start
                if (Networking.LocalPlayer != null)
                {
                    if (VRC.SDKBase.Utilities.IsValid(Networking.LocalPlayer))
                    {
                        UpdateGlobalString(_StringLocalPlayer, Networking.LocalPlayer.displayName);
                    }
                }

                // Set master name once on start
                FindAndUpdateMasterName();
            }
            #endif

            UpdateSettings();
            UpdateThemeColors();
            UpdateCustomStrings();
            if (audioSource == null)
            {
                Debug.LogWarning("No audioSource provided. AudioLink will not do anything until an audio source has been assigned.");
            }

            gameObject.SetActive(true); // client disables extra cameras, so set it true
            transform.position = new Vector3(0f, 10000000f, 0f); // keep this in a far away place

            // Disable camera on start if user didn't ask for it
            if (!audioDataToggle)
            {
                DisableReadback();
            }
        }

        // Only happens once per second.
        private void FPSUpdate()
        {
            #if UDONSHARP
            if( !_hasInitializedTime )
            {
                if( _masterInstanceJoinTime > 0.00001 )
                {
                    //We can now do our time setup.
                    double Now = GetElapsedSecondsSince2019();
                    _elapsedTime = Now - _masterInstanceJoinTime;
                    Debug.Log( $"AudioLink Time Sync Debug: Received instance time of {_masterInstanceJoinTime} and current time of {Now} delta of {_elapsedTime}" );
                    _hasInitializedTime = true;
                    _FPSTime = _elapsedTime;
                }
                else if( _elapsedTime > 10 && Networking.IsMaster )
                {
                    //Have we gone more than 10 seconds and we're master?
                    Debug.Log( "AudioLink Time Sync Debug: You were master.  But no _masterInstanceJoinTime was provided for 10 seconds.  Resetting instance time." );
                    _masterInstanceJoinTime = GetElapsedSecondsSince2019();
                    RequestSerialization();
                    _hasInitializedTime = true;
                    _elapsedTime = 0;
                    _FPSTime = _elapsedTime;
                }
            }
            #endif

            audioMaterial.SetVector(_VersionNumberAndFPSProperty, new Vector4(AUDIOLINK_VERSION_NUMBER, 0, _FPSCount, 1));
            #if UDONSHARP
            audioMaterial.SetVector(_PlayerCountAndData, new Vector4(
                VRCPlayerApi.GetPlayerCount(),
                Networking.IsMaster?1.0f:0.0f,
                #if UNITY_EDITOR
                    0.0f,
                #else
                    Networking.LocalPlayer.isInstanceOwner?1.0f:0.0f,
                #endif
                0 ) );

            #else
                audioMaterial.SetVector(_PlayerCountAndData, new Vector4(
                0,
                0,
                0,
                0 ) );
            #endif
            _FPSCount = 0;
            _FPSTime++;

            // Other things to handle every second.

            // This handles wrapping of the ElapsedTime so we don't lose precision
            // onthe floating point.
            const double ElapsedTimeMSWBoundary = 1024;
            if( _elapsedTime >= ElapsedTimeMSWBoundary )
            {
                //For particularly long running instances, i.e. several days, the first
                //few frames will be spent federating _elapsedTime into _elapsedTimeMSW.
                //This is fine.  It just means over time, the
                _FPSTime = 0;
                _elapsedTime -= ElapsedTimeMSWBoundary;
                _elapsedTimeMSW++;
            }

            // Finely adjust our network time estimate if needed.
            #if UDONSHARP
            int networkTimeMSNow = Networking.GetServerTimeInMilliseconds();
            #else
            int networkTimeMSNow = (int)(Time.time*1000.0f);
            #endif
            int networkTimeDelta = networkTimeMSNow - _networkTimeMS;
            if( networkTimeDelta > 3000 )
            {
                //Major upset, reset.
                _networkTimeMS = networkTimeMSNow;
            }
            else if( networkTimeDelta < -3000 )
            {
                //Major upset, reset.
                _networkTimeMS = networkTimeMSNow;
            }
            else
            {
                //Slowly correct the timebase.
                _networkTimeMS += networkTimeDelta/20;
            }
            //Debug.Log( $"Refinement: ${networkTimeDelta}" );
        }

        private void Update()
        {
            // Tested: There does not appear to be any drift updating it this way.
            _elapsedTime += Time.deltaTime;

            // Advance the current network time by a little.
            // this algorithm also takes into account sub-millisecond jitter.
            {
                double deltaTimeMS = Time.deltaTime*1000.0;
                int advanceTimeMS = (int)(deltaTimeMS);
                _networkTimeMSAccumulatedError += deltaTimeMS - advanceTimeMS;
                if( _networkTimeMSAccumulatedError > 1 )
                {
                    _networkTimeMSAccumulatedError--;
                    advanceTimeMS++;
                }
                _networkTimeMS += advanceTimeMS;
            }

            _FPSCount++;

            if (_elapsedTime >= _FPSTime)
            {
                FPSUpdate();
            }

            // use _AdvancedTimeProps0.w for Debugging
            audioMaterial.SetVector(_AdvancedTimeProps0, new Vector4(
                (float)_elapsedTime,
                (float)_elapsedTimeMSW,
                (float)DateTime.Now.TimeOfDay.TotalSeconds) );

			// Jan 1, 1970 = 621355968000000000.0 ticks.
            double UTCSecondsUnix = DateTime.UtcNow.Ticks/10000000.0-62135596800.0;
            audioMaterial.SetVector(_AdvancedTimeProps1, new Vector4(
                (float)((_networkTimeMS)&65535),
                (float)((_networkTimeMS)>>16),
                (float)(Math.Floor(UTCSecondsUnix/86400)),
                (float)(UTCSecondsUnix%86400)
            ) );

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

                // Used to correct for the volume of the audio source component

                audioMaterial.SetFloat(_SourceVolume, audioSource.volume);
                audioMaterial.SetFloat(_SourceSpatialBlend, audioSource.spatialBlend);
                audioMaterial.SetVector(_SourcePosition, audioSource.transform.position);

                #if UDONSHARP
                    if (Networking.LocalPlayer != null)
                    {
                        float distanceToSource = Vector3.Distance(Networking.LocalPlayer.GetTrackingData(VRCPlayerApi.TrackingDataType.Head).position, audioSource.transform.position);
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
        #endif
        }

        void OnPostRender()
        {
            if (audioDataToggle)
            {
                audioData2D.ReadPixels(new Rect(0, 0, audioData2D.width, audioData2D.height), 0, 0, false);
                audioData = audioData2D.GetPixels();
            }
        }

        private void OnEnable()
        {
            if (!_idsInitialized)
            {
                InitIDs();
            }
            
            EnableAudioLink();
        }

        private void OnDisable()
        {
            DisableAudioLink();
        }

        public void UpdateSettings()
        {
            audioMaterial.SetFloat(_X0, x0);
            audioMaterial.SetFloat(_X1, x1);
            audioMaterial.SetFloat(_X2, x2);
            audioMaterial.SetFloat(_X3, x3);
            audioMaterial.SetFloat(_Threshold0, threshold0);
            audioMaterial.SetFloat(_Threshold1, threshold1);
            audioMaterial.SetFloat(_Threshold2, threshold2);
            audioMaterial.SetFloat(_Threshold3, threshold3);
            audioMaterial.SetFloat(_Gain, gain);
            audioMaterial.SetFloat(_FadeLength, fadeLength);
            audioMaterial.SetFloat(_FadeExpFalloff, fadeExpFalloff);
            audioMaterial.SetFloat(_Bass, bass);
            audioMaterial.SetFloat(_Treble, treble);
        }

        // Note: These might be changed frequently so as an optimization, they're in a different function
        // rather than bundled in with the other things in UpdateSettings().
        public void UpdateThemeColors()
        {
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
            if (player != null)
            {
                if (VRC.SDKBase.Utilities.IsValid(player) && player.isMaster)
                {
                    masterName = player.displayName;
                    UpdateGlobalString(_StringMasterPlayer, player.displayName);
                }
            }
        }

        public override void OnPlayerLeft(VRCPlayerApi player)
        {
            if (player != null)
            {
                if (VRC.SDKBase.Utilities.IsValid(player) && (player.isMaster || player.displayName == masterName))
                {
                    FindAndUpdateMasterName();
                }
            }
        }

        private void FindAndUpdateMasterName()
        {
            VRCPlayerApi[] players = new VRCPlayerApi[VRCPlayerApi.GetPlayerCount()];
            VRCPlayerApi.GetPlayers(players);
            foreach (var player in players)
            {
                if (player != null)
                {
                    if (VRC.SDKBase.Utilities.IsValid(player) && player.isMaster)
                    {
                        masterName = player.displayName;
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
                Networking.SetOwner(Networking.LocalPlayer, gameObject);
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

        private void UpdateGlobalString(int nameID, string input)
        {
            const int maxLength = 32;
            if (input.Length > maxLength)
                input = input.Substring(0, maxLength);

            // Get unicode codepoints
            var codePoints = new int[input.Length];
            int codePointsLength = 0;
            for (int i = 0; i < input.Length; i++)
            {
                codePoints[codePointsLength++] = Char.ConvertToUtf32(input, i);
                if (Char.IsHighSurrogate(input[i]))
                {
                    i += 1;
                }
            }

            // Pack them into vectors
            Vector4[] vecs = new Vector4[maxLength / 4]; // 4 chars per vector
            int j = 0;
            for (int i = 0; i < vecs.Length; i++)
            {
                if (j < codePoints.Length) vecs[i].x = IntToFloatBits24Bit((uint)codePoints[j++]); else break;
                if (j < codePoints.Length) vecs[i].y = IntToFloatBits24Bit((uint)codePoints[j++]); else break;
                if (j < codePoints.Length) vecs[i].z = IntToFloatBits24Bit((uint)codePoints[j++]); else break;
                if (j < codePoints.Length) vecs[i].w = IntToFloatBits24Bit((uint)codePoints[j++]); else break;
            }

            // Expose the vectors to shader
            audioMaterial.SetVectorArray(nameID, vecs);
        }

        public void EnableAudioLink()
        {
            audioRenderTexture.updateMode = CustomRenderTextureUpdateMode.Realtime;
            #if UDONSHARP
            VRCShader.SetGlobalTexture(_AudioTexture, audioRenderTexture);
            #else
            Shader.SetGlobalTexture(_AudioTexture, audioRenderTexture, RenderTextureSubElement.Default);
            #endif
        }

        public void DisableAudioLink()
        {
            audioRenderTexture.updateMode = CustomRenderTextureUpdateMode.OnDemand;
            #if UDONSHARP
            VRCShader.SetGlobalTexture(_AudioTexture, null);
            #else
            Shader.SetGlobalTexture(_AudioTexture, null, RenderTextureSubElement.Default);
            #endif
        }
        
        public void EnableReadback()
        {
            audioDataToggle = true;
            GetComponent<Camera>().enabled = true;
        }

        public void DisableReadback()
        {
            audioDataToggle = false;
            GetComponent<Camera>().enabled = false;
        }

        public void SendAudioOutputData()
        {
            audioSource.GetOutputData(_audioFramesL, 0);                // left channel

            if (_rightChannelTestCounter > 0)
            {
                if (_ignoreRightChannel) {
                    System.Array.Copy(_audioFramesL, 0, _audioFramesR, 0, 4092);
                } else {
                    audioSource.GetOutputData(_audioFramesR, 1);
                }
                _rightChannelTestCounter--;
            } else {
                _rightChannelTestCounter = _rightChannelTestDelay;      // reset test countdown
                _audioFramesR[0] = 0f;                                  // reset tested array element to zero just in case
                audioSource.GetOutputData(_audioFramesR, 1);            // right channel test
                _ignoreRightChannel = (_audioFramesR[0] == 0f) ? true : false;
            }

            System.Array.Copy(_audioFramesL, 0, _samples, 0, 1023); // 4092 - 1023 * 4
            audioMaterial.SetFloatArray(_Samples0L, _samples);
            System.Array.Copy(_audioFramesL, 1023, _samples, 0, 1023); // 4092 - 1023 * 3
            audioMaterial.SetFloatArray(_Samples1L, _samples);
            System.Array.Copy(_audioFramesL, 2046, _samples, 0, 1023); // 4092 - 1023 * 2
            audioMaterial.SetFloatArray(_Samples2L, _samples);
            System.Array.Copy(_audioFramesL, 3069, _samples, 0, 1023); // 4092 - 1023 * 1
            audioMaterial.SetFloatArray(_Samples3L, _samples);

            System.Array.Copy(_audioFramesR, 0, _samples, 0, 1023); // 4092 - 1023 * 4
            audioMaterial.SetFloatArray(_Samples0R, _samples);
            System.Array.Copy(_audioFramesR, 1023, _samples, 0, 1023); // 4092 - 1023 * 3
            audioMaterial.SetFloatArray(_Samples1R, _samples);
            System.Array.Copy(_audioFramesR, 2046, _samples, 0, 1023); // 4092 - 1023 * 2
            audioMaterial.SetFloatArray(_Samples2R, _samples);
            System.Array.Copy(_audioFramesR, 3069, _samples, 0, 1023); // 4092 - 1023 * 1
            audioMaterial.SetFloatArray(_Samples3R, _samples);
        }

        private float Remap(float t, float a, float b, float u, float v)
        {
            return ((t - a) / (b - a)) * (v - u) + u;
        }
    }
}
