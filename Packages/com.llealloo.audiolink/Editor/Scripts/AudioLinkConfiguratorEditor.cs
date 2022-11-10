#if UNITY_EDITOR
  using System.IO;
  using UnityEditor;
  using UnityEngine;
  using VRCAudioLink;
#if UNITY_2021_1_OR_NEWER
  using UnityEditor.SceneManagement;
#else
  using UnityEditor.Experimental.SceneManagement;
#endif
#if UDONSHARP
  using UdonSharp;
  using UdonSharpEditor;
  using VRC.SDK3.Components;
  using VRC.SDK3.Video.Components.AVPro;
  using VRC.Udon;
#endif

[CustomEditor(typeof(AudioLinkAutoConfigurator))]
  public class AudioLinkConfiguratorEditor : UnityEditor.Editor
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
      #if UDONSHARP
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
      if (audioMaterial != null) audioMaterial.objectReferenceValue = t.audioMaterial;
      if (audioMaterialInLeft != null) audioMaterialInLeft.objectReferenceValue = t.audioMaterialInLeft;
      if (audioMaterialInRight != null) audioMaterialInRight.objectReferenceValue = t.audioMaterialInRight;
      if (audioTextureExport != null) audioTextureExport.objectReferenceValue = t.audioTextureExport;
      if (audioData2D != null) audioData2D.objectReferenceValue = t.audioData2d;
      if (audioSource != null) audioSource.objectReferenceValue = t.audioSource;
      if (audioDataToggle != null) audioDataToggle.boolValue = false;
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
#endif
