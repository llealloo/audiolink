
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using Thry.General;
using VRC.Udon;
#if !COMPILER_UDONSHARP && UNITY_EDITOR
using UnityEditor;
using UdonSharpEditor;
#endif

namespace Thry.Clapper
{
    [UdonBehaviourSyncMode(BehaviourSyncMode.None)]
    public class Clapper : UdonSharpBehaviour
    {
        ThryAction[] _clapperActions;

        ClapperEffect _localEffect;
        Thry.ObjectPool.OneObjectPerPlayerPool _effectPool;
        bool hasNetworkedEffect = false;
        bool hasLocalEffect = false;
        HandCollider _left;
        HandCollider _right;
        int _claps = 0;
        float _clastClapTime = 0;

        const float MAX_TIME_BETWEEN_CLAPS = 1;

        const bool DEBUG = true;

        private void Start()
        {
            //Find hand Colliders
            GameObject o = GameObject.Find("[Thry]HandCollider_L");
            if(o == null)
            {
                Debug.LogError("[ThryError] Can't Find Left Thry Hand Collider");
                return;
            }
            _left = o.GetComponent<HandCollider>();
            o = GameObject.Find("[Thry]HandCollider_R");
            if (o == null)
            {
                Debug.LogError("[ThryError] Can't Find Right Thry Hand Collider");
                return;
            }
            _right = o.GetComponent<HandCollider>();

            //Find clapper actions in children
            int actionsCount = 0;
            for(int i = 0; i < transform.childCount; i++)
            {
                Transform child = transform.GetChild(i);
                if (child.GetComponent<ClapperEffect>() != null)
                {
                    _localEffect = transform.GetChild(i).GetComponent<ClapperEffect>();
                    if (!hasNetworkedEffect) hasLocalEffect = true;
                }
                if (child.GetComponent<ObjectPool.OneObjectPerPlayerPool>() != null)
                {
                    _effectPool = transform.GetChild(i).GetComponent<ObjectPool.OneObjectPerPlayerPool>();
                    hasNetworkedEffect = true;
                    hasLocalEffect = false;
                }
                if (child.GetComponent<ThryAction>() != null && child.GetComponent<ThryAction>().isClapperAction)
                {
                    actionsCount++;
                }
            }
            _clapperActions = new ThryAction[actionsCount];
            actionsCount = 0;
            for (int i = 0; i < transform.childCount; i++)
            {
                if (transform.GetChild(i).GetComponent<ThryAction>() != null && transform.GetChild(i).GetComponent<ThryAction>().isClapperAction)
                {
                    _clapperActions[actionsCount++] = transform.GetChild(i).GetComponent<ThryAction>();
                }
            }

            //Register clap callback on hands
            _right.RegisterClapCallback(this.gameObject);
            _left.RegisterClapCallback(this.gameObject);
        }

        private void Update()
        {
            foreach(ThryAction action in _clapperActions)
            {
                if (action.desktopKey != "" && Input.GetKeyDown(action.desktopKey))
                {
                    action.OnInteraction();
                }
            }
            //Dekstop claps
            if (Input.GetKeyDown(KeyCode.F))
            {
                _Clap();
            }
        }

        public override void Interact()
        {
            _PlayClapEffect();
        }

        private void _PlayClapEffect()
        {
            if (hasNetworkedEffect)
            {
                if(_effectPool.LocalBehaviour != null)
                {
                    _effectPool.LocalBehaviour.SendCustomEvent("NetworkPlay");
                }
                else
                {
                    Debug.Log("[Clapper] No Object Pool Object assigned.");
                    if(hasLocalEffect) _localEffect.Play();
                }
            }else if (hasLocalEffect)
            {
                _localEffect.Play();
            }
        }

        public void _Clap()
        {
            _CountClap();
            _PlayClapEffect();
        }

        private void _CountClap()
        {
            _claps++;
            _clastClapTime = Time.time;
            SendCustomEventDelayedSeconds(nameof(_CheckClap), MAX_TIME_BETWEEN_CLAPS + 0.1f);
        }

        public void _CheckClap()
        {
            if(Time.time - _clastClapTime > MAX_TIME_BETWEEN_CLAPS)
            {
                foreach(ThryAction action in _clapperActions)
                {
                    if(action.requiredClaps == _claps)
                    {
                        action.OnInteraction();
                    }
                }
                _claps = 0;
            }
        }
    }

#if !COMPILER_UDONSHARP && UNITY_EDITOR
    [CustomEditor(typeof(Clapper))]
    public class ClapperEditor : Editor
    {
        public override void OnInspectorGUI()
        {
            if (UdonSharpGUI.DrawDefaultUdonSharpBehaviourHeader(target)) return;
            EditorGUILayout.HelpBox("For this prefab to work you need to have [Thry]HandCollider_L, [Thry]HandCollider_R and [Thry]AvatarHeightTracker in your scene.", MessageType.Warning);
            EditorGUILayout.HelpBox("Place any clapper behaviour as child of this gameobject.", MessageType.Info);
        }
    }
#endif
}