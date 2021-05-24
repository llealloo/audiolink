
using UnityEngine;
using VRC.SDKBase;
using UnityEngine.UI;
using System;

#if UDON
using UdonSharp;

#if !COMPILER_UDONSHARP && UNITY_EDITOR
using UnityEditor;
using UdonSharpEditor;
using VRC.Udon;
using VRC.Udon.Common;
using VRC.Udon.Common.Interfaces;
using System.Collections.Immutable;
#endif

public class AudioLink : UdonSharpBehaviour
#else
public class AudioLink : MonoBehaviour
#endif
{
    const float AUDIOLINK_VERSION_NUMBER = 2.04f;

    [Header("Main Settings")]

    [Tooltip("Should be used with AudioLinkInput unless source is 2D. WARNING: if used with a custom 3D audio source (not through AudioLinkInput), audio reactivity will be attenuated by player position away from the Audio Source")]
    public AudioSource audioSource;
    [Tooltip("Enable global _AudioTexture")]
    public bool audioTextureToggle = true;

    [Header("Basic EQ")]
    [Range(0.0f, 2.0f)][Tooltip("Warning: this setting might be taken over by AudioLinkController")]
    public float gain = 1f;
    [Range(0.0f, 2.0f)][Tooltip("Warning: this setting might be taken over by AudioLinkController")]
    public float bass = 1f;
    [Range(0.0f, 2.0f)][Tooltip("Warning: this setting might be taken over by AudioLinkController")]
    public float treble = 1f;

    [Header("4 Band Crossover")]
    [Range(0.04882813f, 0.2988281f)][Tooltip("Bass / low mid crossover")]
    public float x1 = 0.25f;
    [Range(0.375f, 0.625f)][Tooltip("Low mid / high mid crossover")]
    public float x2 = 0.5f;
    [Range(0.7021484f, 0.953125f)][Tooltip("High mid / treble crossover")]
    public float x3 = 0.75f;

    [Header("4 Band Threshold Points (Sensitivity)")]
    [Range(0.0f, 1.0f)][Tooltip("Bass threshold level (lower is more sensitive)")]
    public float threshold0 = 0.45f;
    [Range(0.0f, 1.0f)][Tooltip("Low mid threshold level (lower is more sensitive)")]
    public float threshold1 = 0.45f;
    [Range(0.0f, 1.0f)][Tooltip("High mid threshold level (lower is more sensitive)")]
    public float threshold2 = 0.45f;
    [Range(0.0f, 1.0f)][Tooltip("Treble threshold level (lower is more sensitive)")]
    public float threshold3 = 0.45f;

    [Header("Fade Controls")]
    [Range(0.0f, 1.0f)][Tooltip("Amplitude fade amount. This creates a linear fade-off / trails effect. Warning: this setting might be taken over by AudioLinkController")]
    public float fadeLength = 0.8f;
    [Range(0.0f, 1.0f)][Tooltip("Amplitude fade exponential falloff. This attenuates the above (linear) fade-off exponentially, creating more of a pulsed effect. Warning: this setting might be taken over by AudioLinkController")]
    public float fadeExpFalloff = 0.3f;

    [Header("Internal (Do not modify)")]
    public Material audioMaterial;
    public GameObject audioTextureExport;

    [Header("Experimental (Limits performance)")]
    [Tooltip("Enable Udon audioData array. Required by AudioReactiveLight and AudioReactiveObject. Uses ReadPixels which carries a performance hit. For experimental use when performance is less of a concern")]
    public bool audioDataToggle = false;
    public Color[] audioData;
    public Texture2D audioData2D;                               // Texture2D reference for hacked Blit, may eventually be depreciated

    private float[] _spectrumValues = new float[1024];
    private float[] _spectrumValuesTrim = new float[1023];
    private float[] _audioFrames = new float[1023*4];
    private float[] _samples0 = new float[1023];
    private float[] _samples1 = new float[1023];
    private float[] _samples2 = new float[1023];
    private float[] _samples3 = new float[1023];
    private float _audioLinkInputVolume = 0.01f;                        // smallify input source volume level
    private bool _audioSource2D = false;
    
    // Mechanism to provide sync'd instance time to all avatars.
    [UdonSynced] private Int32 _masterInstanceJoinServerTimeStampMs;
    private Int32 _instanceJoinServerTimeStampMs;
    private double NextFPSTime;
    private int    FPSCount;
    
    Int32 ConvertUInt64ToInt32( UInt64 u6t )
    {
        Int64 intermediate = (UInt32)(u6t & 0xffffffffUL);
        if( intermediate >= 0x80000000 )
        {
            return (Int32)(intermediate - 0x100000000);
        }
        else
        {
            return (Int32)intermediate;            
        }
    }

    void Start()
    {

        {
            // Handle sync'd time stuff.
            
            //Originally used GetServerTimeInMilliseconds
            //GetServerTimeInMilliseconds will alias to every 49.7 days (2^32ms). GetServerTimeInSeconds also aliases.
            //We still alias, but TCL suggested using Networking.GetNetworkDateTime.
            DateTime currentDate = Networking.GetNetworkDateTime();
            UInt64 currentTimeTicks = (UInt64)(currentDate.Ticks/TimeSpan.TicksPerMillisecond);
            Int32 startTime = Networking.GetServerTimeInMilliseconds();

            if (Networking.IsMaster)
            {
                _masterInstanceJoinServerTimeStampMs = startTime;
                RequestSerialization();
            }
            Int32 timeSinceLevelLoadAtInstanceJoinMs = (Int32)( Convert.ToUInt64(Time.timeSinceLevelLoad * 1000) & 0xffffffff ); 
            _instanceJoinServerTimeStampMs = startTime - timeSinceLevelLoadAtInstanceJoinMs;
            Debug.Log($"AudioLink Time Sync Debug: {startTime} {Networking.IsMaster} {_masterInstanceJoinServerTimeStampMs} {_instanceJoinServerTimeStampMs} {timeSinceLevelLoadAtInstanceJoinMs}.");
        }

        UpdateSettings();
        if (audioSource.name.Equals("AudioLinkInput"))
        {
            audioSource.volume = _audioLinkInputVolume;
        } else {
            _audioSource2D = true;
        }
        gameObject.SetActive(true);                             // client disables extra cameras, so set it true
        transform.position = new Vector3(0f, 10000000f, 0f);    // keep this in a far away place
        audioTextureExport.SetActive(audioTextureToggle);
    }

    private void Update() 
    {
        if (audioSource == null) return;
        audioSource.GetOutputData(_audioFrames, 0);
        System.Array.Copy(_audioFrames, 4092-1023*4, _samples0, 0, 1023);
        System.Array.Copy(_audioFrames, 4092-1023*3, _samples1, 0, 1023);
        System.Array.Copy(_audioFrames, 4092-1023*2, _samples2, 0, 1023);
        System.Array.Copy(_audioFrames, 4092-1023*1, _samples3, 0, 1023);
        audioMaterial.SetFloatArray("_Samples0", _samples0);
        audioMaterial.SetFloatArray("_Samples1", _samples1);
        audioMaterial.SetFloatArray("_Samples2", _samples2);
        audioMaterial.SetFloatArray("_Samples3", _samples3);

        {
            /* General Notes:
                As of now, we convert the current "now" time to milliseconds.
                All times are locked to milliseconds.

                If a user is in a level for > 18 hours, the aliasing on 
                Time.timeSinceLevelLoad will exceed 4ms, this restriction can
                be lifted when VRC moves to 2020+. and timeSinceLevelLoadAsDouble
                can be used in the below code.
                
                The user can safely use the red channel to read a value that
                loops over and over from instance start from 0 to 16,777,215ms
                
                Then the green channel will increment.

                NOTE: The 0xffffffff is here to make it clear what is happening.
                The code should safely roll over either way.
            */

            double TimeSinceLoadSeconds = Convert.ToDouble( Time.timeSinceLevelLoad );
            Int32 timeSinceLevelLoadMs = ConvertUInt64ToInt32( (UInt64)(TimeSinceLoadSeconds * 1000.0) );
            Int32 nowMs =
                _instanceJoinServerTimeStampMs -
                _masterInstanceJoinServerTimeStampMs +
                timeSinceLevelLoadMs;
            audioMaterial.SetVector( "_FrameTimeProp", new Vector4(
                (float)( nowMs & 0x3ff ),
                (float)( (nowMs >> 10 ) & 0x3ff ),
                (float)( (nowMs >> 20 ) & 0x3ff ),
                (float)( (nowMs >> 30 ) & 0x3ff )
                ) );
                
            double nowSeconds = DateTime.Now.TimeOfDay.TotalSeconds;
            Int32 ts = ConvertUInt64ToInt32( (UInt64)(nowSeconds * 1000.0) ); 
            audioMaterial.SetVector( "_DayTimeProp", new Vector4(
                (float)( ts & 0x3ff ),
                (float)( (ts >> 10 ) & 0x3ff ),
                (float)( (ts >> 20 ) & 0x3ff ),
                (float)( (ts >> 30 ) & 0x3ff )
                ) );

            FPSCount++;

            FPSCount++;
            if( TimeSinceLoadSeconds >= NextFPSTime )
            {
                audioMaterial.SetVector( "_VersionNumberAndFPSProperty", new Vector4( AUDIOLINK_VERSION_NUMBER, 0, FPSCount, 1 ) );
                FPSCount = 0;
                NextFPSTime++;
            }
        }

        #if UNITY_EDITOR
        UpdateSettings();
        #endif
    }

    void OnPostRender()
    {
        if(audioDataToggle)
        {
            audioData2D.ReadPixels(new Rect(0, 0, audioData2D.width, audioData2D.height), 0, 0, false);
            audioData = audioData2D.GetPixels();
        }
    }

    public void UpdateSettings()
    {
        audioTextureExport.SetActive(audioTextureToggle);
        audioMaterial.SetFloat("_X1", x1);
        audioMaterial.SetFloat("_X2", x2);
        audioMaterial.SetFloat("_X3", x3);
        audioMaterial.SetFloat("_Threshold0", threshold0);
        audioMaterial.SetFloat("_Threshold1", threshold1);
        audioMaterial.SetFloat("_Threshold2", threshold2);
        audioMaterial.SetFloat("_Threshold3", threshold3);
        audioMaterial.SetFloat("_Gain", gain);
        audioMaterial.SetFloat("_FadeLength", fadeLength);
        audioMaterial.SetFloat("_FadeExpFalloff", fadeExpFalloff);
        audioMaterial.SetFloat("_Bass", bass);
        audioMaterial.SetFloat("_Treble", treble);
        audioMaterial.SetFloat("_AudioSource2D", _audioSource2D?1f:0f);
    }

    private float Remap(float t, float a, float b, float u, float v)
    {
        return ( (t-a) / (b-a) ) * (v-u) + u;
    }
}

#if !COMPILER_UDONSHARP && UNITY_EDITOR && UDON
[CustomEditor(typeof(AudioLink))]
public class AudioLinkEditor : Editor
{
    public override void OnInspectorGUI()
    {
        if (UdonSharpGUI.DrawDefaultUdonSharpBehaviourHeader(target)) return;
        EditorGUILayout.Space();
        if (GUILayout.Button(new GUIContent("Link all sound reactive objects to this AudioLink", "Links all UdonBehaviours with 'audioLink' parameter to this object."))) { LinkAll(); }
        EditorGUILayout.Space();
        base.OnInspectorGUI();
    }

    void LinkAll()
    {
        UdonBehaviour[] allBehaviours = UnityEngine.Object.FindObjectsOfType<UdonBehaviour>();
        foreach (UdonBehaviour behaviour in allBehaviours)
        {
            var program = behaviour.programSource.SerializedProgramAsset.RetrieveProgram();
            ImmutableArray<string> exportedSymbolNames = program.SymbolTable.GetExportedSymbols();
            foreach (string exportedSymbolName in exportedSymbolNames)
            {
                if (exportedSymbolName.Equals("audioLink"))
                {
                    var variableValue = UdonSharpEditorUtility.GetBackingUdonBehaviour((UdonSharpBehaviour)target);
                    System.Type symbolType = program.SymbolTable.GetSymbolType(exportedSymbolName);
                    if (!behaviour.publicVariables.TrySetVariableValue("audioLink", variableValue))
                    {
                        if (!behaviour.publicVariables.TryAddVariable(CreateUdonVariable(exportedSymbolName, variableValue, symbolType)))
                        {
                            Debug.LogError($"Failed to set public variable '{exportedSymbolName}' value.");
                        }

                        if(PrefabUtility.IsPartOfPrefabInstance(behaviour))
                        {
                            PrefabUtility.RecordPrefabInstancePropertyModifications(behaviour);
                        }
                    }
                }
            }
        }
    }

    IUdonVariable CreateUdonVariable(string symbolName, object value, System.Type type)
    {
        System.Type udonVariableType = typeof(UdonVariable<>).MakeGenericType(type);
        return (IUdonVariable)Activator.CreateInstance(udonVariableType, symbolName, value);
    }
    
}
#endif
