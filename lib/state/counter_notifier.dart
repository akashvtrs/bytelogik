import 'package:bytelogik/services/counterservice.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; 

class CounterNotifier extends StateNotifier<int> {
  final CounterService _service;
  final String _userId;

  CounterNotifier(this._service, this._userId) : super(0) {
    _load();
  }

  Future<void> _load() async => state = await _service.getValue(_userId);

  Future<void> increment() async {
    state++;
    await _service.setValue(_userId, state);
  }

  Future<void> decrement() async {
    state--;
    await _service.setValue(_userId, state);
  }

  Future<void> reset() async {
    state = 0;
    await _service.setValue(_userId, state);
  }
}
