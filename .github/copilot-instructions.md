# Quanta — Violin Tuning Practice App
## Copilot Instructions

---

## Project Overview

**Quanta** is a Flutter-based violin tuning practice app. It lets players sound reference notes, tune each of the four violin strings using coarse and fine tuning knobs, verify tuning accuracy visually, and explore note deviations. The aesthetic is professional, premium, and instrument-inspired — dark tones with warm gold accents evoking the feel of a fine violin.

---

## Target Platforms

- **Primary**: Android, iOS
- **Secondary**: macOS, Windows (desktop)
- Responsive layout: works on phones, tablets, and desktops without separate codebases.

---

## Design System

### Color Palette

| Token | Hex | Usage |
|---|---|---|
| `colorBackground` | `#0D0D0F` | App background |
| `colorSurface` | `#1A1A1F` | Cards, panels |
| `colorSurfaceElevated` | `#242430` | Elevated surfaces, knob bodies |
| `colorGold` | `#C9A84C` | Primary accent — active states, highlights |
| `colorGoldDim` | `#7A5E28` | Inactive accent, borders |
| `colorString` | `#D6C89A` | Violin string color (cream-gold) |
| `colorStringSelected` | `#E8D5A3` | Selected/active string highlight |
| `colorStringMuted` | `#4A4030` | Unselected string body |
| `colorOnSurface` | `#E8E4DC` | Primary text |
| `colorOnSurfaceMuted` | `#7A7670` | Secondary/muted text |
| `colorSharp` | `#4CAF7D` | In-tune indicator (green) |
| `colorFlat` | `#E05A4E` | Out-of-tune indicator (red) |
| `colorNeutral` | `#C9A84C` | Perfectly in-tune indicator (gold) |

### Typography

Use **Google Fonts** package. Font choices:
- **Display / Labels**: `Cinzel` — elegant, classical serif for note names, headings.
- **Body / Values**: `Inter` or `IBM Plex Mono` — clean, readable for numeric values, cents deviation.
- **Accent**: `Cormorant Garamond` — for decorative headings if needed.

Font sizes follow a strict scale: `10, 12, 14, 16, 20, 24, 32, 48` dp.

### Spacing & Layout

- Base unit: `8 dp`
- All spacing is multiples of `8` (8, 16, 24, 32, 40, 48).
- Consistent `16 dp` horizontal screen margin.
- Corner radii: `8` (small), `16` (card), `999` (pill/circular).

### Elevation & Shadow

Use subtle inner shadows and glows, not Material drop shadows. Achieve depth using gradient overlays and border highlights (thin `0.5 dp` bright top edge on dark surfaces).

### Animation Principles

- All state transitions: `200–300 ms`, `Curves.easeOut`.
- Knob rotation: smooth follow with no snapping feel.
- String vibration: damped sine wave animation when a string sounds.
- Tuning indicator needle: `TweenAnimationBuilder` with springy `Curves.elasticOut` on value change.
- Never use jarring instant transitions. Every change in state has a visual transition.

---

## App Features & UX Specification

### 1. Reference Note Panel (top section)

- A horizontal panel at the top of the screen.
- A segmented selector with exactly four options: **G3**, **D4**, **A4**, **E5** (standard open-string pitches).
- A single **toggle button** (play/stop) that starts or stops the continuous reference tone.
- When active, the selected segment glows in `colorGold` with a subtle pulsing animation on the button icon.
- Only one reference tone can play at a time.
- Reference frequencies (equal temperament, A4 = 440 Hz):
  - G3 = 196.00 Hz
  - D4 = 293.66 Hz
  - A4 = 440.00 Hz
  - E5 = 659.25 Hz

### 2. String Display (main section)

- Four horizontal **violin string** widgets stacked vertically, labeled **E5**, **A4**, **D4**, **G3** from top to bottom (highest to lowest, matching physical violin orientation).
- Each string is rendered as a thin horizontal gradient line (simulating a metal or gut string).
- String visual thickness varies: E is thinnest, G is thickest.
- Each string has:
  - **String label** (note name) on the left.
  - **Current frequency display** in Hz on the right (e.g., `438.2 Hz`).
  - A **toggle button** (small, circular) on the far right to latch the string sound on/off.
  - A **tap area** covering the full string row to select that string.
- The **selected string** glows subtly — a soft ambient glow along the string line, and a highlight border on the row.
- When a string is sounding (toggle active), animate the string with a subtle lateral oscillation (vibration).

### 3. Tuning Knobs (below strings)

- Two large circular **rotary knobs** side by side:
  - **Coarse Tuning** — larger steps (~5 cents per degree).
  - **Fine Tuning** — smaller steps (~0.5 cents per degree).
- Both knobs act on the **currently selected string**.
- Knob design:
  - Dark body (`colorSurfaceElevated`) with a subtle radial gradient for 3D depth.
  - A thin gold ring border.
  - A single indicator line (like a tuning peg marker) that rotates with the knob.
  - A label below each knob.
- **Interaction**: `GestureDetector` with `onPanUpdate` — vertical drag maps to rotation (up = increase pitch, down = decrease pitch).
- While a knob is being actively dragged, the selected string sounds continuously (auto-stops when drag ends unless string toggle is on).
- **Range**: Each string can deviate ±50 cents from its nominal pitch.

### 4. Check Button

- A prominent button labeled **CHECK** (or a tuning fork icon + label).
- On press, evaluates all four strings and shows **tuning indicators** on each string row.
- Tuning indicator: a horizontal **cent deviation bar** — a needle/bar that shows how many cents off from the nearest semitone the current tuning is.
  - Center = in tune (0 cents).
  - Left = flat (negative cents, `colorFlat` red).
  - Right = sharp (positive cents, `colorSharp` green).
  - ±0–5 cents: gold (essentially in tune).
  - ±5–20 cents: orange.
  - ±20–50 cents: red/sharp.
- Below the indicator bar, show the **nearest note name** and the **cent deviation** value numerically (e.g., `A4 −12¢`).
- The indicators animate in sequentially (staggered by 80 ms per string) for a professional reveal feel.

### 5. Reset Button

- A secondary button labeled **RESET**.
- On press, randomizes each string's tuning by ±(10–45) cents from its nominal pitch.
- Shows a brief confirmation animation (the string rows flash/ripple).
- Ask for confirmation only if any string toggle is currently active (sound is playing).

---

## Audio Architecture

### Package

Use **`flutter_soloud`** (preferred) for real-time sine wave synthesis — it supports multi-voice oscillators and runs natively on all platforms.

Alternative fallback: pre-render tone WAV files at build time using a Dart script and play via `just_audio` if `flutter_soloud` integration is too complex for a target platform.

### Audio Service

- `AudioService` is a singleton injected via Riverpod.
- It manages a pool of **voice handles** — one per concurrent tone (reference note + up to 4 strings = 5 max).
- Exposes:
  - `playTone(double frequency, {double volume = 0.6, WaveType type = WaveType.sine})` → `VoiceHandle`
  - `stopTone(VoiceHandle handle)`
  - `updateToneFrequency(VoiceHandle handle, double frequency)` — for real-time knob-drag updates.
  - `stopAll()`
- Applies a short **fade-in/fade-out** (10 ms) on all tone changes to avoid clicks/pops.
- Uses a **slightly detuned second oscillator** (+2 cents, half amplitude) blended in for a richer, violin-like timbre.

---

## State Management

Use **Riverpod** (`flutter_riverpod` + `riverpod_annotation` for code generation).

### Key Providers

```
tunerNotifierProvider        — TunerState (all string states, selected string, reference note)
audioServiceProvider         — AudioService singleton
referenceNoteProvider        — ReferenceNoteState (selected note, is playing)
checkResultsProvider         — List<StringCheckResult>? (null = not checked yet)
```

### TunerState model

```dart
class TunerState {
  final int selectedStringIndex;     // 0–3 (0 = E5, 3 = G3)
  final List<ViolinString> strings;  // 4 strings
}

class ViolinString {
  final String name;           // "E5", "A4", "D4", "G3"
  final double nominalFreq;    // standard frequency in Hz
  final double detuningCents;  // current offset in cents (-50 to +50)
  final bool isSounding;       // toggle state
}
```

---

## Project Folder Structure

```
lib/
├── main.dart
├── app.dart                          # MaterialApp root, theme injection
│
├── core/
│   ├── constants/
│   │   ├── app_colors.dart           # All color tokens
│   │   ├── app_typography.dart       # TextStyles & font setup
│   │   ├── app_spacing.dart          # Spacing constants
│   │   └── note_constants.dart       # Frequencies, note names, cent table
│   ├── theme/
│   │   └── app_theme.dart            # ThemeData factory (dark theme)
│   └── utils/
│       ├── audio_utils.dart          # cents_to_freq, freq_to_note helpers
│       └── math_utils.dart           # lerp, clamp helpers
│
├── features/
│   └── tuner/
│       ├── data/
│       │   └── audio_service.dart    # flutter_soloud wrapper
│       ├── domain/
│       │   ├── models/
│       │   │   ├── violin_string.dart
│       │   │   ├── reference_note.dart
│       │   │   └── string_check_result.dart
│       │   └── tuning_calculator.dart  # cents deviation, nearest note logic
│       └── presentation/
│           ├── providers/
│           │   ├── tuner_provider.dart
│           │   ├── audio_service_provider.dart
│           │   └── check_results_provider.dart
│           ├── screens/
│           │   └── tuner_screen.dart
│           └── widgets/
│               ├── reference_note_panel.dart
│               ├── string_row.dart
│               ├── string_vibration_painter.dart
│               ├── tuning_knob.dart
│               ├── cent_deviation_bar.dart
│               ├── check_button.dart
│               └── reset_button.dart
│
└── shared/
    └── widgets/
        ├── glow_border_container.dart    # Reusable glowing container
        ├── animated_press_button.dart    # Scale-on-press button wrapper
        └── segmented_selector.dart       # Custom segmented control
```

---

## Code Quality & Conventions

### Dart / Flutter

- Dart SDK: `^3.10.0`, Flutter: latest stable.
- Use `const` constructors everywhere possible.
- Prefer `final` for all local variables.
- No `dynamic` types — always explicitly typed.
- Use `sealed` classes for discriminated union states.
- All widget `build()` methods must be pure (no side effects).

### Naming

- Files: `snake_case.dart`
- Classes: `PascalCase`
- Constants: `camelCase` (dart convention) in `const` classes
- Private members: `_camelCase`

### Widget Decomposition

- No widget `build()` should exceed ~80 lines.
- Extract any widget that logically stands alone into its own file.
- Use `CustomPainter` for the string line, vibration animation, and cent deviation bar.

### Linting

`analysis_options.yaml` should enable:
- `flutter_lints` baseline
- `prefer_const_constructors`
- `avoid_print`
- `prefer_final_locals`

---

## Recommended Packages

```yaml
dependencies:
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.3.5
  flutter_soloud: ^3.2.0
  google_fonts: ^6.2.1

dev_dependencies:
  riverpod_generator: ^2.4.3
  build_runner: ^2.4.12
  flutter_lints: ^6.0.0
```

---

## Audio-Visual Synchronization Rules

- Whenever a string's frequency changes (via knob), update the live audio frequency in the same frame — no perceptible lag.
- The Hz value label on the string row updates in real time during knob drag.
- CHECK results are cleared (hidden) whenever a knob is moved or Reset is pressed — they become stale.
- The reference note and string tones can play simultaneously (additive).

---

## Accessibility

- All interactive elements have a minimum touch target of `48×48 dp`.
- Semantic labels on all buttons and knobs for screen readers.
- Color alone is never the only indicator — pair color with text values and position (flat = left, sharp = right).
- Support system font scaling.

---

## Do Not

- Do not use `setState` in screens — all state lives in Riverpod providers.
- Do not hardcode colors or sizes inline — always reference constants.
- Do not use `print()` — use `debugPrint()` wrapped in `kDebugMode` checks.
- Do not add platform-specific code outside the `data/` layer.
- Do not play audio on the main isolate's hot path — use `flutter_soloud`'s internal thread.
- Do not show permission dialogs for microphone — this app does NOT use mic input (output only).
