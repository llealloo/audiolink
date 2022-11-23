using UdonSharp;
using UnityEngine;
using VRC.SDK3.Components;
using VRC.SDKBase;
using VRC.Udon.Common.Interfaces;

#pragma warning disable CS0108
#pragma warning disable IDE0090, IDE1006

namespace QvPen.UdonScript
{
    [DefaultExecutionOrder(10)]
    [UdonBehaviourSyncMode(BehaviourSyncMode.NoVariableSync)]
    public class QvPen_Eraser : UdonSharpBehaviour
    {
        private const string _version = "v3.1.2";

        [SerializeField]
        private Material normal;
        private Material erasing;

        [SerializeField]
        private Transform inkPoolRoot;

        [FieldChangeCallback(nameof(renderer))]
        private Renderer _renderer;
        private Renderer renderer => _renderer ? _renderer : (_renderer = GetComponentInChildren<Renderer>(true));

        [FieldChangeCallback(nameof(sphereCollider))]
        private SphereCollider _sphereCollider;
        private SphereCollider sphereCollider => _sphereCollider ? _sphereCollider : (_sphereCollider = GetComponent<SphereCollider>());

        [FieldChangeCallback(nameof(pickup))]
        private VRC_Pickup _pickup;
        private VRC_Pickup pickup => _pickup ? _pickup : (_pickup = (VRC_Pickup)GetComponent(typeof(VRC_Pickup)));

        [FieldChangeCallback(nameof(objectSync))]
        private VRCObjectSync _objectSync;
        private VRCObjectSync objectSync
            => _objectSync ? _objectSync : (_objectSync = (VRCObjectSync)GetComponent(typeof(VRCObjectSync)));

        private bool isUser;
        private bool isErasing;

        // EraserManager
        private QvPen_EraserManager manager;

        [FieldChangeCallback(nameof(eraserRadius))]
        private float _eraserRadius = 0f;
        private float eraserRadius {
            get {
                if (_eraserRadius > 0f)
                    return _eraserRadius;
                else
                {
                    var s = transform.lossyScale;
                    return _eraserRadius = Mathf.Min(s.x, s.y, s.z) * sphereCollider.radius;
                }
            }
        }

        private int inkColliderLayer;

        private const string inkPoolRootName = "QvPen_InkPool";

        [FieldChangeCallback(nameof(localPlayer))]
        private VRCPlayerApi _localPlayer;
        private VRCPlayerApi localPlayer => _localPlayer ?? (_localPlayer = Networking.LocalPlayer);

        public void _Init(QvPen_EraserManager manager)
        {
            this.manager = manager;
            inkColliderLayer = manager.inkColliderLayer;

            var inkPoolRootGO = GameObject.Find($"/{inkPoolRootName}");
            if (inkPoolRootGO)
                inkPoolRoot = inkPoolRootGO.transform;
            else
            {
                inkPoolRootGO = inkPoolRoot.gameObject;
                inkPoolRootGO.name = inkPoolRootName;
                SetParentAndResetLocalTransform(inkPoolRootGO.transform, null);
                inkPoolRootGO.transform.SetAsFirstSibling();
#if !UNITY_EDITOR
                Log($"{nameof(QvPen)} {_version}");
#endif
            }

            erasing = renderer.sharedMaterial;

            pickup.InteractionText = "Eraser";
            pickup.UseText = "Erase";
        }

        public override void OnPlayerJoined(VRCPlayerApi player)
        {
            if (isUser && isErasing)
                SendCustomNetworkEvent(NetworkEventTarget.All, nameof(OnPickupEvent));
        }

        public override void OnPickup()
        {
            isUser = true;

            sphereCollider.enabled = false;

            manager._TakeOwnership();
            manager.SendCustomNetworkEvent(NetworkEventTarget.All, nameof(QvPen_EraserManager.StartUsing));

            SendCustomNetworkEvent(NetworkEventTarget.All, nameof(OnPickupEvent));
        }

        public override void OnDrop()
        {
            isUser = false;

            sphereCollider.enabled = true;

            manager._ClearSyncBuffer();
            manager.SendCustomNetworkEvent(NetworkEventTarget.All, nameof(QvPen_EraserManager.EndUsing));

            SendCustomNetworkEvent(NetworkEventTarget.All, nameof(OnDropEvent));
        }

        public override void OnPickupUseDown()
        {
            SendCustomNetworkEvent(NetworkEventTarget.All, nameof(StartErasing));
        }

        public override void OnPickupUseUp()
        {
            SendCustomNetworkEvent(NetworkEventTarget.All, nameof(FinishErasing));
        }

        public void OnPickupEvent() => renderer.sharedMaterial = normal;

        public void OnDropEvent() => renderer.sharedMaterial = erasing;

        public void StartErasing()
        {
            isErasing = true;
            renderer.sharedMaterial = erasing;
        }

        public void FinishErasing()
        {
            isErasing = false;
            renderer.sharedMaterial = normal;
        }

        private void SetData(Vector3[] data, int index, Vector3 element)
        {
            if (data.Length >= index)
                data[data.Length - index] = element;
        }

        // Mode
        private const int MODE_UNKNOWN = QvPen_Pen.MODE_UNKNOWN;
        private const int MODE_DRAW = QvPen_Pen.MODE_DRAW;
        private const int MODE_ERASE = QvPen_Pen.MODE_ERASE;
        private const int MODE_DRAW_PLANE = QvPen_Pen.MODE_DRAW_PLANE;
        private int GetFooterSize(int mode)
        {
            switch (mode)
            {
                case MODE_DRAW: return 7;
                case MODE_ERASE: return 6;
                case MODE_UNKNOWN: return 0;
                default: return 0;
            }
        }

        private readonly Collider[] results = new Collider[4];
        public override void PostLateUpdate()
        {
            if (!isHeld || !isErasing || !isUser)
                return;

            var count = Physics.OverlapSphereNonAlloc(transform.position, eraserRadius, results, 1 << inkColliderLayer, QueryTriggerInteraction.Ignore);
            for (var i = 0; i < count; i++)
            {
                var other = results[i];

                if (other
                 && other.transform.parent
                 && other.transform.parent.parent
                 && other.transform.parent.parent.parent
                 && other.transform.parent.parent.parent.parent == inkPoolRoot)
                {
                    var synchronizer = other.GetComponentInParent<QvPen_SequentialSync>();
                    if (synchronizer)
                    {
                        var pen = synchronizer.pen;
                        var penIdVector = pen.penIdVector;
                        var lineRenderer = other.GetComponentInParent<LineRenderer>();
                        if (lineRenderer && lineRenderer.positionCount > 0)
                        {
                            var data = new Vector3[GetFooterSize(MODE_ERASE)];

                            SetData(data, 1, new Vector3(localPlayer.playerId, MODE_ERASE, GetFooterSize(MODE_ERASE)));
                            SetData(data, 2, penIdVector);
                            SetData(data, 3, Vector3.right * lineRenderer.positionCount);
                            SetData(data, 4, lineRenderer.GetPosition(0));
                            SetData(data, 5, lineRenderer.GetPosition(lineRenderer.positionCount / 2));
                            SetData(data, 6, lineRenderer.GetPosition(Mathf.Max(0, lineRenderer.positionCount - 1)));

                            _SendData(data);
                        }
                    }
                }

                results[i] = null;
            }
        }

        private Vector3 GetData(Vector3[] data, int index)
            => data.Length >= index ? data[data.Length - index] : Vector3.negativeInfinity;

        private int GetMode(Vector3[] data) => data.Length >= 1 ? (int)GetData(data, 1).y : MODE_UNKNOWN;

        public void _SendData(Vector3[] data) => manager._SendData(data);

        public void _UnpackData(Vector3[] data)
        {
            if (data.Length == 0)
                return;

            switch (GetMode(data))
            {
                case MODE_ERASE:
                {
                    EraseInk(data);
                    break;
                }
            }
        }

        private void EraseInk(Vector3[] data)
        {
            if (data.Length < GetFooterSize(MODE_ERASE))
                return;

            const float eraserMiniRadius = 0.18e-4f;
            var middlePosition = GetData(data, 5);
            var count = Physics.OverlapSphereNonAlloc(middlePosition, eraserMiniRadius, results, 1 << inkColliderLayer, QueryTriggerInteraction.Ignore);
            for (var i = 0; i < count; i++)
            {
                var other = results[i];

                if (other
                 && other.transform.parent
                 && other.transform.parent.parent
                 && other.transform.parent.parent.parent
                 && other.transform.parent.parent.parent.parent == inkPoolRoot
                )
                {
                    var lineRenderer = other.GetComponentInParent<LineRenderer>();
                    if (lineRenderer
                     && lineRenderer.positionCount == (int)GetData(data, 3).x
                     && lineRenderer.GetPosition(0) == GetData(data, 4)
                     && lineRenderer.GetPosition(lineRenderer.positionCount / 2) == middlePosition
                     && lineRenderer.GetPosition(Mathf.Max(0, lineRenderer.positionCount - 1)) == GetData(data, 6)
                    )
                        Destroy(other.transform.parent.gameObject);
                }

                results[i] = null;
            }
        }


        public bool isHeld => pickup.IsHeld;

        public void _Respawn()
        {
            pickup.Drop();

            if (Networking.LocalPlayer.IsOwner(gameObject))
                objectSync.Respawn();
        }

        #region Utility

        private void SetParentAndResetLocalTransform(Transform child, Transform parent)
        {
            if (child)
            {
                child.SetParent(parent);
                child.localPosition = Vector3.zero;
                child.localRotation = Quaternion.identity;
                child.localScale = Vector3.one;
            }
        }

        #endregion

        #region Log

        private void Log(object o) => Debug.Log($"{logPrefix}{o}", this);
        private void Warning(object o) => Debug.LogWarning($"{logPrefix}{o}", this);
        private void Error(object o) => Debug.LogError($"{logPrefix}{o}", this);

        private readonly Color logColor = new Color(0xf2, 0x7d, 0x4a, 0xff) / 0xff;
        private string ColorBeginTag(Color c) => $"<color=\"#{ToHtmlStringRGB(c)}\">";
        private const string ColorEndTag = "</color>";

        [FieldChangeCallback(nameof(logPrefix))]
        private string _logPrefix;
        private string logPrefix
            => string.IsNullOrEmpty(_logPrefix)
                ? (_logPrefix = $"[{ColorBeginTag(logColor)}{nameof(QvPen)}.{nameof(QvPen.Udon)}.{nameof(QvPen_Eraser)}{ColorEndTag}] ") : _logPrefix;

        private string ToHtmlStringRGB(Color c)
        {
            c *= 0xff;
            return $"{Mathf.RoundToInt(c.r):x2}{Mathf.RoundToInt(c.g):x2}{Mathf.RoundToInt(c.b):x2}";
        }

        #endregion
    }
}
