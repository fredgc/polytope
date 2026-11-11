# GEMINI.md - Developer Guide for Polytope Drawing Tool

Welcome! This guide is designed to help future LLM agents and human developers
get up to speed quickly on the **Polytope** Flutter application.

---

## Developer Rules & Environment Configuration

All contributors and AI agents must follow the central rules defined in
`~/source/gemini/config/rules/`:

* **Task Management (`todo.md`)**: Project tasks and issues are tracked using
  `~/bin/todo.py`. When asked about tasks or what to work on next, execute:

  ```bash
  ~/bin/todo.py list
  ```

Before starting an item, mark it in progress (`~/bin/todo.py doing <N>`). Once
completed, mark it done (`~/bin/todo.py done <N>`). Do not archive completed
tasks until reviewed and verified.

* **Communication Style (`style.md`)**: Be blunt and direct. Avoid polite
  filler and superlatives. Keep responses concise, technical, and focused
  strictly on facts and instructions.

* **Documentation Formatting (`markdown.md`)**: Keep line lengths strictly
  under 80 characters. Always separate list items with a blank line. Always
  follow headers with a blank line. Visually align markdown table column
  borders (`|`).

* **Emacs Integration (`emacs.md`)**: When requested to send a file to Emacs,
  run `emacs-maybe-client -f <file>`.

* **Hardware & Testing (`devices.md`)**: On host `raven`, an Android device
  may be connected via `adb` for Android testing.

---

## 1. Project Purpose & Features

The **Polytope Drawing Tool** is an interactive, cross-platform (Web and
Android) application used to construct, rotate, project, and slice regular
polytopes in 3, 4, and higher dimensions.

### Key Features

* **Higher-Dimensional Polytopes**: Supports regular polytopes including
  simplexes, hypercubes, cross-polytopes, the 24-cell, the 120-cell, and the
  600-cell.

* **Dynamic Hyperplane Slicing**: Calculates the exact 3D cross-sections
  formed by intersecting 4D polytopes with moving 3D hyperplanes.

* **Interactive N-Dimensional Rotation**: Manipulate rotation planes in 3D and
  4D space with continuous speed and angle controls.

* **WebXR and Spatial Rendering**: Provides experimental immersive WebXR
  rendering allowing users to view and manipulate 3D slices and 4D wireframes
  as holographic spatial objects.

---

## 2. Codebase Architecture

```text
lib/
├── animate.dart           # Animation timing and controller utilities
├── color.dart             # Color schemes and face palette management
├── drawable.dart          # Canvas drawable primitives (dots, edges, faces)
├── help.dart              # In-app help viewer loading doc HTML assets
├── main.dart              # App entry point
├── permute.dart           # Coordinate permutation and symmetry generators
├── polytope.dart          # Base polytope data models and topological mesh
├── printer.dart           # Debug logging utilities
├── regular.dart           # Generators for regular polytopes across dimensions
├── scene.dart             # Scene layout and high-dimensional viewport
├── settings.dart          # SharedPreferences persistence and settings dialog
├── slice.dart             # Hyperplane slicing and polygon intersection math
├── slider.dart            # Custom parameter slider widgets
├── spatial_scene.dart     # 3D spatial scene graph for XR pipelines
├── transform.dart         # N-dimensional rotation and projection matrices
├── vector.dart            # Vector and matrix algebra
├── webxr_renderer.dart    # WebXR JavaScript bridge and 3D WebGL renderer
├── widget.dart            # Top-level UI widgets and responsive scaffolding
└── xr_support.dart        # Platform-agnostic XR capability detection
```

---

## 3. Build, Versioning & Deployment Workflow

### Build and Asset Automation (`Makefile`)

The project uses `make` targets to coordinate asset compilation and builds:

* `make docs`: Compiles user markdown docs from `doc/*.md` into
  `assets/*.html` and developer docs (`plan.md`, `README.md`, `GEMINI.md`)
  into `assets/dev/*.html` via `pandoc`.

* `make ASSETS`: Generates icons, favicons, version metadata, and docs.

* `make test`: Runs standard Flutter unit, widget, and ARB localization parity
  tests on every commit (`flutter test --exclude-tags release_audit`). Fast
  execution (~2-5 seconds).

* `make audit`: Runs exhaustive pre-release accessibility and multi-locale
  layout audits (`flutter test test/audit_test.dart`). Tests all supported
  locales, compact mobile/tablet/desktop viewports, 1.5x/2.0x font scaling,
  and WCAG AA guidelines (`labeledTapTargetGuideline`). Required automatically
  by `make stage-release` and `make release`.

* `make stage`: Builds web app with debug flags and runs `firebase_stage.pl`.

* `make release`: Deploys production bundle to Firebase
  (`polytope.gchouse.org`).

### Version Rolling (`roll_build_number.sh`)

Increments the build number in `pubspec.yaml` and propagates the update to
`web/version.json`:

```bash
./roll_build_number.sh
```

---

## 4. Code Style Guidelines

* **Markdown**: Keep line lengths strictly under 80 characters. Always
  separate list items with a blank line. Always follow headers with a blank
  line.

* **Dart**: Run `dart format .` after modifying any code. Keep static analysis
  free of errors and lints.

---

## 5. Testing Guidelines

Run tests before committing:

```bash
flutter test
```
