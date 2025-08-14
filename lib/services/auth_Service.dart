import 'dart:convert';
import 'package:bytelogik/services/sembast.dart';
import 'package:crypto/crypto.dart';
import 'package:sembast/sembast.dart';
import '../models/user.dart'; 

class AuthService {
  final _store = stringMapStoreFactory.store('users');
  final DatabaseService _dbService = DatabaseService();

  String _hash(String password) => sha256.convert(utf8.encode(password)).toString();

  Future<User> signUp(String email, String password) async {
    final db = await _dbService.database;
    final existing = await _store.findFirst(db, finder: Finder(filter: Filter.equals('email', email)));
    if (existing != null) throw Exception('Email already exists');

    final user = User(id: DateTime.now().toIso8601String(), email: email, password: _hash(password));
    await _store.record(user.id).put(db, user.toMap());
    return user;
  }

  Future<User> signIn(String email, String password) async {
    final db = await _dbService.database;
    final existing = await _store.findFirst(db, finder: Finder(filter: Filter.equals('email', email)));
    if (existing == null) throw Exception('User not found');

    final user = User.fromMap(existing.value);
    if (user.password != _hash(password)) throw Exception('Invalid password');
    return user;
  }
}
