using System.Collections;
using UnityEditor;

namespace VRC.PackageManagement.Resolver
{
    public class EditorCoroutine
    {
        public static EditorCoroutine Start( IEnumerator _routine )
        {
            EditorCoroutine coroutine = new EditorCoroutine(_routine);
            coroutine.start();
            return coroutine;
        }
    
    
        public static EditorCoroutine Start(System.Action _action)
        {
            EditorCoroutine coroutine = new EditorCoroutine(_action);
            coroutine.start();
            return coroutine;
        }
    
        readonly IEnumerator routine;
        EditorCoroutine( IEnumerator _routine )
        {
            routine = _routine;
        }
    
        readonly System.Action action;
        EditorCoroutine(System.Action _action)
        {
            action = _action;
        }
    
        void start()
        {
            EditorApplication.update += update;
        }
        public void stop()
        {
            EditorApplication.update -= update;
        }
    
        void update()
        {
            if (routine != null)
            {
                if (!routine.MoveNext())
                    stop();
            }
            else if (action != null)
            {
                action();
                stop();
            }
            else
                stop();
    
        }
    }
}