// SPDX-License-Identifier: MIT
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;

namespace makihiro.PickupObjectFollowPlayer.Scripts
{
    public class PickupObjectFollowPlayer : UdonSharpBehaviour
    {
        [SerializeField] public Renderer mesh;
        [SerializeField] public Material followed;
        [SerializeField] public Material unfollowed;
        private Vector3 dPos;
        private Quaternion dRot;
        private bool isFollowed;

        //Double click
        private const float clickTimeInterval = 0.2184f;
        private bool useDoubleClick = true;
        private float prevClickTime;

        private void Update()
        {
            if (!isFollowed) return;
            var p = Networking.LocalPlayer;

            var rot = p.GetRotation();
            var t = transform;
            t.rotation = rot * dRot;
            t.position = rot * dPos + p.GetPosition();
        }

        public override void OnPickupUseDown()
        {
            if (isFollowed) return;
            if (useDoubleClick && Time.time - prevClickTime < clickTimeInterval)
            {
                prevClickTime = 0f;
                mesh.material = followed;
                isFollowed = true;
                var pick = (VRC_Pickup)gameObject.GetComponent(typeof(VRC_Pickup));
                pick.Drop();

                var p = Networking.LocalPlayer;
                var t = transform;
                var rot = Quaternion.Inverse(p.GetRotation());
                dPos = rot * (t.position - p.GetPosition());
                dRot = rot * t.rotation;
            }
            else
            {
                prevClickTime = Time.time;
            }
            
            
        }

        public override void OnPickup()
        {
            if (!isFollowed) return;
            mesh.material = unfollowed;
            isFollowed = false;
        }
    }
}