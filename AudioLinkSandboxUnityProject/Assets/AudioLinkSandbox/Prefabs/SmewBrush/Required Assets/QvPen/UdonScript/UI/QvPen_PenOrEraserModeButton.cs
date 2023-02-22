using UdonSharp;
using UnityEngine;

namespace QvPen.UdonScript.UI
{
    [DefaultExecutionOrder(30)]
    [UdonBehaviourSyncMode(BehaviourSyncMode.NoVariableSync)]
    public class QvPen_PenOrEraserModeButton : UdonSharpBehaviour
    {
        [SerializeField]
        private QvPen_Settings settings;

        [SerializeField]
        private bool use = true;

        [SerializeField]
        private GameObject displayObjectOn;
        [SerializeField]
        private GameObject displayObjectOff;

        private void Start() => UpdateEnabled();

        public override void Interact()
        {
            use ^= true;
            UpdateEnabled();
        }

        private void UpdateEnabled()
        {
            if (displayObjectOn)
                displayObjectOn.SetActive(use);
            if (displayObjectOff)
                displayObjectOff.SetActive(!use);

            foreach (var penManager in settings.penManagers)
                if (penManager)
                    penManager._SetUseDoubleClick(use);
        }
    }
}
