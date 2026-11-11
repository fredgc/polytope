# Polytope Project Plan

This document outlines the strategic roadmap, architecture goals, and long-
term milestones for the **Polytope** Flutter project.

> **Note**: Active day-to-day tasks and issue tracking are managed >

dynamically using `~/bin/todo.py`. Run `~/bin/todo.py list` to view active >
tasks.

---

This document outlines the architecture, roadmap, and open questions for
adding **Virtual Reality (VR)** and **Augmented/Extended Reality (XR)**
support to the **Polytope** Flutter application.

---

## 1. Executive Summary & Goals

The goal is to allow users to experience regular polytopes (hypercubes,
24-cells, 120-cells, etc.) and their dynamic 3D hyperplane slices as
**interactive 3D holographic objects** in physical space (AR) or immersive
space (VR).

### Guiding Principles

1. **Maximum Shared Dart / Flutter Code**:

   - All high-dimensional mathematics, n-dimensional rotation matrices,
     perspective/zolly projections down to 3D, slice calculation, animations,
     and UI controls remain **100% in pure Dart**.

2. **Minimal Target-Specific Glue**:

   - Platform-dependent code is isolated behind a clean abstract interface
     (`XRSupport` / `XRRenderer`) for:

     - **WebXR** (Meta Quest Browser, Chrome on Android, Vision Pro Safari,
       desktop XR emulators).

     - **Android AR / ARCore** (Mobile phones/tablets with camera
       passthrough).

     - **Android XR** (Headsets running the new Android XR platform / OpenXR /
       Jetpack XR).

3. **Preserve Existing 2D Web & Mobile Functionality**:

   - The standard 2D canvas drawing screen remains the default on non-XR
     devices or when XR mode is not active.

---

## 2. Current Architecture & Gap Analysis

```
Current Architecture:
[Polytope Math (d-dimensions)]
       │
       ▼
[CoordinateTransform] ── (Rotates in d-dim, zolly projects to R3, scales & offsets to R2)
       │
       ▼
[Drawables (Dot, LineSegment, SliceEdge)]
       │
       ▼
[Flutter Canvas (CustomPainter)] ── 2D pixel drawing (sx, sy)
```

### The Gap for XR:

1. **Projection Target**:

   - Currently, `CoordinateTransform.apply` projects points from $\mathbb{R}^d
     \to \mathbb{R}^3$ via:

     ```dart
     // 1. Rotation in R^d:
     temp.x[i] += A[i][j] * (p.x[j] - b.x[j]) * scale;
     // 2. Perspective/zolly reduction down to R^3:
     for (int j = zolly.length - 1; j > 1; j--) {
       for (int i = 0; i < j; i++) {
         temp.x[i] = temp.x[i] / (1.0 - zolly[j] * temp.x[j]);
       }
     }
     ```

At this point, `(temp.x[0], temp.x[1], temp.x[2])` are true **3D coordinates
in $\mathbb{R}^3$**.

   - However, the code immediately flattens them to 2D screen space:

     ```dart
     p.sx = offset.x + zoom * temp.x[0];
     p.sy = offset.y - zoom * temp.x[1];
     p.sz = zoom * temp.x[2]; // sz is only used for z-sorting/coloring
     ```

   - In XR, we do **not** flatten to 2D! The XR device's head tracking and
     stereoscopic cameras handle the final 3D-to-eye projection. We need the
     3D vertices and 3D line/polygon edges.

2. **Rendering Technology**:

   - Flutter's standard `Canvas` is a 2D rendering API.

   - For 3D stereoscopic XR, the target device requires either a 3D scene
     graph, WebGL (for WebXR), or native 3D mesh nodes (ARCore / Android XR).

---

## 3. Proposed Architecture

```
                          ┌─────────────────────────┐
                          │   Polytope Geometry &   │
                          │   Slice Engine (Dart)   │
                          └────────────┬────────────┘
                                       │
                                       ▼
                          ┌─────────────────────────┐
                          │  CoordinateTransform3D  │
                          │  (R^d -> R^3 projection) │
                          └────────────┬────────────┘
                                       │
                                       ▼
                          ┌─────────────────────────┐
                          │      SpatialScene       │
                          │ (3D Vertices, Edges,    │
                          │  Slice Mesh, Colors)    │
                          └────────────┬────────────┘
                                       │
                ┌──────────────────────┴──────────────────────┐
                ▼                                             ▼
     ┌──────────────────────┐                      ┌──────────────────────┐
     │     WebXR Backend    │                      │   Android AR / XR    │
     │   (WebGL / WebXR)    │                      │ (ARCore / AndroidXR) │
     └──────────────────────┘                      └──────────────────────┘
```

### 3.1 The Shared 3D Data Layer (`SpatialScene`)

A pure Dart class that produces geometry buffers without any dependencies on
WebGL, Android, or Flutter UI:

- **Vertices**: `Float32List` containing $(x, y, z)$ coordinates.

- **Edges (Polytope wireframe)**: `Int32List` of index pairs `[v1, v2, v3, v4,
  ...]`.

- **Slice Geometry**:

  - Slice edges (wireframe) and/or slice faces (triangulated 3D polygons).

- **Colors & Opacity**: Node colors (polytope color, slice color, vertex dot
  color).

- **Transform**: Translation / scale anchor in physical space (e.g., 1 meter
  in front of user, 0.5m radius).

### 3.2 Target 1: WebXR (`xr_support_web.dart`)

- **Session Modes**:

  - Supports `immersive-ar` (passthrough on phone Chrome or Quest 3) and
    `immersive-vr` (Quest, Vision Pro, VR headsets).

- **Rendering Strategy Options**:

  - *Option A: Lightweight WebGL2 line/mesh renderer in Dart*

    - Uses `package:web` to obtain `web.WebGLRenderingContext` from an HTML
      `<canvas>`.

    - Simple vertex/fragment shader to render line segments with custom colors
      and simple shaded spheres/triangles.

    - Highly efficient, zero external JS libraries needed, compiles directly
      with `dart2js` / WASM.

  - *Option B: Three.js bridge or Three-dart*

    - Easier lighting and material effects, but requires larger bundle size
      and JS interop overhead.

  - **Recommendation**: Option A (a clean, ~200-line WebGL shader loop in
    Dart) keeps the codebase lightweight and dependency-free.

- **UI Overlay**:

  - Uses WebXR **DOM Overlay** (`dom-overlay` feature).

  - This allows the standard Flutter UI (rotation mode selector, dimension
    picker, slice slider) to float as an HTML layer directly over the XR
    session!

### 3.3 Target 2: Android AR on Mobile (`xr_support_mobile.dart`)

- **Session Mode**: ARCore camera passthrough.

- **Rendering Strategy Options**:

  - *Option A: `ar_flutter_plugin_2`* (Already in `pubspec.yaml`)

    - Uses ARCore on Android.

    - Can anchor a 3D node and update geometry.

  - *Option B: Google SceneView / Filament (via Flutter platform view)*

    - Supports dynamic line and primitive drawing with low latency.

- **UI Overlay**:

  - Standard Flutter widgets laid over the AR camera view using a Flutter
    `Stack`.

### 3.4 Target 3: Android XR (Spatial OS / Headsets)

- Google has announced the **Android XR platform** (for spatial headsets,
  e.g., Samsung XR headset).

- Android XR supports:

  - **Spatial Panels**: Standard 2D Android/Flutter apps running on a floating
    curved panel in 3D space.

  - **Spatial Scenes / OpenXR**: Apps taking over full 3D space with 6DoF
    tracking.

- By structuring our abstraction as `XRSupport`, we can drop in an
  `AndroidXRSupport` implementation when the official Android XR Flutter SDK /
  OpenXR bindings are released.

---

## 4. UI & Interaction in XR

In a 2D screen, interaction is done via mouse drag and touch gestures (drag =
rotate 3D, shift-drag = rotate 4D, etc.). In XR, we have new spatial
capabilities:

1. **Viewing (Head movement)**:

   - 3D perspective and rotation around the 3D projection are natural: the
     user simply walks around or turns their head!

2. **Higher-Dimensional Rotation ($R^4, R^5$)**:

   - Head movement only moves our view in $\mathbb{R}^3$. To rotate planes
     like $x-w$ (the 4th dimension), the user still needs an active rotation
     input.

   - **Approach**: Floating 2D Flutter buttons / joystick / gesture raycast
     (e.g. pinch-drag horizontally to rotate $x-w$).

3. **Slice Slider**:

   - A floating slider panel next to the polytope, or controller thumbstick to
     slide through the hyperplane slice in real time.

4. **World Anchoring**:

   - Tap/pinch to place the polytope on a detected tabletop or suspend it at
     eye level.

---

## 5. Phased Roadmap

| Ready for Android XR headsets.             | Ready for Android XR headsets.                                                                                                                       | Ready for Android XR headsets.                                                           |
| ------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------- |
| Ready for Android XR headsets.             | Ready for Android XR headsets.                                                                                                                       | Ready for Android XR headsets.                                                           |
| Ready for Android XR headsets.             | Ready for Android XR headsets.                                                                                                                       | Ready for Android XR headsets.                                                           |
| Ready for Android XR headsets.             | Ready for Android XR headsets.                                                                                                                       | Ready for Android XR headsets.                                                           |
| Ready for Android XR headsets.             | Ready for Android XR headsets.                                                                                                                       | Ready for Android XR headsets.                                                           |
| Ready for Android XR headsets.             | Ready for Android XR headsets.                                                                                                                       | Ready for Android XR headsets.                                                           |

---

## 6. Architecture Decisions (Confirmed)

Based on project priorities, the following decisions are adopted:

### 1. Visual Style: Shaded 3D Tubes and Spheres

- **Polytope Vertices**: Shaded 3D spheres (using polytope vertex color).

- **Polytope Edges**: Shaded 3D cylinders / tubes connecting the projected 3D
  vertices.

- **Slice Vertices & Edges**: Shaded 3D spheres and cylinders with the
  distinct slice color.

- **Slice Faces**: Translucent shaded planar polygons (triangulated from the
  slice intersections).

- **Rendering Technique**: **Hardware Instancing** in shaders:

  - One unit sphere mesh buffer and one unit cylinder mesh buffer stored on
    GPU.

  - Each frame, Dart provides an instance array of segment endpoints $(A, B)$,
    radius, and color.

  - Vertex shader aligns and scales cylinders between $A$ and $B$, giving
    smooth 90Hz/120Hz rendering on standalone headsets like Meta Quest.

### 2. Target Priority & Fallback Architecture

- **Priority Order**:

  1. **WebXR on Meta Quest** (and WebXR-enabled browsers like Chrome Android /
     Vision Pro Safari).

  2. **Android Mobile AR** (ARCore camera passthrough on phones/tablets).

  3. **Android XR Headsets** (Spatial OS / OpenXR).

- **Settings & Fallback**:

  - Add an "XR Mode" setting in `Settings`:

    - Options: `Auto` (detects best supported system), `WebXR`, `Android AR`,
      or `Disabled`.

  - Graceful fallback: If an XR session fails or is unsupported, the app
    seamlessly falls back to standard 2D canvas mode with an informative
    banner.

### 3. UI & Control Scheme: Easiest First (Floating 2D Overlay)

- **WebXR**: Use **WebXR DOM Overlay** (`dom-overlay`).

  - The standard Flutter 2D UI (dimension picker, polytope selection, 4D
    rotation buttons, slice slider, help) floats as a familiar overlay panel
    over the immersive 3D scene.

- **Android AR**: Use a standard Flutter `Stack` containing the 3D AR view
  beneath the 2D Flutter control widgets.

- **Spatial Expansion (Future)**: Once the core 3D scene is proven and
  interactive, optional in-world 3D spatial handles or wrist menus can be
  introduced.

### 4. WebXR 3D Backend: Direct WebGL2 in Dart

- **Recommendation & Decision**: **Direct WebGL2 via `package:web`**.

  - **Why Direct WebGL2?**

    - **Broadest & Native Support**: WebXR’s `XRWebGLLayer` directly binds to
      WebGL2 contexts. Every WebXR browser (Meta Quest Browser, Chrome,
      Safari) natively supports WebGL2.

    - **No External JS Dependencies**: Zero npm packages, zero external CDNs,
      zero version mismatches.

    - **Fast & Modern**: Direct typed buffer uploads (`Float32List`) from Dart
      to GPU buffers, fully compatible with `dart2js` and Dart WASM
      compilation.

    - **Instancing Simplicity**: For procedural mathematical objects
      (cylinders and spheres), direct shaders are compact (~150-200 lines of
      shader code) and outperform heavy general-purpose 3D engines.

---

## 7. Detailed Step-by-Step Implementation Plan

### Step 1: Geometry Extraction in Pure Dart (`SpatialScene`)

- Create `lib/spatial_scene.dart`:

  - Extracts the $\mathbb{R}^d \to \mathbb{R}^3$ projection from
    `CoordinateTransform`.

  - Produces typed arrays for:

    - `sphereInstances`: `[x, y, z, radius, r, g, b, a]` for polytope and
      slice vertices.

    - `cylinderInstances`: `[x1, y1, z1, x2, y2, z2, radius, r, g, b, a]` for
      edges.

    - `faceTriangles`: 3D vertices and normals for slice polygon fill.

- Add unit tests in `test/spatial_scene_test.dart` to verify vertex/edge
  counts and coordinates match existing polytopes (simplex, hypercube,
  24-cell, etc.).

### Step 2: WebGL Shader Pipeline (`WebXRRenderer`)

- Implement the WebGL2 pipeline in pure Dart:

  - Shaders with Blinn-Phong directional lighting (ambient + diffuse +
    specular highlights).

  - Instanced cylinder generator (transforming a unit cylinder to connect any
    two 3D points).

  - Instanced sphere generator.

  - Single draw call for all edges (`glDrawArraysInstanced` /
    `glDrawElementsInstanced`), and single draw call for all vertices.

### Step 3: WebXR Session & Render Loop (`xr_support_web.dart`)

- Update `xr_support_web.dart`:

  - Request `immersive-vr` or `immersive-ar` session with `dom-overlay`
    enabled.

  - Setup WebXR render loop via `XRSession.requestAnimationFrame`.

  - Bind XR projection and view matrices (per eye) into the shader uniforms.

  - Connect user head position (viewer pose) to the scene camera.

### Step 4: WebXR UI Overlay & Controls

- Configure Flutter web container to participate as the `dom-overlay` root.

- Ensure the slice slider, polytope picker, and higher-dimensional rotation
  controls remain fully responsive via Quest touch controllers or hand
  tracking clicks.

### Step 5: Android Mobile AR Adapter (`xr_support_mobile.dart`)

- Wire up `ar_flutter_plugin_2` or platform view to render the same
  `SpatialScene` instance buffers using ARCore anchors.

- Add camera permission handling and plane detection.

### Step 6: Settings & Release Testing

- Add XR toggle and mode selection to `lib/settings.dart`.

- Verify build with `flutter test` and `flutter build web`.

- Test on Meta Quest Browser over local network / ADB.

---

## Visual & Accessibility Verification Checklist

Perform these manual checks across supported locales (`en`, `es`, `de`, `fr`,
`ja`, `lt`, `pt`, `zh`) on mobile and desktop viewports:

* **Polytope Projections & Canvas**:

  * [ ] Verify 2D, 3D, 4D, and 5D regular polytopes render correctly with
        clear edge contrast in both light and dark modes.

  * [ ] Verify hyperplane slicing renders intersection polygons smoothly when
        toggling **Slice** on and off.

* **Rotation & Transform Modes**:

  * [ ] Cycle through rotation modes (R3, R4, R5, Zolly, Translate) and verify
        drag gestures apply velocity and inertial spin smoothly.

  * [ ] Test snap-to-element buttons (vertex, edge, face, 3-cell) and confirm
        the projection snaps cleanly without visual distortion.

* **Documentation & Help Screen**:

  * [ ] Open Help dialog and verify all tabs load in the active language:

    * `about`: Overview and attribution.

    * `privacy`: Privacy policy.

    * `terms`: Terms of service.

    * `help`: Polytopes introduction and research notes.

    * `slice`: Hyperplane slicing guide.

    * `controls`: Controller and gesture guide.

  * [ ] Verify that markdown formatting and equations render legibly without
        horizontal clipping on narrow screens.

* **Language Menu & Navigation**:

  * [ ] Switch to each language from the top bar language menu and confirm all
        UI labels, toolbars, and help tabs update immediately.

  * [ ] Switch to **Auto** and verify the app reverts cleanly to the system
        default locale.

* **Touch Targets & Screen Readers**:

  * [ ] Verify that top bar action buttons (About, Privacy, Terms, Overview,
        Slices, Controls, Settings, Close) have sufficient touch padding on
        mobile.

  * [ ] Enable TalkBack (Android) or VoiceOver (iOS/macOS) and confirm screen
        reader announcements for transform mode changes and snap actions.
