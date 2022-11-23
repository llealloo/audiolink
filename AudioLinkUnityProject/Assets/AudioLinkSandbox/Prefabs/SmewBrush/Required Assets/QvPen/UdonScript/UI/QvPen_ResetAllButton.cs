using TMPro;
using UdonSharp;
using UnityEngine;
using UnityEngine.UI;
using VRC.SDKBase;
using VRC.Udon.Common.Interfaces;

namespace QvPen.UdonScript.UI
{
    [UdonBehaviourSyncMode(BehaviourSyncMode.NoVariableSync)]
    public class QvPen_ResetAllButton : UdonSharpBehaviour
    {
        [SerializeField]
        private QvPen_Settings settings;

        [SerializeField]
        private Text message;
        [SerializeField]
        private TextMeshPro messageTMP;
        [SerializeField]
        private TextMeshProUGUI messageTMPU;

        private VRCPlayerApi master = null;

        public override void OnPlayerJoined(VRCPlayerApi player)
        {
            if (master == null || player.playerId < master.playerId)
            {
                master = player;
                UpdateMessage();
            }
        }

        public override void OnOwnershipTransferred(VRCPlayerApi player)
        {
            master = player;
            UpdateMessage();
        }

        private void UpdateMessage()
        {
            if (master == null)
                return;

            var displayName = string.Empty;

            var s = master.displayName;
            var cnt = 0;
            for (var i = 0; i < s.Length; i++)
            {
                if (s[i] < 128)
                    cnt += 1;
                else
                    cnt += 2;

                if (cnt < 12)
                    displayName += s[i];
                else
                {
                    if (i == s.Length - 1)
                        displayName += s[i];
                    else
                        displayName += "...";
                    break;
                }
            }

            var messageString = $"<size=8>[Only {(master == null ? nameof(master) : displayName)}]</size>";

            if (message)
                message.text = messageString;

            if (messageTMP)
                messageTMP.text = messageString;

            if (messageTMPU)
                messageTMPU.text = messageString;
        }

        public override void Interact()
        {
            if (!Networking.IsOwner(gameObject))
                return;

            foreach (var penManager in settings.penManagers)
                if (penManager)
                    penManager.SendCustomNetworkEvent(NetworkEventTarget.All, nameof(QvPen_PenManager.ResetPen));

            foreach (var eraserManager in settings.eraserManagers)
                if (eraserManager)
                    eraserManager.SendCustomNetworkEvent(NetworkEventTarget.All, nameof(QvPen_EraserManager.ResetEraser));
        }
    }
}
