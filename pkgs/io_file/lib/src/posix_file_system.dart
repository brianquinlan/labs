// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' as io;

import 'package:stdlibc/stdlibc.dart' as stdlibc;

import 'file_system.dart';

final class PosixMetaData implements Metadata {
  @override
  // TODO: implement isDirectory
  bool get isDirectory => throw UnimplementedError();

  @override
  // TODO: implement isFile
  bool get isFile => throw UnimplementedError();

  @override
  // TODO: implement isLink
  bool get isLink => throw UnimplementedError();

  /// ID of device containing file
  final int st_dev;

  /// Index node number
  final int st_ino;

  /// Number of hard links
  final int st_nlink;

  /// Protection
  final int st_mode;

  /// User ID of owner
  final int st_uid;

  /// Group ID of owner
  final int st_gid;

  /// Device ID (if special file)
  final int st_rdev;

  /// Total size, in bytes
  final int st_size;

  /// Blocksize for file system I/O
  final int st_blksize;

  /// Number of 512B blocks allocated
  final int st_blocks;

  /// Time of last access
  final DateTime st_atim;

  /// Time of last modification
  final DateTime st_mtim;

  /// Time of last status change
  final DateTime st_ctim;

  /// User defined flags
  ///
  /// Only available on macOS.
  final int? st_flags;
}

Exception _getError(int errno, String message, String path) {
  // TODO: In the long-term, do we need to avoid exceptions that are part of
  // `dart:io`? Can we move those exceptions into a different namespace?
  final osError = io.OSError(stdlibc.strerror(errno) ?? '', errno);

  if (errno == stdlibc.EPERM || errno == stdlibc.EACCES) {
    return io.PathAccessException(path, osError, message);
  } else if (errno == stdlibc.EEXIST) {
    return io.PathExistsException(path, osError, message);
  } else if (errno == stdlibc.ENOENT) {
    return io.PathNotFoundException(path, osError, message);
  } else {
    return io.FileSystemException(message, path, osError);
  }
}

/// A [FileSystem] implementation for POSIX systems (e.g. Android, iOS, Linux,
/// macOS).
base class PosixFileSystem extends FileSystem {
  Metadata metadata(String path) {
    final stat = stdlibc.stat(path);
    if (stat == null) {
      final errno = stdlibc.errno;
      throw _getError(errno, 'metadata failed', path);
    }
  }

  @override
  void rename(String oldPath, String newPath) {
    // See https://pubs.opengroup.org/onlinepubs/000095399/functions/rename.html
    if (stdlibc.rename(oldPath, newPath) != 0) {
      final errno = stdlibc.errno;
      throw _getError(errno, 'rename failed', oldPath);
    }
  }
}
