# UdonAirtime
An expressive movement system for VRChat. Includes variable jump height, double jumping, wall riding, wall jumping, and rail grinding via an Udon-powered bézier curve implementation.

## Requirements
* Unity 2019.4.x
* VRCSDK3 (Minimum WORLD-2021.08.04.15.07)
* [UdonSharp](https://github.com/MerlinVR/UdonSharp) (Minimum 0.20.1)
* (Optional) [Simple Object Pool](https://vrcprefabs.com/browse) (search in Udon Prefabs tab)

## Download
Get it in the [releases](https://github.com/squiddingme/UdonAirtime/releases).

## Basic Setup
1. Import VRChat SDK3 to project (don't forget to let the SDK set up your layers and collision matrix)
2. Import [UdonSharp](https://github.com/MerlinVR/UdonSharp) to project
3. (Optional) Import [Simple Object Pool](https://vrcprefabs.com/browse) to project to use the PooledPlayerController, which allows everyone to see each other's effects and sounds
4. Import UdonAirtime package to project

Follow additional instructions and documentation found in readme.pdf in release packages for world and grind rail setup.

## License
This work is licensed under the terms of the MIT license.