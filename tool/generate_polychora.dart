// Tool to generate 600-cell and 120-cell meshes offline.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

class Vec4 {
  final double x, y, z, w;
  const Vec4(this.x, this.y, this.z, this.w);

  double dot(Vec4 o) => x * o.x + y * o.y + z * o.z + w * o.w;
  double get normSq => dot(this);
  double get norm => math.sqrt(normSq);

  Vec4 normalized() {
    double n = norm;
    return Vec4(x / n, y / n, z / n, w / n);
  }

  Vec4 add(Vec4 o) => Vec4(x + o.x, y + o.y, z + o.z, w + o.w);
  Vec4 sub(Vec4 o) => Vec4(x - o.x, y - o.y, z - o.z, w - o.w);
  Vec4 scale(double s) => Vec4(x * s, y * s, z * s, w * s);

  List<double> toList() => [x, y, z, w];
}

void main() {
  print('Generating 600-cell and 120-cell meshes...');
  generate600Cell();
  generate120Cell();
  print('Done generating meshes.');
}

void generate600Cell() {
  double phi = (1.0 + math.sqrt(5.0)) / 2.0;

  List<Vec4> rawVerts = [];

  // 1. 16 vertices of the form (+-1/2, +-1/2, +-1/2, +-1/2)
  for (int s0 in [-1, 1]) {
    for (int s1 in [-1, 1]) {
      for (int s2 in [-1, 1]) {
        for (int s3 in [-1, 1]) {
          rawVerts.add(Vec4(0.5 * s0, 0.5 * s1, 0.5 * s2, 0.5 * s3));
        }
      }
    }
  }

  // 2. 8 vertices from permutations of (+-1, 0, 0, 0)
  for (int i = 0; i < 4; i++) {
    for (int s in [-1, 1]) {
      List<double> c = [0, 0, 0, 0];
      c[i] = s.toDouble();
      rawVerts.add(Vec4(c[0], c[1], c[2], c[3]));
    }
  }

  // 3. 96 vertices from even permutations of (+-phi/2, +-1/2, +-1/(2*phi), 0)
  double a = phi / 2.0;
  double b = 0.5;
  double c = 1.0 / (2.0 * phi);
  double d = 0.0;

  List<List<int>> evenPerms = [
    [0, 1, 2, 3],
    [0, 2, 3, 1],
    [0, 3, 1, 2],
    [1, 0, 3, 2],
    [1, 2, 0, 3],
    [1, 3, 2, 0],
    [2, 0, 1, 3],
    [2, 1, 3, 0],
    [2, 3, 0, 1],
    [3, 0, 2, 1],
    [3, 1, 0, 2],
    [3, 2, 1, 0],
  ];

  for (var p in evenPerms) {
    List<double> base = [a, b, c, d];
    List<double> permVals = [base[p[0]], base[p[1]], base[p[2]], base[p[3]]];
    for (int s0 in [-1, 1]) {
      for (int s1 in [-1, 1]) {
        for (int s2 in [-1, 1]) {
          // coordinate matching d (which is 0) has no sign change
          List<double> signedVals = List.from(permVals);
          for (int k = 0; k < 4; k++) {
            if (p[k] == 0) signedVals[k] *= s0;
            if (p[k] == 1) signedVals[k] *= s1;
            if (p[k] == 2) signedVals[k] *= s2;
          }
          rawVerts.add(
              Vec4(signedVals[0], signedVals[1], signedVals[2], signedVals[3]));
        }
      }
    }
  }

  // Deduplicate vertices
  List<Vec4> vertices = [];
  for (var v in rawVerts) {
    bool exists = false;
    for (var u in vertices) {
      if ((v.sub(u)).normSq < 1e-8) {
        exists = true;
        break;
      }
    }
    if (!exists) {
      vertices.add(v.normalized());
    }
  }

  print('600-cell vertices count: ${vertices.length} (expected 120)');
  assert(vertices.length == 120);

  // Edges: connected if distance is 1/phi = phi - 1 ≈ 0.618034
  double edgeLen = 1.0 / phi;
  double targetDistSq = edgeLen * edgeLen;

  List<List<int>> edges = [];
  Map<int, List<int>> adj = {};
  for (int i = 0; i < vertices.length; i++) {
    adj[i] = [];
  }

  for (int i = 0; i < vertices.length; i++) {
    for (int j = i + 1; j < vertices.length; j++) {
      double d2 = (vertices[i].sub(vertices[j])).normSq;
      if ((d2 - targetDistSq).abs() < 1e-4) {
        edges.add([i, j]);
        adj[i]!.add(j);
        adj[j]!.add(i);
      }
    }
  }

  print('600-cell edges count: ${edges.length} (expected 720)');
  assert(edges.length == 720);

  // Map edge (u, v) with u < v to edge index
  Map<String, int> edgeIndexMap = {};
  for (int idx = 0; idx < edges.length; idx++) {
    int u = math.min(edges[idx][0], edges[idx][1]);
    int v = math.max(edges[idx][0], edges[idx][1]);
    edgeIndexMap['$u,$v'] = idx;
  }

  int getEdge(int u, int v) {
    int a = math.min(u, v);
    int b = math.max(u, v);
    return edgeIndexMap['$a,$b']!;
  }

  // Faces: 3-cliques of mutual neighbors
  List<List<int>> faceVertices = [];
  List<List<int>> faces = [];
  for (int i = 0; i < vertices.length; i++) {
    var neighborsI = adj[i]!;
    for (int j in neighborsI) {
      if (j > i) {
        for (int k in adj[j]!) {
          if (k > j && neighborsI.contains(k)) {
            faceVertices.add([i, j, k]);
            // Ordered cycle of edge indices
            faces.add([getEdge(i, j), getEdge(j, k), getEdge(k, i)]);
          }
        }
      }
    }
  }

  print('600-cell faces count: ${faces.length} (expected 1200)');
  assert(faces.length == 1200);

  Map<String, int> faceIndexMap = {};
  for (int idx = 0; idx < faceVertices.length; idx++) {
    var f = List<int>.from(faceVertices[idx])..sort();
    faceIndexMap['${f[0]},${f[1]},${f[2]}'] = idx;
  }

  int getFace(int u, int v, int w) {
    var f = [u, v, w]..sort();
    return faceIndexMap['${f[0]},${f[1]},${f[2]}']!;
  }

  // Cells: 4-cliques of mutual neighbors (tetrahedra)
  List<List<int>> cells = [];
  List<List<int>> cellVerts = [];
  for (int idx = 0; idx < faceVertices.length; idx++) {
    var tri = faceVertices[idx];
    int u = tri[0], v = tri[1], w = tri[2];
    for (int m in adj[w]!) {
      if (m > w && adj[u]!.contains(m) && adj[v]!.contains(m)) {
        cellVerts.add([u, v, w, m]);
        // 4 faces of tetrahedron
        cells.add([
          getFace(u, v, w),
          getFace(u, v, m),
          getFace(u, w, m),
          getFace(v, w, m)
        ]);
      }
    }
  }

  print('600-cell cells count: ${cells.length} (expected 600)');
  assert(cells.length == 600);

  var jsonMap = {
    'dim': 4,
    'name': '600 Cell',
    'vertices': vertices.map((v) => v.toList()).toList(),
    'edges': edges,
    'faces': faces,
    'cells': cells,
  };

  File('assets/mesh/cell600.json').writeAsStringSync(jsonEncode(jsonMap));
  print(
      'Saved assets/mesh/cell600.json (${File('assets/mesh/cell600.json').lengthSync()} bytes)');
}

void generate120Cell() {
  // Read 600-cell to compute dual
  var json600 = jsonDecode(File('assets/mesh/cell600.json').readAsStringSync());
  List verts600Raw = json600['vertices'];
  List cells600Raw = json600['cells'];
  List faces600Raw = json600['faces'];
  List edges600Raw = json600['edges'];

  List<Vec4> verts600 =
      verts600Raw.map((v) => Vec4(v[0], v[1], v[2], v[3])).toList();

  // 1. Dual Vertices: 600 centers of cells in 600-cell
  // To get vertices of each cell, each face has edges, each edge has vertices.
  List<List<int>> cellVertIndices = [];
  for (var c in cells600Raw) {
    Set<int> vSet = {};
    for (int fIdx in c) {
      for (int eIdx in faces600Raw[fIdx]) {
        vSet.add(edges600Raw[eIdx][0] as int);
        vSet.add(edges600Raw[eIdx][1] as int);
      }
    }
    cellVertIndices.add(vSet.toList()..sort());
  }

  List<Vec4> vertices120 = [];
  for (var cv in cellVertIndices) {
    Vec4 sum = Vec4(0, 0, 0, 0);
    for (int vIdx in cv) {
      sum = sum.add(verts600[vIdx]);
    }
    vertices120.add(sum.normalized());
  }
  print('120-cell vertices count: ${vertices120.length} (expected 600)');
  assert(vertices120.length == 600);

  // 2. Dual Edges: Connect two cell centers if they share a face (triangular face)
  // Find which cells share each face in 600-cell
  Map<int, List<int>> faceToCells = {};
  for (int cIdx = 0; cIdx < cells600Raw.length; cIdx++) {
    for (int fIdx in cells600Raw[cIdx]) {
      faceToCells.putIfAbsent(fIdx, () => []).add(cIdx);
    }
  }

  // Each face in 600-cell is shared by exactly 2 cells
  List<List<int>> edges120 = [];
  Map<int, List<int>> adj120 = {};
  for (int i = 0; i < vertices120.length; i++) {
    adj120[i] = [];
  }

  for (int fIdx = 0; fIdx < faces600Raw.length; fIdx++) {
    var pair = faceToCells[fIdx]!;
    assert(pair.length == 2);
    int u = math.min(pair[0], pair[1]);
    int v = math.max(pair[0], pair[1]);
    edges120.add([u, v]);
    adj120[u]!.add(v);
    adj120[v]!.add(u);
  }

  print('120-cell edges count: ${edges120.length} (expected 1200)');
  assert(edges120.length == 1200);

  Map<String, int> edge120Map = {};
  for (int idx = 0; idx < edges120.length; idx++) {
    int u = edges120[idx][0];
    int v = edges120[idx][1];
    edge120Map['$u,$v'] = idx;
    edge120Map['$v,$u'] = idx;
  }

  int getEdge120(int u, int v) => edge120Map['$u,$v']!;

  // 3. Dual Faces: Each edge in 600-cell corresponds to a pentagonal face in 120-cell
  // An edge in 600-cell is surrounded by 5 tetrahedra.
  // Their 5 centers in 120-cell form a planar regular pentagon.
  Map<int, List<int>> edgeToCells600 = {};
  for (int cIdx = 0; cIdx < cells600Raw.length; cIdx++) {
    Set<int> cellEdges = {};
    for (int fIdx in cells600Raw[cIdx]) {
      for (var eIdx in faces600Raw[fIdx]) {
        cellEdges.add(eIdx as int);
      }
    }
    for (int eIdx in cellEdges) {
      edgeToCells600.putIfAbsent(eIdx, () => []).add(cIdx);
    }
  }

  List<List<int>> faces120 = [];
  for (int eIdx = 0; eIdx < edges600Raw.length; eIdx++) {
    var cycleCells = edgeToCells600[eIdx]!;
    assert(cycleCells.length == 5);

    // Order the 5 vertices into a cycle by edge adjacency
    List<int> ordered = [cycleCells[0]];
    Set<int> remaining = cycleCells.sublist(1).toSet();

    while (remaining.isNotEmpty) {
      int curr = ordered.last;
      int next = remaining.firstWhere((cand) => adj120[curr]!.contains(cand));
      ordered.add(next);
      remaining.remove(next);
    }

    // Build cycle of edge indices
    List<int> faceEdgeIndices = [];
    for (int i = 0; i < 5; i++) {
      faceEdgeIndices.add(getEdge120(ordered[i], ordered[(i + 1) % 5]));
    }
    faces120.add(faceEdgeIndices);
  }

  print('120-cell faces count: ${faces120.length} (expected 720)');
  assert(faces120.length == 720);

  // 4. Dual Cells: Each vertex in 600-cell corresponds to a dodecahedron in 120-cell.
  // In 600-cell, each vertex is surrounded by 12 edges (which become 12 pentagonal faces in 120-cell).
  Map<int, List<int>> vertToEdges600 = {};
  for (int eIdx = 0; eIdx < edges600Raw.length; eIdx++) {
    int u = edges600Raw[eIdx][0] as int;
    int v = edges600Raw[eIdx][1] as int;
    vertToEdges600.putIfAbsent(u, () => []).add(eIdx);
    vertToEdges600.putIfAbsent(v, () => []).add(eIdx);
  }

  List<List<int>> cells120 = [];
  for (int vIdx = 0; vIdx < verts600.length; vIdx++) {
    var incEdges = vertToEdges600[vIdx]!;
    assert(incEdges.length == 12);
    // Each of the 12 edges in 600-cell has index eIdx, which directly indexes faces120[eIdx]!
    cells120.add(incEdges);
  }

  print('120-cell cells count: ${cells120.length} (expected 120)');
  assert(cells120.length == 120);

  var jsonMap = {
    'dim': 4,
    'name': '120 Cell',
    'vertices': vertices120.map((v) => v.toList()).toList(),
    'edges': edges120,
    'faces': faces120,
    'cells': cells120,
  };

  File('assets/mesh/cell120.json').writeAsStringSync(jsonEncode(jsonMap));
  print(
      'Saved assets/mesh/cell120.json (${File('assets/mesh/cell120.json').lengthSync()} bytes)');

  // Also write lib/mesh_data.dart
  generateDartFile();
}

void generateDartFile() {
  var json600 = jsonDecode(File('assets/mesh/cell600.json').readAsStringSync());
  var json120 = jsonDecode(File('assets/mesh/cell120.json').readAsStringSync());

  var buf = StringBuffer();
  buf.writeln(
      '// Generated by tool/generate_polychora.dart. Do not edit manually.');
  buf.writeln('class MeshData {');
  buf.writeln(
      '  static const Map<String, dynamic> cell600 = <String, dynamic>{');
  buf.writeln('    "dim": 4,');
  buf.writeln('    "name": "600 Cell",');
  buf.writeln('    "vertices": ${jsonEncode(json600['vertices'])},');
  buf.writeln('    "edges": ${jsonEncode(json600['edges'])},');
  buf.writeln('    "faces": ${jsonEncode(json600['faces'])},');
  buf.writeln('    "cells": ${jsonEncode(json600['cells'])},');
  buf.writeln('  };');
  buf.writeln();
  buf.writeln(
      '  static const Map<String, dynamic> cell120 = <String, dynamic>{');
  buf.writeln('    "dim": 4,');
  buf.writeln('    "name": "120 Cell",');
  buf.writeln('    "vertices": ${jsonEncode(json120['vertices'])},');
  buf.writeln('    "edges": ${jsonEncode(json120['edges'])},');
  buf.writeln('    "faces": ${jsonEncode(json120['faces'])},');
  buf.writeln('    "cells": ${jsonEncode(json120['cells'])},');
  buf.writeln('  };');
  buf.writeln('}');

  File('lib/mesh_data.dart').writeAsStringSync(buf.toString());
  print(
      'Saved lib/mesh_data.dart (${File('lib/mesh_data.dart').lengthSync()} bytes)');
}
