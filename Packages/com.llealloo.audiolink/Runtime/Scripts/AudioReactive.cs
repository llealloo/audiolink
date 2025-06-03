using UnityEngine;

namespace AudioLink.Reactive
{
#if UDONSHARP
    using UdonSharp;

    [UdonBehaviourSyncMode(BehaviourSyncMode.None)]
    public abstract class AudioReactive : UdonSharpBehaviour
#else
    public abstract class AudioReactive : MonoBehaviour
#endif
    {
        // Maybe something will go here later,
        //
        // For now this is a abstract class for providing
        // a Universal AudioReactive Inspector.
    }
}