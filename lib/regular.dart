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

import 'dart:math' as math;

import "transform.dart";
import "printer.dart";
import "polytope.dart";
import "permute.dart";
import "vector.dart";

enum Regular {
  simplex("Simplex"),
  cube("Cube"),
  cross("Cross Type"), // Also called Orthoplex.
  dodec("Dodecahedron"),
  ico("Icosahedron"),
  cell24("24 Cell");

  const Regular(this.name);

  final String name;
  static final int min_dim = 2;
  static final int max_dim = Vector.d;
  static final double golden =
      (math.sqrt(5.0) - 1.0) / 2.0; // The golden ratio.

  Polytope make(int dim) {
    dprint("Make ${name} of dim ${dim}");
    String old_indent = DebugPrint.incIndent("$dim - ");
    Polytope p = make_inner(dim);
    DebugPrint.decIndent(old_indent);
    return p;
  }

  Polytope make_inner(int dim) {
    if (dim == 0) return Vertex();
    if (dim > Vector.d) dim = Vector.d;
    switch (this) {
      case Regular.simplex:
        return makeSimplex(dim);
      case Regular.cube:
        return makeCube(dim);
      case Regular.cross:
        return makeCross(dim);
      case Regular.dodec:
        return makeDodecahedron(dim);
      case Regular.ico:
        return makeIcosahedron(dim);
      case Regular.cell24:
        return makeCell24(dim);
        break;
    }
  }

  Polytope makeSimplex(int dim) {
    Polytope p = Polytope(dim, "Simplex");
    dprint("made sort_id = ${p.sort_id}");
    for (int c = 0; c < p.dim + 1; c++) {
      // Each cell of a simplex is a simplex.
      Polytope cell = simplex.make(p.dim - 1);
      cell.setParent(p);
      // Move the vertex c of cell c to be the new vertex numbered p.dim.
      Permutation map = Permutation(p.dim);
      map.setMap(c, p.dim);
      dprint("permuting by $map");
      cell.permute(map);
    }
    p.gather(); // Combine equal cells to be the same object.

    // Now, find the coordinates of this simplex.
    // For 1-dim, we put the two points on either side of the origin.
    if (p.dim == 1) {
      Point? pt0 = p.findPoint(0);
      Point? pt1 = p.findPoint(1);
      pt0!.x[0] = 1;
      pt1!.x[0] = -1;
      dprint("GREEN: Edge.");
      DebugPrint.printPoly(p);
      return p;
    }
    // First, move the first point to (0,0,... r), where r preserves all the
    // edge lengths. I.e. 1^2 + r^2 = l^2. This assumes that each cell is
    // already on the unit sphere.
    double l = p.edgeLength();
    double r = math.sqrt(l * l - 1);
    dprint("BLUE: Before pushing pt 0. l = ${zzz(l)}, ${zzz(r)}");
    DebugPrint.printPoly(p);
    Point? pt = p.findPoint(0);
    dprint("First pt = $pt. dim = $dim");
    for (int i = 0; i < p.dim - 1; i++) pt!.x[i] = 0;
    pt!.x[p.dim - 1] = r;
    dprint("BLUE: After push. Before scale and translate.");
    DebugPrint.printPoly(p);
    Vector center = p.findCenter();
    dprint("center = ${zzz(center)}");
    // Next, we translate so that it is centered.
    Vector offset = p.findCenter()..scale(-1.0);
    p.translate(offset);
    pt = p.findPoint(0);
    double s = 1.0 / pt!.norm();
    dprint(
        "BLUE: after translate by ${zzz(offset)}. Before scale. s = ${zzz(s)}");
    DebugPrint.printPoly(p);
    // Then we scale to put it on the unit sphere.
    p.scale(s);
    dprint("GREEN: after scale ${zzz(s)} and translate.");
    DebugPrint.printPoly(p);
    return p;
  }

  Polytope makeCube(int dim) {
    Polytope p = Polytope(dim, "Cube");
    // We have to permute each cell so that it's vertices are
    // using the right points.  The cell are numbered by i=0,1,...d-1 and
    // j = 0,1.   The first i coordinates of the vertices should stay the
    // same, the jth coordinate should always be +1 or -1.  The rest of the
    // coordinates are shifted over one.
    for (int i = 0; i < p.dim; i++) {
      for (int j = 0; j < 2; j++) {
        Polytope cell = cube.make(p.dim - 1);
        cell.setParent(p);

        int mask = exp2(i) - 1; // A bit mask for the first i bits.
        Permutation map = new Permutation(exp2(p.dim));
        for (int k = 0; k < exp2(p.dim); k++) {
          int image = mask & k; // The first i bits stay the same.
          image += (k & ~mask) << 1; // Shift the others over by 1 bit.
          image += (j << i); // Set the ith bit to be j.
          map.setMap(k, image);
        }
        ;
        cell.permute(map);
      }
    }
    // dprint("after adding cells.");
    // DebugPrint.printPoly(p);

    p.gather();
    p.collapse();

    dprint("After permuting.");
    DebugPrint.printPoly(p);

    // The coordinates of a cube are (+/-1, +/-1, +/-1, ...)/sqrt(d) where
    // the scaling factor is choosen so that the points are on the unit
    // sphere.  To decide on the sign of the jth coordinate of the ith
    // point, write i in base 2, and use the jth digit of i.
    // The jth digit of i is 1 if  i & 2^j > 0.
    double s = (1.0 / math.sqrt(p.dim.toDouble()));
    dprint("s = ${zzz(s)}");
    for (int i = 0; i < exp2(p.dim); i++) {
      Point? pt = p.findPoint(i);
      dprint("For cube ${p.sort_id}, looking at point $i = $pt");
      for (int j = 0; j < p.dim; j++) {
        pt!.x[j] = s * plusMinus(i & exp2(j));
      }
      ;
      dprint("... moved to point $i = $pt");
    }
    return p;
  }

  Polytope makeCross(int dim) {
    Polytope p = Polytope(dim, "Cross");
    // A cross-type has 2^d cells. Each cell is a simplex.
    for (int c = 0; c < exp2(dim); c++) {
      Polytope cell = simplex.make(p.dim - 1);
      cell.setParent(p);
      // Next we have to permute the cell so that it uses the proper
      // vertices.  Each cell is a d-1 simplex with d points.
      // For the first cell, the point i should be sent to 2*i.
      // For the cell c, the point i should be sent to 2*i+1 if
      // the ith bit of c is set.
      Permutation map = new Permutation(p.dim);
      for (int i = 0; i < p.dim; i++) {
        map.setMap(i, 2 * i + ((c >> i) & 1));
      }
      cell.permute(map);
    }
    dprint("------------------ cross type gather.");
    p.gather();
    p.collapse(); // Collapse all of the vertices to the origin.

    // The ith coordinate of the point 2*i is -1, and of the
    // point 2*i+1 is +1.
    for (int i = 0; i < p.dim; i++) {
      Point? pt = p.findPoint(2 * i);
      for (int j = 0; j < p.dim; j++) {
        pt!.x[j] = 0;
      }
      pt!.x[i] = -1.0;

      pt = p.findPoint(2 * i + 1);
      for (int j = 0; j < p.dim; j++) {
        pt!.x[j] = 0;
      }
      pt!.x[i] = 1.0;
    }
    ;
    return p;
  }

  Polytope makeDodecahedron(int dim) {
    // Note: we ignore dim.
    // It has dimension 3, with 12 faces.
    Polytope p = Polytope(3, "Dodecahedron");

    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 2; j++) {
        for (int k = 0; k < 2; k++) {
          int c = 4 * i + 2 * j + k;
          // Each cell is a pentagon.
          Polytope cell = Polytope(2, "Pentagon");
          cell.setParent(p);

          // Compute the 5 vertices on face c.
          List<int> l = List.filled(3, 0);
          List<int> pt = List.filled(5, 0);
          l[i] = 1;
          l[(i + 1) % 3] = j;
          l[(i + 2) % 3] = k;
          pt[0] = l[0] * 4 + l[1] * 2 + l[2];
          pt[1] = 8 + i * 4 + j * 2 + k;
          l[i] = 0;
          l[(i + 1) % 3] = j;
          l[(i + 2) % 3] = k;
          pt[2] = l[0] * 4 + l[1] * 2 + l[2];
          pt[3] = 8 + ((i + 2) % 3) * 4 + 0 * 2 + j;
          pt[4] = 8 + ((i + 2) % 3) * 4 + 1 * 2 + j;

          for (int m = 0; m < 5; m++) {
            Polytope edge = simplex.make(1);
            edge.setParent(cell);

            Permutation map = Permutation(2);
            map.setMap(0, pt[m]);
            map.setMap(1, pt[(m + 1) % 5]);
            edge.permute(map);
          }
          cell.gather();

          dprint("after making face $c.");
          DebugPrint.printPoly(cell);
        }
      }
    }
    p.gather();
    p.collapse();

    // The coordinates of dodecahedron are made up of two sorts:
    // The first first set are just (+/-1, +/-1, +/-1) scaled to
    // by r so that they're on the unit sphere.

    double r = (1.0 / math.sqrt(3.0));

    for (int i = 0; i < 2; i++) {
      for (int j = 0; j < 2; j++) {
        for (int k = 0; k < 2; k++) {
          int c = 4 * i + 2 * j + k;
          Point? pt = p.findPoint(c);
          pt!.x[0] = r * plusMinus(i);
          pt!.x[1] = r * plusMinus(j);
          pt!.x[2] = r * plusMinus(k);
        }
      }
    }
    // The second type are made up of x_i = +/- gr and x_(i+1) = +/- 1/gr.
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 2; j++) {
        for (int k = 0; k < 2; k++) {
          int c = 8 + 4 * i + 2 * j + k;
          Point? pt = p.findPoint(c);
          pt!.x[(i + 1) % 3] = (r * plusMinus(j) * golden);
          pt!.x[(i + 2) % 3] = ((r * plusMinus(k))) / golden;
        }
      }
    }
    return p;
    return p;
  }

  Polytope makeIcosahedron(int dim) {
    // Note: we ignore dim.
    // It has dimension 3 with 20 faces.
    Polytope p = Polytope(3, "Icosahedron");
    // There are two types of faces.
    // The first type:
    // TODO: This needs more comments or at least a biblography reference.
    for (int i = 0; i < 3; i++) {
      // 12 cells.
      for (int j = 0; j < 2; j++) {
        for (int k = 0; k < 2; k++) {
          Polytope cell = simplex.make(2);
          cell.setParent(p);
          int c = 4 * i + 2 * j + k;
          Permutation map = Permutation(3);
          map.setMap(0, 4 * i + 2 * j + k);
          map.setMap(1, 4 * ((i + 1) % 3) + 2 * k);
          map.setMap(2, 4 * ((i + 1) % 3) + 2 * k + 1);
          cell.permute(map);
        }
      }
    }
    // The second type:
    for (int i = 0; i < 2; i++) {
      // 8 cells.
      for (int j = 0; j < 2; j++) {
        for (int k = 0; k < 2; k++) {
          Polytope cell = simplex.make(2);
          cell.setParent(p);
          int c = 12 + 4 * i + 2 * j + k;
          Permutation map = Permutation(3);
          map.setMap(0, 4 * 0 + 2 * j + k);
          map.setMap(1, 4 * 1 + 2 * k + i);
          map.setMap(2, 4 * 2 + 2 * i + j);
          cell.permute(map);
        }
      }
    }
    p.gather();
    p.collapse();

    // The coordinates of the icosahedron are given by x_i = +/-1 and
    // x_(i+1) = +/- gr.  These are then scaled by r so that they lie on
    // the unit sphere.  We need to get all combinations of these points.

    double r = (1.0 / math.sqrt(1.0 + golden * golden));

    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 2; j++) {
        for (int k = 0; k < 2; k++) {
          int c = 4 * i + 2 * j + k;
          Point? pt = p.findPoint(c);
          pt!.x[i] += r * plusMinus(j);
          pt!.x[(i + 1) % 3] += (r * golden * plusMinus(k));
        }
      }
    }
    return p;
  }

  Polytope makeCell24(int dim) {
    // Note: we ignore dim.
    //  The 24 cell has 24 octahedrons as its cells.
    Polytope p = Polytope(4, "Cell24");

    List<int> narray = List.filled(81, 0);
    int m = 0;
    for (int i = 1; i < 3 * 3 * 3; i *= 3) {
      for (int j = 3 * i; j < 3 * 3 * 3 * 3; j *= 3) {
        for (int k = -1; k <= 1; k += 2) {
          for (int l = -1; l <= 1; l += 2) {
            narray[40 + k * i + l * j] = m;
            m++;
          }
        }
      }
    }

    List<int> index = List.filled(4, 0);
    // Place the 8 cells that are parallel to the axis.
    for (int i = 0; i < 4; i++) {
      for (int k = -1; k <= 1; k += 2) {
        for (int j = 0; j < 4; j++) {
          index[j] = 0;
        }
        index[i] = k;
        Permutation map = Permutation(6);
        for (int j = 0; j < 3; j++)
          for (int l = 0; l < 2; l++) {
            index[(i + j + 1) % 4] = 2 * l - 1;
            map.setMap(
                j * 2 + l,
                narray[40 +
                    index[0] +
                    index[1] * 3 +
                    index[2] * 9 +
                    index[3] * 27]);
            index[(i + j + 1) % 4] = 0;
          }
        ;
        Polytope cell = cross.make(3);
        cell.setParent(p);
        cell.permute(map);
      }
    }

    List<List<int>> mapindex = List.filled(6, []);
    for (int i = 0; i < 6; i++) mapindex[i] = List.filled(4, 0);
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) mapindex[2 * i][j] = 1;
      mapindex[2 * i][3] = 0;
      mapindex[2 * i][i] = 0;

      for (int j = 0; j < 3; j++) mapindex[(2 * i + 1)][j] = 0;
      mapindex[2 * i + 1][3] = 1;
      mapindex[2 * i + 1][i] = 1;
    }

    for (index[0] = -1; index[0] <= 1; index[0] += 2) {
      for (index[1] = -1; index[1] <= 1; index[1] += 2) {
        for (index[2] = -1; index[2] <= 1; index[2] += 2) {
          for (index[3] = -1; index[3] <= 1; index[3] += 2) {
            Permutation map = new Permutation(6);
            for (int j = 0; j < 3; j++)
              for (int l = 0; l < 2; l++) {
                int k = 0;
                for (int i = 3; i >= 0; i--)
                  k = 3 * k + mapindex[(j * 2 + l)][i] * index[i];
                map.setMap(j * 2 + l, narray[40 + k]);
              }
            Polytope cell = cross.make(3);
            cell.setParent(p);
            cell.permute(map);
          }
        }
      }
    }

    p.gather();

    // The coordinates of the 24 cell are x_i = +/-r and x_j = +/-r.
    p.collapse();
    double r = (1.0 / math.sqrt(2.0));
    int c = 0;
    for (int i = 0; i < 4; i++) {
      for (int j = i + 1; j < 4; j++) {
        // Start j at i+1 to avoid duplicates.
        for (int k = 0; k < 2; k++) {
          for (int l = 0; l < 2; l++) {
            Point? pt = p.findPoint(c);
            pt!.x[i] = r * plusMinus(k);
            pt!.x[j] = r * plusMinus(l);
            c++;
          }
        }
      }
    }
    return p;
  }

  // Returns 1 if j is positive and -1 otherwise.
  static int plusMinus(int j) {
    if (j > 0) return 1;
    return -1;
  }

  static int exp2(int j) => (1 << j); // Returns 2^j.
}
