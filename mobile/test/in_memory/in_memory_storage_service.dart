// ABOUTME: In-memory implementation of StorageService for testing
// ABOUTME: Provides key-value storage without persistence

class InMemoryStorageService {
  final Map<String, dynamic> _storage = {};

  Future<void> set(String key, dynamic value) async {
    _storage[key] = value;
  }

  Future<T?> get<T>(String key) async => _storage[key] as T?;

  Future<void> remove(String key) async {
    _storage.remove(key);
  }

  Future<void> clear() async {
    _storage.clear();
  }

  bool containsKey(String key) => _storage.containsKey(key);
}
