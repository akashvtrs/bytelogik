import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart' show databaseFactoryIo;
import 'package:sembast_web/sembast_web.dart' show databaseFactoryWeb;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DatabaseService {
  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;

    if (kIsWeb) {
      // Use the web database factory
      _db = await databaseFactoryWeb.openDatabase('app.db');
    } else {
      // Use the IO database factory for mobile/desktop
      final dir = await getApplicationDocumentsDirectory();
      await dir.create(recursive: true);
      _db = await databaseFactoryIo.openDatabase(join(dir.path, 'app.db'));
    }
    return _db!;
  }
}
