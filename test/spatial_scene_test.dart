// Copyright 2026 Google LLC
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

import 'package:flutter_test/flutter_test.dart';

import 'package:polytope/polytope.dart';
import 'package:polytope/regular.dart';
import 'package:polytope/scene.dart';
import 'package:polytope/spatial_scene.dart';
import 'package:polytope/transform.dart';
import 'package:polytope/vector.dart';

void main() {
  group('SpatialScene Geometry Tests', () {
    test('3D Cube produces 8 vertex spheres and 12 edge cylinders', () {
      Polytope cube = Regular.cube.make(3);
      CoordinateTransform transform = CoordinateTransform();
      List<Point> points = [for (var v in cube.vertices) v.vertex];
      transform.apply(points);

      SpatialScene spatial = SpatialScene();
      spatial.update(cube, null, transform);

      expect(spatial.sphereCount, equals(8));
      expect(spatial.cylinderCount, equals(12));

      // Buffer lengths
      expect(spatial.sphereBuffer.length, equals(8 * 8));
      expect(spatial.cylinderBuffer.length, equals(12 * 12));

      // No NaN or infinite coordinates
      for (double val in spatial.sphereBuffer) {
        expect(val.isFinite, isTrue);
        expect(val.isNaN, isFalse);
      }
      for (double val in spatial.cylinderBuffer) {
        expect(val.isFinite, isTrue);
        expect(val.isNaN, isFalse);
      }
    });

    test('4D Hypercube produces 16 spheres and 32 cylinders', () {
      Polytope hypercube = Regular.cube.make(4);
      CoordinateTransform transform = CoordinateTransform();
      List<Point> points = [for (var v in hypercube.vertices) v.vertex];
      transform.apply(points);

      SpatialScene spatial = SpatialScene();
      spatial.update(hypercube, null, transform);

      expect(spatial.sphereCount, equals(16));
      expect(spatial.cylinderCount, equals(32));
      expect(spatial.sphereBuffer.length, equals(16 * 8));
      expect(spatial.cylinderBuffer.length, equals(32 * 12));
    });

    test('SpatialScene updates from Scene instance', () {
      Scene scene = Scene();
      scene.setPolytope(Regular.simplex);
      scene.setDim(3); // 3D tetrahedron: 4 vertices, 6 edges
      scene.updateScene();

      SpatialScene spatial = SpatialScene();
      spatial.updateFromScene(scene);

      expect(spatial.sphereCount, equals(4));
      expect(spatial.cylinderCount, equals(6));
    });

    test('SpatialScene with Slice produces slice elements', () {
      Scene scene = Scene();
      scene.setPolytope(Regular.cube);
      scene.setDim(3);
      scene.startAnimation = () {};
      scene.changeSlice(true);
      // Move slider to center of cube (slice height 0)
      scene.slice!.slider.value = 0.0;
      scene.slice!.computeSlice();
      scene.updateScene();

      SpatialScene spatial = SpatialScene();
      spatial.updateFromScene(scene);

      // Cube has 8 base vertices
      expect(spatial.sphereCount, greaterThanOrEqualTo(8));
      // Base cube has 12 edges, slice adds intersecting edge segments
      expect(spatial.cylinderCount, greaterThan(12));
    });
  });
}
