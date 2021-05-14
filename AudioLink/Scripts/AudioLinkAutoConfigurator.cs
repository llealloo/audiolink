#if UNITY_EDITOR
using System.IO;
using UnityEditor;
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
  public override void OnInspectorGUI()
  {
    var t = (AudioLinkAutoConfigurator) target;
    if (valuesSet) {
      DestroyImmediate(t);
      return;
    }
    base.OnInspectorGUI();
    
    #if UDON
    
    var uB = t.gameObject.GetComponent<UdonBehaviour>();
    if (!uB) return;
    var aL = UdonSharpEditorUtility.GetProxyBehaviour(uB) as AudioLink;
    if (!aL) return;
    Undo.RecordObject(aL, "Filled the Audio Link variables");
    aL.audioMaterial = t.audioMaterial;
    aL.audioTextureExport = t.audioTextureExport;
    aL.audioData2D = t.audioData2d;
    aL.audioSource = t.audioSource;
    UdonSharpEditorUtility.CopyProxyToUdon(aL);

    #else
    
    var aL = t.gameObject.GetComponent<AudioLink>();
    if (!aL) return;
    var sO = new SerializedObject(aL);
    var audioMaterial = sO.FindProperty("audioMaterial");
    var audioTextureExport = sO.FindProperty("audioTextureExport");
    var audioData2D = sO.FindProperty("audioData2D");
    var audioSource = sO.FindProperty("audioSource");
    if (audioMaterial.objectReferenceValue != null && audioTextureExport.objectReferenceValue != null &&
        audioData2D.objectReferenceValue != null && audioSource.objectReferenceValue != null) return;
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
    
    #if UDON
    
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
    t.audioSource.gameObject.AddComponent<VRCAVProVideoSpeaker>();
    var spatial = t.audioSource.gameObject.AddComponent<VRCSpatialAudioSource>();
    Undo.RecordObject(spatial, "Adjusted Spatialization");
    spatial.EnableSpatialization = false;
    
    #else
    
    if (t.gameObject.GetComponent<AudioLink>() != null) return;
    var aL = t.gameObject.AddComponent<AudioLink>();
    
    #endif
  }
}
#endif
