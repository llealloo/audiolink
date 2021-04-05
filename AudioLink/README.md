# VRChat Audio Reactivity Prefab
A repository containing audio reactive prefabs for VRChat Udon

## Public example world:
https://vrchat.com/home/launch?worldId=wrld_7cfa5d1c-4177-43ec-ab05-26ec62bb5088

## Prerequisite packages:
- VRChat SDK3 Udon
- UdonSharp
- CyanEmu (optional but highly recommended)

# Download the latest release here:
https://github.com/llealloo/vrc-udon-audio-link/releases/latest

# Installation:

First, have a look at the example scene, "AudioLink4_ExampleScene". It contains a lot of visual documentation of what is going on and includes several example setups. Or cut to the chase:

1) Drag AudioLink4 into scene
2) Drag audio source into AudioLink4 -> "Audio Source" parameter.
3) (optional, recommended) Drag AudioLink4Controller into scene and drag AudioLink4 into the controller's "Audio Link" parameter.

This is set up automatically to export the _AudioTexture globally (including to avatar shaders). To disable this feature, uncheck "Audio Texture Toggle" on the AudioLink object.

To use the other prefabs like AudioReactiveLight & AudioReactiveSurface, please see the example scene for use cases. Generally speaking though, you will just have to drag the prefab into the scene and link the AudioLink4 object onto it.

Also included are 2 other versions of the base module setup with more spectrum bands (32 and 128). They are useful in their own way, but the data is dirtier/noisier and less useful with the other prefab objects so far in this toolkit.


# Thank you
- phosphenolic for the math wizardry, conceptual programming, debugging, design help and emotional support!!!
- Merlin for making UdonSharp and offering many many pointers along the way. Thank you Merlin!
- Orels1 for all of the great help with MaterialPropertyBlocks & shaders
- CyanLaser for making CyanEmu
- Lyuma for helping in many ways and being super nice!
- fuopy for being awesome and reflecting great vibes back into this project
- Colonel Cthulu for incepting the idea to make the audio data visible to avatars
- jackiepi for math wizardry, emotional support and inspiration
- Barry, OM3, GRIMECRAFT for stoking my fire!
- Lamp for the awesome example music and inspiration. Follow them!! https://soundcloud.com/lampdx
- Shelter, Loner, Rizumu, and all of the other dance communities in VRChat for making this project worthwhile