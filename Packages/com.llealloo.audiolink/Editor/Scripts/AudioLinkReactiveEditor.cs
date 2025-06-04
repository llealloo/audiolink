#if !COMPILER_UDONSHARP && UNITY_EDITOR
using UnityEditor;
using System.Collections.Generic;
using UnityEngine;
using System;
using UnityEditorInternal;

namespace AudioLink.Editor
{

    [CustomEditor(typeof(AudioReactive), true)]
    public class AudioLinkReactiveEditor : UnityEditor.Editor
    {
        private List<bool> drawersOpen = new List<bool>();

        private bool blendshapeDrawerOpen = false;
        private List<string> blendshapeNames = new List<string>();
        private ReorderableList blendshapeList;
        
        private void StandardReactiveEditor(string reactiveMessage)
        {
            SerializedProperty audioLinkProperty = serializedObject.FindProperty("audioLink");
            if (audioLinkProperty != null)
            {
                UnityEngine.Object audioLinkObject = audioLinkProperty.objectReferenceValue;
            if (audioLinkObject == null)
                EditorGUILayout.HelpBox("AudioLink is not connected!", MessageType.Warning);
            else if (!((AudioLink)audioLinkObject).audioDataToggle)
                EditorGUILayout.HelpBox("AudioLink Data Readback is DISABLED!\nPress \"Enable Readback\" on AudioLink!", MessageType.Error);
            }
            
            if (reactiveMessage.Length > 0)
                EditorGUILayout.HelpBox(reactiveMessage, MessageType.None);

            EditorGUILayout.Space();

            serializedObject.Update();

            SerializedProperty serializedProperties = serializedObject.GetIterator();

            int drawerCounter = 0;
            int drawerIndex = 0;

            while (serializedProperties.NextVisible(true))
            {
                switch (serializedProperties.propertyType)
                {
                    case SerializedPropertyType.ObjectReference:
                        EditorGUI.BeginDisabledGroup(serializedProperties.name == "m_Script");
                            EditorGUILayout.ObjectField(serializedProperties);
                        EditorGUI.EndDisabledGroup();
                        break;

                    case SerializedPropertyType.Vector3:
                        if (drawerIndex > drawersOpen.Count - 1)
                            drawersOpen.Add(false);

                        drawersOpen[drawerIndex] = EditorGUILayout.BeginFoldoutHeaderGroup(drawersOpen[drawerIndex], serializedProperties.displayName);
                        drawerCounter = 4;
                        drawerIndex++;
                        break;

                    case SerializedPropertyType.Float:
                        if (drawerCounter > 0)
                        {
                            if (drawersOpen[drawerIndex - 1])
                                serializedProperties.floatValue = EditorGUILayout.FloatField(serializedProperties.displayName, serializedProperties.floatValue);
                        }
                        else if (!serializedProperties.propertyPath.Contains("blendshape"))
                            EditorGUILayout.PropertyField(serializedProperties);
                        break;

                    case SerializedPropertyType.Integer:
                        if (serializedProperties.name == "delay")
                        {
                            bool smooth = serializedObject.FindProperty("smooth").boolValue;
                            serializedProperties.intValue = EditorGUILayout.IntSlider(smooth ? "Smoothing (0 - 15)" : "Delay (0 - 127)", serializedProperties.intValue, 0, smooth ? 15 : 127);
                        }
                        else if (!serializedProperties.propertyPath.Contains("blendshape"))
                            EditorGUILayout.PropertyField(serializedProperties);
                        break;

                    case SerializedPropertyType.ArraySize:
                        break;

                    case SerializedPropertyType.Generic:
                        if (!serializedProperties.propertyPath.Contains("blendshape"))
                            EditorGUILayout.PropertyField(serializedProperties);
                        break;

                    default:
                        EditorGUILayout.PropertyField(serializedProperties);
                        break;
                }

                if (drawerCounter > 0)
                {
                    drawerCounter--;
                }
                else EditorGUILayout.EndFoldoutHeaderGroup();

                serializedObject.ApplyModifiedProperties();
            }

        }

        private void BlendshapeReactiveEditor()
        {
            blendshapeDrawerOpen = EditorGUILayout.BeginFoldoutHeaderGroup(blendshapeDrawerOpen, "Blendshapes");

            if (blendshapeDrawerOpen)
            {

                SkinnedMeshRenderer blendshapeMeshRenderer = Selection.activeGameObject.GetComponent<SkinnedMeshRenderer>();

                if (blendshapeMeshRenderer != null)
                    if (blendshapeMeshRenderer.sharedMesh != null)
                    {
                        Mesh blendshapeMesh = blendshapeMeshRenderer.sharedMesh;

                        if (blendshapeMesh.blendShapeCount != blendshapeNames.Count)
                        {
                            blendshapeNames.Clear();
                            for (int indx = 0; indx < blendshapeMesh.blendShapeCount; indx++)
                                blendshapeNames.Add(blendshapeMesh.GetBlendShapeName(indx));
                        }

                        SerializedProperty blendshapeIDs = serializedObject.FindProperty(nameof(AudioReactiveBlendshapes.blendshapeIDs));
                        SerializedProperty blendshapeFromWeights = serializedObject.FindProperty(nameof(AudioReactiveBlendshapes.blendshapeFromWeights));
                        SerializedProperty blendshapeToWeights = serializedObject.FindProperty(nameof(AudioReactiveBlendshapes.blendshapeToWeights));

                        EditorGUILayout.Space();

                        serializedObject.Update();

                        if (blendshapeList == null)
                            blendshapeList = new ReorderableList(new List<String>(), typeof(String));

                        blendshapeList.drawElementCallback = (Rect rect, int indx, bool active, bool focused) =>
                        {

                            int blendshapeID = blendshapeIDs.GetArrayElementAtIndex(indx).intValue;

                            Rect dropdownRect = rect;
                            Rect floatRect = rect;
                            Rect sliderRect = rect;

                            dropdownRect.width = 80;

                            floatRect.width = 40;
                            floatRect.height -= 6;
                            floatRect.x += 85;

                            sliderRect.width = sliderRect.width - (85 + 45 + 45);
                            sliderRect.x += 85 + 45;

                            blendshapeIDs.GetArrayElementAtIndex(indx).intValue = EditorGUI.Popup(dropdownRect, blendshapeIDs.GetArrayElementAtIndex(indx).intValue, blendshapeNames.ToArray());

                            float fromMinimum = blendshapeFromWeights.GetArrayElementAtIndex(indx).floatValue;
                            float toMaximum = blendshapeToWeights.GetArrayElementAtIndex(indx).floatValue;

                            fromMinimum = EditorGUI.FloatField(floatRect, fromMinimum);

                            EditorGUI.MinMaxSlider(sliderRect, ref fromMinimum, ref toMaximum, 0f, 1f);

                            floatRect.x += sliderRect.width + 50;

                            toMaximum = EditorGUI.FloatField(floatRect, toMaximum);

                            blendshapeFromWeights.GetArrayElementAtIndex(indx).floatValue = fromMinimum;
                            blendshapeToWeights.GetArrayElementAtIndex(indx).floatValue = toMaximum;
                        };

                        blendshapeList.onAddCallback = (ReorderableList list) =>
                        {
                            blendshapeIDs.InsertArrayElementAtIndex(blendshapeIDs.arraySize);
                            blendshapeFromWeights.InsertArrayElementAtIndex(blendshapeFromWeights.arraySize);
                            blendshapeToWeights.InsertArrayElementAtIndex(blendshapeToWeights.arraySize);

                            blendshapeIDs.GetArrayElementAtIndex(blendshapeIDs.arraySize - 1).intValue = 0;
                            blendshapeFromWeights.GetArrayElementAtIndex(blendshapeFromWeights.arraySize - 1).floatValue = 0f;
                            blendshapeToWeights.GetArrayElementAtIndex(blendshapeToWeights.arraySize - 1).floatValue = 1f;
                        };

                        blendshapeList.onRemoveCallback = (ReorderableList list) =>
                        {
                            blendshapeIDs.DeleteArrayElementAtIndex(list.index);
                            blendshapeFromWeights.DeleteArrayElementAtIndex(list.index);
                            blendshapeToWeights.DeleteArrayElementAtIndex(list.index);
                        };

                        blendshapeList.drawHeaderCallback = (Rect rect) => GUI.Label(rect, blendshapeMesh.name + " (Mesh)");
                        blendshapeList.draggable = false;

                        if (blendshapeList.list.Count != blendshapeIDs.arraySize)
                        {
                            blendshapeList.list = new List<bool>();

                            for (int indx = 0; indx < blendshapeIDs.arraySize; indx++)
                                blendshapeList.list.Add(false);
                        }

                        blendshapeList.DoLayoutList();

                        serializedObject.ApplyModifiedProperties();

                    }
                    else EditorGUILayout.LabelField("SkinnedMeshRenderer has no Mesh!");

            }

            EditorGUILayout.EndFoldoutHeaderGroup();
            
        }

        public override void OnInspectorGUI()
        {
            string scriptType = target.GetType().ToString();
            string reactiveScriptType = scriptType.Substring("AudioLink.AudioReactive".Length);

            switch (reactiveScriptType)
            {
                case "Light":
                    StandardReactiveEditor("AudioLink Reactive Light:\nChanges the Intensity or Hue of a *Realtime* Light.\n\nNote: Realtime lights are *really* compute expensive,\nplease use a Shader alternative instead.");
                    break;

                case "Object":
                    StandardReactiveEditor("AudioLink Reactive Object:\nMove, Rotate, or Scale a GameObject and it's children relative to it's inital Transform.");
                    break;

                case "Blendshapes":
                    StandardReactiveEditor("AudioLink Reactive Blendshapes:\nDrive multiple Blendshapes on a SkinnedMeshRenderer with different ranges for each Blendshape.\n\nNote: Doesn't work on VR Chat Avatars, Udon / C# only!");

                    BlendshapeReactiveEditor();
                    break;

                case "Surface":
                    StandardReactiveEditor("AudioLink Reactive Surface:\nConfigure a single instance of an AudioReactiveSurface Shader.\n\nNote: To use custom mesh, swap mesh in Mesh Filter component above.");

                    if (EditorApplication.isPlaying)
                        ((AudioReactiveSurface)target).UpdateMaterial();
                    break;

                case "SurfaceArray":
                    StandardReactiveEditor("AudioLink Reactive Surface Array:\nConfigure an array of AudioLinkSurfaces' Shader.\n\nNote: Children should have AudioReactiveSurface shader applied!");

                    if (EditorApplication.isPlaying)
                        ((AudioReactiveSurfaceArray)target).UpdateChildren();
                    break;

                default:
                    StandardReactiveEditor("");
                    break;
            }

            EditorGUILayout.Space();

        }
    }
}
#endif