using TMPro;
using UdonSharp;
using UnityEngine;
using UnityEngine.UI;
using VRC.SDKBase;
using VRC.Udon.Common;
using VRC.Udon.Common.Interfaces;

#pragma warning disable IDE0090, IDE1006

namespace QvPen.UdonScript
{
    [DefaultExecutionOrder(20)]
    [UdonBehaviourSyncMode(BehaviourSyncMode.Manual)]
    public class QvPen_PenManager : UdonSharpBehaviour
    {
        [SerializeField]
        private QvPen_Pen pen;
        
        public Gradient colorGradient = new Gradient();

        public float inkWidth = 0.005f;

        // Layer 0 : Default
        // Layer 9 : Player
        public int inkMeshLayer = 0;
        public int inkColliderLayer = 9;

        public Material pcInkMaterial;
        public Material questInkMaterial;

        [SerializeField]
        private GameObject respawnButton;
        [SerializeField]
        private GameObject clearButton;
        [SerializeField]
        private GameObject inUseUI;

        [SerializeField]
        private Text textInUse;
        [SerializeField]
        private TextMeshPro textInUseTMP;
        [SerializeField]
        private TextMeshProUGUI textInUseTMPU;

        [SerializeField]
        private Shader _roundedTrailShader;
        public Shader roundedTrailShader => _roundedTrailShader;

        private void Start() => pen._Init(this);

        public override void OnPlayerJoined(VRCPlayerApi player)
        {
            if (!Networking.IsOwner(pen.gameObject))
                return;

            if (pen.isHeld)
                SendCustomNetworkEvent(NetworkEventTarget.All, nameof(StartUsing));
        }

        public override void OnPlayerLeft(VRCPlayerApi player)
        {
            if (!Networking.IsOwner(pen.gameObject))
                return;

            if (!pen.isHeld)
                SendCustomNetworkEvent(NetworkEventTarget.All, nameof(EndUsing));
        }

        public void StartUsing()
        {
            if (respawnButton)
                respawnButton.SetActive(false);
            if (clearButton)
                clearButton.SetActive(false);
            if (inUseUI)
                inUseUI.SetActive(true);

            var owner = Networking.GetOwner(pen.gameObject);

            var text = owner != null ? owner.displayName : "Occupied";

            if (textInUse)
                textInUse.text = text;

            if (textInUseTMP)
                textInUseTMP.text = text;

            if (textInUseTMPU)
                textInUseTMPU.text = text;
        }

        public void EndUsing()
        {
            if (respawnButton)
                respawnButton.SetActive(true);
            if (clearButton)
                clearButton.SetActive(true);
            if (inUseUI)
                inUseUI.SetActive(false);

            textInUse.text = string.Empty;
        }

        #region API

        public void _SetWidth(float width)
        {
            inkWidth = width;
            pen._UpdateInkData();
        }

        public void _SetMeshLayer(int layer)
        {
            inkMeshLayer = layer;
            pen._UpdateInkData();
        }

        public void _SetColliderLayer(int layer)
        {
            inkColliderLayer = layer;
            pen._UpdateInkData();
        }

        public void _SetUseDoubleClick(bool value) => pen._SetUseDoubleClick(value);

        public void _SetEnabledSync(bool value) => pen._SetEnabledSync(value);

        public void ResetPen()
        {
            pen._Respawn();
            pen._Clear();
        }

        public void Respawn() => pen._Respawn();

        public void Clear()
        {
            _ClearSyncBuffer();
            pen._Clear();
        }

        #endregion

        #region Network

        public bool _TakeOwnership()
        {
            if (Networking.IsOwner(gameObject))
            {
                _ClearSyncBuffer();
                return true;
            }
            else
            {
                Networking.SetOwner(Networking.LocalPlayer, gameObject);
                return Networking.IsOwner(gameObject);
            }
        }

        private bool isInUseSyncBuffer = false;

        [UdonSynced, System.NonSerialized, FieldChangeCallback(nameof(syncedData))]
        private Vector3[] _syncedData = { };
        private Vector3[] syncedData {
            get => _syncedData;
            set {
                _syncedData = value;

                RequestSendPackage();

                pen._UnpackData(_syncedData);
            }
        }

        private void RequestSendPackage()
        {
            if (VRCPlayerApi.GetPlayerCount() > 1 && Networking.IsOwner(gameObject) && !isInUseSyncBuffer)
            {
                isInUseSyncBuffer = true;
                RequestSerialization();
            }
        }

        public void _SendData(Vector3[] data)
        {
            if (!isInUseSyncBuffer)
                syncedData = data;
        }

        public override void OnPostSerialization(SerializationResult result)
        {
            isInUseSyncBuffer = false;

            if (!result.success)
                pen.DestroyJustBeforeInk();
        }

        public void _ClearSyncBuffer()
        {
            syncedData = new Vector3[] { };
            isInUseSyncBuffer = false;
        }

        #endregion
    }
}
