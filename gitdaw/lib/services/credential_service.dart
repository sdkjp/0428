import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CredentialService {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'github_token';
  static const _usernameKey = 'github_username';

  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<String?> getToken() => _storage.read(key: _tokenKey);

  Future<void> saveUsername(String username) =>
      _storage.write(key: _usernameKey, value: username);

  Future<String?> getUsername() => _storage.read(key: _usernameKey);

  Future<void> clearAll() => _storage.deleteAll();
}
