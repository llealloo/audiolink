#ifndef SHADER_TARGET_SURFACE_ANALYSIS

//uint3 textureDimensions = 0;
//_MainTex.GetDimensions(0,textureDimensions.x,textureDimensions.y,textureDimensions.z);

// You must define:
// VT_TRACE as a name for the trace function
// VT_FN    as a function you implement for getting data
//

#ifndef VT_MAXITER
#define VT_MAXITER 511
#endif

// The return of RayPos actually is the surface of the object where we started tracing.
float4 VT_TRACE( uint3 ARRAYSIZE, inout float3 RayPos, float3 RayDir, float4 Accumulator, float TravelLength = 1e20  )
{
	float3 InvRayDir = -1./RayDir;

	{
		float adv = 0;

		// Trace to surface of the box on the outside.
		float3 AdvancesPlus = (RayPos-(ARRAYSIZE))*InvRayDir;
		float3 AdvancesMinus = RayPos*InvRayDir;
		float3 Mins = min( AdvancesPlus, AdvancesMinus );
		
		// we also max with 0 incase we're inside of the box, so we don't backtrack.
		adv = max( max( Mins.x, Mins.y ), max( Mins.z, 0 ) );
		RayPos += RayDir * adv;
		TravelLength -= adv;
	}
	
	{
		// Trace from where we are on the outside surface to the back
		// end of the box.
		
		float3 distpluses  = float3( RayPos.xyz * InvRayDir );
		float3 distminuses = float3( (RayPos.xyz-ARRAYSIZE) * InvRayDir );
		float3 adv3 = max( distpluses, distminuses );
		float backOfBoxTravelLength = min( min( adv3.x, adv3.y ), adv3.z )-.5;
		TravelLength = min( backOfBoxTravelLength, TravelLength );
	}
	
	RayPos += RayDir * .0001;

	fixed3 Normal;
	int3 CellD = int3( sign( RayDir ) );
	int3 CellP = int3( floor( RayPos ) );

	float4 VecZP = 0.;
	float4 VecZM = 0.;
	int iteration = 0;
	float3 PartialRayPos = frac( RayPos ); 
	
	{
		//Fist step is to step into the the cell, colliding with the grid
		//defined by AddTex.

		//Used for binary search subtracer.
		float TracedMinM = 0.;
		float MinDist;
		float MixTot = 0;

		int3 LowestAxis = 0.0;
		float3 DirComps = -sign( RayDir ); //+1 if pos, -1 if neg
		half3 DirAbs = abs( RayDir );
		float Travel = TravelLength;

		int3 AO2 = ARRAYSIZE/2;
		UNITY_LOOP
		while( ++iteration < VT_MAXITER && Travel > 0 )
		{
#if 0
			if( CellP.y >= ARRAYSIZE.y ) break;
			if( CellP.y < 0 ) break;
			if( CellP.x < 0 || 
				CellP.z < 0 || 
				CellP.x >= ARRAYSIZE.x || 
				CellP.z >= ARRAYSIZE.z )
				break;
#endif
			//if( any( abs( CellP - AO2 - 0.5 ) > AO2 ) ) break;

			//We are tracing into a cell.  Need to figure out how far we move
			//to get into the next cell.
			float3 NextSteps = frac( PartialRayPos * DirComps );

			//Anywhere we have already stepped, force it to be one full step forward.
			NextSteps = NextSteps * ( 1 - LowestAxis ) + LowestAxis;

			//Find out how many units the intersection point between us and
			//the next intersection is in ray space.  This is effectively
			float3 Dists = NextSteps / DirAbs;

			//XXX TODO: This should be optimized!
			LowestAxis = (Dists.x < Dists.y) ?
				 ( ( Dists.x < Dists.z ) ? int3( 1, 0, 0 ) : int3( 0, 0, 1 ) ) :
				 ( ( Dists.y < Dists.z ) ? int3( 0, 1, 0 ) : int3( 0, 0, 1 ) );

			//Find the closest axis.  We do this so we don't overshoot a hit.
			// We max with 0.0001 becuase we don't want a speckle when all dists
			// are almost zero.
			MinDist = max( min( min( Dists.x, Dists.y ), Dists.z ), .0001 );

			//XXX XXX XXX
			VT_FN( CellP, MinDist, Travel, Accumulator );
			
			//We now know which direction we wish to step.
			CellP += CellD * LowestAxis;
			Travel -= MinDist;

			float3 Motion = MinDist * RayDir;
			PartialRayPos = frac( PartialRayPos + Motion );
		} 
	}
	return Accumulator;
}


#endif
