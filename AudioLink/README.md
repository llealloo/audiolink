# Udon AudioLink

## A repository of audio reactive prefabs for VRChat, written in UdonSharp

AudioLink is a system that analyzes and processes in-world audio into many different highly reactive data streams and exposes the data to VRChat Udon, world shaders, and avatar shaders. 

The per-frequency audio amplitude data is first read briefly into Udon using Unity's GetOutputData. It is then sent to the GPU for signal processing and buffered into a CustomRenderTexture. Then, the CustomRenderTexture is broadcast globally (called `_AudioTexture`) which can be picked up by shaders both in-world and across all avatars. 

### [Public example world](https://vrchat.com/home/launch?worldId=wrld_8554f998-d256-44b2-b16f-74aa32aac214)
### [Documentation for shader creators](https://github.com/llealloo/vrc-udon-audio-link/tree/master/Docs)

## 0.2.7 - December 1st, 2021
### New features
- Make AudioLink framerate-invariant, instead of assuming a specific framerate. Features that rely on timing have been updated to reflect this change.
- Add helper functions `AudioLinkGetChronoTime`, `AudioLinkGetChronoTimeNormalized`, `AudioLinkGetChronoTimeInterval` to more easily sample chronotensity values. `AudioLinkGetChronoTime(index, band)` functions as a more-or-less drop-in replacement for `_Time.y`.
- Move `ALPASS_CCCOLORS` section from `(24,22)` to `(25,22)` to avoid confusion. Code that uses the define should continue to work fine.
### Bugfixes
- Fix a nasty bug where mirrors would sometimes causing AudioLink to stop functioning when observed from specific angles.
- Fix erroneous timing code for filtered VU and ColorChord.
- Fix some issues in the documentation.
- Version number was wrong last release. It is fixed now.

## Updating from version 2.6 or lower? (...first time setup? please see next section)
1. Take note of which AudioSource you are using to feed AudioLink, this reference may be lost during upgrade.
2. Install the latest VRChat SDK3 and UdonSharp (following their directions)
3. Close unity
4. With Windows explorer (NOT within Unity), remove the following files & folders:
   - AudioLink (folder)
   - AudioLink.meta
5. Reopen unity
6. Download and install the [latest AudioLink release](https://github.com/llealloo/vrc-udon-audio-link/releases/latest)
7. In scene(s) containing old versions of AudioLink:
   1. Delete both AudioLink and AudioLinkController prefabs from the scene
   2. Re-add AudioLink and AudioLinkController to the scene by dragging the prefabs from the AudioLink folder in projects *(world creators only)*
   3. Click the "Link all sound reactive objects to this AudioLink" button on AudioLink inspector panel *(world creators only)*
   4. Drag the AudioSource you were using previously into the AudioLink audio source parameter
      - NOTE: If you previously used AudioLinkInput, you are welcome to continue doing so, however now in 2.5+ AudioLink is much smarter about inputs. Try dragging it straight into the AudioLink / audio source parameter!
7. If using AudioReactiveObject or AudioReactiveLight components, you will need to manually re-enable the "Audio Data" under AudioLink "experimental" settings. This feature is now considered experimental until VRChat *maybe* gives us native asynchronous readback.

## First time setup

### Requirements
- [VRChat SDK3](https://vrchat.com/home/download) for worlds (Udon)
- [UdonSharp](https://github.com/MerlinVR/UdonSharp/releases/latest)
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