# Changelog

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