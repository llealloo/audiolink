#if UNITY_EDITOR
using UnityEngine;
using UnityEditor;

public class CreateMesh : MonoBehaviour
{
	[MenuItem("Tools/CNBallpit Create Mesh")]
	static void CreateMesh_()
	{
		int size = (32 * 32 * 32)/8;
		Mesh mesh = new Mesh();
		mesh.vertices = new Vector3[1];
		mesh.bounds = new Bounds(new Vector3(0, 0, 0), new Vector3(400, 400, 400));
		mesh.SetIndices(new int[size], MeshTopology.Points, 0, false, 0);
		AssetDatabase.CreateAsset(mesh, "Assets/cnballpit/ball_points_big.asset");

		mesh = new Mesh();
		mesh.vertices = new Vector3[1];
		mesh.bounds = new Bounds(new Vector3(0, 0, 0), new Vector3(0.03125f, 0.03125f, 0.03125f));
		mesh.SetIndices(new int[size], MeshTopology.Points, 0, false, 0);
		AssetDatabase.CreateAsset(mesh, "Assets/cnballpit/ball_points_small.asset");
	}
}
#endif