import 'package:bytelogik/services/databaseservice.dart';
import 'package:sembast/sembast.dart'; 
class CounterService {
  final _store = stringMapStoreFactory.store('counters');
  final DatabaseService _dbService = DatabaseService();

  Future<int> getValue(String userId) async {
    final db = await _dbService.database;
    final record = await _store.record(userId).get(db) as Map<String, dynamic>?;
    return (record?['value'] ?? 0) as int;
  }

  Future<void> setValue(String userId, int value) async {
    final db = await _dbService.database;
    await _store.record(userId).put(db, {'value': value});
  }
}
