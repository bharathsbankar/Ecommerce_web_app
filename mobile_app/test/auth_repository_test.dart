import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/core/errors/failures.dart';
import 'package:mobile_app/core/storage/secure_storage.dart';
import 'package:mobile_app/features/auth/data/auth_repository.dart';

// Self-contained Mock Storage to avoid flutter_secure_storage native channel errors in unit tests
class MockSecureStorage implements SecureStorage {
  final Map<String, String> _data = {};

  @override
  Future<void> saveToken(String token) async {
    _data['jwt_token'] = token;
  }

  @override
  Future<String?> getToken() async {
    return _data['jwt_token'];
  }

  @override
  Future<void> saveUser(Map<String, dynamic> user) async {
    _data['user_data'] = jsonEncode(user);
  }

  @override
  Future<Map<String, dynamic>?> getUser() async {
    final val = _data['user_data'];
    if (val == null) return null;
    return jsonDecode(val) as Map<String, dynamic>;
  }

  @override
  Future<void> clearAll() async {
    _data.clear();
  }
}

// Self-contained Mock Adapter for Dio
class MockDioAdapter implements HttpClientAdapter {
  ResponseBody Function(RequestOptions options)? handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (handler != null) {
      return handler!(options);
    }
    return ResponseBody.fromString(
      '{}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('AuthRepository Unit Tests', () {
    late Dio dio;
    late MockDioAdapter mockAdapter;
    late MockSecureStorage mockStorage;
    late AuthRepository repository;

    setUp(() {
      dio = Dio();
      mockAdapter = MockDioAdapter();
      dio.httpClientAdapter = mockAdapter;
      mockStorage = MockSecureStorage();
      repository = AuthRepository(dio, mockStorage);
    });

    test('Login Success stores token and user details', () async {
      final mockResponseData = {
        'token': 'mock-jwt-token-123',
        'user': {
          'id': 9,
          'email': 'admin@gmail.com',
          'username': 'admin',
          'role': 'admin',
        }
      };

      mockAdapter.handler = (options) {
        return ResponseBody.fromString(
          jsonEncode(mockResponseData),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      final user = await repository.login('admin@gmail.com', 'admin');

      expect(user.id, 9);
      expect(user.role, 'admin');
      
      // Verify saved in MockStorage
      expect(await mockStorage.getToken(), 'mock-jwt-token-123');
      final savedUser = await mockStorage.getUser();
      expect(savedUser?['username'], 'admin');
    });

    test('Login Failure throws AuthFailure', () async {
      mockAdapter.handler = (options) {
        return ResponseBody.fromString(
          jsonEncode({'error': 'Invalid credentials'}),
          401,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      expect(
        () async => await repository.login('admin@gmail.com', 'wrong_pass'),
        throwsA(isA<AuthFailure>()),
      );
    });
  });
}
