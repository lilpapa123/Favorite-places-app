# Performance benchmarks

Deterministic, headless benchmarks for `favorite_places`. They exercise the
real app widgets (`PalcesScreen`, `PalcesList`, `PlaceCard`, `AsciiPhoto`,
`PlacesDetailScreen`, `AddedPlaceScreen`) and the real theme — nothing is
re-implemented except two deliberately plain comparison widgets.

## Run

```bash
flutter test test/perf
```

Capture the machine-readable results (every benchmark prints a `BENCH|` line):

```bash
flutter test test/perf | grep '^BENCH|' | tee bench_results.txt
```

Or run one file:

```bash
flutter test test/perf/bench_image_decode_test.dart
```

## What is measured

| File | Measures |
| --- | --- |
| `bench_image_decode_test.dart` | Decoded bitmap memory and decode time for a 1200x900 camera photo vs a thumbnail-sized decode; ImageCache bytes filled by a photo feed; 1200x900 vs pre-sized source in the same cards. |
| `bench_screens_test.dart` | Cold first-frame cost of home / add-form / detail; idle CPU while the blinking cursor animates (and with animations disabled); scroll frame cost at 10 / 60 / 200 places (laziness); scroll with photo cards at two source resolutions; home screen rebuild cost. |
| `bench_typography_test.dart` | Per-call cost of `AsciiType.*()` (which resolves Google Fonts on every call), `AsciiTheme.data` construction, and a frame with 300 text widgets in app typography vs plain `TextStyle`. |

Fixtures in `fixtures/` are synthetic but photo-realistic 4:3 JPEGs:
`photo_1200x900.jpg` is the size `image_picker(maxWidth: 1200, imageQuality: 85)`
produces on a phone; `photo_168x126.jpg` is that same photo pre-scaled to the
physical size of the 56 px thumbnail at devicePixelRatio 3.

## How to read the numbers

* `flutter test` runs in **debug mode** (JIT, all assertions). Absolute
  millisecond values are upper bounds and are several times slower than a
  profile/release build on a device. Use them for A/B comparisons and for the
  memory numbers (memory is mode-independent).
* Test frames are rendered with a **software rasterizer**: `pump()` measures
  build + layout + paint but not GPU rasterisation, so `ColorFiltered`/gradient
  GPU cost is *not* included.
* The default test surface is 800x600 logical px at DPR 3.0.
* The Google Fonts benchmark measures the app's actual test configuration
  (no bundled fonts, runtime fetching disabled). In production the first call
  may instead download the font and later calls take the "already loaded"
  fast path, which is cheaper than the number printed here but still non-zero
  per call.
* `bench_screens_test.dart` relies on the blinking-cursor animation; the
  reduced-motion test asserts that with `disableAnimations: true` no frames are
  scheduled at all.
