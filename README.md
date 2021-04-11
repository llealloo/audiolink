# Udon AudioLink

## A repository of audio reactive prefabs for VRChat, written in UdonSharp

AudioLink is a system that analyzes the frequencies of in-world audio and exposes the amplitude data to VRChat Udon, world shaders, and avatar shaders. 

The per-frequency audio amplitude data is first read briefly into Udon using Unity's GetSpectrumData. It is then sent to the GPU for signal processing, filtering, and buffered into a CustomRenderTexture which is quickly accessible to other shaders in-world. The CustomRenderTexture is then read back into Udon as a Color[] array of pixels (via ReadPixels) called "audioData" that is easy to access from other UdonBehaviours. As a final step, the CustomRenderTexture is captured as a named grab pass called AudioTexture which can be picked up by shaders globally- including avatars. Both the audioData (ReadPixels) and AudioTexture (grab pass) can be toggled off if performance is an issue, but several of the bundled prefabs rely upon audioData for proper functioning.

##### [Public example world](https://vrchat.com/home/launch?worldId=wrld_7cfa5d1c-4177-43ec-ab05-26ec62bb5088)

## Limitations
- Currently, AVPro Video Player and embedded audio are the only supported audio input sources (sorry no built in Unity video player support yet)
- This package is intended for world building. Audio reactive shaders for avatars will be a separate repo (coming soon)

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
1. Drag AudioLink4 into scene
2. Link audio source.
   * for AVPro Video Player, drag the AVPro video player from your scene (the object with the "VRCAV Pro Video Player" component) into **AudioLink4/AudioLinkInput/VRCAV Pro Video Speaker** "Video Player" field.
   * for embedded audio source, add a new AudioSource to your scene with your embedded audio, then link the same AudioClip to **AudioLink4/AudioLinkInput/Audio Source** "Audio Clip" field. Note: if your audio is set to loop, make sure that loop is also enabled on AudioLinkInput.
3. Drag AudioLink4Controller into scene and drag AudioLink4 into the controller's "Audio Link" parameter.
4. Add some audio reactive objects
   * **AudioReactiveLight** is a Unity light with an UdonBehaviour attached. It will pulse intensity and/or hue shift to the audio.
   * **AudioReactiveObject** is an empty GameObject with an UdonBehaviour attached. Add your own objects underneath these to make audio reactive motion.
   * **AudioReactiveSurface** is a Cube with a special shader and an UdonBehaviour attached. This is a highly optimized audio emissive object.
5. Click the "Link all sound reactive objects..." button to link everything up.

### Note about default settings
This is set up by default to export the AudioTexture grab pass (which enables avatar shader link). To disable this feature, uncheck "Audio Texture Toggle" on the AudioLink object.

### Other examples
Also included are 2 versions of the base module setup with more spectrum band data points (32 and 128). They are useful in their own way, i.e. for making an equalizer, but the data is dirtier/noisier and less useful when in use with the other prefab objects so far in this toolkit.

### Updating from 0.1.4 or earlier to 0.1.5+
Even though there are some major under the hood changes, thankfully this is just a few clicks:
1. Install the new AudioLink package overtop of your old version (double click downloaded package to open in Unity)
2. Accept all changes & additions
3. In your scene, remove AudioLink4 + AudioLink4Controller
4. Re-add AudioLink4 and AudioLink4Controller to the scene
5. Follow "Getting Started" section above to relink audio source and existing sound reactive objects. The audio input method has changed from before.

## Thank you
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
- Shelter, Loner, Rizumu, and all of the other dance communities in VRChat for making this