import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/secure_storage.dart';
import 'auth_event.dart';
import 'network_config.dart';

final dioProvider = Provider<Dio>((ref) {
  final networkConfig = ref.watch(networkConfigProvider);
  final secureStorage = ref.watch(secureStorageProvider);

  final dio = Dio(BaseOptions(
    baseUrl: networkConfig.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'Content-Type': 'application/json',
    },
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await secureStorage.getToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      if (kDebugMode) {
        print('--> ${options.method} ${options.uri}');
        print('Headers: ${options.headers}');
        if (options.data != null) {
          print('Body: ${options.data}');
        }
      }
      return handler.next(options);
    },
    onResponse: (response, handler) {
      if (kDebugMode) {
        print('<-- ${response.statusCode} ${response.requestOptions.uri}');
        print('Response: ${response.data}');
      }
      return handler.next(response);
    },
    onError: (DioException e, handler) async {
      if (kDebugMode) {
        print('<-- ERROR ${e.response?.statusCode} ${e.requestOptions.uri}');
        print('Error Message: ${e.message}');
        print('Error Data: ${e.response?.data}');
      }

      // Globally handle 401 Unauthorized
      if (e.response?.statusCode == 401) {
        // Clear secure storage and log out
        await secureStorage.clearAll();
        try {
          ref.read(authExpiredEventProvider.notifier).state = true;
        } catch (_) {}
      }

      return handler.next(e);
    },
  ));

  return dio;
});
