// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:logging/logging.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    final packageName = input.packageName;
    if (input.config.code.targetOS == OS.windows) return;
    await CBuilder.library(
      name: packageName,
      assetName: 'libc_shim',
      sources: ['src/libc_shim.c', 'src/constants.g.c'],
      flags: ['-Weverything'],
    ).run(
      input: input,
      output: output,
      logger:
          Logger('')
            ..level = Level.ALL
            ..onRecord.listen((record) => print(record.message)),
    );
  });
}
