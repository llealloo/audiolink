#if PVR_CCK_WORLDS
using PVR.CCK.Worlds.Components;
using UnityEditor;
using UnityEngine;

namespace AudioLink.Editor
{
    public static class AudioLinkPSharpIncludeManager
    {
        [InitializeOnLoadMethod]
        public static void SetupPSharpIncludes()
        {
            PVR_WorldDescriptor descriptor = Object.FindObjectOfType<PVR_WorldDescriptor>(); // Scripts not reference in a world descriptor will not compile, so we automatically set them up

			if (descriptor == null) return;

			if (!descriptor.psharpIncludes.Contains("Packages/com.llealloo.audiolink/Runtime/Scripts/AudioLink.PlayerAPI.cs"))
				descriptor.psharpIncludes.Add("Packages/com.llealloo.audiolink/Runtime/Scripts/AudioLink.PlayerAPI.cs");
			if (!descriptor.psharpIncludes.Contains("Packages/com.llealloo.audiolink/Runtime/Scripts/AudioLink.DataAPI.cs"))
				descriptor.psharpIncludes.Add("Packages/com.llealloo.audiolink/Runtime/Scripts/AudioLink.DataAPI.cs");
			if (!descriptor.psharpIncludes.Contains("Packages/com.llealloo.audiolink/Runtime/Scripts/UdonSyncedAttribute.cs"))
				descriptor.psharpIncludes.Add("Packages/com.llealloo.audiolink/Runtime/Scripts/UdonSyncedAttribute.cs");
			if (!descriptor.psharpIncludes.Contains("Packages/com.llealloo.audiolink/Runtime/Scripts/AudioLinkEnums.cs"))
				descriptor.psharpIncludes.Add("Packages/com.llealloo.audiolink/Runtime/Scripts/AudioLinkEnums.cs");
			if (!descriptor.psharpIncludes.Contains("Packages/com.llealloo.audiolink/Runtime/Scripts/AudioReactive.cs"))
				descriptor.psharpIncludes.Add("Packages/com.llealloo.audiolink/Runtime/Scripts/AudioReactive.cs");
		}
    }
}
#endif