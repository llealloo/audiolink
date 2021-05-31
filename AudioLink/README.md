# Udon AudioLink

## A repository of audio reactive prefabs for VRChat, written in UdonSharp

AudioLink is a system that analyzes the frequencies of in-world audio and exposes the amplitude data to VRChat Udon, world shaders, and avatar shaders. 

The per-frequency audio amplitude data is first read briefly into Udon using Unity's GetOutputData. It is then sent to the GPU for signal processing, filtering, and buffered into a CustomRenderTexture which is quickly accessible to other shaders in-world. The CustomRenderTexture is then read back into Udon as a Color[] array of pixels (via ReadPixels) called "audioData" that is easy to access from other UdonBehaviours. As a final step, the CustomRenderTexture is captured as a named grab pass called AudioTexture which can be picked up by shaders globally- including avatars. Both the audioData (ReadPixels) and AudioTexture (grab pass) can be toggled off if performance is an issue, but several of the bundled prefabs rely upon audioData for proper functioning.

##### [Public example world (V1)](https://vrchat.com/home/launch?worldId=wrld_7cfa5d1c-4177-43ec-ab05-26ec62bb5088)
##### [Public example world (V2)](https://vrchat.com/home/launch?worldId=wrld_8554f998-d256-44b2-b16f-74aa32aac214)

## Limitations
- Currently, only 2D audio sources are supported when using Unity video player. For 3D audio sources, please use the AVPro video player and refer to the getting started section for setup with AudioLinkInput method.

## What's new in v2

### New features
- ColorChord support
- Autocorrelator waveform visualizer functionality
- Full raw waveform, VU meter, and 240 point spectrogram (all data is also accessible to avatars)
- New _AudioTexture (avatar texture) size: now 128x64 instead of 32x4. Make sure your avatar and world shaders are updated to the latest & compatible.
- Compatibility in Avatar SDK3 projects for easy local testing with avatars
- New controller with greatly enhanced crossover system & live spectral analysis
- AudioReactiveSurfaceArray prefab: for controlling tens or hundreds of objects using AudioReactiveSurface shader at once w/ GPU instancing
- AudioReactiveSurface pulse: adds a pulse across the UV of the mesh w/ customizable rotation and pulse scale

### Bug fixes
- AudioReactiveObject scale now works

### Migrating from v1 to v2
1. Make sure you have the latest VRChat SDK3 and UdonSharp installed.
2. In your scene, remove AudioLink4 + AudioLink4Controller
3. Close Unity. Using Explorer, delete the AudioLink directory in your Project/Assets folder as well as the associated AudioLink.meta file
4. Open your project in unity again, and install the latest AudioLink v2 package
5. Re-add AudioLink and AudioLinkController to the scene
6. Follow "Getting Started" section to relink audio source and existing sound reactive objects.

## Setup

### Requirements
- VRChat SDK3 for worlds (Udon)
- UdonSharp
- CyanEmu (optional but highly recommended)
- The latest release: https://github.com/llealloo/vrc-udon-audio-link/releases/latest

### Installation
1. Install VRChat SDK3, UdonSharp, CyanEmu, and the latest release of AudioLInk
1. Have a look at the example scene, "AudioLink4_ExampleScene". It contains a lot of visual documentation of what is going on and includes several example setups. Or cut to the chase:

### Getting started
1. Drag AudioLink into scene
2. Link audio source.
   * for 3D audio with AVPro Video Player, drag the AVPro video player from your scene (the object with the "VRCAV Pro Video Player" component) into **AudioLink/AudioLinkInput/VRCAV Pro Video Speaker** "Video Player" field and make sure that AudioLink is using AudioLinkInput as its audio source.
   * for 2D audio sources, drag the audio source into AudioLink's audio source field.
3. Drag AudioLinkController into scene and drag AudioLink into the controller's "Audio Link" parameter.
4. Add some audio reactive objects
   * **AudioReactiveLight** is a Unity light with an UdonBehaviour attached. It will pulse intensity and/or hue shift to the audio.
   * **AudioReactiveObject** is an empty GameObject with an UdonBehaviour attached. Add your own objects underneath these to make audio reactive motion.
   * **AudioReactiveSurface** is a Cube with a special shader and an UdonBehaviour attached. This is a highly optimized audio emissive object.
5. Click the "Link all sound reactive objects..." button to link everything up.

### Note about default settings
This is set up by default to export the AudioTexture grab pass (which enables avatar shader link). To disable this feature, uncheck "Audio Texture Toggle" on the AudioLink object.

### Installing to test Avatar projects
1. Import AudioLink into your avatar project
2. Drag AudioLinkAvatar prefab into scene with your avatar
3. Add your favorite music track to test with to your project
4. Drag your music track from the Project panel into the Hierarchy to create a new AudioSource GameObject
5. Drag the AudioSource object that was created in the Hierarchy into AudioLinkAvatar/audioSource parameter
6. Adjust the Gain/Bass/Treble settings on AudioLinkAvatar if necessary
7. Hit play!

## Thank you
- phosphenolic for the math wizardry, conceptual programming, debugging, design help and emotional support!!!
- cnlohr for the help with the new DFT spectrogram and helping to port AudioLink to 100% shader code
- lox9973 for autocorrelator functionality and the inspirational & tangential math help with signal processing
- Texelsaur for the AudioLinkMiniPlayer and support!
- Merlin for making UdonSharp and offering many many pointers along the way. Thank you Merlin!
- Orels1 for all of the great help with MaterialPropertyBlocks & shaders and the auto configurator script for easy AV3 local testing
- Xiexe for the help developing and testing
- Thryrallo for the help setting up local AV3 testing functionality
- CyanLaser for making CyanEmu
- Lyuma for helping in many ways and being super nice!
- fuopy for being awesome and reflecting great vibes back into this project
- Colonel Cthulu for incepting the idea to make the audio data visible to avatars
- jackiepi for math wizardry, emotional support and inspiration
- Barry, OM3, GRIMECRAFT for stoking my fire!
- Lamp for the awesome example music and inspiration. Follow them!! https://soundcloud.com/lampdx
- Shelter, Loner, Rizumu, and all of the other dance communities in VRChat for making this