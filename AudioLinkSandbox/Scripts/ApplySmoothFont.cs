
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;


#if !COMPILER_UDONSHARP && UNITY_EDITOR // These using statements must be wrapped in this check to prevent issues on builds
using UnityEditor;
using UdonSharpEditor;
#endif

namespace ApplySmoothFont
{
	public class ApplySmoothFont : UdonSharpBehaviour
	{
		[TextArea]
		public string TextSet;
		public int Columns;
		public int Rows;
		public Material mat_ApplySmoothTex;
		private Material UseMaterial;

		void Start()
		{
			if( Rows == 0 ) Rows = 10;
			if( Columns == 0 ) Columns = 20;
			UpdateProps();
		}
		
		public void UpdateProps()
		{
			if( Rows == 0 ) Rows = 10;
			if( Columns == 0 ) Columns = 20;

#if !COMPILER_UDONSHARP && UNITY_EDITOR 
			UseMaterial = new Material(mat_ApplySmoothTex);
#else
			GetComponent<MeshRenderer>().sharedMaterial = mat_ApplySmoothTex;
			UseMaterial = GetComponent<MeshRenderer>().material;
#endif
			//gameObject. 
			UseMaterial.SetInt( "Cols", Columns );
			UseMaterial.SetInt( "Rows", Rows );
			Color [] chardata = new Color[Columns*Rows];
			
			int lx = 0, ly = 0;
			int i = 0;
			
			Color currentColor;
			currentColor.r = 1;
			currentColor.g = 1;
			currentColor.b = 1;
			currentColor.a = 0;
			
			int mode = 0;
			string thistag = "";
			int weight = 0;
			
			for( i = 0; i < TextSet.Length && lx+ly*Columns < Rows*Columns; i++ )
			{
				byte cs = (byte)TextSet[i];
				if( mode == 0 )
				{
					if( cs == 10 )
					{
						// Handle newlines
						lx = 0;
						ly++;
					}
					else if( cs == '<' )
					{
						thistag = "";
						mode = 1;
					}
					else
					{
						// Actually emit a character.
						chardata[lx+ly*Columns] = currentColor;
						chardata[lx+ly*Columns].a = (cs/256.0f) + weight*100+100;
						Debug.Log( chardata[lx+ly*Columns].a );
						lx++;
						if(lx == Columns)
						{
							lx = 0;
							ly++;
						}
					}
				}
				else if( mode == 1 )
				{
					//Parsing based off of https://pinetools.com/syntax-highlighter
					
					if( cs == '>' )
					{
						int weightindex = thistag.IndexOf( "font-weight" );
						int colorindex = thistag.IndexOf( "rgb(" );
						if( weightindex >= 0 )
						{
							weight = 1;
						}
						else
						{
							weight = 0;
						}
						if( colorindex >= 0 )
						{
							string[] rgbv = thistag.Substring( colorindex+4 ).Split( ',', ')', '\"' );
							int tmp;
							
							currentColor.r = int.TryParse( rgbv[0], out tmp )?tmp/255.0f:1.0f;
							currentColor.g = int.TryParse( rgbv[1], out tmp )?tmp/255.0f:1.0f;
							currentColor.b = int.TryParse( rgbv[2], out tmp )?tmp/255.0f:1.0f;
						}
						else
						{
							currentColor.r = 1;
							currentColor.g = 1;
							currentColor.b = 1;
						}
						mode = 0;
					}
					else
					{
						thistag += TextSet[i];
					}
				}
			}
			UseMaterial.SetColorArray( "FontData", chardata );
			
			GetComponent<MeshRenderer>().sharedMaterial = UseMaterial;
		}
	}
	
#if !COMPILER_UDONSHARP && UNITY_EDITOR 
    [CustomEditor(typeof(ApplySmoothFont))]
    public class ApplySmoothFontEditor : Editor
    {
        public override void OnInspectorGUI()
        {
            // Draws the default convert to UdonBehaviour button, program asset field, sync settings, etc.
            if (UdonSharpGUI.DrawDefaultUdonSharpBehaviourHeader(target)) return;

            ApplySmoothFont inspectorBehaviour = (ApplySmoothFont)target;

            EditorGUI.BeginChangeCheck();

            // A simple string field modification with Undo handling
            string newStrVal = EditorGUILayout.TextArea( inspectorBehaviour.TextSet );
            int Columns = EditorGUILayout.IntField( "Columns", inspectorBehaviour.Columns );
            int Rows    = EditorGUILayout.IntField( "Rows", inspectorBehaviour.Rows );

            if (EditorGUI.EndChangeCheck())
            {
                Undo.RecordObject(inspectorBehaviour, "Modify string val");
                inspectorBehaviour.TextSet = newStrVal;
                inspectorBehaviour.Columns = Columns;
                inspectorBehaviour.Rows = Rows;
				inspectorBehaviour.UpdateProps();
            }
        }
    }
#endif
}
