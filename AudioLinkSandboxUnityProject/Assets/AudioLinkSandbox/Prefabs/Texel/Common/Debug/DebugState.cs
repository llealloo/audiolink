
using System;
using UdonSharp;
using UnityEngine;
using UnityEngine.UI;
using VRC.SDKBase;
using VRC.Udon;

namespace Texel
{
    [UdonBehaviourSyncMode(BehaviourSyncMode.NoVariableSync)]
    public class DebugState : UdonSharpBehaviour
    {
        public string title = "Component State";
        public float updateInterval = 1;

        [Header("UI")]
        public Text[] titleText;
        public Text[] keyCol;
        public Text[] valCol;

        int index = 0;
        string[] keys = new string[50];
        string[] values = new string[50];
        string[] keyBuffer = new string[0];
        string[] valBuffer = new string[0];

        Component[] handlers;
        int handlerCount = 0;
        string[] handlerEvents;
        string[] handlerContexts;

        int currentContext = 0;
        bool init = false;

        void Start()
        {
            _EnsureInit();
        }

        public void _EnsureInit()
        {
            if (init)
                return;

            init = true;
            _Init();
        }

        void _Init()
        {
            if (Utilities.IsValid(titleText))
            {
                for (int i = 0; i < titleText.Length; i++)
                    titleText[i].text = title;
            }

            handlers = new Component[0];
            handlerEvents = new string[0];
            handlerContexts = new string[0];

            SendCustomEventDelayedSeconds("_Update", updateInterval);
        }

        public void _Update()
        {
            _Begin();
            if (handlerCount > 0)
            { 
                _UpdateHandlers();
                if (index > 0)
                    _End();
            }

            SendCustomEventDelayedSeconds("_Update", updateInterval);
        }

        public void _Begin()
        {
            index = 0;
        }

        public void _SetValue(string key, string value)
        {
            if (keys.Length == index)
            {
                keys = (string[])_SizeArray(keys, typeof(string), index + 50);
                values = (string[])_SizeArray(values, typeof(string), index + 50);
            }

            if (handlerCount > 1)
                keys[index] = $"{handlerContexts[currentContext]}:{key}";
            else
                keys[index] = key;
            values[index] = value;
            index += 1;
        }

        public void _End()
        {
            if (keyBuffer.Length != index)
            {
                keyBuffer = new string[index];
                valBuffer = new string[index];
            }

            Array.Copy(keys, keyBuffer, index);
            Array.Copy(values, valBuffer, index);

            string joinedKey = string.Join("\n", keyBuffer);
            string joinedVal = string.Join("\n", valBuffer);

            for (int i = 0; i < keyCol.Length; i++)
            {
                keyCol[i].text = joinedKey;
                valCol[i].text = joinedVal;
            }
        }

        public void _Regsiter(Component handler, string eventName, string context)
        {
            if (!Utilities.IsValid(handler) || !Utilities.IsValid(eventName))
                return;

            _EnsureInit();

            for (int i = 0; i < handlerCount; i++)
            {
                if (handlers[i] == handler)
                    return;
            }

            handlers = (Component[])_AddElement(handlers, handler, typeof(Component));
            handlerEvents = (string[])_AddElement(handlerEvents, eventName, typeof(string));
            handlerContexts = (string[])_AddElement(handlerContexts, context, typeof(string));

            handlerCount += 1;
        }

        void _UpdateHandlers()
        {
            for (int i = 0; i < handlerCount; i++)
            {
                currentContext = i;
                UdonBehaviour script = (UdonBehaviour)handlers[i];
                script.SendCustomEvent(handlerEvents[i]);
            }
        }

        Array _AddElement(Array arr, object elem, Type type)
        {
            Array newArr;
            int count = 0;

            if (Utilities.IsValid(arr))
            {
                count = arr.Length;
                newArr = Array.CreateInstance(type, count + 1);
                Array.Copy(arr, newArr, count);
            }
            else
                newArr = Array.CreateInstance(type, 1);

            newArr.SetValue(elem, count);
            return newArr;
        }

        Array _SizeArray(Array arr, Type type, int size)
        {
            Array newArr;

            if (Utilities.IsValid(arr))
            {
                newArr = Array.CreateInstance(type, size);
                Array.Copy(arr, newArr, Math.Min(arr.Length, size));
            }
            else
                newArr = Array.CreateInstance(type, size);

            return newArr;
        }
    }
}
