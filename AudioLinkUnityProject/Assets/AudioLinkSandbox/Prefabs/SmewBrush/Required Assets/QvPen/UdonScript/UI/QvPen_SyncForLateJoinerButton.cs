using UdonSharp;
using UnityEngine;

namespace QvPen.UdonScript.UI
{
    [DefaultExecutionOrder(30)]
    [UdonBehaviourSyncMode(BehaviourSyncMode.NoVariableSync)]
    public class QvPen_SyncForLateJoinerButton : UdonSharpBehaviour
    {
        [SerializeField]
        private QvPen_Settings settings;

        [SerializeField]
        private bool doSync = true;

        [SerializeField]
        private GameObject displayObjectOn;
        [SerializeField]
        private GameObject displayObjectOff;

        private void Start() => UpdateEnabled();

        public override void Interact()
        {
            doSync ^= true;
            UpdateEnabled();
        }

        private void UpdateEnabled()
        {
            if (displayObjectOn)
                displayObjectOn.SetActive(doSync);
            if (displayObjectOff)
                displayObjectOff.SetActive(!doSync);

            foreach (var penManager in settings.penManagers)
                if (penManager)
                    penManager._SetEnabledSync(doSync);
        }
    }
}
