using UdonSharp;
using UnityEngine;

namespace QvPen.UdonScript.UI
{
    [DefaultExecutionOrder(30)]
    [UdonBehaviourSyncMode(BehaviourSyncMode.NoVariableSync)]
    public class QvPen_ShowOrHideButton : UdonSharpBehaviour
    {
        [SerializeField]
        private GameObject[] gameObjects = { };

        [SerializeField]
        private bool isShown = true;

        [SerializeField]
        private GameObject displayObjectOn;
        [SerializeField]
        private GameObject displayObjectOff;

        private void Start() => UpdateActivity();

        public override void Interact()
        {
            isShown ^= true;
            UpdateActivity();
        }

        private void UpdateActivity()
        {
            if (displayObjectOn)
                displayObjectOn.SetActive(isShown);
            if (displayObjectOff)
                displayObjectOff.SetActive(!isShown);

            foreach (var go in gameObjects)
                if (go)
                    go.SetActive(isShown);
        }
    }
}
