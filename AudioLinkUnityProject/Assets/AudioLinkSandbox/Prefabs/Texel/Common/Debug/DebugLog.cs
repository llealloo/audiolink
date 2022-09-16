
using UdonSharp;
using UnityEngine;
using UnityEngine.UI;
using VRC.SDKBase;
using VRC.Udon;

namespace Texel
{
    [AddComponentMenu("Texel/Debug Log")]
    [UdonBehaviourSyncMode(BehaviourSyncMode.Manual)]
    public class DebugLog : UdonSharpBehaviour
    {
        public string title;
        public Text titleText;
        public Text debugText;
        public int lineCount = 27;
        public bool timestamp = false;

        string[] debugLines;
        int debugIndex = 0;

        private void Start()
        {
            if (Utilities.IsValid(titleText))
                titleText.text = title;
        }

        public void _Write(string component, string message)
        {
            if (debugLines == null || debugLines.Length == 0)
            {
                debugLines = new string[lineCount];
                for (int i = 0; i < debugLines.Length; i++)
                    debugLines[i] = "";
            }

            string stamp = "";
            if (timestamp)
                stamp = string.Format("[{0,9:F3}] ", Time.time);

            debugLines[debugIndex] = $"{stamp}[{component}] {message}";

            string buffer = "";
            for (int i = debugIndex + 1; i < debugLines.Length; i++)
                buffer = buffer + debugLines[i] + "\n";
            for (int i = 0; i < debugIndex; i++)
                buffer = buffer + debugLines[i] + "\n";
            buffer = buffer + debugLines[debugIndex];

            debugIndex += 1;
            if (debugIndex >= debugLines.Length)
                debugIndex = 0;

            if (Utilities.IsValid(debugText))
                debugText.text = buffer;
        }

        public void _WriteError(string component, string message)
        {
            _Write(component, $"<color=#FF0000>{message}</color>");
        }
    }
}