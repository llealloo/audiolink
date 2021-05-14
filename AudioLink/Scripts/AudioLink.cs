
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
    [Header("Main Settings")]
    [Tooltip("Enable Udon audioData array")]
    public bool audioDataToggle = true;
    [Tooltip("Enable global _AudioTexture")]
    public bool audioTextureToggle = true;

    [Header("Basic EQ")]
    [Range(0.0f, 2.0f)][Tooltip("Warning: this setting might be taken over by AudioLinkController")]
    public float gain = 1f;
    [Range(0.0f, 2.0f)][Tooltip("Warning: this setting might be taken over by AudioLinkController")]
    public float bass = 1f;
    [Range(0.0f, 2.0f)][Tooltip("Warning: this setting might be taken over by AudioLinkController")]
    public float treble = 1f;

    [Header("Advanced EQ")]
    [Range(0.0f, 1.0f)][Tooltip("This applies a logarithmic amplitude scale")]
    public float logAttenuation = 0.68f;
    [Range(0.0f, 1.0f)][Tooltip("Applies a contrast-like effect to the spectrum values. Brights become brighter and darks become darker")]
    public float contrastSlope = 0.63f;
    [Range(0.0f, 1.0f)][Tooltip("Offsets the contrast effect above, kind of like brightness")]
    public float contrastOffset = 0.62f;

    [Header("Fade Controls")]
    [Range(0.0f, 1.0f)][Tooltip("Amplitude fade amount. This creates a linear fade-off / trails effect. Warning: this setting might be taken over by AudioLinkController")]
    public float fadeLength = 0.85f;
    [Range(0.0f, 1.0f)][Tooltip("Amplitude fade exponential falloff. This attenuates the above (linear) fade-off exponentially, creating more of a pulsed effect. Warning: this setting might be taken over by AudioLinkController")]
    public float fadeExpFalloff = 0.3f;

    [Header("Internal")]
    public Material audioMaterial;
    public GameObject audioTextureExport;
    public Texture2D audioData2D;                               // Texture2D reference for hacked Blit, may eventually be depreciated
    [Tooltip("Should be used with AudioLinkInput unless source is 2D. WARNING: if used with a custom 3D audio source (not through AudioLinkInput), audio reactivity will be attenuated by player position away from the Audio Source")]
    public AudioSource audioSource;
    [Tooltip("Audio reactive noodle seasoning")]
    public Color[] audioData;
    [Tooltip("The number of spectrum bands and their crossover points out of 1023 elements")]
    public float[] audioBands = {0f, 0.25f, 0.5f, .75f};
    [Tooltip("The gain settings of each spectrum band from 0-1")]
    public float[] audioThresholds = {0.75f, 0.5f, 0.4f, 0.5f};

    float[] _spectrumValues = new float[1024];
    float[] _spectrumValuesTrim = new float[1023];
    float[] _audioFrames = new float[1023*4];
    float[] _samples0 = new float[1023];
    float[] _samples1 = new float[1023];
    float[] _samples2 = new float[1023];
    float[] _samples3 = new float[1023];
    
    private float _audioLinkInputVolume = 0.01f;                        // smallify input source volume, re-multiplied by AudioSpectrum.shader
    private bool _audioSource2D = false;

    void Start()
    {
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

        #if UNITY_EDITOR
        audioMaterial.SetFloatArray("_AudioBands", audioBands);
        audioMaterial.SetFloatArray("_AudioThresholds", audioThresholds);
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
        audioMaterial.SetFloatArray("_AudioBands", audioBands);
        audioMaterial.SetFloatArray("_AudioThresholds", audioThresholds);
        audioMaterial.SetFloat("_Gain", gain);
        audioMaterial.SetFloat("_FadeLength", fadeLength);
        audioMaterial.SetFloat("_FadeExpFalloff", fadeExpFalloff);
        audioMaterial.SetFloat("_Bass", bass);
        audioMaterial.SetFloat("_Treble", treble);
        audioMaterial.SetFloat("_ContrastSlope", contrastSlope);
        audioMaterial.SetFloat("_ContrastOffset", contrastOffset);
        audioMaterial.SetFloat("_LogAttenuation", logAttenuation);
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
