#if !UDONSHARP
namespace AudioLink { internal class UdonSyncedAttribute : System.Attribute { } } // stub so we don't have to do the #if UDONSHARP song and dance
#endif