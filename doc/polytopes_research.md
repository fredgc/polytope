# Research: Regular Polytopes in $\mathbb{R}^3$ and $\mathbb{R}^4$

## Summary of Answers

* **$\mathbb{R}^3$ Polytopes (Platonic Solids):**
  There are exactly 5 regular convex polyhedra in $\mathbb{R}^3$. Polytope
  supports all 5.

* **$\mathbb{R}^4$ Polytopes (Regular 4-Polytopes / Polychora):**
  There are exactly 6 regular convex 4-polytopes in $\mathbb{R}^4$.

* **Current $\mathbb{R}^4$ Support in Codebase:**
  Currently, 4 of the 6 are implemented:
  1. 5-cell (Regular Simplex, dim 4)
  2. 8-cell / Tesseract (Hypercube, dim 4)
  3. 16-cell / Orthoplex (Cross Polytope, dim 4)
  4. 24-cell (Octaplex / Icositetrachoron)

  The remaining 2 are:
  5. 120-cell (Hecatonicosachoron)
  6. 600-cell (Hexacosichoron)

---

## 1. Regular Polytopes in $\mathbb{R}^3$ (Platonic Solids)

All 5 are supported in the codebase:

| Name | Schläfli | Vertices | Edges | Faces | Cells | Implementation Method |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Simplex (Tetrahedron) | {3,3} | 4 | 6 | 4 | - | `makeSimplex(3)` |
| Cube (Hexahedron) | {4,3} | 8 | 12 | 6 | - | `makeCube(3)` |
| Cross (Octahedron) | {3,4} | 6 | 12 | 8 | - | `makeCross(3)` |
| Dodecahedron | {5,3} | 20 | 30 | 12 | - | `makeDodecahedron(3)` |
| Icosahedron | {3,5} | 12 | 30 | 20 | - | `makeIcosahedron(3)` |

---

## 2. Regular Polytopes in $\mathbb{R}^4$ (Convex 4-Polytopes)

There are 6 regular convex polychora:

| Name | Schläfli | Vertices | Edges | Faces | Cells | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 5-cell (Simplex) | {3,3,3} | 5 | 10 | 10 | 5 tetrahedra | Supported |
| 8-cell (Tesseract) | {4,3,3} | 16 | 32 | 24 | 8 cubes | Supported |
| 16-cell (Orthoplex) | {3,3,4} | 8 | 24 | 32 | 16 tetrahedra | Supported |
| 24-cell (Icositetrachoron) | {3,4,3} | 24 | 96 | 96 | 24 octahedra | Supported |
| 120-cell (Hecatonicosachoron)| {5,3,3} | 600 | 1200 | 720 | 120 dodecahedra | Planned |
| 600-cell (Hexacosichoron) | {3,3,5} | 120 | 720 | 1200 | 600 tetrahedra | Planned |

---

## 3. Mathematical Foundations & Algebraic References

### Binary Icosahedral Group and Quaternions

The 120 vertices of the 600-cell can be represented as unit quaternions
forming the binary icosahedral group $2I$. In 4D Euclidean space
$\mathbb{R}^4$, a quaternion $q = x_0 + x_1 i + x_2 j + x_3 k$ sits on the
3-sphere $S^3 \subset \mathbb{R}^4$.

* [Binary Icosahedral Group (Wikipedia)](https://en.wikipedia.org/wiki/Binary_icosahedral_group)
* [Quaternions and Spatial Rotation (Wikipedia)](https://en.wikipedia.org/wiki/Quaternions_and_spatial_rotation)
* [600-cell (Wikipedia)](https://en.wikipedia.org/wiki/600-cell)
* [120-cell (Wikipedia)](https://en.wikipedia.org/wiki/120-cell)
* [Coxeter, Regular Polytopes (MathWorld)](https://mathworld.wolfram.com/600-Cell.html)

### Vertex Coordinates

Let $\phi = \frac{1 + \sqrt{5}}{2}$ denote the golden ratio.

The 120 vertices of the unit 600-cell are:
* 16 vertices: $(\pm \frac{1}{2}, \pm \frac{1}{2}, \pm \frac{1}{2}, \pm \frac{1}{2})$
* 8 vertices: permutations of $(\pm 1, 0, 0, 0)$
* 96 vertices: even permutations of
  $(\pm \frac{\phi}{2}, \pm \frac{1}{2}, \pm \frac{1}{2\phi}, 0)$

### Edge and Face Adjacency

* **600-cell:** Two vertices are connected by an edge if and only if their
  Euclidean distance is $1/\phi = \phi - 1 \approx 0.618034$. Each vertex
  has degree 12, forming 720 edges. Each triangular face corresponds to
  a 3-clique of mutually connected vertices (1,200 faces). Each tetrahedral
  cell corresponds to a 4-clique (600 cells).

* **120-cell (Dual Construction):**
  * The 600 vertices are the circumcenters (averages of 4 vertices) of the
    600 tetrahedral cells of the 600-cell, projected to the unit sphere $S^3$.
  * Two 120-cell vertices share an edge if their corresponding tetrahedra share
    a triangular face.
  * 120-cell faces are planar regular pentagons formed by cycles of 5 edges.
  * 120-cell cells are regular dodecahedra corresponding to the 120 vertices
    of the 600-cell.

---

## 4. Implementation Plan & Tool Architecture

To ensure high performance and avoid freeze or jank when opening these shapes:

1. **Pre-generation Tool (`tool/generate_polychora.dart`):**
   * Computes the complete topological incidence mesh:
     * Vertices $(x, y, z, w)$
     * Edges: pairs of vertex indices $[v_1, v_2]$
     * Faces: ordered sequences of edge indices forming closed loops
     * Cells: sets of face indices forming 3D boundary cells
   * Validates topological invariants (Euler characteristic
     $V - E + F - C = 0$, vertex degrees, cell counts).
   * Serializes the meshes into compact JSON asset files:
     * `assets/mesh/cell600.json`
     * `assets/mesh/cell120.json`

2. **Asset Loading & Runtime Integration (`Polytope.loadFromAsset`):**
   * Extend `Polytope` with a direct builder that reconstructs the
     incidence graph from precomputed index tables in $O(V + E + F + C)$
     time, avoiding slow combinatorial deduplication (`gather()`).
   * Add `Regular.cell120` and `Regular.cell600` to the `Regular` enum.
   * Connect with `scene.dart` and `slice.dart` to support full 4D rotation
     and real-time 3D hyperplane slicing.
