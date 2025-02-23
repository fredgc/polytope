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

import 'package:polytope/printer.dart';
import 'package:polytope/transform.dart';
import 'package:polytope/vector.dart';
import 'package:test/test.dart';

bool near(Vector v, List<double> answer) {
  final double tolerance = 1e-6;
  double error = 0;
  for (int i = 0; i < Vector.d; i++) {
    double a = i < answer.length ? answer[i] : 0.0;
    error += (v.x[i] - a) * (v.x[i] - a);
  }
  return error < tolerance * tolerance;
}

void main() {
  group('Test arithmetic', () {
    test('addition', () {
      Vector v1 = Vector.unit(1);
      Vector v2 = Vector.unit(3);
      Vector v3 = v1 + v2;
      expect(near(v3, [0, 1, 0, 1]), true);
    });
  });
}
