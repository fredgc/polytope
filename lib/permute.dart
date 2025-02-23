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

class Permutation {
  List<int> image;

  Permutation(int k) : image = List<int>.filled(k + 1, 0) {
    for (int i = 0; i < k; i++) image[i] = i;
  }

  // Change k to map to ik.
  void setMap(int k, int ik) {
    if (k >= image.length) {
      // Maybe we have to make the array bigger.
      List<int> temp = image = List<int>.filled(k + 1, 0);
      for (int j = 0; j <= k; j++) temp[j] = j;
      for (int j = 0; j < image.length; j++) temp[j] = image[j];
      image = temp;
    }
    image[k] = ik;
  }

  int map(int i) {
    if (i < 0) return i;
    if (i >= image.length) return i;
    return image[i];
  }

  String toString() {
    return "Perm[ " + image.map((p) => "$p").join(", ") + "]";
  }
}
