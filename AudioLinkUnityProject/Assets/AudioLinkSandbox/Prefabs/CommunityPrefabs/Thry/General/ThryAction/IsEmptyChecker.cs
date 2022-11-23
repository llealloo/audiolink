
using Thry.General;
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

namespace Thry.Udon.Action
{
    [UdonBehaviourSyncMode(BehaviourSyncMode.None)]
    public class IsEmptyChecker : UdonSharpBehaviour
    {
        public ThryAction _locker;
        public UnityEngine.UI.Text _insideList; 

        Collider _collider;
        VRCPlayerApi[] players;
        int count = 0;

        bool _isValidating = true;

        private void Start()
        {
            _collider = GetComponent<Collider>();
            players = new VRCPlayerApi[90];
            SendCustomEventDelayedSeconds(nameof(Validate), 5);
        }

        public void Validate()
        {
            ValidatePlayers();
            if (Networking.IsOwner(_locker.gameObject) && count == 0) _locker.SetBool(false);

            _isValidating = count > 0;
            if (_isValidating)
                SendCustomEventDelayedSeconds(nameof(Validate), 60);
        }

        public override void OnPlayerTriggerEnter(VRCPlayerApi player)
        {
            if (player.GetPlayerTag("in room") == "true") return; //done because using chairs you can trigger this multiple times without triggering the exit event
            player.SetPlayerTag("in room", "true");

            players[count++] = player;
            if (!_isValidating)
            {
                SendCustomEventDelayedSeconds(nameof(Validate), 60);
                _isValidating = true;
            }
            UpdateList();
        }

        public override void OnPlayerTriggerExit(VRCPlayerApi player)
        {
            player.SetPlayerTag("in room", "false");

            for (int i = 0; i < count; i++)
            {
                if (players[i] == player)
                {
                    players[i] = players[--count];
                    if (Networking.IsOwner(_locker.gameObject) && count == 0) _locker.SetBool(false);
                    UpdateList();
                }
            }
        }

        public void ValidatePlayers()
        {
            for (int i = 0; i < count; i++)
            {
                if (Utilities.IsValid(players[i]) == false)
                {
                    players[i] = players[--count];
                    UpdateList();
                }
            }
        }

        void UpdateList()
        {
            if (_insideList == null) return;
            string s = "";
            for (int i = 0; i < count; i++)
                if (Utilities.IsValid(players[i]))
                    s += players[i].displayName+ "\n";
            _insideList.text = s;
        }

    }
}