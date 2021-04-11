
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;
using UnityEngine.UI;
using System;

#if !COMPILER_UDONSHARP && UNITY_EDITOR
using UnityEditor;
using UdonSharpEditor;
using VRC.Udon;
using VRC.Udon.Common;
using VRC.Udon.Common.Interfaces;
using System.Collections.Immutable;
#endif

public class AudioLink : UdonSharpBehaviour
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
    [Tooltip("Using other audio sources could lead to unepexcted behavior.")]
    public AudioSource audioSource;
    [Tooltip("Audio reactive noodle seasoning")]
    public Color[] audioData;
    [Tooltip("The number of spectrum bands and their crossover points")]
    public float[] spectrumBands = {20f, 100f, 500f, 2500f};

    float[] _spectrumValues = new float[1024];
    float[] _spectrumValuesTrim = new float[1023];
    float[] _lut;
    float[] _chunks;
    
    private float _inputVolume = 0.01f;                        // smallify input source volume, re-multiplied by AudioSpectrum.shader

    void Start()
    {
        UpdateSettings();
        gameObject.SetActive(true);                             // client disables extra cameras, so set it true
        transform.position = new Vector3(0f, 10000000f, 0f);    // keep this in a far away place
        audioSource.volume = _inputVolume;
        audioTextureExport.SetActive(audioTextureToggle);
    }

    private void Update()
    {
        if (audioSource == null) return;
        audioSource.GetSpectrumData(_spectrumValues, 0, FFTWindow.Hamming);
        Array.Copy(_spectrumValues, 0, _spectrumValuesTrim, 0, 1023);
        audioMaterial.SetFloatArray("Spectrum", _spectrumValuesTrim);
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
        UpdateLUT();
        audioTextureExport.SetActive(audioTextureToggle);
        audioMaterial.SetFloatArray("Lut", _lut);
        audioMaterial.SetFloatArray("Chunks", _chunks);
        audioMaterial.SetFloat("_Gain", gain);
        audioMaterial.SetFloat("_FadeLength", fadeLength);
        audioMaterial.SetFloat("_FadeExpFalloff", fadeExpFalloff);
        audioMaterial.SetFloat("_Bass", bass);
        audioMaterial.SetFloat("_Treble", treble);
        audioMaterial.SetFloat("_ContrastSlope", contrastSlope);
        audioMaterial.SetFloat("_ContrastOffset", contrastOffset);
        audioMaterial.SetFloat("_LogAttenuation", logAttenuation);
    }

    private void UpdateLUT()
    {
        _lut = new float[spectrumBands.Length];
        _chunks = new float[spectrumBands.Length];
        for(var i=0; i<spectrumBands.Length; i++)
        {
            spectrumBands[i] = Mathf.Clamp(spectrumBands[i], 20f, 20000f);
            float bandStart = Mathf.Floor(Remap(spectrumBands[i], 20f, 20000f, 0f, 1023f));
            float bandEnd;
            if(i != spectrumBands.Length-1) 
            { 
                bandEnd = Mathf.Floor(Remap(spectrumBands[i+1], 20f, 20000f, 0f, 1023f)); 
            } else { 
                bandEnd = 1023f; 
            }
            _lut[i] = bandStart;
            _chunks[i] = bandEnd - bandStart;
            Debug.Log("Band " + i.ToString() + ": " + bandStart.ToString() + ", " + _chunks[i].ToString());
        }
    }

    private float Remap(float t, float a, float b, float u, float v)
    {
        return ( (t-a) / (b-a) ) * (v-u) + u;
    }
}




#if !COMPILER_UDONSHARP && UNITY_EDITOR
[CustomEditor(typeof(AudioLink))]
public class AudioLinkEditor : Editor
{
    public override void OnInspectorGUI()
    {
        if (UdonSharpGUI.DrawDefaultUdonSharpBehaviourHeader(target)) return;
        EditorGUILayout.Space();
        if (GUILayout.Button(new GUIContent("Link all " + /*AudioReactiveObjectsCount().ToString() +*/ "sound reactive objects to this AudioLink", "Links all UdonBehaviours with 'audioLink' parameter to this object."))) { LinkAll(); }
        EditorGUILayout.Space();
        base.OnInspectorGUI();
    }

    /*int AudioReactiveObjectsCount()
    {
        int numObjects = 0;
        UdonBehaviour[] allBehaviours = UnityEngine.Object.FindObjectsOfType<UdonBehaviour>();
        foreach (UdonBehaviour behaviour in allBehaviours)
        {
            //Debug.Log("Counting a behaviour");
            var program = behaviour.programSource.SerializedProgramAsset.RetrieveProgram();
            ImmutableArray<string> exportedSymbolNames = program.SymbolTable.GetExportedSymbols();
            foreach (string exportedSymbolName in exportedSymbolNames)
            {
                if (exportedSymbolName.Equals("audioLink"))
                {
                    numObjects++;
                }
            }
        }
        return numObjects;
    }*/

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
                    //Debug.Log(behaviour.name);
                    var variableValue = UdonSharpEditorUtility.GetBackingUdonBehaviour((UdonSharpBehaviour)target);
                    System.Type symbolType = program.SymbolTable.GetSymbolType(exportedSymbolName);
                    if (!behaviour.publicVariables.TrySetVariableValue("audioLink", variableValue))
                    {
                        if (!behaviour.publicVariables.TryAddVariable(CreateUdonVariable(exportedSymbolName, variableValue, symbolType)))
                        {
                            Debug.LogError($"Failed to set public variable '{exportedSymbolName}' value.");
                        }
                        //var proxy = UdonSharpEditorUtility.GetProxyBehaviour(behaviour);
                        //Debug.Log(proxy);
                        //proxy.UpdateProxy();

                        if(PrefabUtility.IsPartOfPrefabInstance(behaviour))
                        {
                            PrefabUtility.RecordPrefabInstancePropertyModifications(behaviour);
                        }
                    }
                }
            }
        }
        //UnityEditor.SceneManagement.EditorSceneManager.MarkSceneDirty(UdonSharpEditorUtility.GetBackingUdonBehaviour((UdonSharpBehaviour)target).gameObject.scene);
    }

    IUdonVariable CreateUdonVariable(string symbolName, object value, System.Type type)
    {
        System.Type udonVariableType = typeof(UdonVariable<>).MakeGenericType(type);
        return (IUdonVariable)Activator.CreateInstance(udonVariableType, symbolName, value);
    }
    
}
#endif




