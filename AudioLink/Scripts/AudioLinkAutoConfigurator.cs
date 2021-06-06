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

namespace VRCAudioLink
{
  public class AudioLinkAutoConfigurator : MonoBehaviour
  {
    public Material audioMaterial;
    public Material audioMaterialInLeft;
    public Material audioMaterialInRight;
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
      if (PrefabStageUtility.GetCurrentPrefabStage() == null && valuesSet)
      {
        DestroyImmediate(t);
        return;
      }

      base.OnInspectorGUI();
      if (PrefabStageUtility.GetCurrentPrefabStage() == null)
      {
        EditorGUILayout.LabelField("This script can be safely removed", new GUIStyle("helpBox"));
      }

      // if we are in PREFAB EDIT mode - we keep the configurator
      #if UDON
          if (PrefabStageUtility.GetCurrentPrefabStage() != null) {
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

      // this gets the AudioLink MonoBehaviour in AVATAR projects and sets the important references
      var aL = t.gameObject.GetComponent<AudioLink>();
      if (!aL) return;
      var sO = new SerializedObject(aL);
      // we look up all the properties that have to be set
      // this uses unity's SerializedProperty syntax
      var audioMaterial = sO.FindProperty("audioMaterial");
      var audioMaterialInLeft = sO.FindProperty("audioMaterialInLeft");
      var audioMaterialInRight = sO.FindProperty("audioMaterialInRight");
      var audioTextureExport = sO.FindProperty("audioTextureExport");
      var audioData2D = sO.FindProperty("audioData2D");
      var audioSource = sO.FindProperty("audioSource");
      var audioDataToggle = sO.FindProperty("audioDataToggle");
      // once we get the properties, we can set them to saved values same way as we do for WORLD code
      audioMaterial.objectReferenceValue = t.audioMaterial;
      audioMaterialInLeft.objectReferenceValue = t.audioMaterialInLeft;
      audioMaterialInRight.objectReferenceValue = t.audioMaterialInRight;
      audioTextureExport.objectReferenceValue = t.audioTextureExport;
      audioData2D.objectReferenceValue = t.audioData2d;
      audioSource.objectReferenceValue = t.audioSource;
      audioDataToggle.boolValue = false;
      sO.ApplyModifiedProperties();

      valuesSet = true;
    }

    private void OnEnable()
    {
      var t = (AudioLinkAutoConfigurator) target;
      if (PrefabStageUtility.GetCurrentPrefabStage() != null)
      {
        return;
      }

      // create AVATAR project behaviour
      if (t.gameObject.GetComponent<AudioLink>() != null) return;
      var aL = t.gameObject.AddComponent<AudioLink>();
    }
  }
}
#endif