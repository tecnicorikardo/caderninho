// Stub para path_provider no Flutter Web.
// As funções abaixo não fazem nada no web — só existem para compilar.

import 'io_stub.dart';

// StorageDirectory precisa existir aqui pois path_provider real o define
enum StorageDirectory { downloads }

Future<Directory> getApplicationDocumentsDirectory() async => Directory('/stub');

Future<List<Directory>?> getExternalStorageDirectories({
  StorageDirectory? type,
}) async => null;

Future<Directory?> getExternalStorageDirectory() async => null;
