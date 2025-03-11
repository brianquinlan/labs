import 'package:win32/win32.dart';

import 'file_system.dart';

final class WindowsMetadata implements Metadata {
  @override
  // TODO: implement isDirectory
  bool get isDirectory => throw UnimplementedError();

  @override
  // TODO: implement isFile
  bool get isFile => throw UnimplementedError();

  @override
  // TODO: implement isLink
  bool get isLink => throw UnimplementedError();
  
  @override
  // TODO: implement isCharacter
  bool get isCharacter => throw UnimplementedError();
  
  @override
  // TODO: implement isPipe
  bool get isPipe => throw UnimplementedError();
  
  WindowsMetadata() {
    
  }
}

// https://learn.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-getfiletype?redirectedfrom=MSDN
base class PosixFileSystem extends FileSystem {
  Metadata metadata(String path) {
    GetFileType();
    WIN32_FILE_ATTRIBUTE_DATA
    GetFileAttributesEx(path, GetFileExMaxInfoLevel, lpFileInformation)
    if (stat == null) {
      final errno = stdlibc.errno;
      throw _getError(errno, 'metadata failed', path);
    }
  }
}
