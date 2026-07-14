# AudioLink Developer Info

Canonical "why" documentation for first-party AudioLink code
(`Packages/com.llealloo.audiolink/`). Source files are kept comment-free; the
reasoning that used to live in inline comments lives here, organized by
file then function/section.

Vendored / third-party code (community prefabs under
`AudioLinkSandboxUnityProject/`, TextMesh Pro, LTCGI, Poiyomi/Thry, Airtime,
QvPen, cnlohr, the VRChat VPM resolver) is intentionally out of scope and is
left untouched, including its own comments and attribution headers.

---

## Runtime/Scripts/AudioLink.cs

`partial class AudioLink`. Compiles as `UdonSharpBehaviour` when `UDONSHARP` is
defined (uploaded VRChat worlds) and as `MonoBehaviour` otherwise
(avatar/editor testing, standalone, WebGL).

### Auto-Director (avatar / editor only)

The Auto-Director is a hands-off reactivity mode: instead of the user hand-tuning
the band sliders per track, it continuously auto-tunes the four band thresholds,
the four crossover frequencies, and the two fade (trail) settings from live
spectrum analysis so any song fills the 0-1 range and every band reacts.
Thresholds set per-band sensitivity and track in real time; crossovers set the
band frequency boundaries and re-balance toward the track's spectral shape; and
the fade shortens for transient-dense music (so a fast breakbeat / jersey mix
reads as crisp madness at speed 20) while lengthening into trails for sustained
music.

The whole feature is wrapped in `#if !UDONSHARP` because it depends on
`AudioSource.GetSpectrumData` / `FFTWindow`, which are not in the Udon whitelist,
and because it is a testing aid for avatar/editor work rather than a world
feature. It is compiled out of uploaded worlds entirely.

**Respecting Autogain.** The shader (`AudioLink.shader`, pass
`Pass3AudioLink4Band` and the GENERALVU autogain block) divides the DFT by a
running loudness peak (fast attack, slow decay) plus `_AutogainDerate` before the
per-band threshold is applied as `magnitude / pow(threshold, 2)`. Any threshold
control that reads the raw pre-autogain spectrum (as the previous implementation
did) fights that normalization. So `RunAutoDirector` mirrors the shader's
normalization in C# before deciding thresholds, and reuses the same
`autogainDerate` value when Autogain is enabled.

#### Fields

- `autoDirectorMode` (bool) - master enable.
- `autoDirectorSpeed` (0.1-20) - the only user control; how fast thresholds track
  the music. There is no sensitivity knob (the loop self-calibrates each band).
  The value is normalized to `n = speed / 20` and used as a frame-rate-independent
  lerp factor `track = 1 - pow(1 - n, deltaTime * 60)`. At speed 20, `n = 1` so
  `track = 1` and the thresholds follow the target instantly (real time) at any
  frame rate; lower speeds add proportionally more smoothing. Crossover motion is
  intentionally not tied to this control (see `AutoDirectorCrossovers`).
- `autoTuneThresholds` / `autoTuneCrossovers` / `autoTuneFade` (bool, all default
  on) - per-section enables. Switching one off stops it driving its section and
  resets that section to defaults once (see `AutoDirectorHandleToggles`), so a user
  can opt out of any single stage. `autoDirectorMode` (the master) is off by
  default, so nothing runs until it is explicitly enabled.

Private state:

- `_spectrumData` (float[1024]) - reused GetSpectrumData buffer; pre-allocated to
  avoid per-frame GC.
- `_autoDirectorBandPeak` (float[4]) - decaying per-band peak of the normalized
  amplitude; the closed-loop reference each band calibrates against.
- `_autoDirectorBandLast` (float[4]) - previous frame's normalized band values,
  used to compute spectral flux (onsets) for the fade.
- `_autoDirectorSpectrumHist` (float[64]) - reused per-frame energy histogram in
  crossover (log-frequency) space, used to place the crossovers.
- `_autoDirectorLevel` (float) - running overall loudness, the C# mirror of the
  shader's autogain peak.
- `_autoDirectorActivity` (float) - smoothed spectral flux; how transient-dense
  the current section is.
- `_autoDirectorFluxMax` (float) - decaying running max of the activity, used to
  self-normalize it into a 0-1 "busy" factor.
- `_autoDirectorPrevThresholds` / `_autoDirectorPrevCrossovers` /
  `_autoDirectorPrevFade` (bool) - previous-frame toggle states, used to detect a
  section being switched off so it can be reset exactly once.

Constants:

- `AutoDirectorMaxSpeed` (20), `AutoDirectorReferenceFps` (60) - the top of the
  speed slider (where tracking becomes instant) and the reference frame rate the
  lerp is normalized against.
- `AutoDirectorAgcAttack` (0.08s), `AutoDirectorAgcRelease` (2.0s) - attack/release
  time constants for `_autoDirectorLevel`, mirroring the shader's quick-attack /
  slow-decay autogain behavior.
- `AutoDirectorPeakDecay` (0.9s) - time constant for the per-band peak decay so
  thresholds relax after a loud section ends.
- `AutoDirectorMinThreshold` (0.2) - floor on the target threshold; prevents the
  band from opening up so far that noise floors read as signal during quiet
  passages.
- `AutoDirectorSilenceFloor` (0.1) - derate used in place of `autogainDerate` when
  Autogain is disabled, so the normalizer stays bounded near silence.
- Crossover mapping constants mirror `AudioLink.cginc`: `AutoDirectorBottomFreq`
  (13.75 Hz), `AutoDirectorExpBins` (24 bins/octave), `AutoDirectorBandBinFloor`
  (29.52 = `0.123 * 240`) and `AutoDirectorBandBinSpan` (210.48 = `240 - 29.52`)
  define the crossover-to-log-bin remap; `AutoDirectorHzPerBin` (23.4375 =
  `24000 / 1024`) converts a linear GetSpectrumData bin to Hz;
  `AutoDirectorFreqBinLow/High` (1..640) bound the linear bins scanned;
  `AutoDirectorXBins` (64) is the histogram resolution;
  `AutoDirectorCrossoverSmoothing` (0.4s) is the crossover time constant;
  `AutoDirectorCrossoverStrength` (0.5) is how far each crossover may deviate from
  its default toward the energy target, which keeps them off their clamp pegs; and
  `AutoDirectorCrossoverGate` (1e-5) skips the update during silence.
- Fade constants: `AutoDirectorActivitySmoothing` (0.3s) smooths the raw flux;
  `AutoDirectorFluxMaxDecay` (4.0s) is the decay of the running flux max used to
  self-normalize activity; `AutoDirectorActivityFloor` (0.02) gates near-silence;
  `AutoDirectorFadeCalm`/`AutoDirectorFadeBusy` (0.45 / 0.02) and
  `AutoDirectorFadeExpCalm`/`AutoDirectorFadeExpBusy` (0.5 / 0.9) are the fade
  length and exp-falloff endpoints blended by the busy factor; and
  `AutoDirectorFadeSmoothing` (0.3s) is how fast the fade settings adapt.
- Default constants used by the reset-on-toggle-off logic and (for the crossovers)
  as the blend anchors: `AutoDirectorDefaultThreshold` (0.45),
  `AutoDirectorDefaultX0..X3` (0 / 0.25 / 0.5 / 0.75), and
  `AutoDirectorDefaultFadeLength` / `AutoDirectorDefaultFadeExp` (0.25 / 0.75).

#### `RunAutoDirector()`

Called from `Update()` (also under `#if !UDONSHARP`) only while
`autoDirectorMode` is on and the audio source is playing. It first calls
`AutoDirectorHandleToggles`; the threshold, crossover, and fade stages then each
run only if their `autoTune*` toggle is enabled.

1. Read the raw linear spectrum with a Blackman-Harris window.
2. Peak-detect each of the four bands over fixed FFT bin ranges
   (0-10 bass, 11-42 low-mid, 43-170 high-mid, 171-853 treble), matching
   AudioLink's default crossover split at 48 kHz / 1024 bins.
3. Update `_autoDirectorLevel` toward the instantaneous overall peak using
   attack when rising and release when falling (the autogain mirror).
4. `norm = 1 / (_autoDirectorLevel + derate)` where `derate` is `autogainDerate`
   when Autogain is on, else `AutoDirectorSilenceFloor`. Multiplying each band
   peak by `norm` reproduces the shader's post-autogain band magnitude, so the
   thresholds are computed in the same space the shader applies them.
5. Compute the frame-rate-independent `track` factor from `autoDirectorSpeed`,
   then per band `AutoDirectorBandThreshold` sets the new threshold and lerps
   toward it at `track`.
6. Call `AutoDirectorCrossovers` to re-balance the band frequency boundaries.
7. Call `AutoDirectorFade` with the normalized band values to adapt the trail
   length to how busy the music is.

#### `AutoDirectorBandThreshold(band, normalized, current, peakDecay, track)`

Maintains the decaying per-band peak and derives the target threshold as
`clamp(sqrt(bandPeak), AutoDirectorMinThreshold, 1)`.

The `sqrt` inverts the shader's `magnitude / pow(threshold, 2)`: setting
`threshold = sqrt(recentPeak)` makes a band's output reach ~1 at its own recent
peak, independent of how loud that band is relative to the others. That is why
quiet bands (typically treble) get lifted automatically while loud bands
(typically bass) are held back, giving full-range motion on every band with no
user calibration. The mapping is fully self-tuning, so there is no sensitivity
control; only `autoDirectorSpeed` remains, governing how fast it tracks.

#### `AutoDirectorCrossovers()`

Self-calibrates `x0`-`x3` so the four bands carry roughly balanced spectral
energy for the current track, in the same log-frequency space the shader uses.

The crossover slider value `x` maps to a log DFT bin
`bin = AutoDirectorBandBinFloor + x * AutoDirectorBandBinSpan` and thus to
`freq = AutoDirectorBottomFreq * 2^(bin / 24)`, spanning ~32 Hz to ~14 kHz. To
work in that space from the linear GetSpectrumData buffer, each linear bin's
energy is placed into a histogram indexed by its `x` position (inverse of the
above mapping). Because a linear FFT is denser at high frequency, many linear
bins fall into each high-`x` slot, so the histogram correctly represents energy
per log-frequency band.

`AutoDirectorSpectrumQuantile` then finds the `x` positions at the 5 / 25 / 50 /
75 percent cumulative-energy marks. Each mark is first clamped to that crossover's
designed inspector range (x0 `[0, 0.168]`, x1 `[0.242, 0.387]`,
x2 `[0.461, 0.628]`, x3 `[0.704, 0.953]`; the ranges do not overlap, which
guarantees `x0 < x1 < x2 < x3`). The target is then
`lerp(default, clampedMark, AutoDirectorCrossoverStrength)`, so a crossover only
moves partway from its default toward the energy mark and never reaches its clamp
peg.

That anchoring matters for build-ups: a riser concentrates energy into a narrow,
sweeping region, which drives the raw quantiles to an extreme. Without the anchor
the crossovers would peg at their clamp limits and crowd two boundaries together
into a very narrow band, which then blows out on the concentrated energy. Blending
toward the default keeps band widths sane through the build-up.

Crossovers lerp toward their targets with a fixed time constant
(`AutoDirectorCrossoverSmoothing`, 0.4s) rather than `autoDirectorSpeed`. It is
kept off the speed slider on purpose: crossovers describe a track's overall
spectral shape, and the 0.4s smoothing filters the per-frame quantile noise so
the bands re-balance quickly without jittering or swapping identity every frame.
The update is skipped entirely when total energy is below
`AutoDirectorCrossoverGate` (silence).

#### `AutoDirectorSpectrumQuantile(targetEnergy)`

Walks the cumulative `_autoDirectorSpectrumHist` and returns the `x` (0-1) at
which the running sum first reaches `targetEnergy`. Returns the bin-center
position `(i + 0.5) / 64`.

#### `AutoDirectorFade(nb0, nb1, nb2, nb3)`

Self-calibrates `fadeLength` and `fadeExpFalloff` so the trail length matches how
transient-dense the music is.

It computes **spectral flux** as the sum of the positive per-band changes since
last frame (`max(0, nb - lastNb)`), i.e. an onset-strength measure that is high
for busy, punchy music and low for sustained tones. Flux is smoothed into
`_autoDirectorActivity`, which is then self-normalized against a decaying running
max (`_autoDirectorFluxMax`) into a 0-1 `busy` factor, so the calibration is
scale-independent across tracks.

`busy` blends the fade endpoints: busy music pulls `fadeLength` toward
`AutoDirectorFadeBusy` (0.02, near-instant so every hit is distinct with no smear)
and
`fadeExpFalloff` toward `AutoDirectorFadeExpBusy` (0.9, sharp pulses); calm music
pulls them toward `AutoDirectorFadeCalm` (0.45, longer trails) and
`AutoDirectorFadeExpCalm` (0.5). This is why a fast breakbeat / jersey mix ends up
with a near-minimum fade and reads as rapid-fire madness, while ambient material
keeps visible trails.

Recall the shader's fade semantics (`AudioLink.shader`): `_FadeLength` near 0 is
snappy with no trail and near 1 holds indefinitely, and `_FadeExpFalloff` sharpens
the decay into a pulse. The fade is intentionally not tied to `autoDirectorSpeed`;
it responds to the music's onset density rather than a manual control.

#### `AutoDirectorHandleToggles()` and the reset helpers

Called at the top of `RunAutoDirector`. It compares each `autoTune*` toggle to its
`_autoDirectorPrev*` value and, on a true-to-false transition, calls the matching
reset once: `AutoDirectorResetThresholds` (all thresholds to 0.45),
`AutoDirectorResetCrossovers` (x0-x3 to 0 / 0.25 / 0.5 / 0.75), or
`AutoDirectorResetFade` (fadeLength 0.25, fadeExpFalloff 0.75). Each reset writes
both the C# field and the shader property, so switching a section off snaps it
straight back to the stock AudioLink defaults instead of leaving it frozen at
whatever the calibration last produced.

Because the check lives inside `RunAutoDirector`, resets fire only while the master
`autoDirectorMode` is running; the per-section toggles do nothing when the director
is off.

#### `ToggleAutoDirector()`, `ToggleAutoTuneThresholds()`, `ToggleAutoTuneCrossovers()`, `ToggleAutoTuneFade()`

Public methods that flip the master and the three per-section bools, for wiring to
UI buttons or inspector/editor toggles in avatar test scenes. Flipping a
per-section bool to off is what the reset logic above keys on.

Full algorithm theory (signal chain, why each stage exists, the maths) lives in
`Docs/AutoDirector.md`.
