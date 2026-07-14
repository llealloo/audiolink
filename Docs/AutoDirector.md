# Auto-Director: automatic AudioLink tuning

The Auto-Director is a fork addition that makes AudioLink fully hands-off for
avatar and editor testing. With it enabled, you drop AudioLink onto any audio
source, press play, and every band reacts well on any track without ever touching
the Gain / EQ / crossover / threshold / fade sliders by hand.

This document explains the algorithm: what it drives, how it tracks the audio,
and why each stage is built the way it is. The per-function code map lives in
`Packages/com.llealloo.audiolink/developer_info.md`; the implementation is in
`Runtime/Scripts/AudioLink.cs` (all of it under `#if !UDONSHARP`).

## Scope: why avatar / editor only

AudioLink compiles two ways from one `partial class`: as an `UdonSharpBehaviour`
in uploaded VRChat worlds, and as a plain `MonoBehaviour` everywhere else
(editor, avatar test scenes, standalone, WebGL). The Auto-Director lives entirely
in the `MonoBehaviour` half:

- It reads the spectrum with `AudioSource.GetSpectrumData` and `FFTWindow`, which
  are not in the Udon whitelist, so it could not compile into a world build.
- It is a creation-time tuning aid. In a real world the thresholds are usually
  hand-authored or driven by the AudioLinkController, so there is nothing to
  auto-direct at runtime.

Because it is wrapped in `#if !UDONSHARP`, it is compiled out of world uploads
completely and cannot affect them.

## What it drives

The AudioLink shader (`Runtime/Shaders/AudioLink.shader`) turns the audio into the
four "AudioLink" band values every reactive shader reads. Simplified, per band:

1. The waveform is scaled by gain and, if Autogain is on, divided by a running
   loudness peak plus `_AutogainDerate` (this is the autogain normalization).
2. A log-frequency DFT is taken.
3. The band's value is the average DFT magnitude across the frequency range
   between its two crossovers `[x_b, x_{b+1}]`.
4. That magnitude is divided by `threshold^2` (the sensitivity control), contrast
   is applied, and finally a fade / trail step blends with the previous frame.

The Auto-Director drives the three parameter groups that shape reactivity:

- the four **thresholds** (`x0`..`x3` sensitivity), continuously, in real time;
- the four **crossovers** (`x0`..`x3` band frequency boundaries), gently;
- the **fade** (`fadeLength`, `fadeExpFalloff` trail length), by how busy the music
  is.

Gain, Bass, and Treble are left manual. They are pre-EQ taste controls; Autogain
already handles overall level, and moving EQ automatically would just fight the
per-band work below.

## Stage 0: the autogain mirror

Everything downstream is decided from a normalized view of the spectrum, so the
first job is to reproduce, in C#, what Autogain does on the GPU.

`GetSpectrumData` returns the raw linear spectrum: pre-gain, pre-EQ, pre-autogain.
If the thresholds were computed from that raw signal (as the first draft of this
feature did) they would fight Autogain, because the shader applies the threshold
to the post-autogain magnitude, not the raw one.

So each frame the Auto-Director maintains `_autoDirectorLevel`, a running overall
loudness with a fast attack (`AutoDirectorAgcAttack`, 0.08s) and slow release
(`AutoDirectorAgcRelease`, 2.0s), mirroring the shader's quick-attack / slow-decay
autogain envelope. It then normalizes each band peak:

```
norm  = 1 / (_autoDirectorLevel + derate)
nb_i  = p_i * norm
```

`derate` is `autogainDerate` when Autogain is on (the exact value the shader uses)
and a bounded fallback (`AutoDirectorSilenceFloor`, 0.1) when it is off. `nb_i` is
therefore the same "band magnitude near unity at the loudest recent moment" that
the shader's threshold operates on. This is what "respecting Autogain" means in
practice.

## Stage 1: threshold AGC (per-band sensitivity, real time)

In the shader the band output is roughly `saturate(magnitude) / threshold^2`. So
to make a band reach ~1 at its own recent peak `m_peak`, the threshold should be
`sqrt(m_peak)`. The Auto-Director does exactly that per band:

```
peak_i    = max(nb_i, peak_i * decay)                 // instant-attack peak hold
target_i  = clamp(sqrt(peak_i), 0.2, 1)               // inverse of / threshold^2
threshold_i = lerp(threshold_i, target_i, track)      // smoothed follow
```

The `sqrt` is the key idea: it inverts the shader's `/ threshold^2`, so each band
fills 0-1 relative to **its own** recent energy. Loud bands (usually bass) get a
high threshold and are held back; quiet bands (usually treble) get a low threshold
and are lifted. That is what makes every band react instead of only the bass.

The peak hold (`AutoDirectorPeakDecay`, 0.9s) rises instantly on a transient and
decays slowly, so a beat pokes through before the threshold catches up, then the
band relaxes. A floor of 0.2 (`AutoDirectorMinThreshold`) stops the band opening
so far that the noise floor reads as signal during quiet passages.

## The speed control

`autoDirectorSpeed` (0.1-20) is the only reactivity knob. It sets the threshold
follow factor in a frame-rate-independent way:

```
n     = speed / 20
track = 1 - pow(1 - n, deltaTime * 60)
```

At speed 20, `n = 1`, so `track = 1` and the thresholds follow the target
instantly (`pow(0, ...) = 0`) at any frame rate. Lower speeds add proportionally
more smoothing, and the `pow(..., deltaTime * 60)` form keeps the wall-clock
convergence identical whether you run at 60, 90, or 144 fps. A fast breakbeat or
jersey mix at speed 20 therefore tracks every hit with zero lag.

## Stage 2: crossover self-calibration (gentle)

The crossovers decide which frequencies each band covers. They map to a
log-frequency DFT bin and thus to a real frequency:

```
bin  = 29.52 + x * 210.48        // 0.123*240 .. 240
freq = 13.75 * 2^(bin / 24)      // ~32 Hz .. ~14 kHz
```

(These constants come straight from `AudioLink.cginc`:
`AUDIOLINK_BOTTOM_FREQUENCY` 13.75, `AUDIOLINK_EXPBINS` 24,
`AUDIOLINK_4BAND_FREQFLOOR` 0.123, ceiling 1, `AUDIOLINK_SPS` 48000.)

Each frame the Auto-Director bins the live spectrum energy into that log-frequency
space. A linear FFT is denser at high frequency, so every linear bin is dropped
into the `x` slot its frequency maps to; the resulting 64-bin histogram is a true
energy-per-log-band distribution. From it, the 5 / 25 / 50 / 75 percent
cumulative-energy marks are the natural equal-energy split points for x0 / x1 / x2
/ x3. A bass-heavy track pushes the splits up; a bright track pulls them down, so
every band stays populated.

Two guards keep this stable:

- **Range clamps.** Each mark is clamped to that crossover's designed inspector
  range (x0 `[0, 0.168]`, x1 `[0.242, 0.387]`, x2 `[0.461, 0.628]`,
  x3 `[0.704, 0.953]`). The ranges do not overlap, which guarantees
  `x0 < x1 < x2 < x3` can never be violated.
- **Default anchoring.** The target is `lerp(default, clampedMark, 0.5)`
  (`AutoDirectorCrossoverStrength`). The crossover only moves halfway from its
  default toward the energy mark, so it never actually reaches its clamp limit.

The anchoring exists specifically to fix build-ups. A riser concentrates energy
into a narrow, sweeping region, which drives the raw quantiles to an extreme.
Without the anchor the crossovers would peg at their clamp limits and crowd two
boundaries together into a very narrow band, and that narrow band then blows out
on the concentrated energy. Anchoring toward the defaults keeps band widths sane
through the whole build-up.

Crossovers move on a fixed 0.4s time constant (`AutoDirectorCrossoverSmoothing`),
deliberately not tied to `autoDirectorSpeed`. They describe a track's overall
spectral shape, which is slow; snapping them per-beat would make bands trade
frequency content and look chaotic. The update is skipped during silence
(`AutoDirectorCrossoverGate`).

## Stage 3: fade self-calibration (by onset density)

The fade is the trail: `fadeLength` near 0 is snappy with no trail, near 1 holds
the value; `fadeExpFalloff` sharpens the decay into a pulse. The right amount
depends entirely on how busy the music is. A dense breakbeat needs almost no fade
so every hit stays distinct; a sustained pad wants a long trail so it does not
look dead between notes.

The Auto-Director measures **spectral flux**, the sum of the positive per-band
changes since last frame:

```
flux = sum over bands of max(0, nb_i - lastNb_i)
```

This is an onset-strength signal: high for punchy, transient-dense material, low
for sustained tones. Flux is smoothed into `_autoDirectorActivity`, then
self-normalized against a decaying running max (`_autoDirectorFluxMax`) into a
0-1 `busy` factor, so the calibration is scale-independent across tracks.

`busy` blends the fade endpoints:

- busy music -> `fadeLength` toward `AutoDirectorFadeBusy` (0.02, near-instant,
  no smear) and `fadeExpFalloff` toward 0.9 (sharp pulses);
- calm music -> `fadeLength` toward `AutoDirectorFadeCalm` (0.45, visible trails)
  and `fadeExpFalloff` toward 0.5.

So a jersey / breakbeat mix ends up pinned at the near-zero fade and, combined
with instant thresholds at speed 20 and the fast crossovers, reads as rapid-fire
madness, while ambient material keeps its trails.

## Per-section toggles and reset

The master `autoDirectorMode` is off by default; nothing runs until it is turned
on. Under it are three per-section toggles, all on by default:

- `autoTuneThresholds`
- `autoTuneCrossovers`
- `autoTuneFade`

Each stage only runs when its toggle is on, so a user can opt out of any single
one (for example, keep auto thresholds but pin the crossovers by hand). When a
toggle is switched off, that section is reset **once** back to the stock AudioLink
defaults rather than being left frozen at whatever the calibration last produced:

- thresholds -> 0.45
- crossovers -> 0 / 0.25 / 0.5 / 0.75
- fade -> 0.25 / 0.75

The transition is detected inside `RunAutoDirector` (comparing each toggle to its
previous-frame value), so resets only happen while the director is actually
running. Each of `ToggleAutoDirector`, `ToggleAutoTuneThresholds`,
`ToggleAutoTuneCrossovers`, and `ToggleAutoTuneFade` is public for wiring to a UI
button or an inspector toggle.

## Tuning reference

All tuning lives in `private const` values at the top of the Auto-Director region.
The ones most worth touching:

| Constant | Default | Effect |
| --- | --- | --- |
| `AutoDirectorMinThreshold` | 0.2 | Lower = bands open up more in quiet passages (more sensitive, more noise). |
| `AutoDirectorPeakDecay` | 0.9s | Higher = thresholds hold longer after a hit. |
| `AutoDirectorCrossoverStrength` | 0.5 | Higher = crossovers adapt more but move closer to their pegs; lower = safer, more default-like. |
| `AutoDirectorCrossoverSmoothing` | 0.4s | How fast the crossovers re-balance. |
| `AutoDirectorFadeBusy` | 0.02 | The short-fade floor for busy music. 0.0 is full instant kill (can flicker). |
| `AutoDirectorFadeCalm` | 0.45 | The long-fade / trail amount for calm music. |

## Limitations

- The mapping from the C# normalized amplitude to the shader's internal magnitude
  is close but not exact (different windowing and log attenuation), so the
  absolute calibration is approximate; the closed loops self-correct around it.
- It needs the audio to actually play locally, so it works in the editor / avatar
  test flow, not in a headless build with no audio.
- `busy` is self-normalized, so a very calm track's own loudest moment still reads
  as relatively busy; this is intentional (it lets calm music pulse) but means the
  fade is a relative, not absolute, measure of tempo.
