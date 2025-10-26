// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Run all code generation and formatting steps.

import 'dart:convert';
import 'dart:io';

import 'package:ffigen/src/executables/ffigen.dart' as ffigen;
import 'build_constants.dart' as build_constants;
import 'build_functions.dart' as build_functions;

void _formatFile(String path) {
  final result = Process.runSync(Platform.executable, [
    'format',
    path,
  ], stderrEncoding: utf8);
  if (result.exitCode != 0) {
    throw Exception('failed to format $path:\n${result.stderr}');
  }
}

void main() async {
  build_constants.main();
  build_functions.main();

  await ffigen.main(['--no-format', '-v', 'severe', '--config', 'misc-ffigen.yaml']);
  await ffigen.main([
    '--no-format',
    '-v',
    'severe',
    '--config',
    'generated-constants-ffigen.yaml',
  ]);
  await ffigen.main([
    '--no-format',
    '-v',
    'severe',
    '--config',
    'generated-functions-ffigen.yaml',
  ]);
  _formatFile('lib/src/constant_bindings.g.dart');
  _formatFile('lib/src/constants.g.dart');
  _formatFile('lib/src/function_bindings.g.dart');
  _formatFile('lib/src/functions.g.dart');
  _formatFile('lib/src/handwritten_constant_bindings.g.dart');
  _formatFile('lib/src/misc_bindings.g.dart');
}
