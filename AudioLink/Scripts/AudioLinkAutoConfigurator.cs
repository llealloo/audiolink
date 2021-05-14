#if UNITY_EDITOR
using System.IO;
using UnityEditor;
using UnityEditor.Experimental.SceneManagement;
using UnityEngine;
#if UDON
using UdonSharp;
using UdonSharpEditor;
using VRC.SDK3.Components;
using VRC.SDK3.Video.Components.AVPro;
using VRC.Udon;
#endif


public class AudioLinkAutoConfigurator : MonoBehaviour
{
  public Material audioMaterial;
  public GameObject audioTextureExport;
  public Texture2D audioData2d;
  public AudioSource audioSource;
}

[CustomEditor(typeof(AudioLinkAutoConfigurator))]
public class AudioLinkConfiguratorEditor : Editor
{
  private bool valuesSet;
  private bool showAdvanced;
  public override void OnInspectorGUI()
  {
    var t = (AudioLinkAutoConfigurator) target;
    // if we are in SCENE VIEW - self-destruct
    if (PrefabStageUtility.GetCurrentPrefabStage() == null && valuesSet) {
      DestroyImmediate(t);
      return;
    }
    base.OnInspectorGUI();
    EditorGUILayout.LabelField("This script can be safely removed", new GUIStyle("helpBox"));

    // if we are in PREFAB EDIT mode - we keep the configurator
    #if UDON
    if (PrefabStageUtility.GetCurrentPrefabStage() != null) {
      if (GUILayout.Button("Remove Configurator")) {
        DestroyImmediate(t);
        return;
      }
      // if you somehow end up with an udon behaviour and other world-speicifc scripts inside the prefab
      // this button can clean it up before the publish
      if (GUILayout.Button("Clean up for prefab publishing")) {
        var uBtoRemove = t.gameObject.GetComponent<UdonBehaviour>();
        if (uBtoRemove) {
          DestroyImmediate(uBtoRemove);
        }
        var spatialSource = t.audioSource.gameObject.GetComponent<VRCSpatialAudioSource>();
        if (spatialSource) {
          DestroyImmediate(spatialSource);
        }
        var avpro = t.audioSource.gameObject.GetComponent<VRCAVProVideoSpeaker>();
        if (avpro) {
          DestroyImmediate(avpro);
        }
      }
    }
    #endif
    
    #if UDON
    // this gets the UdonSharpBehaviour in WORLD projects and sets the important references
    var uB = t.gameObject.GetComponent<UdonBehaviour>();
    if (!uB) return;
    var aL = UdonSharpEditorUtility.GetProxyBehaviour(uB) as AudioLink;
    if (!aL) return;
    Undo.RecordObject(aL, "Filled the Audio Link variables");

    // if you'll want to set more values - you can do it here
    // you can even add more public fields to the configurator on the very top
    // and reference them same way, like `aL.myFloatField = t.myFloatField;`
    aL.audioMaterial = t.audioMaterial;
    aL.audioTextureExport = t.audioTextureExport;
    aL.audioData2D = t.audioData2d;
    aL.audioSource = t.audioSource;
    UdonSharpEditorUtility.CopyProxyToUdon(aL);

    #else
    // this gets the AudioLink MonoBehaviour in AVATAR projects and sets the important references
    var aL = t.gameObject.GetComponent<AudioLink>();
    if (!aL) return;
    var sO = new SerializedObject(aL);
    // we look up all the properties that have to be set
    // this uses unity's SerializedProperty syntax
    var audioMaterial = sO.FindProperty("audioMaterial");
    var audioTextureExport = sO.FindProperty("audioTextureExport");
    var audioData2D = sO.FindProperty("audioData2D");
    var audioSource = sO.FindProperty("audioSource");
    // once we get the properties, we can set them to saved values same way as we do for WORLD code
    audioMaterial.objectReferenceValue = t.audioMaterial;
    audioTextureExport.objectReferenceValue = t.audioTextureExport;
    audioData2D.objectReferenceValue = t.audioData2d;
    audioSource.objectReferenceValue = t.audioSource;
    sO.ApplyModifiedProperties();
    
    #endif
    valuesSet = true;
  }

  private void OnEnable()
  {
    var t = (AudioLinkAutoConfigurator) target;
    if (PrefabStageUtility.GetCurrentPrefabStage() != null) {
      return;
    }
    
    #if UDON
    // create WORLD project behaviour
    if (t.gameObject.GetComponent<UdonBehaviour>() != null) return;
    var uB = t.gameObject.AddComponent<UdonBehaviour>();
    var ms = MonoScript.FromMonoBehaviour(t);
    var scriptFilePath = AssetDatabase.GetAssetPath( ms );
    var fileInfo = new FileInfo(scriptFilePath);
    var dirInfo = fileInfo.Directory;
    var scriptFolder = dirInfo.ToString().Replace("\\", "/");
    var assetsPath = Application.dataPath;
    scriptFolder = scriptFolder.Replace(assetsPath, "Assets");
    var audioLinkProgram = scriptFolder + "/AudioLink.asset";
    uB.programSource = AssetDatabase.LoadAssetAtPath<UdonSharpProgramAsset>(audioLinkProgram);

    // create VRC AvPro Video Speaker
    t.audioSource.gameObject.AddComponent<VRCAVProVideoSpeaker>();

    // create VRC Spatial Audio Source
    var spatial = t.audioSource.gameObject.AddComponent<VRCSpatialAudioSource>();
    Undo.RecordObject(spatial, "Adjusted Spatialization");
    spatial.EnableSpatialization = false;
    spatial.Gain = 0;
    
    #else
    // create AVATAR project behaviour
    if (t.gameObject.GetComponent<AudioLink>() != null) return;
    var aL = t.gameObject.AddComponent<AudioLink>();
    
    #endif
  }
}
#endif
