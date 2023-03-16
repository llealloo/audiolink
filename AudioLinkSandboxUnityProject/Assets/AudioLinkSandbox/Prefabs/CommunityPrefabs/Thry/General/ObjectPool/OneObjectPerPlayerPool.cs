
using UdonSharp;
using UnityEngine;
using VRC.SDK3.Components;
using VRC.SDKBase;
using VRC.Udon;

namespace Thry.ObjectPool
{
    public class OneObjectPerPlayerPool : UdonSharpBehaviour
    {
        public VRCObjectPool _objectPool;

        [HideInInspector]
        public GameObject LocalGameObject;

        [HideInInspector]
        public UdonBehaviour LocalBehaviour;

        bool hasToInit = true;
        int check = 0;

        private void Update()
        {
            if (hasToInit)
            {
                if(Networking.IsOwner(_objectPool.Pool[check]) && _objectPool.Pool[check].activeSelf)
                {
                    LocalGameObject = _objectPool.Pool[check];
                    LocalBehaviour = (UdonBehaviour)LocalGameObject.GetComponent(typeof(UdonBehaviour));
                    hasToInit = false;
                }
                check = (check + 1) % _objectPool.Pool.Length;
            }
        }

        public override void OnPlayerJoined(VRCPlayerApi player)
        {
            if (Networking.IsMaster)
            {
                GameObject o = _objectPool.TryToSpawn();
                Networking.SetOwner(player, o);
            }
        }

        public override void OnPlayerLeft(VRCPlayerApi player)
        {
            if (Networking.IsMaster)
            {
                foreach(GameObject o in _objectPool.Pool)
                {
                    if(o.activeSelf && Networking.IsOwner(player, o)) _objectPool.Return(o);
                }
            }
        }
    }
}