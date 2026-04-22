// Stub para dart:io no Flutter Web.
// Fornece apenas File, Directory e Platform — sem funções de path_provider.

class File {
  File(String path);
  Future<List<int>> readAsBytes() async => [];
  Future<File> writeAsBytes(List<int> bytes, {bool flush = false}) async => this;
  String get path => '';
}

class Directory {
  Directory(this.path);
  final String path;
}

class Platform {
  static bool get isAndroid => false;
  static bool get isIOS => false;
  static bool get isWindows => false;
  static bool get isMacOS => false;
  static bool get isLinux => false;
}
