# Polytope Project Plan

This document outlines the strategic roadmap, architecture goals, and long-term
milestones for adding **Virtual Reality (VR)** and **Augmented/Extended Reality
(XR)** support to the **Polytope** Flutter application across WebXR and Android
builds.

> **Note**: Active day-to-day tasks and issue tracking are managed dynamically
> using `~/bin/todo.py`. Run `~/bin/todo.py list` to view active tasks.

---

## 1. Executive Summary & Goals

The goal is to allow users to experience regular polytopes (hypercubes,
24-cells, 120-cells, 600-cells, etc.) and their dynamic 3D hyperplane slices as
**interactive 3D holographic objects** in physical space (AR) or immersive
space (VR).

### Guiding Principles

1. **Maximum Shared Dart / Flutter Code**:

   - All high-dimensional mathematics, $n$-dimensional rotation matrices,
     perspective/zolly projections down to 3D, slice calculation, $x_4$ rainbow
     coloring, animations, and UI controls remain **100% in pure Dart**.

2. **Minimal Target-Specific Glue**:

   - Platform-dependent code is isolated behind a clean abstract interface
     (`XRSupport`) for:

     - **WebXR** (`lib/xr_support_web.dart` + `lib/webxr_renderer.dart` —
       Meta Quest Browser, Chrome on Android, Vision Pro Safari, desktop XR
       emulators).

     - **Android Mobile AR / ARCore** (`lib/xr_support_mobile.dart` — Android
       phones and tablets with camera passthrough).

     - **Android XR Headsets** (`lib/xr_support_mobile.dart` — standalone
       spatial headsets running Android XR / OpenXR / Jetpack XR).

3. **Preserve Existing 2D Web & Mobile Functionality**:

   - The standard 2D canvas drawing screen remains the default on non-XR
     devices or when XR mode is not active.

---

## 2. Current Architecture & Implementation Status

```text
                     ┌─────────────────────────┐
                     │   Polytope Geometry &   │
                     │   Slice Engine (Dart)   │
                     └────────────┬────────────┘
                                  │
                                  ▼
                     ┌─────────────────────────┐
                     │   CoordinateTransform   │
                     │ (R^d -> R^3 + wx4 math) │
                     └────────────┬────────────┘
                                  │
            ┌─────────────────────┴─────────────────────┐
            ▼                                           ▼
 ┌──────────────────────┐                    ┌──────────────────────┐
 │   2D Canvas Engine   │                    │     SpatialScene     │
 │  (Dot, LineSegment,  │                    │ (Float32List sphere  │
 │  SlideEdge, Clipper) │                    │  & cylinder buffers) │
 └──────────────────────┘                    └──────────┬───────────┘
                                                        │
                              ┌─────────────────────────┴───┐
                              ▼                             ▼
                   ┌──────────────────────┐      ┌──────────────────────┐
                   │     WebXR Backend    │      │   Android AR / XR    │
                   │ (WebGL2 Instancing)  │      │ (ARCore / OpenXR)    │
                   └──────────────────────┘      └──────────────────────┘
```

### Completed Shared & WebXR Components

* **3D Projection (`lib/transform.dart`, `lib/vector.dart`)**:
  `CoordinateTransform.projectTo3D` and `apply` compute 3D world coordinates
  (`wx`, `wy`, `wz`) and the 4D depth coordinate (`wx4 = temp.x[3]`) prior to
  2D screen flattening (`sx`, `sy`, `sz`).

* **Shared 3D Scene Graph (`lib/spatial_scene.dart`)**:
  `SpatialScene` converts `Scene` vertices, edges, and active hyperplane slice
  intersections into contiguous GPU-ready buffers every frame:

  - `sphereBuffer`: `8` floats per sphere (`[x, y, z, radius, r, g, b, a]`).

  - `cylinderBuffer`: `12` floats per cylinder
    (`[x1, y1, z1, x2, y2, z2, radius, r, g, b, a, 0.0]`).

  - Supports both solid colors (`poly_color`, `slice_color`) and $x_4$ rainbow
    coloring (`color_by_x4`, `slice_color_by_x4`).

* **WebXR Backend (`lib/xr_support_web.dart`, `lib/webxr_renderer.dart`)**:
  Complete WebGL2 instanced renderer (`glDrawElementsInstanced`) with
  Blinn-Phong lighting, supporting `immersive-vr`, `immersive-ar`, and `inline`
  WebXR sessions.

### Current Gap on Android (`lib/xr_support_mobile.dart`)

* `AndroidXRSupport` currently mounts a placeholder `ARView` from
  `ar_flutter_plugin_2` (`showPlanes: true`, `showWorldOrigin: true`) without
  consuming `SpatialScene` buffers or rendering polytope geometry.

* `AndroidXRSupport.checkSupport()` currently sets `supported = true`
  unconditionally without querying device ARCore or OpenXR availability.

* `AndroidXRSupport.buildScene()` lacks the 2D Flutter control overlay (exit
  button, polytope/dimension selectors, $R^4$ rotation pad, and slice slider).

---

## 3. Plan for Adding XR Support on the Android Build

Android XR support targets two complementary form factors from a single Android
build:

1. **Android Mobile AR (Phones & Tablets via ARCore)**: Camera passthrough
   where the 3D polytope and slice hologram is anchored on a physical tabletop
   or floating 0.5–0.8m in front of the device camera.

2. **Android XR Headsets (Spatial OS / OpenXR / Jetpack XR)**: Headsets and XR
   glasses running Android XR, supporting both **Home Space** (2D Flutter
   spatial panel alongside a 3D volume) and **Full Space** (stereoscopic 6DoF
   passthrough/VR).

### 3.1 Rendering Strategy on Android

Polytopes such as the 120-cell (600 vertices, 1,200 edges) and 600-cell (120
vertices, 720 edges) animate continuously at 60–120 Hz during 4D rotations and
hyperplane slicing. Creating and mutating hundreds of individual high-level
scene-graph nodes (`ARNode`) over a Flutter `MethodChannel` every frame would
introduce severe serialization overhead and frame drops.

Instead, the Android build will mirror the proven `WebXRRenderer` architecture:

* **Single-Call Hardware Instancing (OpenGL ES 3.0 / Vulkan)**:

  - Reuse the exact same `SpatialScene.sphereBuffer` and
    `SpatialScene.cylinderBuffer` (`Float32List`) generated in Dart.

  - Pass the two flat `Float32List` byte buffers (`Uint8List` / `Float32List`)
    across a single lightweight platform call per frame (or shared FFI buffer)
    to a native Kotlin/C++ OpenGL ES 3.0 renderer.

  - Reuse the GLSL ES 3.0 instanced sphere and cylinder vertex/fragment shaders
    from `lib/webxr_renderer.dart`: one unit sphere VBO and one unit cylinder
    VBO on the GPU, drawn in 2 draw calls per eye (`glDrawElementsInstanced`).

* **Camera & Pose Integration**:

  - **On Mobile ARCore**: The native GLES3 renderer draws the ARCore background
    camera texture, queries the ARCore `Camera` `viewMatrix` and
    `projectionMatrix` plus the active world `Anchor` pose, and renders the
    instanced spheres and cylinders into the Flutter `Texture` /
    `PlatformView`.

  - **On Android XR Headsets**: When running in an OpenXR / Jetpack XR full
    space session, the same GLES3 instanced renderer runs per-eye using the
    headset's `XRView` projection and view matrices.

### 3.2 UI & Interaction Design on Android XR

1. **2D Flutter Control Overlay (`Stack`)**:

   - `AndroidXRSupport.buildScene(BuildContext context)` will render a `Stack`
     with the 3D AR/XR viewport filling the background and translucent Material
     controls pinned to the top and bottom edges:

     - **Top Bar**: Back button (`onExitXR` to return to 2D canvas), Polytope
       selector menu, Dimension menu, Movement mode menu ($R^3$, $R^4$, $R^5$,
       Zolly), and Re-center / Reset Anchor button.

     - **Bottom Bar**: Slice toggle checkbox and `MySlider` hyperplane slice
       slider with speed controls.

2. **Spatial Touch & Hand Gestures**:

   - **Viewing in $\mathbb{R}^3$**: Moving the phone or headset naturally moves
     the camera around the 3D projection in physical space.

   - **Higher-Dimensional Rotation ($\mathbb{R}^4, \mathbb{R}^5$)**: 1-finger
     drag on the viewport background routes to `scene.transform.rotatePair` for
     the active movement dimension (defaulting to `Rotate R4` in XR since 3D
     viewing is handled by physical camera motion).

   - **Scale & Placement**: 2-finger pinch adjusts `SpatialScene.worldScale`
     (default `0.35m` radius), and tapping a detected ARCore plane anchors the
     polytope at that 3D hit location (defaulting to `0.6m` in front of the
     initial camera pose before any plane is tapped).

---

## 4. Phased Implementation Roadmap for Android XR

| Phase | Milestone              | Key Deliverables                           |
| ----- | ---------------------- | ------------------------------------------ |
| 1     | Manifest & Capabilities| Optional ARCore/XR manifest, runtime check |
| 2     | Flutter XR Overlay     | `Stack` UI controls, `repaint_counter` sync|
| 3     | GLES3 Instancing       | Kotlin GLES3 shaders using `SpatialScene`  |
| 4     | ARCore Anchoring       | Plane tap placement, 4D drag, pinch scale  |
| 5     | Android XR & Release   | OpenXR headset mode, device audit, release |

### Phase 1: Android Manifest, Permissions & Capability Detection

* **Update `android/app/src/main/AndroidManifest.xml`**:

  - Add `<uses-permission android:name="android.permission.CAMERA" />`.

  - Add `<uses-feature android:name="android.hardware.camera.ar"
    android:required="false" />` and `<meta-data
    android:name="com.google.ar.core" android:value="optional" />` so the app
    remains installable on non-AR devices.

  - Add Android XR spatial activity metadata so Android XR headsets can launch
    the app in spatial panel or full-space mode.

* **Runtime Capability Check (`AndroidXRSupport.checkSupport`)**:

  - Query the native platform channel for ARCore availability
    (`ArCoreApk.getInstance().checkAvailability`) or Android XR / OpenXR
    runtime presence, and set `supported` accurately instead of hardcoding
    `true`.

### Phase 2: Flutter XR Overlay & Animation Sync (`lib/xr_support_mobile.dart`)

* Build `AndroidXRWidget` in `lib/xr_support_mobile.dart` (mirroring
  `WebXRWidget` in `lib/xr_support_web.dart`):

  - Listen to `scene.repaint_counter` so any 4D rotation, slice slider change,
    or `MyAnimator` tick immediately updates `SpatialScene` and pushes new
    instance buffers to the Android renderer.

  - Render translucent top/bottom control bars over the AR viewport for
    switching polytopes, dimensions, $R^4$/$R^5$ rotation, slice position, and
    exiting back to 2D mode (`onExitXR`).

### Phase 3: Native GLES3 Instanced Renderer on Android

* Implement a lightweight Kotlin OpenGL ES 3.0 renderer in
  `android/app/src/main/kotlin/...`:

  - Port the vertex and fragment shaders from `lib/webxr_renderer.dart`
    (instanced spheres + instanced cylinders with Blinn-Phong lighting).

  - Expose a `MethodChannel` / `EventChannel` (`org.gchouse.polytope/xr`) with
    methods:

    - `checkXrSupport()` -> returns `{arCore: bool, openXr: bool}`

    - `startSession()` / `stopSession()`

    - `updateGeometry(Float32List spheres, Float32List cylinders)`

    - `resetAnchor()`

* Verify that the 120-cell (600 spheres + 1,200 cylinders) renders at a steady
  60+ FPS on an Android device connected via `adb` on host `raven`.

### Phase 4: ARCore World Anchoring & Touch Gestures

* Default the polytope origin to `(0, 0, -0.6)` meters in local session space
  so the polytope is immediately visible upon entering AR without requiring the
  user to scan a floor/table first.

* Allow tapping a detected ARCore plane to move the world anchor to the hit
  pose, and provide a "Reset Position" button in the overlay to re-center the
  hologram in front of the current camera view.

* Connect single-finger drag on the AR view to 4D rotation (`Rotate R4`) and
  two-finger pinch to `SpatialScene.worldScale`.

### Phase 5: Android XR Headsets, Settings & Production Enablement

* Add a setting in `lib/settings.dart` (`enable_xr` or XR mode selector) or
  enable the AR/XR app bar button in release builds once Android ARCore and
  WebXR sessions are verified end-to-end.

* Test on physical Android hardware via `adb` (`flutter run -d <device-id>`)
  and verify clean fallback to 2D canvas mode when camera permission is denied.

---

## 5. Visual & Accessibility Verification Checklist

Perform these checks across supported locales (`en`, `es`, `de`, `fr`, `ja`,
`lt`, `pt`, `zh`) on mobile and desktop viewports:

* **Polytope Projections & Canvas**:

  * [ ] Verify 2D, 3D, 4D, and 5D regular polytopes render correctly with
        clear edge contrast in both light and dark modes.

  * [ ] Verify $x_4$ rainbow coloring (`Color Lines by x4 Distance` and
        `Color Slice Lines by x4 Distance`) renders smooth red-to-violet
        gradients along edges.

  * [ ] Verify hyperplane slicing renders intersection polygons smoothly when
        toggling **Slice** on and off.

* **Rotation & Transform Modes**:

  * [ ] Cycle through rotation modes (R3, R4, R5, Zolly, Translate, Scale) and
        verify drag gestures apply velocity and inertial spin smoothly.

  * [ ] Test snap-to-element buttons (vertex, edge, face, 3-cell) and confirm
        the projection snaps cleanly without visual distortion.

* **Documentation & Help Screen**:

  * [ ] Open Help dialog and verify all tabs load in the active language
        (`about`, `privacy`, `terms`, `help`, `slice`, `controls`).

  * [ ] Verify that markdown formatting and equations render legibly without
        horizontal clipping on narrow screens.

* **Language Menu & Navigation**:

  * [ ] Switch to each language from the top bar language menu and confirm all
        UI labels, toolbars, settings, and help tabs update immediately.

  * [ ] Switch to **Auto** and verify the app reverts cleanly to the system
        default locale.

* **Touch Targets & Screen Readers**:

  * [ ] Run `make audit` to verify zero layout overflows at `1.5x` text scaling
        and full compliance with `labeledTapTargetGuideline`.
