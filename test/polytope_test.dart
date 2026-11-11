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

import 'package:flutter/material.dart';
import 'package:test/test.dart';

import 'package:polytope/drawable.dart';
import 'package:polytope/polytope.dart';
import 'package:polytope/printer.dart';
import 'package:polytope/regular.dart';
import 'package:polytope/scene.dart';
import 'package:polytope/slice.dart';
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
      checkSizes(triangle, [3, 3]);
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
    test('4 dim 120 cell.', () {
      checkSizes(Regular.cell120.make(4), [600, 1200, 720, 120]);
    });
    test('4 dim 600 cell.', () {
      checkSizes(Regular.cell600.make(4), [120, 720, 1200, 600]);
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
        expect(Regular.cell120.make(i).dim, 4);
        expect(Regular.cell600.make(i).dim, 4);
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

  group('Line clipping.', () {
    test('Crossing lines clip the one further away in Z', () {
      Scene scene = Scene();
      scene.drawables.clear();
      scene.points.clear();

      // Front horizontal segment: (-10, 0) to (10, 0) at z = 10
      Point p1 = Point()
        ..sx = -10
        ..sy = 0
        ..sz = 10;
      Point p2 = Point()
        ..sx = 10
        ..sy = 0
        ..sz = 10;
      Polytope e1 = Polytope(1, "E1");
      e1.cells.add(Vertex()..vertex = p1);
      e1.cells.add(Vertex()..vertex = p2);
      LineSegment s1 = LineSegment(e1, const Color(0xFFFFFFFF));

      // Back vertical segment: (0, -10) to (0, 10) at z = 0
      Point p3 = Point()
        ..sx = 0
        ..sy = -10
        ..sz = 0;
      Point p4 = Point()
        ..sx = 0
        ..sy = 10
        ..sz = 0;
      Polytope e2 = Polytope(1, "E2");
      e2.cells.add(Vertex()..vertex = p3);
      e2.cells.add(Vertex()..vertex = p4);
      LineSegment s2 = LineSegment(e2, const Color(0xFFFFFFFF));

      scene.drawables.addAll([s1, s2]);
      scene.clipLines();

      // s1 is in front (z=10 > z=0), so it should have no gaps
      expect(s1.gaps, isNull);
      // s2 is in back (z=0 < z=10), so it should have a gap around t=0.5
      expect(s2.gaps, isNotNull);
      expect(s2.gaps!.length, 2);
      double gStart = s2.gaps![0];
      double gEnd = s2.gaps![1];
      expect(gStart, lessThan(0.5));
      expect(gEnd, greaterThan(0.5));
    });

    test('SlideEdge crossing clips behind edge and does not clip at line ends',
        () {
      Scene scene = Scene();
      scene.drawables.clear();
      scene.points.clear();

      // Polytope edge: (-10, 0) to (10, 0) at z = 10
      Vertex v1 = Vertex(id: 1);
      v1.vertex.sx = -10;
      v1.vertex.sy = 0;
      v1.vertex.sz = 10;
      Vertex v2 = Vertex(id: 2);
      v2.vertex.sx = 10;
      v2.vertex.sy = 0;
      v2.vertex.sz = 10;
      Polytope e1 = Polytope(1, "E1");
      e1.cells.add(v1);
      e1.cells.add(v2);
      LineSegment polyEdge = LineSegment(e1, const Color(0xFFFFFFFF));

      // SlideDot sliding on e1
      SlideDot d1 = SlideDot(v1, v2, Vector.unit(0), const Color(0xFFFFFF00));
      d1.sx = 0;
      d1.sy = 0;
      d1.sz = 10;

      // Another SlideDot elsewhere: (0, 20) at z = 10
      Vertex v3 = Vertex(id: 3);
      Vertex v4 = Vertex(id: 4);
      SlideDot d2 = SlideDot(v3, v4, Vector.unit(0), const Color(0xFFFFFF00));
      d2.sx = 0;
      d2.sy = 20;
      d2.sz = 10;

      // SlideEdge from d1 to d2 (vertical line starting exactly on polyEdge at (0,0))
      SlideEdge sliceEdge1 = SlideEdge(d1, d2, const Color(0xFFFFFF00));
      sliceEdge1.visible = true;

      scene.drawables.addAll([polyEdge, sliceEdge1]);
      scene.clipLines();

      // Since d1 lies on polyEdge (ends at polyEdge), they should NOT clip each other
      expect(polyEdge.gaps, isNull);
      expect(sliceEdge1.gaps, isNull);

      // Now add a crossing SlideEdge in the background at z = 0 crossing sliceEdge1
      SlideDot d3 = SlideDot(v3, v4, Vector.unit(0), const Color(0xFFFFFF00));
      d3.sx = -10;
      d3.sy = 10;
      d3.sz = 0;
      SlideDot d4 = SlideDot(v3, v4, Vector.unit(0), const Color(0xFFFFFF00));
      d4.sx = 10;
      d4.sy = 10;
      d4.sz = 0;
      SlideEdge sliceEdge2 = SlideEdge(d3, d4, const Color(0xFFFFFF00));
      sliceEdge2.visible = true;

      scene.drawables.add(sliceEdge2);
      scene.clipLines();

      // sliceEdge1 is in front at z=10, so no gaps
      expect(sliceEdge1.gaps, isNull);
      // sliceEdge2 is in back at z=0, so it gets a gap around crossing point (0, 10)
      expect(sliceEdge2.gaps, isNotNull);
      expect(sliceEdge2.gaps!.length, 2);
    });
  });
}
