using System;
using System.Collections.Immutable;
using UdonSharp;
using UdonSharpEditor;
using UnityEditor;
using UnityEngine;
using VRC.Udon;
using VRC.Udon.Common;
using VRC.Udon.Common.Interfaces;
using VRCAudioLink;

#if !COMPILER_UDONSHARP && UNITY_EDITOR && UDON
    [CustomEditor(typeof(AudioLink))]
    public class AudioLinkEditor : UnityEditor.Editor
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
                if (!behaviour.programSource) continue;
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