import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart' show databaseFactoryIo;
import 'package:sembast_web/sembast_web.dart' show databaseFactoryWeb;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'dart:io' show Platform;

class DatabaseService {
  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;

    if (Platform.isAndroid || Platform.isIOS) {
      final dir = await getApplicationDocumentsDirectory();
      await dir.create(recursive: true);
      _db = await databaseFactoryIo.openDatabase(join(dir.path, 'app.db'));
    } else {
      _db = await databaseFactoryWeb.openDatabase('app.db');
    }
    return _db!;
  }
}
