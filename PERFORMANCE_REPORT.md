# Performance report — `favorite_places`

**Verdict:** the app is small and functionally light, and basic rendering is fine — the feed is lazy (8–9 cards built for 200 saved places) and the frame pipeline is cheap. Three issues dominate its performance profile, in order of impact:

1. **Every photo thumbnail decodes the full 1200×900 capture** (`Image.file` without `cacheWidth`). One 56 px thumbnail keeps **4.32 MB** of bitmap in memory instead of **84.7 KB** — a **51× waste**; the 100 MB `ImageCache` fills after **~24 photos**, after which scrolling thrashes the cache (re-decode + re-upload on every scroll-back).
2. **The blinking cursor runs an `AnimationController.repeat` forever**, so the app requests a frame at every vsync for the whole session (**60/60 frames scheduled while completely idle**, measured). The app can never idle → battery/thermals, on the landing screen.
3. **Google Fonts are resolved at runtime on every style creation and are not bundled.** First launch downloads **185 KB** of TTF from `fonts.gstatic.com` and renders fallback text until it arrives; each `AsciiType.*()` call re-enters google_fonts' pipeline (**18.9 µs vs 0.47 µs for a plain `TextStyle`**, debug mode); and if the fetch ever fails (offline first run), every text style call re-attempts the fetch for the rest of the session.

Nothing here is an emergency for a small local app, but #1 and #2 are cheap, high-value fixes (≈20 min each).

**Measured on:** Flutter 3.47.9 / Dart 3.13.7, macOS 27.2.1 (arm64), `flutter analyze` clean, existing 6/6 tests passing. Benchmarks: 17 deterministic headless tests in `test/perf/` (see [`test/perf/README.md`](test/perf/README.md)), raw output in `test/perf/results/bench_results.txt`. Source-level audit cross-checked against the Flutter SDK and package internals.

---

## 1. How it was measured

| Layer | Method | Caveat |
| --- | --- | --- |
| Screen/frame cost | Real app widgets pumped in `flutter test` (`bench_screens_test.dart`), wall-clock `Stopwatch` around `tester.pump()` (build + layout + paint) | **Debug mode (JIT, assertions, no AOT)**: absolute ms values are upper bounds, several times slower than profile/release on a device. Software rasterizer: no GPU paint/raster cost. Surface 800×600 logical @ DPR 3. |
| Image memory | `ImageCache.currentSizeBytes` with real 1200×900 JPEG fixtures decoded by the app's own widget tree (`bench_image_decode_test.dart`) | Memory numbers are **mode-independent** — these are the app's real decoded sizes. |
| Typography | 3 000-call microbenchmarks + 300-text-widget A/B frames (`bench_typography_test.dart`, `bench_typography_loaded_test.dart`); warm-path test feeds the real TTFs through google_fonts' injectable HTTP client so the package's real load path runs | Debug-mode JIT; per-call µs are upper bounds, but the structural work per call (verified in package source) is real. |
| Source audit | Read all 17 `lib/` files + google_fonts 8.2.1 / Flutter SDK internals for exact mechanisms (line numbers in findings) | Estimates are labelled as such. |

Reproduce:

```bash
cd /Users/khaledwaled/favorite_places
flutter test --concurrency=1 test/perf        # 17 benchmarks, ~6 s
flutter test test/perf | grep '^BENCH|'       # machine-readable lines
```

Every benchmark prints `BENCH|name|value|unit` lines. Fixtures: `test/perf/fixtures/photo_1200x900.jpg` is the 4:3, 1200 px-wide photo `image_picker(maxWidth: 1200, imageQuality: 85)` produces; `photo_168x126.jpg` is the same photo pre-scaled to the thumbnail's physical size (56 px × DPR 3), used as the "correctly sized decode" comparison *without changing app code*.

---

## 2. Measured results

### 2.1 Startup / first frames (debug mode, upper bounds)

| Screen | First frame (median) | First-ever frame |
| --- | --- | --- |
| Home (empty state) | **12.96 ms** | 208.7 ms |
| Add-place form | **21.01 ms** | — |
| Place detail (with 1200×900 photo) | **11.22 ms** | — |
| Home rebuild (state change) | **0.13 ms** | — |

Startup is not a problem: the tree is small, and the theme is built once per launch (`AsciiTheme.data` is only read in `MyApp.build`, which does not rebuild). The one-time 208.7 ms first-ever frame is engine/font/first-touch warm-up in debug. The add-form's higher cost comes from the text field + autofocus subtree.

### 2.2 Idle behaviour — the app never idles

| State | Frames scheduled / 60 vsyncs | CPU per simulated second |
| --- | --- | --- |
| Home screen, cursor blinking (default) | **60 / 60** | **9.79 ms** |
| Home screen, `disableAnimations: true` | **0 / 60** | 2.03 ms (pump overhead only) |

`BlinkingCursor` (`lib/widgets/blinking_cursor.dart:24-27`) calls `_controller.repeat(reverse: true)`; a `Ticker` stays armed forever, so the engine is asked for a frame every vsync for the entire session. The blink only needs an alpha change ~1.4×/s, i.e. **~2 frames per 700 ms**, not 60–120. `FadeTransition` avoids rebuilding the subtree (verified in SDK source), so this is idle power/thermal cost rather than per-frame jank — but it is the largest idle-power item in the codebase, and the home screen is where users sit.

### 2.3 Feed scrolling — list virtualisation is healthy

| Places | Cards actually built | Frame time median / p90 (debug) |
| --- | --- | --- |
| 10 | 8 | 0.75 / 1.74 ms |
| 60 | 9 | 1.73 / 3.45 ms |
| 200 | 8 | 1.16 / 2.82 ms |

Confirmed: `ListView.separated` stays lazy (8–9 widgets built for 200 items) and each item is wrapped in a `RepaintBoundary` by default, so a moving list is cheap. Frame cost does **not** grow with the number of saved places.

### 2.4 Photos — the expensive part

| Measurement | Value |
| --- | --- |
| JPEG produced by capture (`maxWidth: 1200`, quality 85) | 33.8 KB, **1200×900 px** |
| Decoded bitmap when `Image.file` has no `cacheWidth` (what the app does) | **4 320 000 B = 4.12 MiB** |
| Decoded bitmap at thumbnail size (168×126, DPR 3) | **84 672 B = 82.7 KiB** |
| Waste factor | **51×** per thumbnail |
| Decode time, full size vs thumbnail-sized | **3.19 ms vs 0.81 ms** (3.9×) |
| `ImageCache` maximum | **104 857 600 B** → fills at **~24 photos** |
| Cache after building a 12-photo feed (8 visible cards) | **47 520 000 B / 11 live images** |
| Same cards with pre-sized 168×126 sources | **677 376 B / 8 live images** |

Details: `PlaceCard` renders the photo in a 56×56 box (`lib/widgets/place_card.dart:67`) via `AsciiPhoto` → `Image.file(image, fit: fit)` (`lib/widgets/ascii_photo.dart:36-38`). `Image.file` only downscales at decode time if `cacheWidth`/`cacheHeight` is given (SDK: `image.dart:537-545` → `ResizeImage.resizeIfNeeded`); without it the provider is a `FileImage` keyed on path and the engine decodes the **intrinsic** size. Consequences:

- 8 visible thumbnails hold **34.6 MB** of bitmaps (measured 47.5 MB including the 250 px cache-extent cards); each 1200×900 texture is uploaded to the GPU even though it is drawn at 168 px (default `FilterQuality.medium` adds mipmaps).
- With **~24 photos** the cache is full; from then on every scroll-back evicts + re-reads + re-decodes + re-uploads at ~4 ms of decode per image (plus upload), which is where real jank appears on low-end devices. The more places a user saves, the worse it gets.
- The detail screen is fine at full resolution (it displays the photo full-width), and today it shares the thumbnail's cache entry — but after fixing thumbnails the detail screen needs a `precacheImage` on tap (see fixes).

### 2.5 Typography / fonts

| Measurement | Value |
| --- | --- |
| `AsciiType.body()` per call (app) | **18.9 µs** (warm-path run: 24.7 µs) |
| `GoogleFonts.ibmPlexMono()` per call (inside it) | **11.3 µs** |
| Plain runtime `TextStyle` per call | **0.47 µs** |
| `AsciiType.*` call sites in `lib/` | **27** |
| Calls per home rebuild | ≈21–27 (5 fixed + 2 per built card) |
| Frame with 300 text widgets: app typography vs plain | **+3.48 ms (+22%)** debug |
| First-launch font download | **185 136 B** (76 988 B IBM Plex Mono + 112 148 B JetBrains Mono) |
| `AsciiTheme.data` construction | 0.07 ms warm, 28.7 ms first-ever (once per launch) |

Why 18.9 µs: every `AsciiType` helper calls `GoogleFonts.ibmPlexMono()` / `GoogleFonts.jetBrainsMono()` (`lib/theme/app_theme.dart:109,124`). In google_fonts 8.2.1 that method **rebuilds a 14- or 16-entry map literal of `GoogleFontsFile` objects on every call** (the constructor is non-`const`, `google_fonts_descriptor.dart:38`; map at `google_fonts_parts/part_i.dart:41-140`, `part_j.dart`), scans it with `_closestMatch` (no early exit), allocates 3 `TextStyle`s, 2 `Future`s, a descriptor/variant/family and several strings, and does 2 hash-set operations. The font is fetched at runtime because **no font assets are bundled** (`pubspec.yaml` `assets:`/`fonts:` blocks are comments), so first launch blocks on 185 KB of HTTPS and paints fallback text until the font registers; an offline first run fails the fetch, which *unmarks* the family (`google_fonts_base.dart:180`) so **every subsequent style call re-attempts the fetch**.

The per-call cost is real but bounded: ~0.4 ms per home rebuild in debug (≈21 calls), most of it JIT upper-bound overhead. Fixing it is mostly about the network/fallback behaviour and garbage, not frame rate.

---

## 3. Findings and fixes (ranked by impact ÷ effort)

### 3.1 High — thumbnails decode full-resolution photos

`lib/widgets/ascii_photo.dart:36` (used by `lib/widgets/place_card.dart:67`). Confirmed by measurement: 4.32 MB per thumbnail, 51× waste, cache full at 24 photos.

```dart
// lib/widgets/ascii_photo.dart
class AsciiPhoto extends StatelessWidget {
  const AsciiPhoto({
    super.key,
    required this.image,
    this.fit = BoxFit.cover,
    this.caption,
    this.logicalSize, // NEW: layout width in logical px; pass 56 from PlaceCard
  });

  final File image;
  final BoxFit fit;
  final String? caption;
  final double? logicalSize;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        ColorFiltered(
          colorFilter: const ColorFilter.matrix(_tintMatrix),
          child: Image.file(
            image,
            fit: fit,
            // Decode 168x126 on a 3x phone instead of 1200x900: 4.12 MiB -> 82.7 KiB.
            cacheWidth: logicalSize == null ? null : (logicalSize! * dpr).round(),
            gaplessPlayback: true,
            filterQuality: FilterQuality.low, // no mipmap chain for a downscaled thumb
            errorBuilder: /* unchanged */,
          ),
        ),
        // ... overlay/caption unchanged
      ],
    );
  }
}

// lib/widgets/place_card.dart:67
AsciiPhoto(image: widget.place.image!, logicalSize: _thumbSize)
```

Also add, when opening the detail screen (`lib/widgets/palces_list.dart:35`), a warm-up so the route transition does not pay the full decode: `precacheImage(FileImage(place.image!), context)`.

Effect: per-thumbnail memory **4.12 MiB → 82.7 KiB**, cache capacity **24 → ~1200 photos**, decode 3.9× faster, and no 1200 px texture uploads. One parameter + one call site.

### 3.2 High — the blinking cursor keeps the app awake forever

`lib/widgets/blinking_cursor.dart:24-48`. Measured: 60/60 frames scheduled with the app untouched; 0/60 with reduce-motion. Replace the ticker with a timer that only paints when the blink state changes:

```dart
class _BlinkingCursorState extends State<BlinkingCursor> {
  Timer? _timer;
  bool _visible = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _timer?.cancel();
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _visible = true; // honour reduce-motion: no blinking at all
      return;
    }
    _timer = Timer.periodic(AsciiMotion.blink, (_) {
      if (mounted) setState(() => _visible = !_visible); // ~2 frames per 700 ms
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Opacity(
        opacity: _visible ? 1 : 0,
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: ColoredBox(color: widget.color),
        ),
      );
}
```

If the visual wants a soft fade, wrap in `AnimatedOpacity(duration: 40ms)` — still only a handful of frames per toggle. This removes the only permanently-running ticker in the app (routes covered by another opaque route are already muted by `TickerMode`, but the home screen is the landing screen).

### 3.3 High — fonts are fetched at runtime on every style resolution

`lib/theme/app_theme.dart:109,124` + `pubspec.yaml` (no bundled fonts). Bundle the TTFs and reference the family natively; this removes the 185 KB first-launch download, the fallback-font reflow, the offline retry storm and the per-call pipeline:

```yaml
# pubspec.yaml
flutter:
  uses-material-design: true
  fonts:
    - family: IBMPlexMono
      fonts:
        - asset: assets/fonts/IBMPlexMono-Regular.ttf
        - asset: assets/fonts/IBMPlexMono-SemiBold.ttf
          weight: 600
    - family: JetBrainsMono
      fonts:
        - asset: assets/fonts/JetBrainsMono-Regular.ttf
```

```dart
// lib/theme/app_theme.dart — drop the google_fonts import
static const String _mono = 'IBMPlexMono';
static const String _code = 'JetBrainsMono';

static TextStyle _body({required double size, required Color color,
    FontWeight weight = FontWeight.w400, double letterSpacing = 0}) =>
    TextStyle(fontFamily: _mono, fontSize: size, height: 1.35,
        fontWeight: weight, letterSpacing: letterSpacing, color: color);
```

The font files this report measured are in `test/perf/fixtures/fonts/` (byte-identical to what google_fonts downloads: sha256 matches the gstatic hash). Bonus: today `GoogleFonts.ibmPlexMono()` is called with no weight, so all `w600` text is **synthetic** bold; bundling the SemiBold face fixes that too.

Minimum-diff alternative if bundling is out of scope — resolve the family once instead of per call:

```dart
static final String _ibmFamily = GoogleFonts.ibmPlexMono().fontFamily;
static final String _jetFamily = GoogleFonts.jetBrainsMono().fontFamily;
```

### 3.4 Medium — rebuild granularity when a place is added

`lib/screens/palces.dart:15,44-48` watches the whole list at the screen root, so one `addPlace` (`user_palces.dart:11` prepends and copies) rebuilds the AppBar, status strip, button and every built card. Measured cost is small today (**0.13 ms** per home rebuild in debug), but it multiplies the typography and image work above. Push the watch down and add identity keys:

```dart
itemBuilder: (context, index) => PlaceCard(
  key: ValueKey(places[index].id),   // stable identity when prepending
  place: places[index], index: index, onTap: ...);
```

and make `_StatusStrip` a `ConsumerWidget` watching `userPlacesProvider.select((p) => p.length)` / a `photoCountProvider`, so the screen shell stops rebuilding on every add.

### 3.5 Medium — per-card compositing / paint

`lib/widgets/ascii_photo.dart:34-58`: `ColorFiltered` always pushes an offscreen `ColorFilterLayer` per thumbnail (`alwaysNeedsCompositing => child != null` in the SDK), and the gradient `BoxDecoration`/`LinearGradient` (including two `withValues` colors) is rebuilt on every card build and re-shaded on every paint. The 168×168 layer is cheap, so this is not urgent, but hoisting the gradient decoration to a `static final` is free:

```dart
static final BoxDecoration _tintOverlay = BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [AsciiPalette.accent.withValues(alpha: 0.20),
             AsciiPalette.accentSoft.withValues(alpha: 0.08)],
  ),
);
```

The real win is 3.1 (the filter samples a 1200 px texture today; after the fix it samples 168 px). Do **not** add per-item `RepaintBoundary`s — the list already does that (verified in SDK: `scroll_view.dart:1538`, `scroll_delegate.dart:560`).

### 3.6 Low — smaller items

- `lib/screens/places_detail.dart:43`: a `ListView` for two static children — `SingleChildScrollView` + `Column` is lighter (also add the `precacheImage` from 3.1).
- `lib/models/place.dart:12`: stores `dart:io File` pointing into image_picker's **temporary** directory; the OS can purge it (photos then show "// image unavailable"). Copy into documents storage at save time. No persistence means cold start is always empty.
- `lib/providers/user_palces.dart:11`: `[newPlace, ...state]` copies the whole list per add (O(n)); fine at this scale, worth a `List.unmodifiable` only if the list is ever capped/paged.
- `lib/widgets/place_card.dart:41`: `Semantics(button: true, label: title)` duplicates the child `Text` semantics; minor churn when a screen reader is active.

### 3.7 Verified non-issues (do not "fix")

- Items already get a `RepaintBoundary` from `ListView.separated` (SDK default `addRepaintBoundaries: true`).
- `AsciiTheme.data` is a `getter`, but it is only evaluated once per launch (`lib/main.dart:18`, `MyApp` never rebuilds) — measured 0.07 ms warm; it is not a per-frame cost.
- The existing tests' `disableAnimations: true` is correct and not a performance smell.
- Riverpod 3.5 legacy `StateNotifier` adds one allocation per state change — no measurable frame impact; the granularity issue (3.4) is architectural, not the legacy API.

---

## 4. Fix plan (suggested order)

| # | Change | Effort | Expected effect |
| --- | --- | --- | --- |
| 1 | `cacheWidth`/`logicalSize` on the thumbnail `Image.file` (+ `precacheImage` on detail push) | ~20 min | 51× less image memory, cache full at ~1200 instead of 24 photos, 3.9× cheaper decodes |
| 2 | Timer-based blink in `BlinkingCursor` | ~20 min | app idles again: 60–120 frames/s → ~2 frames/700 ms; removes the steady-state power draw |
| 3 | Bundle the TTFs, drop google_fonts from the runtime path, cache `TextStyle`s | ~1 h | no 185 KB first-launch fetch, no fallback-font reflow, no offline retry storm, ~18 µs/call → near-zero |
| 4 | Push `ref.watch` down + add `ValueKey`s | ~30 min | avoids rebuilding the shell + all cards on every add |
| 5 | Hoist the gradient decoration; `SingleChildScrollView` on detail | ~15 min | small paint/allocation win |

Re-run `flutter test --concurrency=1 test/perf` after each step; the `BENCH|` lines are directly comparable.

---

## 5. Limits of this report

- **No trustworthy device-profile frame timings were captured in this session.** The macOS profile build compiles and launches (`flutter build macos --profile` succeeds; a Profile app exists), but headless frame-timing collection through `integration_test`/`flutter drive` failed in this environment (test harness error, no timeline data produced). All absolute frame numbers above therefore come from **debug-mode, software-rasterized `flutter test`** and are upper bounds. The *relative* comparisons (photo vs pre-sized photo, animations on/off, 10 vs 200 places) and the **memory numbers** are valid regardless of mode.
- GPU/raster cost of the per-card `ColorFiltered` + gradient is **not measured** (no GPU in `flutter test`); it is flagged as medium and should be confirmed with DevTools on a real device.
- Battery/thermal impact is inferred from the frame-scheduling measurement, not measured.
- Font first-load latency is network-dependent; the mechanism (fallback text until `FontLoader` registers, then a text relayout via `systemFontsDidChange`) is verified in SDK source, the perceived duration is not.
