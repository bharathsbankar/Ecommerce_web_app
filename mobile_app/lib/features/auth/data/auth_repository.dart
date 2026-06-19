import 'package:dio/dio.dart';
import '../../../core/errors/failures.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../domain/auth_user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthRepository {
  final Dio _dio;
  final SecureStorage _storage;

  AuthRepository(this._dio, this._storage);

  Future<AuthUser> login(String email, String password) async {
    try {
      final response = await _dio.post('/api/auth/login', data: {
        'email': email,
        'password': password,
      });
      
      final token = response.data['token'] as String;
      final userMap = response.data['user'] as Map<String, dynamic>;
      final user = AuthUser.fromJson(userMap);
      
      await _storage.saveToken(token);
      await _storage.saveUser(userMap);
      
      return user;
    } on DioException catch (e) {
      final msg = e.response?.data?['error'] ?? e.message ?? 'Login failed';
      throw AuthFailure(msg);
    } catch (e) {
      throw AuthFailure('An unexpected error occurred: $e');
    }
  }

  Future<void> register(String email, String username, String password, String role) async {
    try {
      await _dio.post('/api/auth/register', data: {
        'email': email,
        'username': username,
        'password': password,
        'role': role,
      });
    } on DioException catch (e) {
      final msg = e.response?.data?['error'] ?? e.message ?? 'Registration failed';
      throw AuthFailure(msg);
    } catch (e) {
      throw AuthFailure('An unexpected error occurred: $e');
    }
  }

  Future<void> logout() async {
    await _storage.clearAll();
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(secureStorageProvider);
  return AuthRepository(dio, storage);
});
