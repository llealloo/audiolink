using System.Collections.Generic;
using System.Linq;
using ABI.CCK.Components;
using ABI.CCK.Components.ScriptableObjects;
using UnityEditor;
using UnityEditor.Events;
using UnityEngine;
using UnityEngine.UI;

// Generates a CCK-only version of the AudioLink controller from the VRChat prefab.
// Needs the CVR CCK: copy into a CVR project's Assets/Editor, then AudioLink > Generate CVR Controller.
//
//   Slider --onValueChanged--> VariableBuffer --OnVariableBufferUpdate (networked, buffered)-->
//     SetPropertyByValue: AudioLink material updater, screen material updater, Slider.value
//
//   Toggle (now a Button) --onClick--> Interactable.CustomTrigger --> buffer = (buffer - 1) * -1
//     buffer comparison --> Checkmark on/off
//
//   Theme colours: 12 hidden sliders (HSV x 4 slots) --> buffers (networked, buffered) -->
//     LuaFunctionCall ApplyThemeColors (AudioLinkThemeColors.lua converts HSV to RGB)
public static class CVRControllerConverter
{
    private const string SourcePrefab = "Packages/com.llealloo.audiolink/Runtime/AudioLinkController.prefab";
    private const string OutputPrefab = "Packages/com.llealloo.audiolink/Runtime/CVRAudioLinkController.prefab";
    private const string AudioLinkMaterialPath = "Packages/com.llealloo.audiolink/Runtime/Materials/mat_AudioLink.mat";
    private const string ScreenMaterialPath = "Packages/com.llealloo.audiolink/Runtime/Materials/mat_AudioLinkControllerScreenMaterial.mat";
    private const string LogPrefix = "[CVRControllerConverter] ";

    private const int ArithmeticStatic = 0;
    private const int OperatorAdd = 0;
    private const int OperatorSubtract = 1;
    private const int OperatorMultiply = 2;
    private const int ComparisonStatic = 0;
    private const int ComparatorEqual = 0;
    private const int ComparatorNotEqual = 5;
    private const int ObjectEnable = 0;
    private const int ObjectDisable = 1;

    // Slider object, AudioLink material property, screen material property.
    private static readonly (string slider, string audioLink, string screen)[] Sliders =
    {
        ("Slider_Gain", "_Gain", "_Gain"),
        ("Slider_FadeLength", "_FadeLength", "_HitFade"),
        ("Slider_FadeExpFalloff", "_FadeExpFalloff", "_ExpFalloff"),
        ("Slider_X0", "_X0", "_X0"),
        ("Slider_X1", "_X1", "_X1"),
        ("Slider_X2", "_X2", "_X2"),
        ("Slider_X3", "_X3", "_X3"),
        ("Slider_Threshold0", "_Threshold0", "_Threshold0"),
        ("Slider_Threshold1", "_Threshold1", "_Threshold1"),
        ("Slider_Threshold2", "_Threshold2", "_Threshold2"),
        ("Slider_Threshold3", "_Threshold3", "_Threshold3"),
    };

    // Toggle object, AudioLink property, screen property, buffer value while the checkmark shows.
    // Theme mode is 0 (ColorChord) while checked and 1 (custom) while unchecked, as in ThemeColorController.
    private static readonly (string toggle, string audioLink, string screen, float checkedValue)[] Toggles =
    {
        ("Auto Gain Toggle", "_Autogain", "_AutoGain", 1f),
        ("Theme Color Toggle", "_ThemeColorMode", "_ThemeColorMode", 0f),
    };

    // No CCK equivalent yet: power would need to reach into the separate CVRAudioLink prefab.
    private static readonly string[] Hidden =
    {
        "Power Button",
    };

    private const string LuaScriptPath = "Packages/com.llealloo.audiolink/Runtime/AudioLinkThemeColors.lua";
    private const string ThemeToggle = "Theme Color Toggle";
    private const float CustomThemeMode = 1f;
    private static readonly string[] HsvChannels = { "H", "S", "V" };
    private static readonly string[] HsvSliders = { "Slider_Hue", "Slider_Saturation", "Slider_Value" };
    private static readonly string[] HsvBindings = { "Hue", "Saturation", "Value" };

    // AudioLink's default custom theme colours.
    private static readonly Color[] DefaultThemeColors = { Color.yellow, Color.blue, Color.red, Color.green };

    private static Material _audioLinkMaterial;
    private static Material _screenMaterial;
    private static readonly Dictionary<string, (CVRVariableBuffer buffer, CVRInteractable interactable)> _toggles = new Dictionary<string, (CVRVariableBuffer, CVRInteractable)>();

    [MenuItem("AudioLink/Generate CVR Controller")]
    private static void Generate()
    {
        _toggles.Clear();
        _audioLinkMaterial = AssetDatabase.LoadAssetAtPath<Material>(AudioLinkMaterialPath);
        _screenMaterial = AssetDatabase.LoadAssetAtPath<Material>(ScreenMaterialPath);

        GameObject source = AssetDatabase.LoadAssetAtPath<GameObject>(SourcePrefab);
        GameObject root = (GameObject)PrefabUtility.InstantiatePrefab(source);
        PrefabUtility.UnpackPrefabInstance(root, PrefabUnpackMode.Completely, InteractionMode.AutomatedAction);
        root.name = "CVRAudioLinkController";

        Strip(root);

        Transform parameters = new GameObject("CVR Parameters").transform;
        parameters.SetParent(root.transform, false);

        List<(CVRVariableBuffer buffer, float value)> defaults = new List<(CVRVariableBuffer, float)>();

        foreach ((string slider, string audioLink, string screen) in Sliders)
        {
            defaults.Add(ConvertSlider(root, parameters, slider, audioLink, screen));
        }

        foreach ((string toggle, string audioLink, string screen, float checkedValue) in Toggles)
        {
            defaults.Add(ConvertToggle(root, parameters, toggle, audioLink, screen, checkedValue));
        }

        defaults.AddRange(ConvertTheme(root, parameters));
        ConvertReset(root, parameters, defaults);
        ConvertHandles(root);

        foreach (string name in Hidden)
        {
            Find(root, name).SetActive(false);
        }

        PrefabUtility.SaveAsPrefabAsset(root, OutputPrefab);
        Object.DestroyImmediate(root);
        Debug.Log(LogPrefix + $"Saved {OutputPrefab}: {Sliders.Length} sliders, {Toggles.Length} toggles, reset, handles.");
    }

    // Removes AudioLink's C#, Udon, missing VRChat scripts, and every UI listener.
    private static void Strip(GameObject root)
    {
        int removed = 0;

        foreach (Transform t in root.GetComponentsInChildren<Transform>(true))
        {
            removed += GameObjectUtility.RemoveMonoBehavioursWithMissingScript(t.gameObject);

            foreach (MonoBehaviour behaviour in t.GetComponents<MonoBehaviour>())
            {
                if (behaviour.GetType().Namespace == "AudioLink")
                {
                    Object.DestroyImmediate(behaviour);
                    removed++;
                }
            }
        }

        GameObject themeColorController = Find(root, "ThemeColorController");
        Object.DestroyImmediate(themeColorController);

        foreach (Slider slider in root.GetComponentsInChildren<Slider>(true))
        {
            ClearListeners(slider.onValueChanged);
        }
        foreach (Toggle toggle in root.GetComponentsInChildren<Toggle>(true))
        {
            ClearListeners(toggle.onValueChanged);
        }
        foreach (Button button in root.GetComponentsInChildren<Button>(true))
        {
            ClearListeners(button.onClick);
        }

        Debug.Log(LogPrefix + $"Stripped {removed} scripts.");
    }

    private static void ClearListeners(UnityEngine.Events.UnityEventBase unityEvent)
    {
        for (int i = unityEvent.GetPersistentEventCount() - 1; i >= 0; i--)
        {
            UnityEventTools.RemovePersistentListener(unityEvent, i);
        }
    }

    private static (CVRVariableBuffer, float) ConvertSlider(GameObject root, Transform parameters, string name, string audioLinkProperty, string screenProperty)
    {
        Slider slider = Find(root, name).GetComponent<Slider>();
        float value = slider.value;

        (GameObject holder, CVRVariableBuffer buffer, CVRInteractable interactable) = CreateParameter(parameters, name, value, audioLinkProperty, screenProperty);

        CVRInteractableAction update = UpdateAction(holder, buffer);
        update.operations.Add(SetProperty(buffer, slider.gameObject, typeof(Slider), "value", true));
        interactable.actions.Add(update);

        UnityEventTools.AddPersistentListener(slider.onValueChanged, buffer.SetValue);
        AddPointerCollider(slider.gameObject);

        return (buffer, value);
    }

    private static (CVRVariableBuffer, float) ConvertToggle(GameObject root, Transform parameters, string name, string audioLinkProperty, string screenProperty, float checkedValue)
    {
        GameObject toggleObject = Find(root, name);
        Toggle toggle = toggleObject.GetComponent<Toggle>();
        GameObject checkmark = toggle.graphic.gameObject;
        Graphic background = toggle.targetGraphic;
        float uncheckedValue = 1f - checkedValue;
        float value = toggle.isOn ? checkedValue : uncheckedValue;

        Object.DestroyImmediate(toggle);
        Button button = toggleObject.AddComponent<Button>();
        button.targetGraphic = background;
        checkmark.SetActive(value == checkedValue);

        (GameObject holder, CVRVariableBuffer buffer, CVRInteractable interactable) = CreateParameter(parameters, name, value, audioLinkProperty, screenProperty);

        interactable.actions.Add(UpdateAction(holder, buffer));

        // 1 -> 0 and 0 -> 1 without a conditional.
        CVRInteractableAction flip = new CVRInteractableAction
        {
            actionType = CVRInteractableAction.ActionRegister.OnCustomTrigger,
            execType = CVRInteractableAction.ExecutionType.LocalNotNetworked,
        };
        flip.operations.Add(Arithmetic(buffer, OperatorSubtract, 1f));
        flip.operations.Add(Arithmetic(buffer, OperatorMultiply, -1f));
        interactable.actions.Add(flip);

        interactable.actions.Add(ShowWhen(buffer, ComparatorEqual, checkedValue, checkmark, ObjectEnable));
        interactable.actions.Add(ShowWhen(buffer, ComparatorNotEqual, checkedValue, checkmark, ObjectDisable));

        UnityEventTools.AddVoidPersistentListener(button.onClick, interactable.CustomTrigger);
        AddPointerCollider(toggleObject);

        _toggles[name] = (buffer, interactable);
        return (buffer, value);
    }

    // Colours live in twelve hidden sliders, each synced through a buffered buffer; Lua converts
    // HSV to RGB and paints the materials. Returns the hidden buffers and defaults for reset.
    private static List<(CVRVariableBuffer, float)> ConvertTheme(GameObject root, Transform parameters)
    {
        List<(CVRVariableBuffer, float)> defaults = new List<(CVRVariableBuffer, float)>();

        GameObject theme = new GameObject("Theme Colors");
        theme.transform.SetParent(parameters, false);
        CVRLuaClientBehaviour lua = theme.AddComponent<CVRLuaClientBehaviour>();
        lua.asset = LoadLuaScript();

        List<CVRBaseLuaBehaviour.BoundObject> bound = new List<CVRBaseLuaBehaviour.BoundObject>
        {
            Bind("AudioLinkMaterial", _audioLinkMaterial),
            Bind("ScreenMaterial", _screenMaterial),
        };

        // Hidden storage: H0 S0 V0 .. H3 S3 V3.
        for (int slot = 0; slot < DefaultThemeColors.Length; slot++)
        {
            Color.RGBToHSV(DefaultThemeColors[slot], out float h, out float s, out float v);
            float[] hsv = { h, s, v };

            for (int channel = 0; channel < HsvChannels.Length; channel++)
            {
                string name = HsvChannels[channel] + slot;
                GameObject storage = new GameObject(name);
                storage.transform.SetParent(theme.transform, false);
                Slider slider = storage.AddComponent<Slider>();
                slider.minValue = 0f;
                slider.maxValue = 1f;
                slider.value = hsv[channel];

                (GameObject holder, CVRVariableBuffer buffer, CVRInteractable interactable) = CreateBuffer(storage.transform, "Buffer", hsv[channel]);
                CVRInteractableAction update = new CVRInteractableAction
                {
                    actionType = CVRInteractableAction.ActionRegister.OnVariableBufferUpdate,
                    execType = CVRInteractableAction.ExecutionType.GlobalNetworkedBuffered,
                    varBufferVal = buffer,
                };
                update.operations.Add(SetProperty(buffer, storage, typeof(Slider), "value", true));
                update.operations.Add(LuaCall(theme, "ApplyThemeColors"));
                interactable.actions.Add(update);

                UnityEventTools.AddPersistentListener(slider.onValueChanged, buffer.SetValue);
                bound.Add(Bind(name, slider));
                defaults.Add((buffer, hsv[channel]));
            }
        }

        (CVRVariableBuffer themeMode, CVRInteractable themeInteractable) = _toggles[ThemeToggle];

        // Lua forces custom colours through a hidden mirror of the theme mode buffer, because Lua
        // also moves the visible HSV sliders itself and those moves must not change the mode.
        GameObject modeMirror = new GameObject("ThemeMode");
        modeMirror.transform.SetParent(theme.transform, false);
        Slider modeSlider = modeMirror.AddComponent<Slider>();
        modeSlider.minValue = 0f;
        modeSlider.maxValue = 1f;
        modeSlider.value = themeMode.defaultValue;
        UnityEventTools.AddPersistentListener(modeSlider.onValueChanged, themeMode.SetValue);
        themeInteractable.actions[0].operations.Add(SetProperty(themeMode, modeMirror, typeof(Slider), "value", true));
        bound.Add(Bind("ThemeMode", modeSlider));

        // Visible HSV sliders edit the selected slot.
        CVRInteractable edit = LocalLuaTrigger(theme.transform, "Edit", theme, "OnHsvChanged");
        for (int i = 0; i < HsvSliders.Length; i++)
        {
            Slider slider = Find(root, HsvSliders[i]).GetComponent<Slider>();
            UnityEventTools.AddVoidPersistentListener(slider.onValueChanged, edit.CustomTrigger);
            AddPointerCollider(slider.gameObject);
            bound.Add(Bind(HsvBindings[i], slider));
        }

        // Slot buttons select locally and switch to custom colours.
        for (int slot = 0; slot < DefaultThemeColors.Length; slot++)
        {
            Button button = Find(root, "Custom Color Button " + slot).GetComponent<Button>();
            CVRInteractable select = LocalLuaTrigger(theme.transform, "Select " + slot, theme, "SelectSlot" + slot);
            UnityEventTools.AddVoidPersistentListener(button.onClick, select.CustomTrigger);
            UnityEventTools.AddFloatPersistentListener(button.onClick, themeMode.SetValue, CustomThemeMode);
            AddPointerCollider(button.gameObject);
        }

        lua.boundObjects = bound.ToArray();
        return defaults;
    }

    private static CVRLuaScript LoadLuaScript()
    {
        AssetDatabase.ImportAsset(LuaScriptPath);
        CVRLuaScript script = AssetDatabase.LoadAssetAtPath<CVRLuaScript>(LuaScriptPath);
        if (script == null)
        {
            throw new System.InvalidOperationException(LogPrefix + $"{LuaScriptPath} did not import as a CVRLuaScript");
        }
        return script;
    }

    private static CVRBaseLuaBehaviour.BoundObject Bind(string name, Object thing)
    {
        return new CVRBaseLuaBehaviour.BoundObject { name = name, boundThing = thing };
    }

    private static CVRInteractable LocalLuaTrigger(Transform parent, string name, GameObject lua, string function)
    {
        GameObject holder = new GameObject(name);
        holder.transform.SetParent(parent, false);
        CVRInteractable interactable = holder.AddComponent<CVRInteractable>();
        interactable.version = CVRInteractable.LATEST_VERSION;

        CVRInteractableAction action = new CVRInteractableAction
        {
            actionType = CVRInteractableAction.ActionRegister.OnCustomTrigger,
            execType = CVRInteractableAction.ExecutionType.LocalNotNetworked,
        };
        action.operations.Add(LuaCall(lua, function));
        interactable.actions.Add(action);
        return interactable;
    }

    private static CVRInteractableActionOperation LuaCall(GameObject lua, string function)
    {
        return new CVRInteractableActionOperation
        {
            type = CVRInteractableActionOperation.ActionType.LuaFunctionCall,
            gameObjectVal = lua,
            stringVal = function,
        };
    }

    private static (GameObject, CVRVariableBuffer, CVRInteractable) CreateBuffer(Transform parent, string name, float value)
    {
        GameObject holder = new GameObject(name);
        holder.transform.SetParent(parent, false);

        CVRVariableBuffer buffer = holder.AddComponent<CVRVariableBuffer>();
        buffer.defaultValue = value;

        CVRInteractable interactable = holder.AddComponent<CVRInteractable>();
        interactable.version = CVRInteractable.LATEST_VERSION;

        return (holder, buffer, interactable);
    }

    // Reset writes each buffer back to its default: buffer * 0 + default.
    private static void ConvertReset(GameObject root, Transform parameters, List<(CVRVariableBuffer buffer, float value)> defaults)
    {
        Button button = Find(root, "Reset Button").GetComponent<Button>();

        GameObject holder = new GameObject("Reset");
        holder.transform.SetParent(parameters, false);
        CVRInteractable interactable = holder.AddComponent<CVRInteractable>();
        interactable.version = CVRInteractable.LATEST_VERSION;

        CVRInteractableAction reset = new CVRInteractableAction
        {
            actionType = CVRInteractableAction.ActionRegister.OnCustomTrigger,
            execType = CVRInteractableAction.ExecutionType.LocalNotNetworked,
        };
        foreach ((CVRVariableBuffer buffer, float value) in defaults)
        {
            reset.operations.Add(Arithmetic(buffer, OperatorMultiply, 0f));
            reset.operations.Add(Arithmetic(buffer, OperatorAdd, value));
        }
        interactable.actions.Add(reset);

        UnityEventTools.AddVoidPersistentListener(button.onClick, interactable.CustomTrigger);
        AddPointerCollider(button.gameObject);
    }

    private static void ConvertHandles(GameObject root)
    {
        foreach (string name in new[] { "LeftHandle", "RightHandle" })
        {
            GameObject handle = Find(root, name);
            CVRPickupObject pickup = handle.AddComponent<CVRPickupObject>();
            pickup.version = CVRPickupObject.LATEST_VERSION;
            handle.AddComponent<CVRObjectSync>();
        }
    }

    // Buffer, interactable and AudioLink material updater on the holder; screen updater on a child,
    // so each SetPropertyByValue resolves to exactly one updater.
    private static (GameObject, CVRVariableBuffer, CVRInteractable) CreateParameter(Transform parameters, string name, float value, string audioLinkProperty, string screenProperty)
    {
        GameObject holder = new GameObject(name);
        holder.transform.SetParent(parameters, false);

        CVRVariableBuffer buffer = holder.AddComponent<CVRVariableBuffer>();
        buffer.defaultValue = value;

        CVRInteractable interactable = holder.AddComponent<CVRInteractable>();
        interactable.version = CVRInteractable.LATEST_VERSION;

        AddUpdater(holder, _audioLinkMaterial, audioLinkProperty, value);

        GameObject screen = new GameObject("Screen");
        screen.transform.SetParent(holder.transform, false);
        AddUpdater(screen, _screenMaterial, screenProperty, value);

        return (holder, buffer, interactable);
    }

    private static void AddUpdater(GameObject target, Material material, string property, float value)
    {
        CVRGlobalMaterialPropertyUpdater updater = target.AddComponent<CVRGlobalMaterialPropertyUpdater>();
        updater.material = material;
        updater.propertyName = property;
        updater.propertyType = CVRGlobalMaterialPropertyUpdater.PropertyType.paramFloat;
        updater.floatValue = value;
    }

    // Networked and buffered so late joiners receive the current value.
    private static CVRInteractableAction UpdateAction(GameObject holder, CVRVariableBuffer buffer)
    {
        CVRInteractableAction action = new CVRInteractableAction
        {
            actionType = CVRInteractableAction.ActionRegister.OnVariableBufferUpdate,
            execType = CVRInteractableAction.ExecutionType.GlobalNetworkedBuffered,
            varBufferVal = buffer,
        };
        action.operations.Add(SetProperty(buffer, holder, typeof(CVRGlobalMaterialPropertyUpdater), "floatValue", false));
        action.operations.Add(SetProperty(buffer, holder.transform.Find("Screen").gameObject, typeof(CVRGlobalMaterialPropertyUpdater), "floatValue", false));
        return action;
    }

    private static CVRInteractableActionOperation SetProperty(CVRVariableBuffer buffer, GameObject target, System.Type component, string member, bool isProperty)
    {
        return new CVRInteractableActionOperation
        {
            type = CVRInteractableActionOperation.ActionType.SetPropertyByValue,
            varBufferVal = buffer,
            gameObjectVal = target,
            stringVal3 = component.AssemblyQualifiedName,
            stringVal4 = member,
            boolVal = isProperty,
        };
    }

    // result = buffer <operator> value, written back into the same buffer.
    private static CVRInteractableActionOperation Arithmetic(CVRVariableBuffer buffer, int op, float value)
    {
        return new CVRInteractableActionOperation
        {
            type = CVRInteractableActionOperation.ActionType.VariableBufferArithmetic,
            floatVal = ArithmeticStatic,
            varBufferVal = buffer,
            floatVal2 = op,
            floatVal3 = value,
            varBufferVal3 = buffer,
        };
    }

    private static CVRInteractableAction ShowWhen(CVRVariableBuffer buffer, int comparator, float value, GameObject target, int state)
    {
        CVRInteractableAction action = new CVRInteractableAction
        {
            actionType = CVRInteractableAction.ActionRegister.OnVariableBufferComparision,
            execType = CVRInteractableAction.ExecutionType.LocalNotNetworked,
            floatVal = ComparisonStatic,
            varBufferVal = buffer,
            floatVal2 = comparator,
            floatVal3 = value,
        };
        CVRInteractableActionOperation show = new CVRInteractableActionOperation
        {
            type = CVRInteractableActionOperation.ActionType.SetGameObjectActive,
            floatVal = state,
        };
        show.targets.Add(target);
        action.operations.Add(show);
        return action;
    }

    // CVR's pointer hits colliders, not graphics; sized to the control's rect as in the old prefab.
    private static void AddPointerCollider(GameObject target)
    {
        if (target.GetComponent<Collider>() != null)
        {
            return;
        }

        RectTransform rect = (RectTransform)target.transform;
        BoxCollider collider = target.AddComponent<BoxCollider>();
        collider.isTrigger = true;
        collider.size = new Vector3(rect.rect.width, rect.rect.height, 1f);
        collider.center = rect.rect.center;
    }

    private static GameObject Find(GameObject root, string name)
    {
        Transform found = root.GetComponentsInChildren<Transform>(true).FirstOrDefault(t => t.name == name);
        if (found == null)
        {
            throw new System.InvalidOperationException(LogPrefix + $"'{name}' not found in {SourcePrefab}");
        }
        return found.gameObject;
    }
}
