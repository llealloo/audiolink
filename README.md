# Udon AudioLink

## A repository of audio reactive prefabs for VRChat, written in UdonSharp

AudioLink is a system that analyzes and processes in-world audio into many different highly reactive data streams and exposes the data to VRChat Udon, world shaders, and avatar shaders. 

The per-frequency audio amplitude data is first read briefly into Udon using Unity's GetOutputData. It is then sent to the GPU for signal processing and buffered into a CustomRenderTexture. Then, the CustomRenderTexture is broadcast globally (called `_AudioTexture`) which can be picked up by shaders both in-world and across all avatars. 

### [Public example world](https://vrchat.com/home/launch?worldId=wrld_8554f998-d256-44b2-b16f-74aa32aac214)
### [Documentation for shader creators](https://github.com/llealloo/vrc-udon-audio-link/tree/master/Docs)
### [If you are looking to use AudioLink for ChilloutVR, check out this fork instead](https://github.com/DomNomNomVR/cvr-audio-link)

## 0.3.0 - September 18th, 2022
### New features
- AudioLink is now a curated package! As such, it can be installed with [VRChat Creator Companion](https://vcc.docs.vrchat.com/). This is new the recommended way to install AudioLink. For avatar projects and non-VRChat use cases, there is a regular old UnityPackage you can use. Please see the readme for [a guide on how to update your projects](#updating-world-projects-from-version-28-or-lower-first-time-setup-please-see-next-section). We recommend you follow this guide, as the update is a breaking change.
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

## Updating world projects from version 2.8 or lower? (...first time setup? please see next section)
0. If you are trying to upgrade an avatar project, **DO NOT** follow the steps below. Instead, see the next section.
1. Before upgrading your project, **MAKE A BACKUP**! The latest version of AudioLink changes many things - better safe than sorry.
2. Take note of which AudioSource you are using to feed AudioLink, this reference may be lost during upgrade.
3. If you haven't ever used VRChat Creator Companion (VCC) with your project, follow the steps below. Otherwise, skip to step 4:
   - Download and install the [VRChat Creator Companion](https://vrchat.com/download/vcc), open it up.
   - Use the "Add" option in the "Projects" tab and follow the steps shown to add your project to the VCC.
   - Open the Projects tab, select your project, press the "Migrate" button and follow the steps shown.
4. Open the Projects tab and select your project.
5. On the right side, find the AudioLink package and add it. If it doesn't show up, make sure you have the "Curated" toggle enabled in the top-right drop-down.
6. In a file browser, **without Unity open**, navigate to your projects Assets folder and delete the "AudioLink" folder and "AudioLink.meta" file.
7. Open the Project in Unity.
8. You may be prompted by the AudioLink shader upgrader to upgrade old shaders. You should do so if your project uses any custom AudioLink-enabled shaders.
9. If you were using assets from the AudioLink example scene, you'll have to import it, as it isn't imported by default. To do so, use the "AudioLink -> Open AudioLink Example Scene" in top menu of the editor.
10. If you were using AudioReactiveObject or AudioReactiveLight
   components, you may need to manually re-enable the "Audio Data" under AudioLink "experimental" settings. This feature is now considered experimental until VRChat *maybe* gives us native asynchronous readback.
11. In scene(s) containing old versions of AudioLink:
   - Delete both AudioLink and AudioLinkController prefabs from the scene.
   - Re-add AudioLink and AudioLinkController to the scene by dragging the prefabs from the Packages/com.llealloo.audiolink/Runtime folder.
   - Click the "Link all sound reactive objects to this AudioLink" button on AudioLink inspector panel.
   - Drag the AudioSource you were using previously into the AudioLink audio source parameter.
      - NOTE: If you previously used AudioLinkInput, you are welcome to continue doing so, however now in 2.5+ AudioLink is much smarter about inputs. Try dragging it straight into the AudioLink / audio source parameter!

## Upgrading avatar projects
1. In a file browser, delete the "Assets/AudioLink" folder and the "AudioLink.meta" file.
2. Follow the "First time setup" steps for avatar projects described below.

## First time setup
Looking to test out an avatar? See the "For Avatar Testing" section. Otherwise, see the "For Worlds" section below. After installation, check the "Getting Started" section for some tips.

### For Worlds
1. Download and install the [VRChat Creator Companion](https://vrchat.com/download/vcc) (VCC), open it up.
2. Add your project to the VCC:
   - If you want to create a new project, use the "New" option in the "Projects" tab and follow the steps there.
   - If you want to use an existing project, use the "Add" option in the "Projects" tab and follow the steps there.
3. Open the Projects tab and select your project. If you have never used the VCC with the project, use the "Migrate" button to upgrade it.
4. On the right side, find the AudioLink package and add it. If it doesn't show up, make sure you have the "Curated" toggle enabled in the top-right drop-down.
5. At this point, the installation is done. To open your project, you can use the "Open Project" button in the VCC. If you want to view the example scene, use the "AudioLink -> Open AudioLink Example Scene" button in the top menu of the editor.

### For Avatar Testing
1. Download and Import the latest **UnityPackage** AudioLink Release at https://github.com/llealloo/vrc-udon-audio-link/releases.
2. Open the AudioLink folder and drag AudioLinkAvatar into your scene's hierarchy.
3. Under AudioLinkAvatar/AudioLinkInput, add a music track to the AudioClip in the AudioSource.
   - If you need it louder, duplicate the AudioLinkInput object and increase the volume on that one. Make sure Not to adjust the volume on the main AudioLinkInput object - it needs to stay at 0.01.
4. Enter playmode to test your avatar.

### For non-VRChat uses
1. Download and Import the latest **UnityPackage** AudioLink Release at https://github.com/llealloo/vrc-udon-audio-link/releases.
2. Open the AudioLink folder and drag the AudioLink prefab into your scene's hierarchy. It should work out of the box.

## Getting started
After installation, to use AudioLink:
1. Drag AudioLink prefab into scene. For worlds, it is in "Packages/com.llealloo.audiolink/Runtime/AudioLink.prefab". For avatars and non-VRChat uses, it is under "Assets/AudioLink/AudioLink.prefab".
2. Link audio source by dragging the AudioSource gameobject into AudioLink's audio source parameter.
3. Drag AudioLinkController prefab into scene and drag AudioLink into the controller's "Audio Link" parameter.
4. Click the "Link all sound reactive objects..." button to link everything up.

If you want to see an example of a scene with AudioLink set up, press the "AudioLink -> Open AudioLink Example Scene" in the top menu of the editor.

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
