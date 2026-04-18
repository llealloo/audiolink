using UnityEngine;

namespace AudioLink
{
#if UDONSHARP
    using UdonSharp;

    [UdonBehaviourSyncMode(BehaviourSyncMode.None)]
    public abstract class AudioReactive : UdonSharpBehaviour
#elif PVR_CCK_WORLDS
    using PVR.CCK.Worlds.PSharp;

    public abstract class AudioReactive : PSharpBehaviour
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