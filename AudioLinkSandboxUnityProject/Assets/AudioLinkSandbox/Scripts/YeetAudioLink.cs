
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

public class YeetAudioLink : UdonSharpBehaviour
{
    
    public float yeetIntensity = 10;
    public GameObject spawn;
    
    private float _lastYeet;
    private Vector3 _startPosition;
    private Quaternion _startRotation;

    void Start()
    {
        _lastYeet = 0;
        _startPosition = transform.position;
        _startRotation = transform.rotation;
    }

    public override void OnPlayerTriggerStay(VRCPlayerApi player)
    {
        OnPlayerTriggerEnter( player );
    }
    
    public override void OnPlayerTriggerEnter(VRCPlayerApi player)
    {
        if( Time.timeSinceLevelLoad - _lastYeet > 0.2 && Vector3.Distance( transform.position, spawn.transform.position ) > 7 )
        {
            Vector3 yeetvector = transform.TransformDirection( Vector3.forward ) * -yeetIntensity;
            player.SetVelocity( yeetvector );
            _lastYeet = Time.timeSinceLevelLoad;
        }
    }
    
    public void OnTriggerEnter(Collider collide)
    {
        Vector3 yeetvector = transform.TransformDirection( Vector3.forward ) * -yeetIntensity;
        if( Utilities.IsValid( collide ) )
        {
            GameObject go = collide.gameObject;
            if( Utilities.IsValid( go ) )
            {
                Rigidbody rb = collide.gameObject.GetComponent<Rigidbody>();
                if( Utilities.IsValid( rb ) )
                {
                    rb.velocity = yeetvector;
                }
            }
        }
    }

    public void Respawn()
    {
        if (Networking.IsOwner(gameObject))
        {
            transform.SetPositionAndRotation(_startPosition, _startRotation);
        }
    }
}
