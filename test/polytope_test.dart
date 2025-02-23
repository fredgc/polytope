// Copyright 2024 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:test/test.dart';

import 'package:polytope/polytope.dart';
import 'package:polytope/printer.dart';
import 'package:polytope/regular.dart';
import 'package:polytope/transform.dart';
import 'package:polytope/vector.dart';

final double tolerance = 0.0001;
void checkSizes(Polytope p, List<int> sizes) {
  expect(sizes.length, p.dim, reason: "dimension of $p is wrong");
  for (int i = 0; i < sizes.length; i++) {
    expect(p.size(i), sizes[i],
        reason: "Number of $p's cells of dim $i is wrong");
  }
}

void expectNear(num t1, num t2, Polytope p, Polytope top) {
  expect(t1, closeTo(t2, tolerance),
      reason: "${zzz(t1)} != ${zzz(t2)}, for $p\nIn $top");
}

// Go through the iterator and make surea ll the computed values are the same.
void checkSame<P>(Polytope top, Iterator<P> it, num Function(P p) computer,
    {void Function(num t1, num t2, Polytope p, Polytope top) check =
        expectNear}) {
  // Find the first one.
  if (!it.moveNext()) return;
  num val1 = computer(it.current);
  while (it.moveNext()) {
    num val2 = computer(it.current);
    check(val1, val2, it.current as Polytope, top);
  }
}

void main() {
  group('Polygon sizes.', () {
    setUp(() {
      DebugPrint.print_debug = 0;
    });

    test('Debug print.', () {
      Polytope.polytope_count = 0;
      dprint("YELLOW: Getting ready to make a poly.");
      Polytope p = Regular.cross.make(5);
      DebugPrint.print_debug = 1;
      checkSizes(p, [10, 40, 80, 80, 32]);
      dprint("YELLOW: Here is the poly.");
      // p.printAll();
      dprint(
          "YELLOW: ---------------------------------------------------------.");
      DebugPrint.print_debug = 0;
    });

    // test('Debug print.', () {
    //   DebugPrint.print_debug = 1;
    //   Polytope.polytope_count = 0;
    //   dprint("YELLOW: Getting ready to make a poly.");
    //   Polytope p = Regular.simplex.make(2);
    //   dprint("YELLOW: Here is the poly.");
    //   p.printAll();
    //   dprint("YELLOW: Compute size 0");
    //   int s = p.size(0);
    //   dprint("YELLOW: Size = $s");
    //   DebugPrint.print_debug = 0;
    // });

    test('Triangle.', () {
      DebugPrint.print_debug = 0; //XXX put at start of all tests?
      Polytope triangle = Regular.simplex.make(2);
    });
    test('Square.', () {
      Polytope square = Regular.cube.make(2);
      checkSizes(square, [4, 4]);
    });
    test('Cross type.', () {
      Polytope cross = Regular.cube.make(2);
      checkSizes(cross, [4, 4]);
    });
  });
  group('Plantonic Solids size.', () {
    setUp(() {
      DebugPrint.print_debug = 0;
    });
    // The platonic dim-3 polyhedron.
    test('Tetrahedron.', () {
      checkSizes(Regular.simplex.make(3), [4, 6, 4]);
    });
    test('Cube.', () {
      checkSizes(Regular.cube.make(3), [8, 12, 6]);
    });
    test('Octahedron.', () {
      checkSizes(Regular.cross.make(3), [6, 12, 8]);
    });
    test('Dodecahedron.', () {
      checkSizes(Regular.dodec.make(3), [20, 30, 12]);
    });
    test('Icosahedron.', () {
      checkSizes(Regular.ico.make(3), [12, 30, 20]);
    });
    // And the small ones in dimension 4.
    test('4 dim simplex.', () {
      checkSizes(Regular.simplex.make(4), [5, 10, 10, 5]);
    });
    test('4 dim cube.', () {
      checkSizes(Regular.cube.make(4), [16, 32, 24, 8]);
    });
    test('4 dim cross type.', () {
      checkSizes(Regular.cross.make(4), [8, 24, 32, 16]);
    });
    test('4 dim 24 cell.', () {
      checkSizes(Regular.cell24.make(4), [24, 96, 96, 24]);
    });
    // Ref: https://en.wikipedia.org/wiki/Cross-polytope.
    test('5 dim simplex.', () {
      checkSizes(Regular.simplex.make(5), [6, 15, 20, 15, 6]);
    });
    test('5 dim cube.', () {
      checkSizes(Regular.cube.make(5), [32, 80, 80, 40, 10]);
    });
    test('5 dim cross type.', () {
      checkSizes(Regular.cross.make(5), [10, 40, 80, 80, 32]);
    });
  });
  group('Dimensions.', () {
    setUp(() {
      DebugPrint.print_debug = 0;
    });
    test('Check dimensions.', () {
      for (int i = Regular.min_dim; i <= Regular.max_dim; i++) {
        expect(Regular.simplex.make(i).dim, i);
        expect(Regular.cube.make(i).dim, i);
        expect(Regular.cross.make(i).dim, i);
        expect(Regular.dodec.make(i).dim, 3);
        expect(Regular.ico.make(i).dim, 3);
        expect(Regular.cell24.make(i).dim, 4);
      }
    });
  });
  group('Regular.', () {
    for (int i = Regular.min_dim; i <= Regular.max_dim; i++) {
      for (Regular type in Regular.values) {
        test('Dim $i, $type has vertex on unit sphere.', () {
          Polytope p = type.make(i);
          for (var v in p.vertices) {
            expect(v.vertex.norm(), closeTo(1.0, tolerance),
                reason: "Vertex $v of $type in dim $i");
          }
          for (int h = 1; h < p.dim; h++) {
            p.cellFirst(h);
            for (var v in p.vertices) {
              expect(v.vertex.norm(), closeTo(1.0, tolerance),
                  reason: "Vertex $v of $type in dim $i. Rotate $h first.");
            }
          }
        });
      }
    }
    for (int i = Regular.min_dim; i <= Regular.max_dim; i++) {
      for (Regular type in Regular.values) {
        test('Dim $i, $type edge length same.', () {
          Polytope p = type.make(i);
          checkSame(p, p.edges, (edge) {
            expect(edge.cells.length, 2, reason: "Bad edge in dim $i $type");
            Vertex v1 = edge.cells.elementAt(0) as Vertex;
            Vertex v2 = edge.cells.elementAt(1) as Vertex;
            Vector delta = v2.vertex - v1.vertex;
            return delta.norm();
          });
        });
      }
    }
    for (int i = Regular.min_dim; i <= Regular.max_dim; i++) {
      for (Regular type in Regular.values) {
        test('Dim $i, $type same number of cells.', () {
          Polytope p = type.make(i);
          for (int c = 0; c < p.dim; c++) {
            checkSame(p, PolyIterator(p, c), (cell) => cell.cells.length);
          }
        });
      }
    }
    for (int i = Regular.min_dim; i <= Regular.max_dim; i++) {
      for (Regular type in Regular.values) {
        test('Dim $i, $type same number of parents.', () {
          Polytope p = type.make(i);
          for (int c = 0; c < p.dim; c++) {
            checkSame(p, PolyIterator(p, c), (cell) => cell.parents.length);
          }
        });
      }
    }
  });
}
