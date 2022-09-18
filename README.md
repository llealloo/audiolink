# Udon AudioLink

## A repository of audio reactive prefabs for VRChat, written in UdonSharp

AudioLink is a system that analyzes and processes in-world audio into many different highly reactive data streams and exposes the data to VRChat Udon, world shaders, and avatar shaders. 

The per-frequency audio amplitude data is first read briefly into Udon using Unity's GetOutputData. It is then sent to the GPU for signal processing and buffered into a CustomRenderTexture. Then, the CustomRenderTexture is broadcast globally (called `_AudioTexture`) which can be picked up by shaders both in-world and across all avatars. 

### [Public example world](https://vrchat.com/home/launch?worldId=wrld_8554f998-d256-44b2-b16f-74aa32aac214)
### [Documentation for shader creators](https://github.com/llealloo/vrc-udon-audio-link/tree/master/Docs)
### [If you are looking to use AudioLink for ChilloutVR, check out this fork instead](https://github.com/DomNomNomVR/cvr-audio-link)

## 0.3.0 - September 18th, 2022
### New features
- AudioLink is now a curated package! As such, it can be installed with [VRChat Creator Companion](https://vcc.docs.vrchat.com/). This is new the recommended way to install AudioLink. For avatar projects and non-VRChat use cases, there is a regular old UnityPackage you can use. Please see the readme for a guide on how to update your projects. We recommend you follow this guide, as the update is a breaking change.
- Since the folder structure has changed, custom shaders may need to be upgraded. A tool has been included to automatically upgrade shaders where needed. This tool is accessible from "AudioLink -> Update AudioLink compatible shaders" in the top menu of the editor. (Thanks, 3)
- Added Global Strings - text which can be read from AudioLink compatible shaders. Use this to retrieve the name of the local player and master in a shader, or to feed custom string data through. Info on usage is in Documentation. See `AudioLinkGetGlobalStringChar(uint stringIndex, uint charIndex)` in AudioLink.cginc for details.
- Included Amplify nodes for using AudioLink have been overhauled. They are now in their own "AudioLink" category, and handle including the relevant files automatically. Also, links to documentation are added. (Thanks, Nestorboy)
- The live AudioLink demo world has gotten an overhaul, and has a bunch of new cool things to play with.
- The included video player, AudioLinkMiniPlayer, has been updated to support LTCGI. (Thanks, Texelsaur)
- The example AudioLink scene can now be quickly accessed using the "AudioLink -> Open AudioLink Example Scene" button in the top menu of the editor.
### Changes
- The GrabPass utilized by AudioLink has been removed! We use the new `VRCShader.SetGlobalTexture` to expose a globally available texture now. This is an improvement to stability and performance. Existing shaders should still be compatible with new versions of AudioLink.
- The camera used by AudioLink to provide audio data to udon (using the Experimental Audio Readback feature) will now be disabled when it isn't needed, which should improve performance a bit.
- Be consistent with swizzling in AudioLink shaders, use 'xyzw' everywhere.
### Bugfixes
- Issue [191](https://github.com/llealloo/vrc-udon-audio-link/issues/191) and [186](https://github.com/llealloo/vrc-udon-audio-link/issues/186) have been fixed. (Thanks, 3)
- Remove some old profiling code that could have a very slight impact on performance. (Thanks, 3)

## Updating from version 2.8 or lower? (...first time setup? please see next section)
- TODO
1. Take note of which AudioSource you are using to feed AudioLink, this reference may be lost during upgrade.
2. Install the latest VRChat SDK3 and UdonSharp (following their directions)
3. Close unity
4. With Windows explorer (NOT within Unity), remove the following files & folders:
   - AudioLink (folder)
   - AudioLink.meta
5. Reopen unity
6. Download and install the [latest AudioLink release](https://github.com/llealloo/vrc-udon-audio-link/releases/latest)
7. If using AudioReactiveObject or AudioReactiveLight
   components, you will need to manually re-enable the "Audio Data" under AudioLink "experimental" settings. This feature is now considered experimental until VRChat *maybe* gives us native asynchronous readback.
8. In scene(s) containing old versions of AudioLink:
   1. Delete both AudioLink and AudioLinkController prefabs from the scene
   2. Re-add AudioLink and AudioLinkController to the scene by dragging the prefabs from the AudioLink folder in projects *(world creators only)*
   3. Click the "Link all sound reactive objects to this AudioLink" button on AudioLink inspector panel *(world creators only)*
   4. Drag the AudioSource you were using previously into the AudioLink audio source parameter
      - NOTE: If you previously used AudioLinkInput, you are welcome to continue doing so, however now in 2.5+ AudioLink is much smarter about inputs. Try dragging it straight into the AudioLink / audio source parameter!

## First time setup
Looking to test out an avatar? See the "For Avatar Testing" section. Otherwise, see the "For Worlds" section below.

### For Worlds
- TODO

### For Avatar Testing
- Download and Import the latest **UnityPackage** AudioLink Release at https://github.com/llealloo/vrc-udon-audio-link/releases
- Open the AudioLink folder and drag AudioLinkAvatar into your scene's hierarchy
- Under AudioLinkAvatar/AudioLinkInput, add a music track to the AudioClip in the AudioSource.
  - If you need it louder, duplicate the AudioLinkInput object and increase the volume on that one. Make sure Not to adjust the volume on the main AudioLinkInput object - it needs to stay at 0.01.

### For non-VRChat uses
- Download and Import the latest **UnityPackage** AudioLink Release at https://github.com/llealloo/vrc-udon-audio-link/releases
- Open the AudioLink folder and drag the AudioLink prefab into your scene's hierarchy. It should work out of the box.

### Requirements
- [VRChat SDK3](https://vrchat.com/home/download) for worlds (Udon)
- [UdonSharp](https://github.com/vrchat-community/UdonSharp/releases/latest)
- [CyanEmu](https://github.com/CyanLaser/CyanEmu/releases/latest) (optional but highly recommended)
- The latest release: https://github.com/llealloo/vrc-udon-audio-link/releases/latest

### Installation
1. Install VRChat SDK3, UdonSharp, CyanEmu, and the latest release of AudioLInk
2. Have a look at the example scene, "AudioLink_ExampleScene". It contains a lot of visual documentation of what is going on and includes several example setups. Or cut to the chase:

### Getting started
1. Drag AudioLink into scene
2. Link audio source by dragging the AudioSource gameobject into AudioLink's audio source parameter
3. Drag AudioLinkController into scene and drag AudioLink into the controller's "Audio Link" parameter.
4. Click the "Link all sound reactive objects..." button to link everything up.

### Installing to test Avatar projects
1. Import AudioLink into your avatar project
   - **NOTE**: Do _not_ install UdonSharp, CyanEmu or any other tools meant for worlds into your project. When testing avatars, you should import _only_ the AudioLink package, and none of its usual dependencies.
2. Drag AudioLinkAvatar prefab into scene with your avatar
3. Add your favorite music track to test with to your project
4. Drag your music track from the Project panel into the Hierarchy to create a new AudioSource GameObject
5. Drag the AudioSource object that was created in the Hierarchy into AudioLinkAvatar/audioSource parameter
6. Adjust the Gain/Bass/Treble settings on AudioLinkAvatar if necessary
7. Hit play!

## Compatible tools / assets
- [Silent Cel Shading Shader](https://gitlab.com/s-ilent/SCSS) by Silent
- [Mochies Unity Shaders](https://github.com/MochiesCode/Mochies-Unity-Shaders/releases) by Mochie
- [Fire Lite](https://discord.gg/24W435s) by Rollthered
- [VR Stage Lighting](https://github.com/AcChosen/VR-Stage-Lighting) by AcChosen
- [Poiyomi Shader](https://poiyomi.com/) by Poiyomi
- [orels1 AudioLink Shader](https://github.com/orels1/orels1-AudioLink-Shader) by orels1
- [VRC Things](https://github.com/PiMaker/VRChatUnityThings) by \_pi\_
- [June Screen FX](https://luka.moe/june.html) by luka

## Thank you
- phosphenolic for the math wizardry, conceptual programming, debugging, design help and emotional support!!!
- cnlohr for the help with the new DFT spectrogram and helping to port AudioLink to 100% shader code
- lox9973 for autocorrelator functionality and the inspirational & tangential math help with signal processing
- Texelsaur for the AudioLinkMiniPlayer and support!
- Pema for the help with strengthening the codebase and inspiration!
- Merlin for making UdonSharp and offering many many pointers along the way. Thank you Merlin!
- Orels1 for all of the great help with MaterialPropertyBlocks & shaders and the auto configurator script for easy AV3 local testing
- Xiexe for the help developing and testing
- Thryrallo for the help setting up local AV3 testing functionality
- CyanLaser for making CyanEmu
- Lyuma for helping in many ways and being super nice!
- ACIIL for the named texture check in AudioLink.cginc
- fuopy for being awesome and reflecting great vibes back into this project
- Colonel Cthulu for incepting the idea to make the audio data visible to avatars
- jackiepi for math wizardry, emotional support and inspiration
- Barry, OM3, GRIMECRAFT for stoking my fire!
- Lamp for the awesome example music and inspiration. Follow them!! https://soundcloud.com/lampdx
- Shelter, Loner, Rizumu, and all of the other dance communities in VRChat for making this

## Developer Notes

### `reup.bat` for auto syncing a developer branch

First, fork vrc-udon-audio-link into your personal github account using the github GUI, then make a new unity project called `AudioLinkWork` then, check out your copy of of vrc-udon-audio-link, and move its contents, `.git` included into the `Assets` folder of the project you made.  Once done, place the following .bat file in that Assets folder.

I recommend executing this following `reup.bat` from the command line to address merge conflicts and other errors.

```bat
rem be sure you're on the `dev` branch!
git remote set-url origin https://github.com/llealloo/vrc-udon-audio-link
git pull
git remote set-url origin https://github.com/YOUR_GITHUB_USERNAME_HERE/vrc-udon-audio-link
```

### Version update processes

 * Update readme in both places (root and AudioLink folder)
    * Check section on how to update
    * Copy over changelog for the new version to readme 
 * Update documentation where necessary
 * Update changelog
 * Bump version number in AudioLink.cs
 * Clean up assets in wrong folders
 * Test with latest U#
 * Make release GitHub release with new relevant changelog attached
 * Update the live world
