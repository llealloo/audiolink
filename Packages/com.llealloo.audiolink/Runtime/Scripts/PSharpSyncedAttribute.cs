#if !PVR_CCK_WORLDS
namespace AudioLink {
	internal class PSharpSyncedAttribute : System.Attribute 
	{
		public readonly SyncType syncType;
		public readonly string valueChangedCallback;

		public PSharpSyncedAttribute(SyncType type = 0, string valueChangedCallback = null)
		{
			// Stub, same reason as the UdonSyncedAttribute, but for if we dont have the PVR Worlds CCK
		}
	}
	public enum SyncType
	{
		Automatic,
		Manual
	}
}
#endif