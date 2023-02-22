using UdonSharp;
using UnityEngine;
using VRC.SDK3.Components;
using VRC.SDKBase;
using VRC.Udon.Common.Interfaces;

#pragma warning disable IDE0090, IDE1006
#pragma warning disable IDE0066, IDE0074

namespace QvPen.UdonScript
{
    [DefaultExecutionOrder(10)]
    [UdonBehaviourSyncMode(BehaviourSyncMode.NoVariableSync)]
    public class QvPen_Pen : UdonSharpBehaviour
    {
        private const string _version = "v3.1.2";

        [Header("Pen")]
        [SerializeField]
        private TrailRenderer trailRenderer;
        [SerializeField]
        private TrailRenderer trailRenderer2;
        [SerializeField]
        private LineRenderer inkPrefab;

        [SerializeField]
        private Transform inkPosition;
        [SerializeField]
        private Transform inkPoolRoot;
        [System.NonSerialized]
        public Transform inkPool;
        [System.NonSerialized]
        public Transform inkPoolSynced;// { get; private set; }
        private Transform inkPoolNotSynced;

        public AudioSource SoundFX; //SMEW

        private QvPen_SequentialSync synchronizer;

        [Header("Pointer")]
        [SerializeField]
        private Transform pointer;
        [FieldChangeCallback(nameof(pointerRadius))]
        private float _pointerRadius = 0f;
        private float pointerRadius {
            get {
                if (_pointerRadius > 0f)
                    return _pointerRadius;
                else
                {
                    var sphereCollider = pointer.GetComponent<SphereCollider>();
                    sphereCollider.enabled = false;
                    var s = pointer.lossyScale;
                    return _pointerRadius = Mathf.Min(s.x, s.y, s.z) * sphereCollider.radius;
                }
            }
        }
        [SerializeField, FieldChangeCallback(nameof(pointerRadiusMultiplierForDesktop))]
        private float _pointerRadiusMultiplierForDesktop = 5f;
        private float pointerRadiusMultiplierForDesktop => isUserInVR ? 1f : Mathf.Abs(_pointerRadiusMultiplierForDesktop);
        [SerializeField]
        private Material pointerMaterialNormal;
        [SerializeField]
        private Material pointerMaterialActive;
        [SerializeField]
        private bool canBeErasedWithOtherPointers = true;

        private bool enabledSync = true;

        [FieldChangeCallback(nameof(inkPrefabCollider))]
        private MeshCollider _inkPrefabCollider;
        private MeshCollider inkPrefabCollider
            => _inkPrefabCollider ? _inkPrefabCollider : (_inkPrefabCollider = inkPrefab.GetComponentInChildren<MeshCollider>(true));
        private GameObject lineInstance;

        private bool isUser;

        // Components
        [FieldChangeCallback(nameof(pickup))]
        private VRC_Pickup _pickup;
        private VRC_Pickup pickup => _pickup ? _pickup : (_pickup = (VRC_Pickup)GetComponent(typeof(VRC_Pickup)));

        [FieldChangeCallback(nameof(objectSync))]
        private VRCObjectSync _objectSync;
        private VRCObjectSync objectSync
            => _objectSync ? _objectSync : (_objectSync = (VRCObjectSync)GetComponent(typeof(VRCObjectSync)));

        // PenManager
        private QvPen_PenManager manager;

        // Ink
        private int inkMeshLayer;
        private int inkColliderLayer;
        private const float followSpeed = 30f;
        private int inkNo;

        // Pointer
        private bool isPointerEnabled;
        private Renderer pointerRenderer;

        // Double click
        private bool useDoubleClick = true;
        private const float clickTimeInterval = 0.2184f;
        private float prevClickTime;
        private readonly float clickPosInterval = (Vector3.one * 0.00552f).sqrMagnitude;
        private Vector3 prevClickPos;

        // State
        private const int StatePenIdle = 0;
        private const int StatePenUsing = 1;
        private const int StateEraserIdle = 2;
        private const int StateEraserUsing = 3;
        private int currentState = StatePenIdle;
        private string nameofCurrentState {
            get {
                switch (currentState)
                {
                    case StatePenIdle: return nameof(StatePenIdle);
                    case StatePenUsing: return nameof(StatePenUsing);
                    case StateEraserIdle: return nameof(StateEraserIdle);
                    case StateEraserUsing: return nameof(StateEraserUsing);
                    default: return string.Empty;
                }
            }
        }

        // Sync state
        [System.NonSerialized]
        public int currentSyncState = SYNC_STATE_Idle;
        public const int SYNC_STATE_Idle = 0;
        public const int SYNC_STATE_Started = 1;
        public const int SYNC_STATE_Finished = 2;

        // Ink pool
        private const string inkPoolRootName = "QvPen_InkPool";
        private const string inkPoolName = "InkPool";
        private int penId;
        public Vector3 penIdVector { get; private set; }
        private string penIdString;

        private const string inkPrefix = "Ink";
        private float inkWidth;

        [FieldChangeCallback(nameof(localPlayer))]
        private VRCPlayerApi _localPlayer;
        private VRCPlayerApi localPlayer => _localPlayer ?? (_localPlayer = Networking.LocalPlayer);

        public void _Init(QvPen_PenManager manager)
        {
            this.manager = manager;
            _UpdateInkData();

            inkPool = inkPoolRoot.Find(inkPoolName);

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

            SetParentAndResetLocalTransform(inkPool, inkPoolRootGO.transform);

            penId = string.IsNullOrEmpty(Networking.GetUniqueName(gameObject))
                ? 0 : Networking.GetUniqueName(gameObject).GetHashCode();
            penIdVector = new Vector3((penId >> 24) & 0x00ff, (penId >> 12) & 0x0fff, penId & 0x0fff);
            penIdString = $"0x{(int)penIdVector.x:x2}{(int)penIdVector.y:x3}{(int)penIdVector.z:x3}";
            inkPool.name = $"{inkPoolName} ({penIdString})";

            synchronizer = inkPool.GetComponent<QvPen_SequentialSync>();
            if (synchronizer)
                synchronizer.pen = this;

            inkPoolSynced = inkPool.Find("Synced");
            inkPoolNotSynced = inkPool.Find("NotSynced");

#if !UNITY_EDITOR
            Log($"I'm {penIdString}");
#endif

            pickup.InteractionText = nameof(QvPen);
            pickup.UseText = "Draw";

            pointerRenderer = pointer.GetComponent<Renderer>();
            pointer.gameObject.SetActive(false);
            pointer.transform.localScale *= pointerRadiusMultiplierForDesktop;
        }

        public void _UpdateInkData()
        {
            inkWidth = manager.inkWidth;
            inkMeshLayer = manager.inkMeshLayer;
            inkColliderLayer = manager.inkColliderLayer;

            inkPrefab.gameObject.layer = inkMeshLayer;
            inkPrefabCollider.gameObject.layer = inkColliderLayer;

#if UNITY_ANDROID
            var material = manager.questInkMaterial;
            inkPrefab.widthMultiplier = inkWidth;
            trailRenderer.widthMultiplier = inkWidth;
#else
            var material = manager.pcInkMaterial;
            if (material && material.shader == manager.roundedTrailShader)
            {
                inkPrefab.widthMultiplier = 0f;
                trailRenderer.widthMultiplier = 0f;
                material.SetFloat("_Width", inkWidth);
            }
            else
            {
                inkPrefab.widthMultiplier = inkWidth;
                trailRenderer.widthMultiplier = inkWidth;
            }
#endif

            inkPrefab.material = material;
            trailRenderer.material = material;
            inkPrefab.colorGradient = manager.colorGradient;
            trailRenderer.colorGradient = manager.colorGradient;
        }

        private void LateUpdate()
        {
            if (!isHeld || isPointerEnabled)
                return;

            if (isUser)
                trailRenderer.transform.SetPositionAndRotation(
                    Vector3.Lerp(trailRenderer.transform.position, inkPosition.position, Time.deltaTime * followSpeed),
                    Quaternion.Lerp(trailRenderer.transform.rotation, inkPosition.rotation, Time.deltaTime * followSpeed));
            else
                trailRenderer.transform.SetPositionAndRotation(inkPosition.position, inkPosition.rotation);
        }

        public bool _CheckId(Vector3 idVector) => idVector == penIdVector;

        #region Data protocol

        #region Base

        // Mode
        public const int MODE_UNKNOWN = -1;
        public const int MODE_DRAW = 1;
        public const int MODE_ERASE = 2;
        public const int MODE_DRAW_PLANE = 3;
        private int GetFooterSize(int mode)
        {
            switch (mode)
            {
                case MODE_UNKNOWN: return 0;
                case MODE_DRAW: return 7;
                case MODE_ERASE: return 6;
                default: return 0;
            }
        }

        private int currentDrawMode = MODE_DRAW;

        #endregion

        private Vector3 GetData(Vector3[] data, int index)
            => data.Length >= index ? data[data.Length - index] : Vector3.negativeInfinity;

        private void SetData(Vector3[] data, int index, Vector3 element)
        {
            if (data.Length >= index)
                data[data.Length - index] = element;
        }

        private int GetMode(Vector3[] data) => data.Length >= 1 ? (int)GetData(data, 1).y : MODE_UNKNOWN;

        private int GetFooterLength(Vector3[] data) => data.Length >= 1 ? (int)GetData(data, 1).z : 0;

        #endregion

        private readonly Collider[] results = new Collider[4];
        public override void PostLateUpdate()
        {
            if (!isHeld || !isPointerEnabled || !isUser)
                return;

            var count = Physics.OverlapSphereNonAlloc(pointer.position, pointerRadius, results, 1 << inkColliderLayer, QueryTriggerInteraction.Ignore);
            for (var i = 0; i < count; i++)
            {
                var other = results[i];

                if (other && other.transform.parent && other.transform.parent.parent)
                {
                    if (canBeErasedWithOtherPointers
                      ? other.transform.parent.parent.parent && other.transform.parent.parent.parent.parent == inkPoolRoot
                      : other.transform.parent.parent.parent == inkPool
                    )
                    {
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
                    //else if (
                    //    false
                    //)
                    //{
                    //
                    //}
                }

                results[i] = null;
            }
        }

        #region Events

        private bool isSwitchedUseText = false;

        public override void OnPickup()
        {
            isUser = true;

            manager._TakeOwnership();
            manager.SendCustomNetworkEvent(NetworkEventTarget.All, nameof(QvPen_PenManager.StartUsing));

            SendCustomNetworkEvent(NetworkEventTarget.All, nameof(ChangeStateToPenIdle));

            pickup.UseText = (isSwitchedUseText ^= true) ? "Draw" : "Double qk UseDown : Switch modes";
        }

        public override void OnDrop()
        {
            isUser = false;

            manager.SendCustomNetworkEvent(NetworkEventTarget.All, nameof(QvPen_PenManager.EndUsing));

            SendCustomNetworkEvent(NetworkEventTarget.All, nameof(ChangeStateToPenIdle));

            manager._ClearSyncBuffer();
        }
        public TrailRenderer copyTrail;
        public override void OnPickupUseDown()
        {
            prevClickTime = Time.time;
            prevClickPos = inkPosition.position;

            
            switch (currentState)
            {
                case StatePenIdle:
                    { 
                        SendCustomNetworkEvent(NetworkEventTarget.All, nameof(ChangeStateToPenUsing));
                        //SMEW
                        if (copyTrail)
                        {
                            copyTrail.emitting = true;
                            
                        }
                        
                        break;
                    }
                case StateEraserIdle:
                    {
                        SendCustomNetworkEvent(NetworkEventTarget.All, nameof(ChangeStateToEraseUsing));
                        break;
                    }
                default:
                    {
                        Error($"Unexpected state : {nameofCurrentState} at {nameof(OnPickupUseDown)}");
                        break;
                    }
            }
        }



        public override void OnPickupUseUp()
        {
            switch (currentState)
            {
                case StatePenUsing:
                {
                    SendCustomNetworkEvent(NetworkEventTarget.All, nameof(ChangeStateToPenIdle));
                    //SMEW
                    if (copyTrail)
                    {
                        copyTrail.emitting = false;
                    }
                    break;
                }
                case StateEraserUsing:
                {
                    SendCustomNetworkEvent(NetworkEventTarget.All, nameof(ChangeStateToEraseIdle));
                    break;
                }
                case StatePenIdle:
                {
                    Log($"Change state : {nameof(StateEraserIdle)} to {nameofCurrentState}");
                    break;
                }
                case StateEraserIdle:
                {
                    Log($"Change state : {nameof(StatePenIdle)} to {nameofCurrentState}");
                    break;
                }
                default:
                {
                    Error($"Unexpected state : {nameofCurrentState} at {nameof(OnPickupUseUp)}");
                    break;
                }
            }
        }

        public void _SetUseDoubleClick(bool value)
        {
            useDoubleClick = value;
            SendCustomNetworkEvent(NetworkEventTarget.All, nameof(ChangeStateToPenIdle));
        }

        public void _SetEnabledSync(bool value)
        {
            enabledSync = value;
        }

        private GameObject justBeforeInk;
        public void DestroyJustBeforeInk()
        {
            Destroy(justBeforeInk);
            inkNo--;
        }

        private void OnEnable()
        {
            if (inkPool)
                inkPool.gameObject.SetActive(true);
        }

        private void OnDisable()
        {
            if (inkPool)
                inkPool.gameObject.SetActive(false);
        }

        private void OnDestroy() => Destroy(inkPool);

        #endregion

        #region ChangeState

        public void ChangeStateToPenIdle()
        {
            switch (currentState)
            {
                case StatePenUsing:
                {
                    FinishDrawing();
                    break;
                }
                case StateEraserIdle:
                {
                    ChangeToPen();
                    break;
                }
                case StateEraserUsing:
                {
                    DisablePointer();
                    ChangeToPen();
                    break;
                }
            }
            currentState = StatePenIdle;
        }

        public void ChangeStateToPenUsing()
        {
            switch (currentState)
            {
                case StatePenIdle:
                {
                    StartDrawing();
                    break;
                }
                case StateEraserIdle:
                {
                    ChangeToPen();
                    StartDrawing();
                    break;
                }
                case StateEraserUsing:
                {
                    DisablePointer();
                    ChangeToPen();
                    StartDrawing();
                    break;
                }
            }
            currentState = StatePenUsing;
        }

        public void ChangeStateToEraseIdle()
        {
            switch (currentState)
            {
                case StatePenIdle:
                {
                    ChangeToEraser();
                    break;
                }
                case StatePenUsing:
                {
                    FinishDrawing();
                    ChangeToEraser();
                    break;
                }
                case StateEraserUsing:
                {
                    DisablePointer();
                    break;
                }
            }
            currentState = StateEraserIdle;
        }

        public void ChangeStateToEraseUsing()
        {
            switch (currentState)
            {
                case StatePenIdle:
                {
                    ChangeToEraser();
                    EnablePointer();
                    break;
                }
                case StatePenUsing:
                {
                    FinishDrawing();
                    ChangeToEraser();
                    EnablePointer();
                    break;
                }
                case StateEraserIdle:
                {
                    EnablePointer();
                    break;
                }
            }
            currentState = StateEraserUsing;
        }

        #endregion

        private bool isCheckedIsUserInVR = false;
        [FieldChangeCallback(nameof(isUserInVR))]
        private bool _isUserInVR;
        private bool isUserInVR => isCheckedIsUserInVR ? _isUserInVR
            : (isCheckedIsUserInVR = true) && (_isUserInVR = localPlayer != null && localPlayer.IsUserInVR());

        public bool isHeld => pickup.IsHeld;

        public void _Respawn()
        {
            pickup.Drop();

            if (Networking.IsOwner(gameObject))
                objectSync.Respawn();
        }

        public void _Clear()
        {
            foreach (Transform ink in inkPoolSynced)
                Destroy(ink.gameObject);

            foreach (Transform ink in inkPoolNotSynced)
                Destroy(ink.gameObject);

            inkNo = 0;
        }

        private void StartDrawing()
        {
            trailRenderer.gameObject.SetActive(true);
            //var newobj = VRCInstantiate(BrushAudio);
            if (SoundFX)
            {
                SoundFX.Play();
            }
            

        }

        private void FinishDrawing()
        {
            if (isUser)
            {
                var data = PackData(trailRenderer, currentDrawMode);

                _SendData(data);
            }

            trailRenderer.gameObject.SetActive(false);
            if (SoundFX)
            {
                SoundFX.Stop();
            }
            
            trailRenderer.Clear();

        }

        private Vector3[] PackData(TrailRenderer trailRenderer, int mode)
        {
            if (!trailRenderer)
                return null;

            var positionCount = trailRenderer.positionCount;
            var data = new Vector3[positionCount + GetFooterSize(mode)];

            trailRenderer.GetPositions(data);

            System.Array.Reverse(data, 0, positionCount);

            SetData(data, 1, new Vector3(localPlayer.playerId, mode, GetFooterSize(mode)));
            SetData(data, 2, penIdVector);
            SetData(data, 3, new Vector3(inkMeshLayer, inkColliderLayer, enabledSync ? 1f : 0f));
            SetData(data, 4, Vector3.right * positionCount);
            SetData(data, 5, data[0]);
            SetData(data, 6, data[positionCount / 2]);
            SetData(data, 7, data[Mathf.Max(0, positionCount - 1)]);

            return data;
        }

        public Vector3[] _PackData(LineRenderer lineRenderer, int mode)
        {
            if (!lineRenderer)
                return null;

            var positionCount = lineRenderer.positionCount;
            var data = new Vector3[positionCount + GetFooterSize(mode)];

            lineRenderer.GetPositions(data);

            var inkMeshLayer = (float)lineRenderer.gameObject.layer;
            var inkColliderLayer = (float)lineRenderer.GetComponentInChildren<Collider>(true).gameObject.layer;

            SetData(data, 1, new Vector3(localPlayer.playerId, mode, GetFooterSize(mode)));
            SetData(data, 2, penIdVector);
            SetData(data, 3, new Vector3(inkMeshLayer, inkColliderLayer, enabledSync ? 1f : 0f));
            SetData(data, 4, Vector3.right * positionCount);
            SetData(data, 5, data[0]);
            SetData(data, 6, data[positionCount / 2]);
            SetData(data, 7, data[Mathf.Max(0, positionCount - 1)]);

            return data;
        }

        public void _SendData(Vector3[] data) => manager._SendData(data);

        private void EnablePointer()
        {
            isPointerEnabled = true;
            pointerRenderer.sharedMaterial = pointerMaterialActive;
        }

        private void DisablePointer()
        {
            isPointerEnabled = false;
            pointerRenderer.sharedMaterial = pointerMaterialNormal;
        }

        private void ChangeToPen()
        {
            DisablePointer();
            pointer.gameObject.SetActive(false);
        }

        private void ChangeToEraser()
        {
            pointer.gameObject.SetActive(true);
        }

        public void _UnpackData(Vector3[] data)
        {
            if (data.Length == 0)
                return;

            switch (GetMode(data))
            {
                case MODE_DRAW:
                {
                    CreateInkInstance(data);
                    break;
                }
                case MODE_ERASE:
                {
                    EraseInk(data);
                    break;
                }
            }
        }

        #region Draw Line

        private void CreateInkInstance(Vector3[] data)
        {
            if (ExistsLine(data))
                return;

            lineInstance = VRCInstantiate(inkPrefab.gameObject);
            lineInstance.name = $"{inkPrefix} ({inkNo++})";

            var inkInfo = GetData(data, 3);
            lineInstance.layer = (int)inkInfo.x;
            lineInstance.GetComponentInChildren<Collider>(true).gameObject.layer = (int)inkInfo.y;
            SetParentAndResetLocalTransform(lineInstance.transform, (int)inkInfo.z == 1 ? inkPoolSynced : inkPoolNotSynced);

            var line = lineInstance.GetComponent<LineRenderer>();
            line.positionCount = data.Length - GetFooterLength(data);
            line.SetPositions(data);

            CreateInkCollider(line);

            lineInstance.SetActive(true);

            justBeforeInk = lineInstance;
        }

        private void CreateInkCollider(LineRenderer lineRenderer)
        {

            lineRenderer.material = trailRenderer.material; 

            var inkCollider = lineRenderer.GetComponentInChildren<Collider>(true);
            inkCollider.name = "InkCollider";
            SetParentAndResetLocalTransform(inkCollider.transform, lineInstance.transform);

            var mesh = new Mesh();
            //var filter = new MeshFilter();
            //filter.mesh = trailRenderer;//.material;
            {
                var tmpWidthMultiplier = lineRenderer.widthMultiplier;

                lineRenderer.widthMultiplier = inkWidth;
                lineRenderer.BakeMesh(mesh);
                lineRenderer.widthMultiplier = tmpWidthMultiplier;
            }

            
            inkCollider.GetComponent<MeshCollider>().sharedMesh = mesh;
            inkCollider.gameObject.SetActive(true);
        }

        private bool ExistsLine(Vector3[] data)
        {
            if (data.Length < GetFooterSize(MODE_DRAW))
                return true;

            var exists = false;

            const float eraserMiniRadius = 0.18e-4f;
            var middlePosition = GetData(data, 6);
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
                     && lineRenderer.positionCount == (int)GetData(data, 4).x
                     && lineRenderer.GetPosition(0) == GetData(data, 5)
                     && lineRenderer.GetPosition(lineRenderer.positionCount / 2) == middlePosition
                     && lineRenderer.GetPosition(Mathf.Max(0, lineRenderer.positionCount - 1)) == GetData(data, 7)
                    )
                        exists |= true;
                }

                results[i] = null;
            }

            return exists;
        }

        #endregion

        #region Erase Line

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
                 && (canBeErasedWithOtherPointers
                    ? other.transform.parent.parent.parent && other.transform.parent.parent.parent.parent == inkPoolRoot
                    : other.transform.parent.parent.parent == inkPool
                    )
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

        #endregion

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
                ? (_logPrefix = $"[{ColorBeginTag(logColor)}{nameof(QvPen)}.{nameof(QvPen.Udon)}.{nameof(QvPen_Pen)}{ColorEndTag}] ") : _logPrefix;

        private string ToHtmlStringRGB(Color c)
        {
            c *= 0xff;
            return $"{Mathf.RoundToInt(c.r):x2}{Mathf.RoundToInt(c.g):x2}{Mathf.RoundToInt(c.b):x2}";
        }

        #endregion
    }
}
