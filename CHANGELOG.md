# Changelog
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
### Changes
- Refactoring, restyling, and renaming across entire codebase
- AudioReactiveSurface (Amplify shader) converted to built-in AudioLink.cginc functions
- AudioLink shader menu reorganized
### Bugfixes
- Audio values clamped to prevent overflow

##  Might want to add older versions here
It can be the same as release notes. Update on each packaged release.