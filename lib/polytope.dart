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
import 'package:ordered_set/ordered_set.dart';

import "transform.dart";
import "printer.dart";
import "permute.dart";
import "vector.dart";

class Polytope implements Comparable<Polytope> {
  final int dim;
  final String name;
  OrderedSet<Polytope> cells = OrderedSet((a, b) => a.compareTo(b));
  Set<Polytope> parents = {};

  static int polytope_count = 0;
  int get sort_id => poly_id;
  int poly_id = 0;

  Polytope(this.dim, this.name) {
    poly_id = polytope_count++;
  }

  // These can be used in for-each loops.
  VertIterator get vertices => VertIterator(this);
  PolyIterator get edges => PolyIterator(this, 1);
  PolyIterator get faces => PolyIterator(this, 2);

  void setParent(Polytope parent) {
    parent.cells.add(this);
    parents = {parent};
  }

  // Find the vertex with id n, or null if it does not exist.
  Point? findPoint(int n) {
    for (Vertex v in vertices) {
      if (v.id == n) return v.vertex;
    }
    return null;
  }

  void permute(Permutation map) {
    for (var v in vertices) v.permute(map);
    // After permuting, we have changed the order of points.
    for (var edge in edges) edge.cells.rebalanceAll();
  }

  @override
  int compareTo(Polytope other) {
    if (dim != other.dim) {
      return dim.compareTo(other.dim);
    }
    return sort_id.compareTo(other.sort_id);
  }

  // Gather together cells (vertices, edges, faces, etc.). I.e. if two
  // cells are identical, then the second one should just be a pointer to
  // the first.
  void gather() {
    // Start at the bottom (i.e. dim = 0) and go up.
    for (int d = 0; d < dim; d++) {
      // Keep a list of cells to delete, because we cannot modify an iterator
      // while iterating.
      AbsorbList absorb_list = AbsorbList();
      // For each cell of dimension d.
      PolyIterator i1 = PolyIterator(this, d);
      while (i1.moveNext()) {
        PolyIterator i2 = PolyIterator.from(i1);
        while (i2.moveNext()) {
          if (i1.current == i2.current) {
            absorb_list.add(i1.current, i2.current);
          }
        }
      }
      absorb_list.doit();
    }
  }

  // Absorb the dead polytope into this one.  We assume that the cells are
  // already identical, and we add all of their parents to us.
  void absorb(Polytope dead) {
    if (identical(this, dead)) {
      return;
    }
    // First add all of dead's parents to this's parents. And delete dead from
    // the parent's collection of cells.
    parents.addAll(dead.parents);
    for (var parent in dead.parents) {
      parent.cells.remove(dead);
      parent.cells.add(this);
    }
    dead.parents.clear();
    // Next, remove dead from the parent collection in all of the cells.
    for (var cell in dead.cells) {
      cell.parents.remove(dead);
      cell.parents.add(this);
    }
    dead.cells.clear();
  }

  // The number of cells (or subcells) if dimension d.
  int size(int d) {
    int count = 0;
    PolyIterator it = PolyIterator(this, d);
    while (it.moveNext()) count++;
    return count;
  }

  // Move each vertex to the origin.
  void collapse() {
    scale(0);
  }

  void scale(double s) {
    for (var v in vertices) {
      v.vertex.scale(s);
    }
  }

  void translate(Vector v) {
    for (var vert in vertices) {
      vert.vertex.add(v);
    }
  }

  // Rotate the polytope so that the vector a ends up at b. The vector b will be
  // normalized.
  void rotateInto(Vector a, Vector b) {
    // Normalize b.
    b.scale(1.0 / b.norm());
    // Project a onto the perpendicular to b: a' = a - (a * b) * b
    double ct = b.dot(a); // Component of a in the direction b.
    Vector ap = a - b * ct;
    double norm = ap.norm();
    if (norm == 0) {
      return; // If a is already in the direction of b, nothing to do.
    }
    // Normalize ap:
    ap.scale(1.0 / norm);
    // The rotation of the point p will be as follows.  First project
    // p onto  a' and b, using ac = <p,a'> and bc = <p,b>.  Then
    // subtract off the component of p in these two directions:
    // p' = p - ac*a' - bc*b.  Then add the new components in these
    // directions: p'' = p' + (cos(theta)*ac - sin(theta)*bc) a'
    //                      + (sin(theta)*ac + cos(theta)*bc) b
    //                 =  p + (-ac + cos(theta)*ac - sin(theta)*bc) a'
    //                      + (-bc + sin(theta)*ac + cos(theta)*bc) b
    // If we let ct1 = cos(theta) -1, and st = sin(theta), we'll get
    // p'' = p+ (ct1*ac - st*bc)*a' + (st*ac + ct1*bc)*b.
    double st = ap.dot(a); // The component of a in the direction a'.
    double l = math
        .sqrt(ct * ct + st * st); // Length of component of a in plane (a', b).
    // Normailze {ct, st}.
    ct = ct / l;
    st = st / l;
    double ct1 = ct - 1.0;
    for (var v in vertices) {
      Point pt = v.vertex;
      double ac = pt.dot(ap); // Project pt onto span(b,a').
      double bc = pt.dot(b);
      Vector temp1 = ap * (ct1 * ac - st * bc);
      Vector temp2 = b * (st * ac + ct1 * bc);
      pt.add(temp1);
      pt.add(temp2);
    }
  }

  // Rotate the polytope so that a cell of dimension d points in the
  // direction of the unit vector e_h, where h = dimension of the polytope.
  void cellFirst(int d) {
    // Find a cell of dimension d.
    for (var cell in PolyIterator(this, d)) {
      // Move the whole polytope so that it is centered at 0.
      Point center = findCenter();
      center.scale(-1.0);
      translate(center);

      // We want this to end up pointing up.
      Point cell_center = cell.findCenter();
      //print("For d=$d, center=${zzz(center)}, cell " +
      //    "center = ${zzz(cell_center)}");

      int h = dim - 1;
      Vector b = Vector.unit(h);
      rotateInto(cell_center, b);

      // Move the whole polytope back to where it was centered before.
      center.scale(-1.0);
      translate(center);
      return; // Just do this for the first cell found.
    }
    assert(false); // Did not find any d-dim cells.
  }

  Point findCenter() {
    Point center = Point();
    int count = 0;
    for (var v in vertices) {
      count++;
      center.add(v.vertex);
    }
    if (count > 0) {
      double r = 1.0 / count.toDouble();
      center.scale(r);
    }
    return center;
  }

  double edgeLength() {
    for (var e in edges) {
      assert(e.cells.length == 2);
      Vertex v1 = e.cells.elementAt(0) as Vertex;
      Vertex v2 = e.cells.elementAt(1) as Vertex;
      Vector delta = v2.vertex - v1.vertex;
      return delta.norm();
    }
    dprint("XXX -- there are no edges!");
    return 0.0;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Polytope) return false;
    Polytope that = other as Polytope;
    if (dim != that.dim) return false;
    if (cells.length != that.cells.length) return false;
    var it1 = cells.iterator;
    var it2 = other.cells.iterator;
    while (it1.moveNext() && it2.moveNext()) {
      if (it1.current.sort_id != it2.current.sort_id) return false;
    }
    return true;
  }

  @override
  String toString() {
    return "${dim}-${name}-${sort_id}";
  }

  void printSelf(String indent) {
    String clist = cells.toList().map((p) => "${p.poly_id}").join(", ");
    String plist = parents.toList().map((p) => "${p.poly_id}").join(", ");
    print("${indent}$this. ${cells.length} cells ($clist)." +
        " ${parents.length} parents ($plist)");
  }

  void printConcise() {
    String indent = "";
    for (int d = dim; d >= 0; d--) {
      print(indent + "cell of dim=$d");
      indent = indent + "  ";
      for (var cell in PolyIterator(this, d)) {
        cell.printSelf(indent);
      }
    }
  }

  void printAll({String indent = ""}) {
    String plist = parents.toList().map((p) => "${p.poly_id}").join(", ");
    print("${indent}id=${sort_id}. ${cells.length} cells." +
        " ${parents.length} parents $plist. $this");
    for (var cell in cells) {
      cell.printAll(indent: indent + "  ");
    }
  }
}

class Vertex extends Polytope {
  Point vertex;
  Vertex({int id = 0})
      : vertex = Point(id: id),
        super(0, "POINT");

  int get id => vertex.id;
  @override
  int get sort_id => vertex.id;

  String toString() {
    return "V${vertex.id}";
  }

  void printSelf(String indent) {
    String plist = parents.toList().map((p) => "${p.poly_id}").join(", ");
    print("${indent}$this ${parents.length} parents ($plist), $vertex");
  }

  void printAll({String indent = ""}) {
    String plist = parents.toList().map((p) => "${p.poly_id}").join(", ");
    print("${indent}id=${sort_id}/${poly_id}. " +
        "${parents.length} parents $plist. $this");
  }

  Point? findPoint(int n) {
    if (n == id) {
      return vertex;
    } else {
      return null;
    }
  }

  void permute(Permutation map) {
    vertex.permute(map);
  }

  Point findCenter() => Point.from(vertex);

  // Two Vertices are equal if their points are equal.
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (!(other is Vertex)) return false;
    Vertex that = other as Vertex;
    return that.vertex == this.vertex;
  }
}

class PolyIterator extends Iterable<Polytope> implements Iterator<Polytope> {
  List<Iterator<Polytope>> iters;
  bool done = false;
  Polytope get current => iters.last.current;
  int dim;
  Iterator<Polytope> get iterator => this;

  // Create an iterator of all subcells that have dimesion dim. We
  // expect dim >= 0, and dim < polytope.dim.
  PolyIterator(Polytope polytope, this.dim) : iters = [] {
    iters.add([polytope].iterator);
    bool result = iters[0].moveNext();
    assert(result, "List has iterator.");
    if (polytope.dim < dim) done = true;
    if (polytope.cells.length == 0) done = true;
  }

  // Copy the iterator from the above, starting at the where the other left off.
  PolyIterator.from(PolyIterator other)
      : iters = [],
        done = other.done,
        dim = other.dim {
    if (done) return;
    iters.add([other.iters[0].current].iterator);
    bool result = iters[0].moveNext();
    assert(result, "List has iterator.");
    for (int i = 1; i < other.iters.length; i++) {
      iters.add(iters[i - 1].current.cells.iterator);
      while (
          iters[i].moveNext() && iters[i].current != other.iters[i].current) {
        // catch this up to other.
      }
    }
  }

  bool moveNext() {
    if (done) return false;
    Polytope top = iters.first.current;
    final int max_depth = top.dim - dim;
    // If we're looking for the top level, then the original polytope is
    // the only element.
    if (max_depth == 0) {
      done = true; // Return true just once.
      return true;
    }
    // Start at the bottom and try to increment. If that fails, then move up.
    int depth = iters.length - 1;
    // Unless the list of iterators is not created, then start at the top.
    if (iters.length == 1) {
      depth = 1;
    }
    while (depth <= max_depth && depth > 0) {
      Polytope parent = iters[depth - 1].current; // depth > 0, so this is ok.
      if (depth >= iters.length) {
        // If this is the first pass, then we need to create the first interator.
        iters.add(parent.cells.iterator);
      }
      if (!iters[depth].moveNext()) {
        // We've exhausted the cells at this depth.
        // Move up one and go forward.
        depth--;
        if (depth == 0) {
          // We have exhausted all depths.
          done = true;
          return false;
        }
      } else {
        Polytope p = iters[depth].current;
        Polytope first_parent = p.parents.first;

        if (first_parent == parent) {
          // This p is good. Use it and go down one depth.
          depth++;
          if (depth > max_depth) {
            return true;
          }
          // Start a new iterator at this depth. Continue this loop at this depth.
          if (depth < iters.length) {
            iters[depth] = p.cells.iterator;
          } else {
            iters.add(p.cells.iterator);
          }
          continue;
        } else {
          // This p has already been used, skip it.
          continue;
        }
      }
    }
    assert(false, "Loop should never finish.");
    return false;
  }
}

class VertIterator extends Iterable<Vertex> implements Iterator<Vertex> {
  PolyIterator iter;
  Vertex get current => iter.current as Vertex;
  Iterator<Vertex> get iterator => this;

  VertIterator(Polytope polytope) : iter = PolyIterator(polytope, 0);
  VertIterator.from(VertIterator other) : iter = PolyIterator.from(other.iter);
  bool moveNext() => iter.moveNext();
}

// A list of absorptions we plan to make.
class AbsorbList {
  List<List<Polytope>> pairs = [];

  void add(Polytope a, Polytope b) {
    pairs.add([a, b]);
  }

  void doit() {
    for (var pair in pairs) {
      pair[0].absorb(pair[1]);
    }
  }
}
