import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart' as sembast_io;
import 'package:sembast_web/sembast_web.dart' as sembast_web;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

class DatabaseService {
  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;

    if (kIsWeb) {
      _db = await sembast_web.databaseFactoryWeb.openDatabase('app.db');
    } else {
      final dir = await getApplicationDocumentsDirectory();
      await dir.create(recursive: true);
      _db = await sembast_io.databaseFactoryIo.openDatabase(join(dir.path, 'app.db'));
    }
    return _db!;
  }
}
