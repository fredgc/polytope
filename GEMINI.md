# GEMINI.md - Developer Guide for Polytope Drawing Tool

Welcome! This guide is designed to help future LLM agents and human developers
get up to speed quickly on the **Polytope** Flutter application.

-------------------------------------------------------------------------------

## Developer Rules & Environment Configuration

All contributors and AI agents must follow the central rules defined in
`~/source/gemini/config/rules/`:

- **Task Management (`todo.md`)**: Project tasks and issues are tracked using
  `~/bin/todo.py`. Always execute `~/bin/todo.py` directly (do not prefix with
  `python` or `python3`):

  ``` bash
  ~/bin/todo.py list
  ```

  Before starting an item, mark it in progress (`~/bin/todo.py doing <N>`).
  Once completed, mark it done (`~/bin/todo.py done <N>`). Do not archive
  completed tasks (`~/bin/todo.py archive`) until reviewed and verified.
  Cross-project recipes live in `~/source/gemini/recipes/<name>.md` and are
  managed via `~/bin/todo.py recipes`. If `~/bin/todo.py` fails due to expired
  Google Cloud tokens, stop and ask the user to run `gcloud auth login`.

- **Communication Style (`style.md`)**: Be blunt and direct. Avoid polite
  filler and superlatives. Keep responses concise, technical, and focused
  strictly on facts and instructions.

- **Documentation Formatting (`markdown.md`)**: Keep line lengths strictly
  under 80 characters. Always separate list items with a blank line. Always
  follow headers with a blank line. Visually align markdown table column
  borders (`|`).

- **Tool & Git Usage (`tools.md`)**: Always use native `read_file`,
  `edit_file`, and `write_file` tools instead of shell commands like `cat`,
  `head`, `tail`, `sed -i`, or `perl -i`. Prefer `git -C <path> <subcommand>`
  over `cd <path> && git <subcommand>`. Never rewrite git history using
  `git reset` or squash commits on dev branches; always add incremental
  commits.

- **Emacs Integration (`emacs.md`)**: When requested to send a file to Emacs,
  run `emacs-maybe-client -f <file>` (or omit `-f` to wait for editing).

- **Hardware & Testing (`devices.md`)**: On host `raven`, an Android device may
  be connected via `adb` for Android testing (`adb reverse tcp:5505 tcp:5505`).

-------------------------------------------------------------------------------

## 1. Project Purpose & Features

The **Polytope Drawing Tool** is an interactive, cross-platform (Web and
Android) application used to construct, rotate, project, and slice regular
polytopes in 2, 3, 4, and 5 dimensions.

### Key Features

- **Higher-Dimensional Polytopes**: Supports regular polytopes including
  simplexes, hypercubes, cross-polytopes (orthoplexes), dodecahedra,
  icosahedra, the 24-cell, the 120-cell, and the 600-cell.

- **Dynamic Hyperplane Slicing**: Calculates the exact 3D cross-sections formed
  by intersecting higher-dimensional polytopes with moving hyperplanes, with
  sticky transition points at vertices.

- **Interactive N-Dimensional Rotation**: Manipulate rotation planes in
  $\mathbb{R}^3$, $\mathbb{R}^4$, and $\mathbb{R}^5$, perspective (zolly),
  translation, scaling, and orientation snaps (vertex, edge, face, 3-cell
  first).

- **Depth Cues & $x_4$ Rainbow Coloring**: Supports 2D crossing-line gap
  clipping (`enable_line_clipping`) to show 3D depth ($z$) and optional smooth
  rainbow gradient coloring (`color_by_x4`, `slice_color_by_x4`) mapping the
  lowest $x_4$ coordinate to red and highest $x_4$ coordinate to violet.

- **Internationalization (i18n)**: Localized across 8 languages (`de`, `en`,
  `es`, `fr`, `ja`, `lt`, `pt`, `zh`) for both UI strings (`lib/l10n/*.arb`)
  and compiled HTML help documentation (`doc/*.md`).

- **WebXR and Spatial Rendering**: Provides experimental immersive 3D rendering
  allowing users to view and manipulate 3D slices and 4D wireframes as
  holographic spatial objects via instanced spheres and cylinders.

-------------------------------------------------------------------------------

## 2. Codebase Architecture

``` text
lib/
├── animate.dart                 # Animation timing and controller utilities
├── color.dart                   # Color schemes, pickers, and theme management
├── drawable.dart                # 2D canvas drawables (Dot, LineSegment, gaps)
├── firebase_options.dart        # Firebase platform configuration
├── help.dart                    # In-app help viewer loading doc HTML assets
├── help_nav_listener.dart       # Conditional export for help navigation
├── help_nav_listener_stub.dart  # Non-web stub for help navigation listener
├── help_nav_listener_web.dart   # Web postMessage listener for help links
├── l10n/                        # ARB translation files and generated l10n
├── main.dart                    # App entry point and route registration
├── mesh_data.dart               # Precomputed 4D meshes (120-cell, 600-cell)
├── permute.dart                 # Coordinate permutation and symmetry helpers
├── polytope.dart                # Base polytope data models and topology mesh
├── printer.dart                 # Debug formatting and logging utilities
├── regular.dart                 # Generators for regular polytopes across dims
├── scene.dart                   # Scene state, clipping, x4 bounds, and input
├── settings.dart                # SharedPreferences persistence and UI screen
├── slice.dart                   # Hyperplane slicing & intersection drawables
├── slider.dart                  # Custom parameter slider with sticky stops
├── spatial_scene.dart           # 3D instanced sphere/cylinder scene for XR
├── transform.dart               # N-dimensional rotation and zolly projection
├── vector.dart                  # Vector and Point algebra in R^d
├── web_cache.dart               # Conditional export for web version checking
├── web_cache_stub.dart          # Non-web stub for cache checking
├── web_cache_web.dart           # Web version.json polling and cache busting
├── webxr_renderer.dart          # WebGL2 instanced sphere/cylinder shader loop
├── widget.dart                  # Top-level responsive UI and app bar controls
├── xr_support.dart              # Platform-agnostic XR capability interface
├── xr_support_mobile.dart       # Android AR / XR implementation
├── xr_support_stub.dart         # Fallback stub for unsupported platforms
└── xr_support_web.dart          # WebXR session and render loop implementation
```

-------------------------------------------------------------------------------

## 3. Development Best Practices & Gotchas

- **Localization Parity**: Whenever adding a user-visible string or setting,
  add the key and metadata to `lib/l10n/app_en.arb`, add translations to all 7
  other ARB files (`app_de.arb`, `app_es.arb`, `app_fr.arb`, `app_ja.arb`,
  `app_lt.arb`, `app_pt.arb`, `app_zh.arb`), and run `flutter gen-l10n`.
  `test/localization_test.dart` enforces strict key parity across all ARB
  files.

- **Settings Registration**: New settings (`SavableBool`, `SavableDouble`,
  `SavableColor`) must have a unique `name` key, be registered in
  `Scene.initSettings` or `Slice.initSettings`, and map their `name` to a
  localized label in `Savable.localizedName` (`lib/settings.dart`).

- **Responsive Layout & Accessibility**: `SettingsScreen` uses `Wrap` rows
  separated by `EndOfRow` markers, and `PolyAppWidget` automatically collapses
  toolbar items into a secondary scrollable bar on compact viewports
  (`width < 600` or text overflow). Any new interactive widget must pass
  `make audit` across all locales at `1.5x` text scaling and satisfy WCAG AA
  tap target guidelines (`labeledTapTargetGuideline`).

- **Coordinate Pipeline**: `CoordinateTransform.projectTo3D` rotates in
  $\mathbb{R}^d$ and applies perspective (`zolly`) down to $\mathbb{R}^3$.
  `CoordinateTransform.apply` populates 3D world coordinates (`wx`, `wy`,
  `wz`), the 4D coordinate (`wx4 = temp.x[3]`), and 2D screen coordinates
  (`sx`, `sy`, `sz`). `SlideDot` instances are included in `scene.points` so
  they receive the same transform updates every frame.

- **Platform Conditional Imports**: Web-only packages (`package:web`,
  `dart:js_interop`, `package:webxr`) and mobile-only packages
  (`ar_flutter_plugin_2`) must never be imported directly in shared files. Use
  conditional exports (`xr_support.dart`, `web_cache.dart`,
  `help_nav_listener.dart`) so unit tests and cross-platform builds compile
  cleanly.

- **Window Size in Widget Tests**: Avoid deprecated `tester.binding.window`
  APIs; use `tester.view.physicalSize` and `tester.view.devicePixelRatio` with
  `addTearDown`.

-------------------------------------------------------------------------------

## 4. Build, Versioning & Deployment Workflow

### Build and Asset Automation (`Makefile`)

The project uses `make` targets to coordinate asset compilation and builds:

- `make docs`: Compiles user markdown docs from `doc/*.md` into `assets/*.html`
  and developer docs (`plan.md`, `README.md`, `GEMINI.md`) into
  `assets/dev/*.html` via `pandoc`.

- `make ASSETS`: Generates icons, favicons, mesh JSON, and compiled HTML docs.

- `make test`: Runs standard Flutter unit, widget, and ARB localization parity
  tests (`flutter test --exclude-tags release_audit`). Fast execution (\~2-8
  seconds).

- `make audit`: Runs exhaustive pre-release accessibility and multi-locale
  layout audits (`flutter test test/audit_test.dart`). Tests all supported
  locales, compact mobile/tablet/desktop viewports, `1.5x` font scaling, and
  WCAG AA guidelines (`labeledTapTargetGuideline`). Required automatically by
  `make stage-release` and `make release`.

- `make stage`: Builds web app and deploys to the Firebase staging channel via
  `firebase_stage.pl`.

- `make stage-release`: Runs `make audit`, builds web app, and deploys to the
  Firebase staging channel.

- `make release`: Runs `make audit`, builds all targets (`make build_all`), and
  deploys production bundle to Firebase (`polytope.gchouse.org`).

### Version Rolling (`roll_build_number.sh`)

Increments the build number in `pubspec.yaml`:

``` bash
roll_build_number.sh
```

-------------------------------------------------------------------------------

## 5. Code Style Guidelines

- **Markdown**: Keep line lengths strictly under 80 characters. Always separate
  list items with a blank line. Always follow headers with a blank line.
  Visually align markdown table column borders (`|`).

- **Dart**: Run `dart format .` after modifying any code. Keep
  `flutter analyze` free of errors, warnings, and lints.

-------------------------------------------------------------------------------

## 6. Testing Guidelines

Run targeted tests during development for fast feedback, and run the full test
suite before committing:

- **Polytope Topology, Slicing, Clipping & $x_4$ Coloring**:

  ``` bash
  flutter test test/polytope_test.dart
  ```

- **Coordinate Transform & Projection Math**:

  ``` bash
  flutter test test/transform_test.dart
  ```

- **3D Spatial Scene Buffers**:

  ``` bash
  flutter test test/spatial_scene_test.dart
  ```

- **Localization & ARB Key Parity**:

  ``` bash
  flutter test test/localization_test.dart
  ```

- **Theme & Settings UI**:

  ``` bash
  flutter test test/theme_test.dart
  ```

- **Help Screen & Documentation Tabs**:

  ``` bash
  flutter test test/help_test.dart
  ```

- **Pre-Release Multi-Locale Layout & Accessibility Audit**:

  ``` bash
  make audit
  ```

- **Full Standard Test Suite**:

  ``` bash
  make test
  ```
