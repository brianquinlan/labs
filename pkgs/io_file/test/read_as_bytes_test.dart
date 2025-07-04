// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:io_file/io_file.dart';
import 'package:io_file/src/internal_constants.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:win32/win32.dart' as win32;

import 'errors.dart' as errors;
import 'fifo.dart';
import 'test_utils.dart';

void main() {
  //TODO(brianquinlan): test with a very long path.

  group('readAsBytes', () {
    late String tmp;
    late String cwd;

    setUp(() {
      tmp = createTemp('readAsBytes');
      cwd = fileSystem.currentDirectory;
      fileSystem.currentDirectory = tmp;
    });

    tearDown(() {
      fileSystem.currentDirectory = cwd;
      deleteTemp(tmp);
    });

    test('non-existant file', () {
      expect(
        () => fileSystem.readAsBytes('doesnotexist'),
        throwsA(
          isA<PathNotFoundException>()
              .having((e) => e.message, 'message', 'open failed')
              .having(
                (e) => e.osError?.errorCode,
                'errorCode',
                Platform.isWindows ? win32.ERROR_FILE_NOT_FOUND : errors.enoent,
              )
              .having((e) => e.path, 'path', 'doesnotexist'),
        ),
      );
    });

    test('directory', () {
      expect(
        () => fileSystem.readAsBytes(tmp),
        throwsA(
          isA<FileSystemException>()
              .having(
                (e) => e.message,
                'message',
                Platform.isWindows ? 'open failed' : 'read failed',
              )
              .having(
                (e) => e.osError?.errorCode,
                'errorCode',
                Platform.isWindows ? win32.ERROR_ACCESS_DENIED : errors.eisdir,
              )
              .having((e) => e.path, 'path', tmp),
        ),
      );
    });

    test('symlink', () {
      final path1 = '$tmp/file1';
      final path2 = '$tmp/file2';

      final data = randomUint8List(20);
      File(path1).writeAsBytesSync(data);
      Link(path2).createSync(path1);

      expect(fileSystem.readAsBytes(path2), data);
    });

    test('broken symlink', () {
      final path1 = '$tmp/file1';
      final path2 = '$tmp/file2';

      final data = randomUint8List(20);
      File(path1).writeAsBytesSync(data);
      Link(path2).createSync(path1);
      File(path1).deleteSync();

      expect(
        () => fileSystem.readAsBytes(path2),
        throwsA(
          isA<PathNotFoundException>()
              .having((e) => e.message, 'message', 'open failed')
              .having((e) => e.osError?.errorCode, 'errorCode', errors.enoent)
              .having((e) => e.path, 'path', path2),
        ),
      );
    });

    group('fifo (does not have length)', () {
      for (var i = 0; i <= 1024; ++i) {
        test('Read small file: $i bytes', () async {
          final data = randomUint8List(i);

          final fifo =
              (await Fifo.create('$tmp/file'))
                ..write(data)
                ..close();

          expect(fileSystem.readAsBytes(fifo.path), data);
        });
      }

      test('many single byte reads', () async {
        final data = randomUint8List(20);

        final fifo = await Fifo.create('$tmp/file');
        for (var byte in data) {
          fifo
            ..write(Uint8List(1)..[0] = byte)
            ..delay(const Duration(milliseconds: 10));
        }
        fifo.close();

        expect(fileSystem.readAsBytes(fifo.path), data);
      });

      for (var i = blockSize - 2; i <= blockSize + 2; ++i) {
        test('Read close to `blockSize`: $i bytes', () async {
          final data = randomUint8List(i);

          final fifo =
              (await Fifo.create('$tmp/file'))
                ..write(data)
                ..close();

          expect(fileSystem.readAsBytes(fifo.path), data);
        });
      }
    });
    group('regular files', () {
      test('absolute path, long file name', () {
        final data = randomUint8List(20);
        final path = p.join(tmp, 'f' * 255);
        File(path).writeAsBytesSync(data);

        expect(fileSystem.readAsBytes(path), data);
      });

      test('relative path, long file name', () {
        final data = randomUint8List(20);
        final path = 'f' * 255;
        File(path).writeAsBytesSync(data);

        expect(fileSystem.readAsBytes(path), data);
      });

      for (var i = 0; i <= 1024; ++i) {
        test('Read small file: $i bytes', () {
          final data = randomUint8List(i);
          final path = '$tmp/file';

          File(path).writeAsBytesSync(data);
          expect(fileSystem.readAsBytes(path), data);
        });
      }

      for (var i = maxReadSize - 2; i <= maxReadSize + 2; ++i) {
        test('Read close to `maxReadSize`: $i bytes', () {
          final data = randomUint8List(i);
          final path = '$tmp/file1';

          File(path).writeAsBytesSync(data);
          expect(fileSystem.readAsBytes(path), data);
        });
      }

      test('very large file', () {
        // >INT_MAX on macOS, >SSIZE_MAX on Linux.
        // See documentation for `maxReadSize`.
        final data = randomUint8List(1 << 31);
        final path = '$tmp/file';

        File(path).writeAsBytesSync(data);
        expect(fileSystem.readAsBytes(path), data);
      }, skip: 'very slow');
    });
  });
}
