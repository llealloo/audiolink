
using System;
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

namespace Texel
{
    [AddComponentMenu("Texel/Access Control")]
    [UdonBehaviourSyncMode(BehaviourSyncMode.Manual)]
    [DefaultExecutionOrder(-1)]
    public class AccessControl : UdonSharpBehaviour
    {
        [Header("Optional Components")]
        [Tooltip("Log debug statements to a world object")]
        public DebugLog debugLog;

        [Header("Access Options")]
        public bool allowInstanceOwner = true;
        public bool allowMaster = true;
        public bool restrictMasterIfOwnerPresent = false;
        public bool allowWhitelist = false;
        public bool allowAnyone = false;

        [Header("Default Options")]
        [Tooltip("Whether ACL is enforced.  When not enforced, access is always given.")]
        public bool enforce = true;
        [Tooltip("Write out debug info to VRChat log")]
        public bool debugLogging = false;

        [Header("Access Whitelist")]
        [Tooltip("A list of admin users who have access when allow whitelist is enabled")]
        public string[] userWhitelist;

        const int RESULT_ALLOW = 1;
        const int RESULT_PASS = 0;
        const int RESULT_DENY = -1;

        bool _localPlayerWhitelisted = false;
        bool _localPlayerMaster = false;
        bool _localPlayerInstanceOwner = false;
        bool _localCalculatedAccess = false;

        bool _worldHasOwner = false;
        VRCPlayerApi[] _playerBuffer = new VRCPlayerApi[100];

        UdonBehaviour cachedAccessHandler;
        Component[] accessHandlers;
        int accessHandlerCount = 0;
        string[] accessHandlerEvents;
        string[] accessHandlerParams;
        string[] accessHandlerResults;

        Component[] validateHandlers;
        int validateHandlerCount = 0;
        string[] validateHandlerEvents;

        void Start()
        {
            VRCPlayerApi player = Networking.LocalPlayer;
            if (Utilities.IsValid(player))
            {
                if (_PlayerWhitelisted(player))
                    _localPlayerWhitelisted = true;

                _localPlayerMaster = player.isMaster;
                _localPlayerInstanceOwner = player.isInstanceOwner;
            }

            if (allowInstanceOwner && _localPlayerInstanceOwner)
                _localCalculatedAccess = true;
            if (allowWhitelist && _localPlayerWhitelisted)
                _localCalculatedAccess = true;
            if (allowAnyone)
                _localCalculatedAccess = true;

            DebugLog("Setting up access");
            if (allowInstanceOwner)
                DebugLog($"Instance Owner: {_localPlayerInstanceOwner}");
            if (allowMaster)
                DebugLog($"Instance Master: {_localPlayerMaster}");
            if (allowWhitelist)
                DebugLog($"Whitelist: {_localPlayerWhitelisted}");
            if (allowAnyone)
                DebugLog($"Anyone: True");

            _SearchInstanceOwner();
        }

        public override void OnPlayerJoined(VRCPlayerApi player)
        {
            _SearchInstanceOwner();
            _CallValidateHandlers();
        }

        public override void OnPlayerLeft(VRCPlayerApi player)
        {
            _SearchInstanceOwner();
            _CallValidateHandlers();
        }

        void _SearchInstanceOwner()
        {
            int playerCount = VRCPlayerApi.GetPlayerCount();
            _playerBuffer = VRCPlayerApi.GetPlayers(_playerBuffer);

            _worldHasOwner = false;
            for (int i = 0; i < playerCount; i++)
            {
                VRCPlayerApi player = _playerBuffer[i];
                if (Utilities.IsValid(player) && player.IsValid() && player.isInstanceOwner)
                {
                    _worldHasOwner = true;
                    break;
                }
            }
        }

        public void _Enforce(bool state)
        {
            enforce = state;
            _CallValidateHandlers();
        }

        public bool _PlayerWhitelisted(VRCPlayerApi player)
        {
            if (!Utilities.IsValid(userWhitelist))
                return false;

            string playerName = player.displayName;
            foreach (string user in userWhitelist)
            {
                if (playerName == user)
                    return true;
            }

            return false;
        }

        public bool _LocalWhitelisted()
        {
            return _localPlayerWhitelisted;
        }

        public bool _HasAccess(VRCPlayerApi player)
        {
            if (!enforce)
                return true;

            bool isMaster = Utilities.IsValid(player) ? player.isMaster : false;

            int handlerResult = _CheckAccessHandlerAccess(player);
            if (handlerResult == RESULT_DENY)
                return false;
            if (handlerResult == RESULT_ALLOW)
                return true;

            if (_localCalculatedAccess)
                return true;

            if (allowMaster && isMaster)
                return !restrictMasterIfOwnerPresent || !_worldHasOwner;

            return false;
        }

        public bool _LocalHasAccess()
        {
            return _HasAccess(Networking.LocalPlayer);
        }

        // One or more registered access handlers have a chance to force-allow or force-deny access for a player.
        // If a handler has no preference, it should return RESULT_PASS (0) to allow the next handler to make a decision
        // or let the local access control settings take effect.

        public void _RegsiterAccessHandler(Component handler, string eventName, string playerParamVar, string resultVar)
        {
            if (!Utilities.IsValid(handler))
                return;

            for (int i = 0; i < accessHandlerCount; i++)
            {
                if (accessHandlers[i] == handler)
                    return;
            }

            accessHandlers = (Component[])_AddElement(accessHandlers, handler, typeof(Component));
            accessHandlerEvents = (string[])_AddElement(accessHandlerEvents, eventName, typeof(string));
            accessHandlerParams = (string[])_AddElement(accessHandlerParams, playerParamVar, typeof(string));
            accessHandlerResults = (string[])_AddElement(accessHandlerResults, resultVar, typeof(string));

            DebugLog($"Registered access handler {eventName}");

            cachedAccessHandler = (UdonBehaviour)handler;

            accessHandlerCount += 1;
        }

        // Validate handlers are called when access controller thinks permissions may have changed.  Can be caused by
        // change in master/owner, whitelist, or request from external source

        public void _RegisterValidateHandler(Component handler, string eventName)
        {
            if (!Utilities.IsValid(handler))
                return;

            for (int i = 0; i < validateHandlerCount; i++)
            {
                if (validateHandlers[i] == handler)
                    return;
            }

            validateHandlers = (Component[])_AddElement(validateHandlers, handler, typeof(Component));
            validateHandlerEvents = (string[])_AddElement(validateHandlerEvents, eventName, typeof(string));

            DebugLog($"Registered validate handler {eventName}");

            validateHandlerCount += 1;
        }

        public void _Validate()
        {
            _CallValidateHandlers();
        }

        int _CheckAccessHandlerAccess(VRCPlayerApi player)
        {
            if (!Utilities.IsValid(accessHandlers))
                return RESULT_PASS;

            int handlerCount = accessHandlers.Length;
            if (handlerCount == 0)
                return RESULT_PASS;

            if (handlerCount == 1)
            {
                cachedAccessHandler.SetProgramVariable(accessHandlerParams[0], player);
                cachedAccessHandler.SendCustomEvent(accessHandlerEvents[0]);
                return (int)cachedAccessHandler.GetProgramVariable(accessHandlerResults[0]);
            }

            for (int i = 0; i < handlerCount; i++)
            {
                UdonBehaviour script = (UdonBehaviour)accessHandlers[i];
                if (!Utilities.IsValid(script))
                    continue;

                script.SetProgramVariable(accessHandlerParams[i], player);
                script.SendCustomEvent(accessHandlerEvents[i]);
                int result = (int)script.GetProgramVariable(accessHandlerResults[i]);
                if (result == RESULT_PASS)
                    continue;

                return result;
            }

            return RESULT_PASS;
        }

        void _CallValidateHandlers()
        {
            for (int i = 0; i < validateHandlerCount; i++)
            {
                UdonBehaviour script = (UdonBehaviour)validateHandlers[i];
                if (!Utilities.IsValid(script))
                    continue;

                script.SendCustomEvent(validateHandlerEvents[i]);
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

        void DebugLog(string message)
        {
            if (!debugLogging)
                Debug.Log("[Texel:AccessControl] " + message);
            if (Utilities.IsValid(debugLog))
                debugLog._Write("AccessControl", message);
        }
    }
}
