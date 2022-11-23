using UnityEngine;
using VRC.SDKBase;

#if UDON
using UdonSharp;
using VRC.Udon;
using BrokeredUpdates;

public class ballpit_stable_control : UdonSharpBehaviour
{
	[UdonSynced] public float gravityF = 9.8f;
	[UdonSynced] public float friction = .008f;
	[UdonSynced] public int mode = 3;
	[UdonSynced] public bool balls_reset = false;
	
	public int qualitymode;
	public Material ballpitA;
	public Material ballpitB;
	public Material ballpitRender;
	public GameObject ballpitRenderObject;
	public Material VideoToStealMaterial;
	public CustomRenderTexture CRTColors;
	public Camera   depthCameraTop;
	public Camera   depthCameraBottom;
	public Shader   depthOverrideShader;
	
	public GameObject Fan0;
	public GameObject Fan1;
	public GameObject Fan2;
	public GameObject Magnet0;
	public GameObject Magnet1;
	public GameObject Magnet2;
	public GameObject Shroom0;
	public GameObject Shroom1;
	public GameObject Shroom2;
	public GameObject Shroom3;
	public GameObject Shroom4;
	public GameObject Shroom5;
	
	int numupdatebuttons;
	ballpit_update_property [] updatebuttons;
	
	int was_mode = 100;
	bool was_balls_reset = false;
	float was_gravity_f = 0;
	float was_friction = 0;
	int was_qualitymode = 0;
	bool was_master = false;

	void Start()
	{
		if (Networking.IsMaster)
		{
			gravityF = 9.8f;
			friction = .008f;
			mode = 3;
			balls_reset = false;
		}
		qualitymode = 1;
		Debug.Log( "ballpit stable control " + gravityF + " / " + friction );
		//GameObject.Find( "BrokeredUpdateManager" ).GetComponent<BrokeredUpdateManager>()._RegisterSlowUpdate( this );
	}
	
	public void AddUpdatable( ballpit_update_property btn )
	{
		if( updatebuttons == null )
		{
			updatebuttons = new ballpit_update_property[20];
			numupdatebuttons = 0;
		}
		updatebuttons[numupdatebuttons++] = btn;
	}
	
	public void ModeUpdate()
	{
		if( was_mode != mode || was_balls_reset != balls_reset || gravityF != was_gravity_f || friction != was_friction || qualitymode != was_qualitymode || was_master != Networking.IsMaster )
		{
			ballpitA.SetFloat( "_ResetBalls", balls_reset?1.0f:0.0f );
			ballpitB.SetFloat( "_ResetBalls", balls_reset?1.0f:0.0f );
			ballpitRender.SetFloat( "_Mode", mode );

			CRTColors.updateMode = (mode == 6)?CustomRenderTextureUpdateMode.Realtime:CustomRenderTextureUpdateMode.OnLoad;

			ballpitA.SetFloat( "_GravityValue", gravityF );
			ballpitB.SetFloat( "_GravityValue", gravityF );
			ballpitA.SetFloat( "_Friction", friction );
			ballpitB.SetFloat( "_Friction", friction );
			ballpitRender.SetFloat( "_ExtraPretty", qualitymode );
			Physics.gravity = new Vector3( 0, -(gravityF*.85f+1.5f), 0 );
			
			was_master = Networking.IsMaster;
			was_qualitymode = qualitymode;
			was_mode = mode;
			was_balls_reset = balls_reset;
			was_gravity_f = gravityF;
			was_friction = friction;

			int i;
			for( i = 0; i < numupdatebuttons; i++ )
			{
				updatebuttons[i].UpdateMaterialWithSelMode();
			}
		}
	}
	
	public void _SlowUpdate()
	{
		//TODO: This should not be needed every frame.
		ModeUpdate();
		
		Transform t;

		if( Utilities.IsValid( Fan0 ) )
		{
			t = Fan0.transform;
			Vector4 fan_position = t.localPosition;
			Vector4 fan_rotation = new Vector4( t.localRotation.x, t.localRotation.y, t.localRotation.z, t.localRotation.w );
			fan_position.w = t.localScale.z;
			ballpitA.SetVector( "_FanPosition0", fan_position );
			ballpitA.SetVector( "_FanRotation0", fan_rotation );
			ballpitB.SetVector( "_FanPosition0", fan_position );
			ballpitB.SetVector( "_FanRotation0", fan_rotation );
		}
		if( Utilities.IsValid( Fan1 ) )
		{
			t = Fan1.transform;
			Vector4 fan_position = t.localPosition;
			Vector4 fan_rotation = new Vector4( t.localRotation.x, t.localRotation.y, t.localRotation.z, t.localRotation.w );
			fan_position.w = t.localScale.z;
			ballpitA.SetVector( "_FanPosition1", fan_position );
			ballpitA.SetVector( "_FanRotation1", fan_rotation );
			ballpitB.SetVector( "_FanPosition1", fan_position );
			ballpitB.SetVector( "_FanRotation1", fan_rotation );
		}
		if( Utilities.IsValid( Fan2 ) )
		{
			t = Fan2.transform;
			Vector4 fan_position = t.localPosition;
			Vector4 fan_rotation = new Vector4( t.localRotation.x, t.localRotation.y, t.localRotation.z, t.localRotation.w );
			fan_position.w = t.localScale.z;
			ballpitA.SetVector( "_FanPosition2", fan_position );
			ballpitA.SetVector( "_FanRotation2", fan_rotation );
			ballpitB.SetVector( "_FanPosition2", fan_position );
			ballpitB.SetVector( "_FanRotation2", fan_rotation );
		}
		if( Utilities.IsValid( Magnet0 ) )
		{
			t = Magnet0.transform;
			Vector4 fan_position = t.localPosition;
			fan_position.w = t.localScale.x*5;
			ballpitA.SetVector( "_MagnetPos0", fan_position );
			ballpitB.SetVector( "_MagnetPos0", fan_position );
		}
		if( Utilities.IsValid( Magnet1 ) )
		{
			t = Magnet1.transform;
			Vector4 fan_position = t.localPosition;
			fan_position.w = t.localScale.x*5;
			ballpitA.SetVector( "_MagnetPos1", fan_position );
			ballpitB.SetVector( "_MagnetPos1", fan_position );
		}
		if( Utilities.IsValid( Magnet2 ) )
		{
			t = Magnet2.transform;
			Vector4 fan_position = t.localPosition;
			fan_position.w = t.localScale.x*5;
			ballpitA.SetVector( "_MagnetPos2", fan_position );
			ballpitB.SetVector( "_MagnetPos2", fan_position );
		}
		if( Utilities.IsValid( Shroom0 ) )
		{
			t = Shroom0.transform;
			Vector4 fan_position = t.localPosition;
			fan_position.w = t.localScale.x;
			ballpitA.SetVector( "_ShroomPos0", fan_position );
			ballpitB.SetVector( "_ShroomPos0", fan_position );
		}
		if( Utilities.IsValid( Shroom1 ) )
		{
			t = Shroom1.transform;
			Vector4 fan_position = t.localPosition;
			fan_position.w = t.localScale.x;
			ballpitA.SetVector( "_ShroomPos1", fan_position );
			ballpitB.SetVector( "_ShroomPos1", fan_position );	
		}
		if( Utilities.IsValid( Shroom2 ) )
		{
			t = Shroom2.transform;
			Vector4 fan_position = t.localPosition;
			fan_position.w = t.localScale.x;
			ballpitA.SetVector( "_ShroomPos2", fan_position );
			ballpitB.SetVector( "_ShroomPos2", fan_position );
		}
		if( Utilities.IsValid( Shroom3 ) )
		{
			t = Shroom3.transform;
			Vector4 fan_position = t.localPosition;
			fan_position.w = t.localScale.x;
			ballpitA.SetVector( "_ShroomPos3", fan_position );
			ballpitB.SetVector( "_ShroomPos3", fan_position );		
		}
		if( Utilities.IsValid( Shroom4 ) )
		{
			t = Shroom4.transform;
			Vector4 fan_position = t.localPosition;
			fan_position.w = t.localScale.x;
			ballpitA.SetVector( "_ShroomPos4", fan_position );
			ballpitB.SetVector( "_ShroomPos4", fan_position );
		}
		if( Utilities.IsValid( Shroom5 ) )
		{
			t = Shroom5.transform;
			Vector4 fan_position = t.localPosition;
			fan_position.w = t.localScale.x;
			ballpitA.SetVector( "_ShroomPos5", fan_position );
			ballpitB.SetVector( "_ShroomPos5", fan_position );
		}
	}
	
	//https://github.com/MerlinVR/UdonSharp/wiki/events
	public override void OnDeserialization()
	{
		ModeUpdate();
	}
}

#else
public class ballpit_stable_control : MonoBehaviour { }
#endif