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

// This command line tool will tweak an html file to match the current build.
// In particular, it rewrites $VERSION with the version number.

import 'dart:async';
import 'dart:io';
import 'package:args/args.dart';

const inputOptionName = 'input';
const outputOptionName = 'output';

void main(List<String> arguments) async {
  // The flutter tool will invoke this program with two arguments, one for
  // the `--input` option and one for the `--output` option.
  // `--input` is the original asset file that this program should transform.
  // `--output` is where flutter expects the transformation output to be written to.
  final parser = ArgParser()
    ..addOption(inputOptionName, mandatory: true, abbr: 'i')
    ..addOption(outputOptionName, mandatory: true, abbr: 'o');

  ArgResults argResults = parser.parse(arguments);
  final String inputFilePath = argResults[inputOptionName];
  final String outputFilePath = argResults[outputOptionName];

  try {
    var worker = MyReWriter();
    int result = await worker.rewrite(inputFilePath, outputFilePath);
    print("Done with worker.");
    exit(result);
  } catch (e) {
    // The flutter command line tool will see a non-zero exit code (1 in this case)
    // and fail the build. Anything written to stderr by the asset transformer
    // will be surfaced by flutter.
    stderr.writeln(
      'Unexpected exception when producing grayscale image.\n'
      'Details: $e',
    );
    exit(1);
  }
  print("Done with main.");
}

class MyReWriter {
  String build = "";

  Map<Pattern, String> replacements = {};

  MyReWriter() {
    var env = Platform.environment;
    build = env["FLUTTER_BUILD_MODE"] ?? "-undefined-";
    print("The value of FLUTTER_BUILD_MODE is $build");

    // env.forEach((key, value) {
    //     print("BLUE: Env $key = $value");
    // });
  }

  Future<void> getVersion() async {
    RegExp re = RegExp(r'^version: *(.*)');
    for (String line in await File("pubspec.yaml").readAsLines()) {
      var match = re.firstMatch(line);
      if (match != null) {
        if (match.group(1) == null) {
          stderr.writeln("The version was null! match=$match");
          exit(1);
        }
        String version = match.group(1)!;
        if (build != "release") version = "$version ($build)";
        replacements[RegExp(r'{{ *VERSION *}}')] = version;
        return;
      }
    }
  }

  Future<int> rewrite(String inputFilePath, String outputFilePath) async {
    print("in=$inputFilePath, out=$outputFilePath");
    await getVersion();
    IOSink output = File(outputFilePath).openWrite();
    for (String line in await File(inputFilePath).readAsLines()) {
      replacements.forEach((re, result) {
        line = line.replaceAll(re, result);
      });
      output.writeln(line);
    }
    await output.flush();
    return 0;
  }
}
