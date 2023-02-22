Simple object pool by Phasedragon
V0.2 October 16th 2020

REQUIRES UDONSHARP

This is an Udonsharp script that will distribute a unique object to every player in the instance. The primary advantage of this system is that it
does not rely on synced variables, network events, or even ownership to determine who owns what object. This means that as soon as a player joins
they know exactly what object to grab and they do not have to wait for the master to give them anything. This also means that you can use
an alternate mode where no ownership transfer happens at all and yet everyone can still agree exactly who "owns' which object.

## Intended use case

	Objects in this pool should be used for replicating local objects across the network or displaying information from VRCPlayerAPIs.

	Synced variables should not STORE values as a way of keeping track of state. Instead they should be used to DISPLAY data.

## Setup

	1: Create a new gameobject and give it the "SimpleObjectPool" Udonbehaviour

	2: Compile all scripts
	
	3: Create a child of that gameobject and give it the desired child script. This can be either "ObjectPoolChild" or your own custom script.

	4: If you want to use your own child script, there are only 2 things you need:
		1: UpdateOwner method that sets some variable to the networking owner
		2: OnPlayerLeft method that sets that variable to null.
		Take a look at the object pool child script to see how these are done. Everything else on that script is non-critical.

	5: Duplicate that object until there are 80 copies (or your world capacity times two)

## DoNotTransferOwnership mode

	When this bool is enabled, no ownership transfer will happen to the children. This significantly reduces network load at the cost of not being
	able to use synced variables. There are a lot of situations where you might not need synced variables, such as adding hitboxes or nametags
	to players. If you use this mode, setup is slightly different. When creating your own child script, the correct owner is sent to a variable
	named "Owner" on your script. "UpdateOwner" is then called in order for your script to react to that change.

## What can be guaranteed

	All pool objects not in use will be disabled so they do not incur additional cost through update loops and network syncing.

	Objects are assigned with priority given to players that joined earliest.

	UpdateOwner will not be called until the correct owner has fully taken ownership.

	If you use the "GetPlayersObject" function, that will always give you the correct object, even if the networking owner has not updated yet.

	This script will not use any synced variables and in most cases, it will not send any network events. One network event is used as a last resort.

## What cannot be guaranteed

	Players will not always have the same object as when they joined. When a player leaves, some objects shift around to fill the missing spot.

	Instances with a large number of players may not work well with this system. It is still under development so that may change.