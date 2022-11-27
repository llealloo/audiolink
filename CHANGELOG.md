# Changelog

## 0.3.1 - November 26th, 2022
### Changes
- Updated the AudioLink package to work in both world and avatar projects, by removing the dependency on UdonSharp. The first time you attempt to import AudioLink into a world project, a popup will appear prompting you to install UdonSharp.

## 0.3.0 - November 11th, 2022
### New features
- AudioLink is now a curated package! As such, it can be installed with [VRChat Creator Companion](https://vcc.docs.vrchat.com/). This is new the recommended way to install AudioLink. For avatar projects and non-VRChat use cases, there is a regular old UnityPackage you can use. Please see the readme for a guide on how to update your projects. We recommend you follow this guide, as the update is a breaking change.
- Since the folder structure has changed, custom shaders may need to be upgraded. A tool has been included to automatically upgrade shaders where needed. This tool is accessible from "AudioLink -> Update AudioLink compatible shaders" in the top menu of the editor. (Thanks, 3)
- Added Global Strings - text which can be read from AudioLink compatible shaders. Use this to retrieve the name of the local player and master in a shader, or to feed custom string data through. Info on usage is in Documentation. See `AudioLinkGetGlobalStringChar(uint stringIndex, uint charIndex)` in AudioLink.cginc for details.
- Included Amplify nodes for using AudioLink have been overhauled. They are now in their own "AudioLink" category, and handle including the relevant files automatically. Also, links to documentation are added. (Thanks, Nestorboy)
- Added a function, `AudioLinkGetAudioSourcePosition()`, for getting the worldspace position of the audio source being used to feed AudioLink. (Thanks, 3)
- Various shaders have been updated to supported Single Pass Stereo Instanced rendering, for future compatability. (Thanks, 3)
- The included video player, AudioLinkMiniPlayer, has been updated to support LTCGI. (Thanks, Texelsaur)
- The example AudioLink scene can now be quickly accessed using the "AudioLink -> Open AudioLink Example Scene" button in the top menu of the editor.
- The live AudioLink demo world has gotten an overhaul, and has a bunch of new cool things to play with.
### Changes
- The GrabPass utilized by AudioLink has been removed! We use the new `VRCShader.SetGlobalTexture` to expose a globally available texture now. This is an improvement to stability and performance. Existing shaders should still be compatible with new versions of AudioLink.
- The camera used by AudioLink to provide audio data to udon (using the Experimental Audio Readback feature) will now be disabled when it isn't needed, which should improve performance a bit.
- When using an AudioLinkController, the values selected in the AudioLink inspector are now respected, instead of the controller overriding them on initialization. (Thanks, 3)
- Be consistent with swizzling in AudioLink shaders, use 'xyzw' everywhere.
- Removed uses of SetProgramVariable and SendCustomEvent throughout AudioLink code. (Thanks, 3)
- Use VRCShader.PropertyToID instead of strings for better performance. (Thanks, 3)
### Bugfixes
- Issue [191](https://github.com/llealloo/vrc-udon-audio-link/issues/191) and [186](https://github.com/llealloo/vrc-udon-audio-link/issues/186) have been fixed. (Thanks, 3)
- Remove some old profiling code that could have a very slight impact on performance. (Thanks, 3)
- Fix the "Link all sound reactive objects to this AudioLink" button, which was broken when using UdonSharp 1.x. (Thanks, 3)
- Fix some minor inconsistencies in documentation.

## 0.2.8 - May 14th, 2022
### New features
- AudioLink theme colors are now configurable via the AudioLink controller with a slick color-picker GUI. (Thanks, DomNomNom)
- Added the ability to get the time since Unix epoch in days, and milliseconds since 12:00 AM UTC. Additionally, a helper function, `AudioLinkGetTimeOfDay()` has been added, which lets you easily get the current hours, minutes and seconds of the time of day in UTC.
- An editor scripting define, `AUDIOLINK`, which will be automatically added when AudioLink is included. (Thanks, Float3)
- AudioLink can now compile without VRCSDK and UDON, for use outside of VRChat. This kind of usecase is still experimental at best, though. (Thanks, Float3 and yewnyx)
- Added a few new helper methods to sample various notes of the DFT. (Thanks, Float3)
### Changes
- AudioLink theme colors have been cleaned up, including a new demo in the example scene, and the ability to change the colors in realtime in the editor. (Thanks, DomNomNom)
- Changed a few default settings on the AudioLink controller to be more responsive. (Thanks, DomNomNom)
- Changed folder structure to put less clutter into user projects.
### Bugfixes
- Fix vertical UV flip of the AudioLink texture on Quest. (Thanks, Shadowriver)
- Fix error when using "Link all sound reactive objects to this AudioLink" button. (Thanks, Nestorboy)
- Add a header guard to `AudioLink.cginc` to prevent duplicate includes. (Thanks, PiMaker)
- Fix various warnings in shader code. (Thanks, Float3)
- Fix NaN-propagation issue in the included video player. (Thanks, Texelsaur)
- Add a player validity check to the included video player. (Thanks, Texelsaur)
- Use `Networking.LocalPlayer.isInstanceOwner` instead of `Networking.IsInstanceOwner`, which is broken. (Thanks, techanon)
- The logos on the AudioLink controller were using point filtering, which was changed to bilinear. (Thanks, DomNomNom)

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

## 0.2.6 - August 10th, 2021
### New features (big thanks to @cnlohr and @pema99)
- Chronotensity feature provides timing information to shaders which changes in reaction to audio
- ColorChord index colors, a new way to get audio reactive colors from ColorChord
- Globally configurable theme colors
- Filtered VU, smoothly filtered versions of VU data
- Amplify nodes and example shaders for above features
- Added `AudioLinkGetAmplitudeAtFrequency` and `AudioLinkGetAmplitudeAtNote` functions for easily sampling specific parts of the audio spectrum corresponding to certain frequencies or semitones
### Changes
- UnU sliders (thanks Texelsaur)
- Various improvements to included video player, now with a resync button (thanks again, Texelsaur)
- Recursive / nesting support for AudioReactiveSurfaceArray prefab
### Bugfixes
- Fixed certain parts of filtered 4band data always being zero (thanks DomNomNom)

## 0.2.5 - June 7th, 2021
### Breaking changes
#### AudioLink.cginc
- Renamed `AudioLinkAvailableNonSurface` to `AudioLinkAvailable` - It supports surface shaders now
- Renamed `ETOTALBINS` to `AUDIOLINK_ETOTALBINS`
- Renamed `ALDecodeDataAsUInt` to `AudioLinkDecodeDataAsUInt`
- Renamed `ALDecodeDataAsSeconds` to `AudioLinkDecodeDataAsSeconds`
- Renamed `Remap` to `AudioLinkRemap`
- Renamed `HSVtoRGB` to `AudioLinkHSVtoRGB`
- Renamed `CCtoRGB` to `AudioLinkCCtoRGB`
- Renamed `GetSelfPixelData` to `AudioLinkGetSelfPixelData`
### New features
- Added a shader function get the version of AudioLink currently running in the world, `AudioLinkGetVersion`.
- Handling of 3D audio sources by Xiexe
- Amplify templates for Lit & Unlit
- Amplify functions for use in the above templates
- Left/right VU meter data (instead of just left)
- Left/right Waveform data (instead of just left)

### Changes
- Refactoring, restyling, and renaming across entire codebase
- AudioReactiveSurface (Amplify shader) converted to built-in AudioLink.cginc functions
- AudioLink shader menu reorganized
- Removed an extern call from AudioLink.cs update loop
- Reuse of internal sample arrays
### Bugfixes
- Audio values clamped to prevent overflow
- AVPro log spamming & mono output bugfix (mainly a problem if using VRChat w/ a headset)
