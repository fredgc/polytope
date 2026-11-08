# Polytope Drawing Tool (v2.1.0+3)

An interactive, educational application for constructing, rotating, and slicing
regular polytopes across 3, 4, and higher dimensions.

* **Live Web App**: [polytope.gchouse.org](https://polytope.gchouse.org)

* **Android Package**: `org.gchouse.polytope`

---

## Documentation

In-depth documentation and policies are located in `doc/`:

* [doc/about.md](doc/about.md): Project origins, mathematical background on
  regular polytopes, and version details.

* [doc/privacy.md](doc/privacy.md): Privacy policy and explanation of local
  preference persistence via SharedPreferences.

* [doc/terms.md](doc/terms.md): Terms of service.

---

## Core Features

* **Higher-Dimensional Regular Polytopes**:
  Explore regular polytopes including the simplex, hypercube (tesseract),
  cross-polytope (16-cell), 24-cell, 120-cell, and 600-cell.

* **Dynamic Hyperplane Slicing**:
  Observe animated 3D hyperplane slices intersecting 4D polytopes as the slice
  offset varies continuously.

* **N-Dimensional Rotations**:
  Interact with multiple simultaneous 2D rotation planes with variable speed
  and direction controls.

* **Spatial WebXR Support**:
  Experience 3D cross-sections and 4D projections as interactive spatial
  holograms in WebXR-compatible browsers and headsets.

---

## Getting Started

### Prerequisites

* [Flutter SDK](https://docs.flutter.dev/get-started/install)
  (3.24+ recommended)

* `make` and [Pandoc](https://pandoc.org/) (for compiling documentation)

### Forking and Cloning

1. Fork the repository on GitHub to your personal account.

2. Clone your fork locally:

   ```bash
   git clone https://github.com/<your-username>/polytope.git
   cd polytope
   ```

3. Install Flutter dependencies:

   ```bash
   flutter pub get
   ```

4. Build documentation assets:

   ```bash
   make docs
   ```

### Running Locally

To run the web version in Chrome:

```bash
flutter run -d chrome
```

To run on a connected Android device or emulator:

```bash
flutter run -d android
```

### Running Tests

Execute the unit and widget test suite:

```bash
flutter test
```

### Building Releases

Use the provided `Makefile` to generate release assets:

```bash
make build_all
```

---

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md) for details.

---

## License

This project is open-source and licensed under the
[Apache 2.0 License](LICENSE).

---

## Disclaimer

This project is not an official Google project. It is not supported by Google
and Google specifically disclaims all warranties as to its quality,
merchantability, or fitness for a particular purpose.
